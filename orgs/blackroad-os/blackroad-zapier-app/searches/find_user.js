/**
 * Search: Find User
 * Search for a user by email or ID
 */

const BASE_URL = 'https://api.blackroad.io';

module.exports = {
  key: 'find_user',
  noun: 'User',

  display: {
    label: 'Find User',
    description: 'Find a user by email or ID.',
  },

  operation: {
    inputFields: [
      {
        key: 'email',
        label: 'Email',
        type: 'string',
        helpText: 'Search by email address',
      },
      {
        key: 'user_id',
        label: 'User ID',
        type: 'string',
        helpText: 'Search by user ID',
      },
    ],

    perform: async (z, bundle) => {
      const response = await z.request({
        url: `${BASE_URL}/v1/users/search`,
        method: 'GET',
        params: {
          email: bundle.inputData.email,
          id: bundle.inputData.user_id,
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
      role: 'developer',
      created_at: '2026-01-01T00:00:00Z',
    },

    outputFields: [
      { key: 'id', label: 'User ID', type: 'string' },
      { key: 'email', label: 'Email', type: 'string' },
      { key: 'name', label: 'Name', type: 'string' },
      { key: 'role', label: 'Role', type: 'string' },
      { key: 'created_at', label: 'Created At', type: 'datetime' },
    ],
  },
};
