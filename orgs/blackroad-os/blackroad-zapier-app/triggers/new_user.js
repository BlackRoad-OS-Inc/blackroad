/**
 * Trigger: New User Created
 * Fires when a new user signs up for BlackRoad
 */

const BASE_URL = 'https://api.blackroad.io';

module.exports = {
  key: 'new_user',
  noun: 'User',

  display: {
    label: 'New User',
    description: 'Triggers when a new user signs up for BlackRoad.',
    important: true,
  },

  operation: {
    type: 'polling',

    inputFields: [
      {
        key: 'product',
        label: 'Product',
        type: 'string',
        choices: ['all', 'vllm', 'api', 'agents', 'dashboard'],
        default: 'all',
        helpText: 'Filter by product (optional)',
      },
    ],

    perform: async (z, bundle) => {
      const response = await z.request({
        url: `${BASE_URL}/v1/webhooks/users`,
        method: 'GET',
        params: {
          product: bundle.inputData.product,
          since: bundle.meta.isLoadingSample ? undefined : bundle.meta.zap.last_poll,
        },
        headers: {
          Authorization: `Bearer ${bundle.authData.apiKey}`,
        },
      });

      return response.json.users || [];
    },

    sample: {
      id: 'user_abc123',
      email: 'user@example.com',
      name: 'Jane Doe',
      created_at: '2026-02-15T10:00:00Z',
      product: 'vllm',
      plan: 'pro',
    },

    outputFields: [
      { key: 'id', label: 'User ID', type: 'string' },
      { key: 'email', label: 'Email', type: 'string' },
      { key: 'name', label: 'Name', type: 'string' },
      { key: 'created_at', label: 'Created At', type: 'datetime' },
      { key: 'product', label: 'Product', type: 'string' },
      { key: 'plan', label: 'Plan', type: 'string' },
    ],
  },
};
