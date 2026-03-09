/**
 * Trigger: Usage Threshold
 * Fires when usage exceeds a specified threshold
 */

const BASE_URL = 'https://api.blackroad.io';

module.exports = {
  key: 'usage_threshold',
  noun: 'Usage Alert',

  display: {
    label: 'Usage Threshold Exceeded',
    description: 'Triggers when usage (API calls, compute, storage) exceeds your threshold.',
  },

  operation: {
    type: 'polling',

    inputFields: [
      {
        key: 'metric',
        label: 'Metric',
        type: 'string',
        choices: ['api_calls', 'compute_hours', 'storage_gb', 'bandwidth_gb'],
        required: true,
      },
      {
        key: 'threshold',
        label: 'Threshold',
        type: 'integer',
        required: true,
        helpText: 'Alert when usage exceeds this value',
      },
    ],

    perform: async (z, bundle) => {
      const response = await z.request({
        url: `${BASE_URL}/v1/webhooks/usage`,
        method: 'GET',
        params: {
          metric: bundle.inputData.metric,
          threshold: bundle.inputData.threshold,
          since: bundle.meta.isLoadingSample ? undefined : bundle.meta.zap.last_poll,
        },
        headers: {
          Authorization: `Bearer ${bundle.authData.apiKey}`,
        },
      });

      return response.json.alerts || [];
    },

    sample: {
      id: 'alert_usage_001',
      metric: 'api_calls',
      threshold: 100000,
      current_value: 125847,
      percent_over: 25.8,
      period: 'monthly',
      alerted_at: '2026-02-15T10:00:00Z',
    },

    outputFields: [
      { key: 'id', label: 'Alert ID', type: 'string' },
      { key: 'metric', label: 'Metric', type: 'string' },
      { key: 'threshold', label: 'Threshold', type: 'integer' },
      { key: 'current_value', label: 'Current Value', type: 'integer' },
      { key: 'percent_over', label: 'Percent Over', type: 'number' },
      { key: 'period', label: 'Period', type: 'string' },
      { key: 'alerted_at', label: 'Alerted At', type: 'datetime' },
    ],
  },
};
