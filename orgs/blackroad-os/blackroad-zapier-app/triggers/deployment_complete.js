/**
 * Trigger: Deployment Complete
 * Fires when a deployment finishes (success or failure)
 */

const BASE_URL = 'https://api.blackroad.io';

module.exports = {
  key: 'deployment_complete',
  noun: 'Deployment',

  display: {
    label: 'Deployment Complete',
    description: 'Triggers when a deployment finishes (success or failure).',
    important: true,
  },

  operation: {
    type: 'polling',

    inputFields: [
      {
        key: 'status',
        label: 'Status Filter',
        type: 'string',
        choices: ['all', 'success', 'failure'],
        default: 'all',
        helpText: 'Filter by deployment status',
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
        url: `${BASE_URL}/v1/webhooks/deployments`,
        method: 'GET',
        params: {
          status: bundle.inputData.status,
          service: bundle.inputData.service,
          since: bundle.meta.isLoadingSample ? undefined : bundle.meta.zap.last_poll,
        },
        headers: {
          Authorization: `Bearer ${bundle.authData.apiKey}`,
        },
      });

      return response.json.deployments || [];
    },

    sample: {
      id: 'deploy_xyz789',
      service: 'blackroad-api',
      version: 'v1.2.3',
      status: 'success',
      started_at: '2026-02-15T09:55:00Z',
      completed_at: '2026-02-15T10:00:00Z',
      duration_seconds: 300,
      deployed_by: 'user_abc123',
      environment: 'production',
      url: 'https://api.blackroad.io',
    },

    outputFields: [
      { key: 'id', label: 'Deployment ID', type: 'string' },
      { key: 'service', label: 'Service', type: 'string' },
      { key: 'version', label: 'Version', type: 'string' },
      { key: 'status', label: 'Status', type: 'string' },
      { key: 'started_at', label: 'Started At', type: 'datetime' },
      { key: 'completed_at', label: 'Completed At', type: 'datetime' },
      { key: 'duration_seconds', label: 'Duration (seconds)', type: 'integer' },
      { key: 'deployed_by', label: 'Deployed By', type: 'string' },
      { key: 'environment', label: 'Environment', type: 'string' },
      { key: 'url', label: 'URL', type: 'string' },
    ],
  },
};
