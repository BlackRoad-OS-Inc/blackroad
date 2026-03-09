/**
 * Action: Create User
 * Create a new user in BlackRoad
 */

const BASE_URL = 'https://api.blackroad.io';

module.exports = {
  key: 'create_user',
  noun: 'User',

  display: {
    label: 'Create User',
    description: 'Create a new user in your BlackRoad organization.',
  },

  operation: {
    inputFields: [
      {
        key: 'email',
        label: 'Email',
        type: 'string',
        required: true,
      },
      {
        key: 'name',
        label: 'Name',
        type: 'string',
        required: true,
      },
      {
        key: 'role',
        label: 'Role',
        type: 'string',
        choices: ['admin', 'developer', 'viewer'],
        default: 'developer',
      },
      {
        key: 'products',
        label: 'Products',
        type: 'string',
        list: true,
        choices: ['vllm', 'api', 'agents', 'dashboard'],
        helpText: 'Which products this user can access',
      },
      {
        key: 'send_invite',
        label: 'Send Invite Email',
        type: 'boolean',
        default: true,
      },
    ],

    perform: async (z, bundle) => {
      const response = await z.request({
        url: `${BASE_URL}/v1/users`,
        method: 'POST',
        headers: {
          Authorization: `Bearer ${bundle.authData.apiKey}`,
          'Content-Type': 'application/json',
        },
        body: {
          email: bundle.inputData.email,
          name: bundle.inputData.name,
          role: bundle.inputData.role,
          products: bundle.inputData.products,
          send_invite: bundle.inputData.send_invite,
        },
      });

      return response.json;
    },

    sample: {
      id: 'user_new123',
      email: 'newuser@example.com',
      name: 'New User',
      role: 'developer',
      products: ['vllm', 'api'],
      created_at: '2026-02-15T10:00:00Z',
      invite_sent: true,
    },

    outputFields: [
      { key: 'id', label: 'User ID', type: 'string' },
      { key: 'email', label: 'Email', type: 'string' },
      { key: 'name', label: 'Name', type: 'string' },
      { key: 'role', label: 'Role', type: 'string' },
      { key: 'products', label: 'Products', type: 'string' },
      { key: 'created_at', label: 'Created At', type: 'datetime' },
      { key: 'invite_sent', label: 'Invite Sent', type: 'boolean' },
    ],
  },
};
