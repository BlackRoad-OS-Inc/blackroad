/**
 * Trigger: Agent Status Change
 * Fires when an AI agent's status changes
 */

const BASE_URL = 'https://api.blackroad.io';

module.exports = {
  key: 'agent_status_change',
  noun: 'Agent',

  display: {
    label: 'Agent Status Change',
    description: 'Triggers when an AI agent goes online, offline, or changes status.',
  },

  operation: {
    type: 'polling',

    inputFields: [
      {
        key: 'status',
        label: 'New Status',
        type: 'string',
        choices: ['all', 'online', 'offline', 'busy', 'error'],
        default: 'all',
      },
      {
        key: 'agent_type',
        label: 'Agent Type',
        type: 'string',
        choices: ['all', 'infrastructure', 'code_review', 'security', 'analytics'],
        default: 'all',
      },
    ],

    perform: async (z, bundle) => {
      const response = await z.request({
        url: `${BASE_URL}/v1/webhooks/agents`,
        method: 'GET',
        params: {
          status: bundle.inputData.status,
          type: bundle.inputData.agent_type,
          since: bundle.meta.isLoadingSample ? undefined : bundle.meta.zap.last_poll,
        },
        headers: {
          Authorization: `Bearer ${bundle.authData.apiKey}`,
        },
      });

      return response.json.agents || [];
    },

    sample: {
      id: 'agent_roadie_001',
      name: 'Roadie',
      type: 'infrastructure',
      previous_status: 'offline',
      new_status: 'online',
      changed_at: '2026-02-15T10:00:00Z',
      tasks_completed: 42,
      uptime_percent: 99.9,
    },

    outputFields: [
      { key: 'id', label: 'Agent ID', type: 'string' },
      { key: 'name', label: 'Agent Name', type: 'string' },
      { key: 'type', label: 'Agent Type', type: 'string' },
      { key: 'previous_status', label: 'Previous Status', type: 'string' },
      { key: 'new_status', label: 'New Status', type: 'string' },
      { key: 'changed_at', label: 'Changed At', type: 'datetime' },
      { key: 'tasks_completed', label: 'Tasks Completed', type: 'integer' },
      { key: 'uptime_percent', label: 'Uptime %', type: 'number' },
    ],
  },
};
