/**
 * BlackRoad Zapier App
 * Official integration for connecting BlackRoad OS to 5000+ apps
 */

const authentication = require('./lib/authentication');

// Triggers
const newUserTrigger = require('./triggers/new_user');
const deploymentCompleteTrigger = require('./triggers/deployment_complete');
const errorOccurredTrigger = require('./triggers/error_occurred');
const agentStatusChangeTrigger = require('./triggers/agent_status_change');
const usageThresholdTrigger = require('./triggers/usage_threshold');

// Actions
const deployProductAction = require('./actions/deploy_product');
const createUserAction = require('./actions/create_user');
const updateConfigAction = require('./actions/update_config');
const sendNotificationAction = require('./actions/send_notification');
const scaleAgentsAction = require('./actions/scale_agents');

// Searches
const findUserSearch = require('./searches/find_user');
const findDeploymentSearch = require('./searches/find_deployment');

module.exports = {
  version: require('./package.json').version,
  platformVersion: require('zapier-platform-core').version,

  authentication: authentication,

  // Branding
  beforeRequest: [
    (request, z, bundle) => {
      request.headers['X-BlackRoad-Source'] = 'zapier';
      request.headers['X-BlackRoad-Version'] = '1.0.0';
      return request;
    }
  ],

  afterResponse: [
    (response, z, bundle) => {
      if (response.status >= 400) {
        const message = response.json?.error?.message || 'Unknown error';
        throw new z.errors.Error(message, 'ApiError', response.status);
      }
      return response;
    }
  ],

  // Triggers - events that start a Zap
  triggers: {
    [newUserTrigger.key]: newUserTrigger,
    [deploymentCompleteTrigger.key]: deploymentCompleteTrigger,
    [errorOccurredTrigger.key]: errorOccurredTrigger,
    [agentStatusChangeTrigger.key]: agentStatusChangeTrigger,
    [usageThresholdTrigger.key]: usageThresholdTrigger,
  },

  // Actions - things the Zap can do
  creates: {
    [deployProductAction.key]: deployProductAction,
    [createUserAction.key]: createUserAction,
    [updateConfigAction.key]: updateConfigAction,
    [sendNotificationAction.key]: sendNotificationAction,
    [scaleAgentsAction.key]: scaleAgentsAction,
  },

  // Searches - find specific records
  searches: {
    [findUserSearch.key]: findUserSearch,
    [findDeploymentSearch.key]: findDeploymentSearch,
  },
};
