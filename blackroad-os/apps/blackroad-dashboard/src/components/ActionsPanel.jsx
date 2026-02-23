import { useState } from 'react'
import styles from './ActionsPanel.module.css'

const ACTIONS = [
  {
    id: 'worker',
    label: 'Deploy Worker',
    icon: '⚡',
    desc: 'wrangler deploy → blackroad-os-api',
    color: '#F5A623',
    cmd: 'cd blackroad-os/workers/blackroad-os-api && wrangler deploy',
  },
  {
    id: 'railway',
    label: 'Deploy Railway',
    icon: '🚂',
    desc: 'railway up → current project',
    color: '#a78bfa',
    cmd: 'railway up',
  },
  {
    id: 'pages',
    label: 'Deploy Dashboard',
    icon: '🌐',
    desc: 'wrangler pages deploy → dashboard.blackroad.io',
    color: '#2979FF',
    cmd: 'cd blackroad-os/apps/blackroad-dashboard && npm run build && wrangler pages deploy dist --project-name=blackroad-dashboard',
  },
  {
    id: 'git',
    label: 'Git Push',
    icon: '◆',
    desc: 'push master → BlackRoad-OS-Inc',
    color: '#FF1D6C',
    cmd: 'git push origin master',
  },
]

export default function ActionsPanel() {
  const [copied, setCopied] = useState(null)

  const copy = (action) => {
    navigator.clipboard.writeText(action.cmd)
    setCopied(action.id)
    setTimeout(() => setCopied(null), 1500)
  }

  return (
    <section className={styles.panel}>
      <header className={styles.header}>
        <span className={styles.title}>◆ Quick Actions</span>
        <span className="muted" style={{ fontSize: 12 }}>copy to run</span>
      </header>

      <div className={styles.grid}>
        {ACTIONS.map(a => (
          <button
            key={a.id}
            className={`${styles.action} ${copied === a.id ? styles.copied : ''}`}
            onClick={() => copy(a)}
            style={{ '--accent': a.color }}
          >
            <span className={styles.icon}>{a.icon}</span>
            <div className={styles.text}>
              <span className={styles.label}>{copied === a.id ? '✓ Copied!' : a.label}</span>
              <span className={styles.desc}>{a.desc}</span>
            </div>
          </button>
        ))}
      </div>

      <div className={styles.footer}>
        <span className="muted" style={{ fontSize: 11 }}>
          Run commands in <code style={{ color: 'var(--amber)', fontSize: 11 }}>~/blackroad</code>
        </span>
      </div>
    </section>
  )
}
