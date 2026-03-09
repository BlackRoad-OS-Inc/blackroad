/**
 * BlackRoad Zapier Authentication
 * API Key-based authentication
 */

const BASE_URL = 'https://api.blackroad.io';

const authentication = {
  type: 'custom',

  fields: [
    {
      key: 'apiKey',
      label: 'API Key',
      type: 'string',
      required: true,
      helpText: 'Your BlackRoad API key. Find it at https://blackroad.io/settings/api',
    },
    {
      key: 'orgId',
      label: 'Organization ID',
      type: 'string',
      required: false,
      helpText: 'Optional: Your organization ID for team accounts',
    },
  ],

  test: async (z, bundle) => {
    const response = await z.request({
      url: `${BASE_URL}/v1/auth/verify`,
      method: 'GET',
      headers: {
        Authorization: `Bearer ${bundle.authData.apiKey}`,
      },
    });

    if (response.status !== 200) {
      throw new z.errors.Error('Invalid API key', 'AuthenticationError', response.status);
    }

    return response.json;
  },

  connectionLabel: (z, bundle) => {
    return bundle.inputData.email || bundle.inputData.org_name || 'BlackRoad Account';
  },
};

// Helper to add auth headers to all requests
const addAuthHeaders = (request, z, bundle) => {
  if (bundle.authData.apiKey) {
    request.headers.Authorization = `Bearer ${bundle.authData.apiKey}`;
  }
  if (bundle.authData.orgId) {
    request.headers['X-BlackRoad-Org'] = bundle.authData.orgId;
  }
  return request;
};

module.exports = authentication;
module.exports.addAuthHeaders = addAuthHeaders;
