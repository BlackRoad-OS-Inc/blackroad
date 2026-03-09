/**
 * Action: Scale Agents
 * Scale the number of AI agents up or down
 */

const BASE_URL = 'https://api.blackroad.io';

module.exports = {
  key: 'scale_agents',
  noun: 'Agent Pool',

  display: {
    label: 'Scale Agents',
    description: 'Scale the number of AI agents up or down.',
  },

  operation: {
    inputFields: [
      {
        key: 'agent_type',
        label: 'Agent Type',
        type: 'string',
        required: true,
        choices: ['infrastructure', 'code_review', 'security', 'analytics', 'general'],
      },
      {
        key: 'target_count',
        label: 'Target Count',
        type: 'integer',
        required: true,
        helpText: 'The desired number of agents',
      },
      {
        key: 'scaling_policy',
        label: 'Scaling Policy',
        type: 'string',
        choices: ['immediate', 'gradual'],
        default: 'gradual',
        helpText: 'How quickly to scale',
      },
    ],

    perform: async (z, bundle) => {
      const response = await z.request({
        url: `${BASE_URL}/v1/agents/scale`,
        method: 'POST',
        headers: {
          Authorization: `Bearer ${bundle.authData.apiKey}`,
          'Content-Type': 'application/json',
        },
        body: {
          agent_type: bundle.inputData.agent_type,
          target_count: bundle.inputData.target_count,
          scaling_policy: bundle.inputData.scaling_policy,
        },
      });

      return response.json;
    },

    sample: {
      agent_type: 'infrastructure',
      previous_count: 5,
      target_count: 10,
      scaling_policy: 'gradual',
      status: 'scaling',
      estimated_completion: '2026-02-15T10:05:00Z',
    },

    outputFields: [
      { key: 'agent_type', label: 'Agent Type', type: 'string' },
      { key: 'previous_count', label: 'Previous Count', type: 'integer' },
      { key: 'target_count', label: 'Target Count', type: 'integer' },
      { key: 'scaling_policy', label: 'Scaling Policy', type: 'string' },
      { key: 'status', label: 'Status', type: 'string' },
      { key: 'estimated_completion', label: 'Estimated Completion', type: 'datetime' },
    ],
  },
};
