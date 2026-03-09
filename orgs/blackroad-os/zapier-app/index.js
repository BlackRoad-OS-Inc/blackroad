const authentication = require('./authentication');
const statusTrigger = require('./triggers/status');
const deployAction = require('./creates/deploy');

module.exports = {
  version: require('./package.json').version,
  platformVersion: require('zapier-platform-core').version,
  authentication: authentication,
  triggers: { [statusTrigger.key]: statusTrigger },
  creates: { [deployAction.key]: deployAction }
};
