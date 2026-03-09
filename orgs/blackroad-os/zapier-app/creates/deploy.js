module.exports = {
  key: 'deploy',
  noun: 'Deployment',
  display: { label: 'Deploy Service', description: 'Deploy to BlackRoad infrastructure' },
  operation: {
    inputFields: [
      { key: 'service', required: true, label: 'Service Name' },
      { key: 'target', required: true, label: 'Target', choices: ['cloudflare', 'railway', 'vercel'] }
    ],
    perform: async (z, bundle) => {
      return { success: true, service: bundle.inputData.service, target: bundle.inputData.target };
    }
  }
};
