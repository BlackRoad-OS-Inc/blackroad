// 🖤🛣️ BlackRoad Domain Registry - Control Panel JavaScript

const API_BASE = 'http://lucidia:8090/api';
const DEPLOY_API = 'http://alice:9001/api';

// Tab Navigation
document.querySelectorAll('.tab').forEach(tab => {
    tab.addEventListener('click', () => {
        const tabName = tab.dataset.tab;

        // Update tabs
        document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
        tab.classList.add('active');

        // Update content
        document.querySelectorAll('.tab-content').forEach(content => {
            content.classList.remove('active');
        });
        document.getElementById(`${tabName}-tab`).classList.add('active');

        // Load data for the tab
        loadTabData(tabName);
    });
});

// Load data based on active tab
function loadTabData(tabName) {
    switch(tabName) {
        case 'domains':
            loadDomains();
            break;
        case 'dns':
            loadDNSRecords();
            break;
        case 'deployments':
            loadDeployments();
            break;
    }
}

// Load Domains
async function loadDomains() {
    const grid = document.getElementById('domains-grid');

    try {
        const response = await fetch(`${API_BASE}/domains`);
        const data = await response.json();

        if (data.success && data.domains.length > 0) {
            grid.innerHTML = data.domains.map(domain => `
                <div class="domain-card">
                    <div class="domain-name">${domain.domain}</div>
                    <div class="domain-info">Registrar: ${domain.registrar || 'N/A'}</div>
                    <div class="domain-info">Status: ${domain.status}</div>
                    <div class="domain-info">Nameservers: ${(domain.nameservers || []).join(', ')}</div>
                    <div class="domain-actions">
                        <button class="btn-primary btn-small" onclick="viewDomain('${domain.domain}')">View</button>
                        <button class="btn-secondary btn-small" onclick="editDNS('${domain.domain}')">DNS</button>
                        <button class="btn-secondary btn-small" onclick="deployDomain('${domain.domain}')">Deploy</button>
                    </div>
                </div>
            `).join('');

            document.getElementById('domain-count').textContent = data.domains.length;
        } else {
            grid.innerHTML = '<div class="loading">No domains found. Add your first domain!</div>';
        }
    } catch (error) {
        console.error('Error loading domains:', error);
        grid.innerHTML = '<div class="loading">Error loading domains. Check API connection.</div>';
    }
}

// Load DNS Records
async function loadDNSRecords() {
    const list = document.getElementById('records-list');

    try {
        const response = await fetch(`${API_BASE}/domains`);
        const data = await response.json();

        if (data.success && data.domains.length > 0) {
            let allRecords = [];

            // Fetch records for each domain
            for (const domain of data.domains) {
                const recordsResponse = await fetch(`${API_BASE}/domains/${domain.domain}/records`);
                const recordsData = await recordsResponse.json();

                if (recordsData.success && recordsData.records) {
                    allRecords = allRecords.concat(recordsData.records.map(r => ({
                        ...r,
                        domain: domain.domain
                    })));
                }
            }

            if (allRecords.length > 0) {
                list.innerHTML = allRecords.map(record => `
                    <div class="record-item">
                        <div class="record-type">${record.record_type}</div>
                        <div class="record-name">${record.name}</div>
                        <div class="record-value">${record.value}</div>
                        <div>${record.ttl}s</div>
                        <button class="btn-secondary btn-small" onclick="deleteRecord('${record.id}')">Delete</button>
                    </div>
                `).join('');

                document.getElementById('record-count').textContent = allRecords.length;
            } else {
                list.innerHTML = '<div class="loading">No DNS records found</div>';
            }
        }
    } catch (error) {
        console.error('Error loading DNS records:', error);
        list.innerHTML = '<div class="loading">Error loading DNS records</div>';
    }
}

// Load Deployments
async function loadDeployments() {
    const list = document.getElementById('deployments-list');

    try {
        const response = await fetch(`${API_BASE}/deployments`);
        const data = await response.json();

        if (data.success && data.deployments && data.deployments.length > 0) {
            list.innerHTML = data.deployments.map(deployment => `
                <div class="record-item">
                    <div>${deployment.domain}</div>
                    <div class="record-value">${deployment.repo_url}</div>
                    <div>${deployment.branch}</div>
                    <div class="record-type">${deployment.status}</div>
                    <div>${new Date(deployment.deployed_at).toLocaleDateString()}</div>
                </div>
            `).join('');

            document.getElementById('deployment-count').textContent = data.deployments.length;
        } else {
            list.innerHTML = '<div class="loading">No deployments yet</div>';
            document.getElementById('deployment-count').textContent = '0';
        }
    } catch (error) {
        console.error('Error loading deployments:', error);
        list.innerHTML = '<div class="loading">Error loading deployments</div>';
    }
}

// Modal Functions
function showAddDomainModal() {
    document.getElementById('add-domain-modal').classList.add('active');
}

function closeModal(modalId) {
    document.getElementById(modalId).classList.remove('active');
}

// Form Submission
document.getElementById('add-domain-form')?.addEventListener('submit', async (e) => {
    e.preventDefault();

    const formData = new FormData(e.target);
    const domainData = {
        domain: formData.get('domain'),
        registrar: formData.get('registrar'),
        nameservers: formData.get('nameservers').split(',').map(ns => ns.trim())
    };

    try {
        const response = await fetch(`${API_BASE}/domains`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(domainData)
        });

        const data = await response.json();

        if (data.success) {
            closeModal('add-domain-modal');
            loadDomains();
            alert(`Domain ${domainData.domain} added successfully!`);
        } else {
            alert(`Error: ${data.error}`);
        }
    } catch (error) {
        alert(`Error adding domain: ${error.message}`);
    }
});

// Initial Load
loadDomains();
