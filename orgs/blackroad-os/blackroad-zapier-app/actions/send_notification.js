/**
 * Action: Send Notification
 * Send a notification through BlackRoad channels
 */

const BASE_URL = 'https://api.blackroad.io';

module.exports = {
  key: 'send_notification',
  noun: 'Notification',

  display: {
    label: 'Send Notification',
    description: 'Send a notification through BlackRoad (Slack, email, webhook).',
  },

  operation: {
    inputFields: [
      {
        key: 'channel',
        label: 'Channel',
        type: 'string',
        required: true,
        choices: ['slack', 'email', 'webhook', 'all'],
        default: 'slack',
      },
      {
        key: 'title',
        label: 'Title',
        type: 'string',
        required: true,
      },
      {
        key: 'message',
        label: 'Message',
        type: 'text',
        required: true,
      },
      {
        key: 'severity',
        label: 'Severity',
        type: 'string',
        choices: ['info', 'warning', 'error', 'critical'],
        default: 'info',
      },
      {
        key: 'recipients',
        label: 'Recipients',
        type: 'string',
        list: true,
        helpText: 'Email addresses or Slack channels (optional)',
      },
    ],

    perform: async (z, bundle) => {
      const response = await z.request({
        url: `${BASE_URL}/v1/notifications`,
        method: 'POST',
        headers: {
          Authorization: `Bearer ${bundle.authData.apiKey}`,
          'Content-Type': 'application/json',
        },
        body: {
          channel: bundle.inputData.channel,
          title: bundle.inputData.title,
          message: bundle.inputData.message,
          severity: bundle.inputData.severity,
          recipients: bundle.inputData.recipients,
          source: 'zapier',
        },
      });

      return response.json;
    },

    sample: {
      id: 'notif_abc123',
      channel: 'slack',
      title: 'Deployment Complete',
      message: 'The deployment was successful!',
      severity: 'info',
      sent_at: '2026-02-15T10:00:00Z',
      delivered: true,
    },

    outputFields: [
      { key: 'id', label: 'Notification ID', type: 'string' },
      { key: 'channel', label: 'Channel', type: 'string' },
      { key: 'title', label: 'Title', type: 'string' },
      { key: 'message', label: 'Message', type: 'string' },
      { key: 'severity', label: 'Severity', type: 'string' },
      { key: 'sent_at', label: 'Sent At', type: 'datetime' },
      { key: 'delivered', label: 'Delivered', type: 'boolean' },
    ],
  },
};
