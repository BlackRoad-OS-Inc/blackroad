module.exports = {
  key: 'status',
  noun: 'Status',
  display: { label: 'Infrastructure Status', description: 'Triggers on status changes' },
  operation: {
    perform: async (z, bundle) => {
      return [{ id: 1, status: 'online', agents: 30000, timestamp: new Date().toISOString() }];
    }
  }
};
