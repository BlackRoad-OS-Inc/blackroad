/**
 * Trigger: Error Occurred
 * Fires when an error occurs in any BlackRoad service
 */

const BASE_URL = 'https://api.blackroad.io';

module.exports = {
  key: 'error_occurred',
  noun: 'Error',

  display: {
    label: 'Error Occurred',
    description: 'Triggers when an error occurs in any BlackRoad service.',
    important: true,
  },

  operation: {
    type: 'polling',

    inputFields: [
      {
        key: 'severity',
        label: 'Severity',
        type: 'string',
        choices: ['all', 'critical', 'error', 'warning'],
        default: 'error',
        helpText: 'Minimum severity level',
      },
      {
        key: 'service',
        label: 'Service',
        type: 'string',
        helpText: 'Filter by service name (optional)',
      },
    ],

    perform: async (z, bundle) => {
      const response = await z.request({
        url: `${BASE_URL}/v1/webhooks/errors`,
        method: 'GET',
        params: {
          severity: bundle.inputData.severity,
          service: bundle.inputData.service,
          since: bundle.meta.isLoadingSample ? undefined : bundle.meta.zap.last_poll,
        },
        headers: {
          Authorization: `Bearer ${bundle.authData.apiKey}`,
        },
      });

      return response.json.errors || [];
    },

    sample: {
      id: 'err_def456',
      service: 'blackroad-agents',
      severity: 'error',
      message: 'Agent connection timeout',
      code: 'AGENT_TIMEOUT',
      occurred_at: '2026-02-15T10:00:00Z',
      resolved: false,
      affected_users: 12,
    },

    outputFields: [
      { key: 'id', label: 'Error ID', type: 'string' },
      { key: 'service', label: 'Service', type: 'string' },
      { key: 'severity', label: 'Severity', type: 'string' },
      { key: 'message', label: 'Message', type: 'string' },
      { key: 'code', label: 'Error Code', type: 'string' },
      { key: 'occurred_at', label: 'Occurred At', type: 'datetime' },
      { key: 'resolved', label: 'Resolved', type: 'boolean' },
      { key: 'affected_users', label: 'Affected Users', type: 'integer' },
    ],
  },
};
