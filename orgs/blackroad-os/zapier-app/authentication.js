module.exports = {
  type: 'custom',
  fields: [{ key: 'apiKey', label: 'API Key', required: true, type: 'string' }],
  test: async (z, bundle) => ({ success: true }),
  connectionLabel: 'BlackRoad OS'
};
