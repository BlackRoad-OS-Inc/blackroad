/**
 * Action: Deploy Product
 * Trigger a deployment for a BlackRoad service
 */

const BASE_URL = 'https://api.blackroad.io';

module.exports = {
  key: 'deploy_product',
  noun: 'Deployment',

  display: {
    label: 'Deploy Product',
    description: 'Trigger a deployment for a BlackRoad service.',
    important: true,
  },

  operation: {
    inputFields: [
      {
        key: 'service',
        label: 'Service',
        type: 'string',
        required: true,
        choices: [
          'blackroad-api',
          'blackroad-dashboard',
          'blackroad-agents',
          'blackroad-vllm',
          'blackroad-landing',
        ],
        helpText: 'The service to deploy',
      },
      {
        key: 'environment',
        label: 'Environment',
        type: 'string',
        choices: ['production', 'staging', 'development'],
        default: 'production',
      },
      {
        key: 'version',
        label: 'Version',
        type: 'string',
        helpText: 'Version tag (optional, defaults to latest)',
      },
      {
        key: 'notify_slack',
        label: 'Notify Slack',
        type: 'boolean',
        default: true,
        helpText: 'Send deployment notification to Slack',
      },
    ],

    perform: async (z, bundle) => {
      const response = await z.request({
        url: `${BASE_URL}/v1/deployments`,
        method: 'POST',
        headers: {
          Authorization: `Bearer ${bundle.authData.apiKey}`,
          'Content-Type': 'application/json',
        },
        body: {
          service: bundle.inputData.service,
          environment: bundle.inputData.environment,
          version: bundle.inputData.version,
          notify_slack: bundle.inputData.notify_slack,
          source: 'zapier',
        },
      });

      return response.json;
    },

    sample: {
      id: 'deploy_xyz789',
      service: 'blackroad-api',
      environment: 'production',
      version: 'v1.2.3',
      status: 'in_progress',
      started_at: '2026-02-15T10:00:00Z',
      estimated_duration: 180,
    },

    outputFields: [
      { key: 'id', label: 'Deployment ID', type: 'string' },
      { key: 'service', label: 'Service', type: 'string' },
      { key: 'environment', label: 'Environment', type: 'string' },
      { key: 'version', label: 'Version', type: 'string' },
      { key: 'status', label: 'Status', type: 'string' },
      { key: 'started_at', label: 'Started At', type: 'datetime' },
      { key: 'estimated_duration', label: 'Estimated Duration (s)', type: 'integer' },
    ],
  },
};
