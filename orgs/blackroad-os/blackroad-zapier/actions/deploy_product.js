const deploy = async (z, bundle) => {
  const response = await z.request({
    method: 'POST',
    url: 'https://api.blackroad.io/v1/zapier/deploy',
    body: {
      product: bundle.inputData.product,
      environment: bundle.inputData.environment,
      config: bundle.inputData.config
    }
  });
  return response.data;
};

module.exports = {
  key: 'deploy_product',
  noun: 'Deployment',
  display: {
    label: 'Deploy Product',
    description: 'Deploy a BlackRoad product.'
  },
  operation: { perform: deploy }
};
