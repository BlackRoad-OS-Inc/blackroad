/**
 * Action: Update Config
 * Update configuration for a BlackRoad service
 */

const BASE_URL = 'https://api.blackroad.io';

module.exports = {
  key: 'update_config',
  noun: 'Config',

  display: {
    label: 'Update Configuration',
    description: 'Update configuration settings for a BlackRoad service.',
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
          'blackroad-agents',
          'blackroad-vllm',
        ],
      },
      {
        key: 'key',
        label: 'Config Key',
        type: 'string',
        required: true,
        helpText: 'The configuration key to update',
      },
      {
        key: 'value',
        label: 'Value',
        type: 'string',
        required: true,
        helpText: 'The new value',
      },
      {
        key: 'environment',
        label: 'Environment',
        type: 'string',
        choices: ['production', 'staging', 'development'],
        default: 'production',
      },
    ],

    perform: async (z, bundle) => {
      const response = await z.request({
        url: `${BASE_URL}/v1/config/${bundle.inputData.service}`,
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${bundle.authData.apiKey}`,
          'Content-Type': 'application/json',
        },
        body: {
          key: bundle.inputData.key,
          value: bundle.inputData.value,
          environment: bundle.inputData.environment,
        },
      });

      return response.json;
    },

    sample: {
      service: 'blackroad-api',
      key: 'rate_limit',
      value: '1000',
      environment: 'production',
      updated_at: '2026-02-15T10:00:00Z',
      updated_by: 'zapier',
    },

    outputFields: [
      { key: 'service', label: 'Service', type: 'string' },
      { key: 'key', label: 'Config Key', type: 'string' },
      { key: 'value', label: 'Value', type: 'string' },
      { key: 'environment', label: 'Environment', type: 'string' },
      { key: 'updated_at', label: 'Updated At', type: 'datetime' },
      { key: 'updated_by', label: 'Updated By', type: 'string' },
    ],
  },
};
