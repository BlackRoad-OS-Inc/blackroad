import React from 'react';

const config = {
  logo: <span style={{ fontWeight: 600, fontSize: '1.2rem' }}>BlackRoad OS Docs</span>,
  project: {
    link: 'https://github.com/BlackRoad-OS',
  },
  chat: {
    link: 'https://discord.gg/blackroad', // Update with real Discord when available
  },
  docsRepositoryBase: 'https://github.com/BlackRoad-OS/blackroad-docs',
  footer: {
    text: (
      <span>
        © {new Date().getFullYear()} BlackRoad OS, Inc. |{' '}
        <a href="https://blackroad.io" target="_blank" rel="noopener noreferrer">
          blackroad.io
        </a>
        {' '}|{' '}
        <a href="https://lucidia.earth" target="_blank" rel="noopener noreferrer">
          Meet Lucidia
        </a>
      </span>
    ),
  },
  head: (
    <>
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <meta property="og:title" content="BlackRoad OS Documentation" />
      <meta property="og:description" content="Everything you need to build with transparent, accountable AI." />
      <link rel="icon" href="/favicon.ico" />
    </>
  ),
  primaryHue: 210, // Blue hue for links
  darkMode: true,
  nextThemes: {
    defaultTheme: 'dark',
  },
  sidebar: {
    defaultMenuCollapseLevel: 1,
    toggleButton: true,
  },
  toc: {
    backToTop: true,
  },
  editLink: {
    text: 'Edit this page on GitHub →',
  },
  feedback: {
    content: 'Question? Give us feedback →',
    labels: 'feedback',
  },
  search: {
    placeholder: 'Search docs...',
  },
  banner: {
    dismissible: true,
    key: 'beta-launch',
    text: (
      <a href="https://lucidia.earth" target="_blank" rel="noopener noreferrer">
        🎉 BlackRoad OS is in beta. Meet Lucidia →
      </a>
    ),
  },
  gitTimestamp: ({ timestamp }: { timestamp: Date }) => (
    <>Last updated on {timestamp.toLocaleDateString()}</>
  ),
};

export default config;
