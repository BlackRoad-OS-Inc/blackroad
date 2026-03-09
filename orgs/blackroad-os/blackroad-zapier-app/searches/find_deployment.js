/**
 * Search: Find Deployment
 * Search for a deployment by ID or service
 */

const BASE_URL = 'https://api.blackroad.io';

module.exports = {
  key: 'find_deployment',
  noun: 'Deployment',

  display: {
    label: 'Find Deployment',
    description: 'Find a deployment by ID or service.',
  },

  operation: {
    inputFields: [
      {
        key: 'deployment_id',
        label: 'Deployment ID',
        type: 'string',
        helpText: 'Search by deployment ID',
      },
      {
        key: 'service',
        label: 'Service',
        type: 'string',
        helpText: 'Search by service name (returns most recent)',
      },
    ],

    perform: async (z, bundle) => {
      const response = await z.request({
        url: `${BASE_URL}/v1/deployments/search`,
        method: 'GET',
        params: {
          id: bundle.inputData.deployment_id,
          service: bundle.inputData.service,
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
      environment: 'production',
      completed_at: '2026-02-15T10:00:00Z',
    },

    outputFields: [
      { key: 'id', label: 'Deployment ID', type: 'string' },
      { key: 'service', label: 'Service', type: 'string' },
      { key: 'version', label: 'Version', type: 'string' },
      { key: 'status', label: 'Status', type: 'string' },
      { key: 'environment', label: 'Environment', type: 'string' },
      { key: 'completed_at', label: 'Completed At', type: 'datetime' },
    ],
  },
};
