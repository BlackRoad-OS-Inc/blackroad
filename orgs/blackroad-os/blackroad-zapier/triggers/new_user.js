const trigger = async (z, bundle) => {
  const response = await z.request({
    url: 'https://api.blackroad.io/v1/zapier/users/recent',
    params: { since: bundle.inputData.since }
  });
  return response.data;
};

module.exports = {
  key: 'new_user',
  noun: 'User',
  display: {
    label: 'New User Created',
    description: 'Triggers when a new user signs up.'
  },
  operation: { perform: trigger }
};
