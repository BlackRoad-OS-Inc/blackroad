/**
 * BlackRoad Agent OS - Frontend Application
 */

// State
const state = {
    agents: [],
    tasks: [],
    selectedTask: null,
    approvalTask: null,
    ws: null,
    connected: false,
};

// DOM Elements
const elements = {
    connectionStatus: document.getElementById('connection-status'),
    agentCount: document.getElementById('agent-count'),
    agentList: document.getElementById('agent-list'),
    taskForm: document.getElementById('task-form'),
    taskRequest: document.getElementById('task-request'),
    targetAgent: document.getElementById('target-agent'),
    targetRole: document.getElementById('target-role'),
    skipApproval: document.getElementById('skip-approval'),
    approvalQueue: document.getElementById('approval-queue'),
    runningTasks: document.getElementById('running-tasks'),
    taskHistory: document.getElementById('task-history'),
    detailPanel: document.getElementById('detail-panel'),
    detailContent: document.getElementById('detail-content'),
    approvalModal: document.getElementById('approval-modal'),
    approvalModalBody: document.getElementById('approval-modal-body'),
};

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    connectWebSocket();
    setupEventListeners();
});

// WebSocket Connection
function connectWebSocket() {
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const wsUrl = `${protocol}//${window.location.host}/ws/client`;

    state.ws = new WebSocket(wsUrl);

    state.ws.onopen = () => {
        state.connected = true;
        updateConnectionStatus();
        console.log('WebSocket connected');
    };

    state.ws.onclose = () => {
        state.connected = false;
        updateConnectionStatus();
        console.log('WebSocket disconnected, reconnecting...');
        setTimeout(connectWebSocket, 3000);
    };

    state.ws.onerror = (error) => {
        console.error('WebSocket error:', error);
    };

    state.ws.onmessage = (event) => {
        const message = JSON.parse(event.data);
        handleMessage(message);
    };
}

function handleMessage(message) {
    switch (message.type) {
        case 'initial_state':
            state.agents = message.agents || [];
            state.tasks = message.tasks || [];
            renderAll();
            break;

        case 'agent_connected':
            updateAgent(message.agent);
            break;

        case 'agent_disconnected':
            removeAgent(message.agent_id);
            break;

        case 'task_updated':
            updateTask(message.task);
            break;

        case 'task_output':
            appendTaskOutput(message.task_id, message.stream, message.content);
            break;

        case 'command_result':
            updateCommandResult(message);
            break;

        case 'pong':
            // Keep-alive response
            break;

        default:
            console.log('Unknown message type:', message.type);
    }
}

// Event Listeners
function setupEventListeners() {
    elements.taskForm.addEventListener('submit', handleTaskSubmit);

    // Keep-alive ping
    setInterval(() => {
        if (state.ws && state.ws.readyState === WebSocket.OPEN) {
            state.ws.send(JSON.stringify({ type: 'ping' }));
        }
    }, 30000);
}

async function handleTaskSubmit(e) {
    e.preventDefault();

    const request = elements.taskRequest.value.trim();
    if (!request) return;

    const payload = {
        request,
        target_agent_id: elements.targetAgent.value || null,
        target_role: elements.targetRole.value || null,
        skip_approval: elements.skipApproval.checked,
    };

    try {
        const response = await fetch('/api/tasks', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload),
        });

        if (response.ok) {
            elements.taskRequest.value = '';
        } else {
            const error = await response.json();
            alert(`Error: ${error.detail || 'Failed to create task'}`);
        }
    } catch (error) {
        console.error('Failed to create task:', error);
        alert('Failed to create task');
    }
}

// State Updates
function updateAgent(agent) {
    const index = state.agents.findIndex(a => a.id === agent.id);
    if (index >= 0) {
        state.agents[index] = agent;
    } else {
        state.agents.push(agent);
    }
    renderAgents();
}

function removeAgent(agentId) {
    const index = state.agents.findIndex(a => a.id === agentId);
    if (index >= 0) {
        state.agents[index].status = 'offline';
    }
    renderAgents();
}

function updateTask(task) {
    const index = state.tasks.findIndex(t => t.id === task.id);
    if (index >= 0) {
        state.tasks[index] = task;
    } else {
        state.tasks.unshift(task);
    }
    renderTasks();

    if (state.selectedTask && state.selectedTask.id === task.id) {
        state.selectedTask = task;
        renderTaskDetail(task);
    }
}

function appendTaskOutput(taskId, stream, content) {
    if (state.selectedTask && state.selectedTask.id === taskId) {
        const outputEl = document.getElementById('task-output');
        if (outputEl) {
            outputEl.textContent += content;
            outputEl.scrollTop = outputEl.scrollHeight;
        }
    }
}

function updateCommandResult(result) {
    // Update command status in detail view if visible
}

// Rendering
function renderAll() {
    renderAgents();
    renderTasks();
}

function renderAgents() {
    const online = state.agents.filter(a => a.status === 'online').length;
    elements.agentCount.textContent = `${online}/${state.agents.length}`;

    // Update target agent dropdown
    elements.targetAgent.innerHTML = '<option value="">Any Agent</option>';
    state.agents
        .filter(a => a.status === 'online')
        .forEach(agent => {
            const option = document.createElement('option');
            option.value = agent.id;
            option.textContent = agent.display_name || agent.id;
            elements.targetAgent.appendChild(option);
        });

    // Render agent cards
    elements.agentList.innerHTML = state.agents.map(agent => `
        <div class="agent-card ${agent.status}" onclick="selectAgent('${agent.id}')">
            <div class="agent-name">${agent.display_name || agent.id}</div>
            <div class="agent-meta">
                ${agent.hostname} &middot; ${agent.status}
            </div>
            ${agent.roles && agent.roles.length ? `
                <div class="agent-roles">
                    ${agent.roles.map(r => `<span class="role-tag">${r}</span>`).join('')}
                </div>
            ` : ''}
            ${agent.telemetry ? `
                <div class="agent-meta">
                    CPU: ${agent.telemetry.cpu_percent?.toFixed(0) || 0}% &middot;
                    RAM: ${agent.telemetry.memory_percent?.toFixed(0) || 0}%
                </div>
            ` : ''}
        </div>
    `).join('');
}

function renderTasks() {
    const awaiting = state.tasks.filter(t => t.status === 'awaiting_approval');
    const running = state.tasks.filter(t => t.status === 'running');
    const history = state.tasks.filter(t =>
        !['awaiting_approval', 'running', 'pending', 'planning'].includes(t.status)
    ).slice(0, 20);

    elements.approvalQueue.innerHTML = awaiting.length ?
        awaiting.map(renderTaskCard).join('') :
        '<p class="placeholder">No tasks awaiting approval</p>';

    elements.runningTasks.innerHTML = running.length ?
        running.map(renderTaskCard).join('') :
        '<p class="placeholder">No tasks running</p>';

    elements.taskHistory.innerHTML = history.length ?
        history.map(renderTaskCard).join('') :
        '<p class="placeholder">No recent tasks</p>';
}

function renderTaskCard(task) {
    const statusClass = task.status.replace('_', '-');
    const agent = state.agents.find(a => a.id === task.assigned_agent_id);

    return `
        <div class="task-card" onclick="selectTask('${task.id}')">
            <div class="task-header">
                <span class="task-id">#${task.id}</span>
                <span class="status-badge ${statusClass}">${task.status}</span>
            </div>
            <div class="task-request">${escapeHtml(task.request)}</div>
            <div class="task-meta">
                ${agent ? `<span>${agent.display_name || agent.id}</span>` : ''}
                ${task.plan ? `<span class="risk-${task.plan.risk_level}">${task.plan.risk_level} risk</span>` : ''}
                <span>${formatTime(task.created_at)}</span>
            </div>
        </div>
    `;
}

function renderTaskDetail(task) {
    if (!task) {
        elements.detailContent.innerHTML = '<p class="placeholder">Select a task to view details</p>';
        return;
    }

    const agent = state.agents.find(a => a.id === task.assigned_agent_id);

    let html = `
        <div class="detail-section">
            <h3>Request</h3>
            <p>${escapeHtml(task.request)}</p>
        </div>

        <div class="detail-section">
            <h3>Status</h3>
            <span class="status-badge ${task.status}">${task.status}</span>
            ${agent ? `<p style="margin-top: 8px;">Running on: ${agent.display_name || agent.id}</p>` : ''}
        </div>
    `;

    if (task.plan) {
        html += `
            <div class="detail-section">
                <h3>Plan</h3>
                ${task.plan.reasoning ? `<p style="margin-bottom: 8px;">${escapeHtml(task.plan.reasoning)}</p>` : ''}
                <div class="command-list">
                    ${task.plan.commands.map((cmd, i) => `
                        <div class="command-item">
                            <div class="plan-command-dir">${cmd.dir}</div>
                            <div>${escapeHtml(cmd.run)}</div>
                        </div>
                    `).join('')}
                </div>
            </div>
        `;
    }

    if (task.output || task.status === 'running') {
        html += `
            <div class="detail-section">
                <h3>Output</h3>
                <div id="task-output" class="output-display">${escapeHtml(task.output || '')}</div>
            </div>
        `;
    }

    if (task.error) {
        html += `
            <div class="detail-section">
                <h3>Error</h3>
                <div class="output-display" style="color: var(--danger);">${escapeHtml(task.error)}</div>
            </div>
        `;
    }

    if (task.status === 'awaiting_approval') {
        html += `
            <div class="detail-section">
                <button class="btn btn-success" onclick="openApprovalModal('${task.id}')" style="margin-right: 8px;">Review & Approve</button>
                <button class="btn btn-danger" onclick="quickReject('${task.id}')">Reject</button>
            </div>
        `;
    }

    elements.detailContent.innerHTML = html;
    elements.detailPanel.classList.remove('hidden');
}

// Actions
function selectAgent(agentId) {
    elements.targetAgent.value = agentId;
}

function selectTask(taskId) {
    state.selectedTask = state.tasks.find(t => t.id === taskId);
    renderTaskDetail(state.selectedTask);
}

function closeDetailPanel() {
    state.selectedTask = null;
    elements.detailPanel.classList.add('hidden');
}

function openApprovalModal(taskId) {
    state.approvalTask = state.tasks.find(t => t.id === taskId);
    if (!state.approvalTask || !state.approvalTask.plan) return;

    const task = state.approvalTask;
    const plan = task.plan;

    elements.approvalModalBody.innerHTML = `
        <div class="plan-section">
            <h4>Request</h4>
            <p>${escapeHtml(task.request)}</p>
        </div>

        <div class="plan-section">
            <h4>Risk Level</h4>
            <span class="risk-${plan.risk_level}">${plan.risk_level.toUpperCase()}</span>
        </div>

        ${plan.reasoning ? `
            <div class="plan-section">
                <h4>Reasoning</h4>
                <p>${escapeHtml(plan.reasoning)}</p>
            </div>
        ` : ''}

        ${plan.steps && plan.steps.length ? `
            <div class="plan-section">
                <h4>Steps</h4>
                <ol class="plan-steps">
                    ${plan.steps.map(s => `<li>${escapeHtml(s)}</li>`).join('')}
                </ol>
            </div>
        ` : ''}

        <div class="plan-section">
            <h4>Commands</h4>
            <div class="plan-commands">
                ${plan.commands.map(cmd => `
                    <div class="plan-command">
                        <div class="plan-command-dir">${cmd.dir}</div>
                        <code>${escapeHtml(cmd.run)}</code>
                    </div>
                `).join('')}
            </div>
        </div>
    `;

    elements.approvalModal.classList.remove('hidden');
}

function closeApprovalModal() {
    state.approvalTask = null;
    elements.approvalModal.classList.add('hidden');
}

async function approveTask() {
    if (!state.approvalTask) return;

    try {
        const response = await fetch(`/api/tasks/${state.approvalTask.id}/approve`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ task_id: state.approvalTask.id, approved: true }),
        });

        if (response.ok) {
            closeApprovalModal();
        } else {
            const error = await response.json();
            alert(`Error: ${error.detail}`);
        }
    } catch (error) {
        console.error('Failed to approve task:', error);
        alert('Failed to approve task');
    }
}

async function rejectTask() {
    if (!state.approvalTask) return;

    const reason = prompt('Rejection reason (optional):');

    try {
        const response = await fetch(`/api/tasks/${state.approvalTask.id}/approve`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                task_id: state.approvalTask.id,
                approved: false,
                reason: reason || undefined,
            }),
        });

        if (response.ok) {
            closeApprovalModal();
        } else {
            const error = await response.json();
            alert(`Error: ${error.detail}`);
        }
    } catch (error) {
        console.error('Failed to reject task:', error);
        alert('Failed to reject task');
    }
}

async function quickReject(taskId) {
    const reason = prompt('Rejection reason (optional):');

    try {
        await fetch(`/api/tasks/${taskId}/approve`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ task_id: taskId, approved: false, reason }),
        });
    } catch (error) {
        console.error('Failed to reject task:', error);
    }
}

// Utilities
function updateConnectionStatus() {
    elements.connectionStatus.textContent = state.connected ? 'Connected' : 'Disconnected';
    elements.connectionStatus.className = `status-badge ${state.connected ? 'online' : 'offline'}`;
}

function escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function formatTime(isoString) {
    if (!isoString) return '';
    const date = new Date(isoString);
    const now = new Date();
    const diff = now - date;

    if (diff < 60000) return 'just now';
    if (diff < 3600000) return `${Math.floor(diff / 60000)}m ago`;
    if (diff < 86400000) return `${Math.floor(diff / 3600000)}h ago`;
    return date.toLocaleDateString();
}
