function buildMemoryBlocks(entries, title = 'Recent Memory') {
  const actionEmojis = {
    deployed: '🚀',
    created: '➕',
    updated: '✏️',
    fixed: '🔧',
    configured: '⚙️',
    milestone: '⭐',
    til: '💡',
    announce: '📢',
    progress: '📊',
    blocked: '🚫',
  };

  const blocks = [
    {
      type: 'header',
      text: {
        type: 'plain_text',
        text: `🧠 ${title}`,
      },
    },
    {
      type: 'divider',
    },
  ];

  entries.forEach((entry) => {
    const emoji = actionEmojis[entry.action] || '📌';
    const details = entry.details ? ` - ${entry.details.substring(0, 60)}${entry.details.length > 60 ? '...' : ''}` : '';
    const time = formatRelativeTime(new Date(entry.timestamp));

    blocks.push({
      type: 'section',
      text: {
        type: 'mrkdwn',
        text: `${emoji} *${entry.action}* → \`${entry.entity}\`${details}\n_${time}_ | \`${entry.hash.substring(0, 8)}...\``,
      },
    });
  });

  blocks.push({
    type: 'context',
    elements: [
      {
        type: 'mrkdwn',
        text: `Showing ${entries.length} entries | <https://console.blackroad.io/memory|View All>`,
      },
    ],
  });

  return blocks;
}

function formatRelativeTime(date) {
  const now = new Date();
  const diffMs = now - date;
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);

  if (diffMins < 1) return 'just now';
  if (diffMins < 60) return `${diffMins}m ago`;
  if (diffHours < 24) return `${diffHours}h ago`;
  if (diffDays < 7) return `${diffDays}d ago`;
  return date.toLocaleDateString();
}

module.exports = { buildMemoryBlocks };
