import { useState, useEffect } from 'react'
import AgentPanel from './components/AgentPanel.jsx'
import RailwayPanel from './components/RailwayPanel.jsx'
import GitHubPanel from './components/GitHubPanel.jsx'
import Settings from './components/Settings.jsx'
import styles from './App.module.css'

const STORAGE_KEY = 'br_dashboard_config'
const DEFAULT_CONFIG = {
  railwayToken: '',
  githubToken: '',
  githubOrg: 'BlackRoad-OS-Inc',
  githubRepo: 'blackroad',
}

function loadConfig() {
  try { return { ...DEFAULT_CONFIG, ...JSON.parse(localStorage.getItem(STORAGE_KEY) || '{}') } }
  catch { return DEFAULT_CONFIG }
}

export default function App() {
  const [view, setView] = useState('dashboard')
  const [config, setConfig] = useState(loadConfig)
  const [saved, setSaved] = useState(false)

  const saveConfig = (next) => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(next))
    setConfig(next)
    setSaved(true)
    setTimeout(() => { setSaved(false); setView('dashboard') }, 1000)
  }

  // Auto-route to settings if no tokens set
  useEffect(() => {
    if (!config.railwayToken && !config.githubToken) setView('settings')
  }, []) // eslint-disable-line

  const hasTokens = config.railwayToken || config.githubToken

  return (
    <div className={styles.app}>
      {/* Header */}
      <header className={styles.header}>
        <div className={styles.logo}>
          <span className="grad-text" style={{ fontSize: 18, fontWeight: 800 }}>◆ BlackRoad OS</span>
          <span className={styles.tagline}>Mission Control</span>
        </div>
        <nav className={styles.nav}>
          <NavBtn active={view === 'dashboard'} onClick={() => setView('dashboard')}>Dashboard</NavBtn>
          <NavBtn active={view === 'settings'}  onClick={() => setView('settings')}>Settings</NavBtn>
        </nav>
      </header>

      {/* Body */}
      <main className={styles.main}>
        {view === 'settings' ? (
          <Settings config={config} onSave={saveConfig} />
        ) : (
          <>
            {saved && <div className={styles.toast}>✓ Saved</div>}
            <div className={styles.grid}>
              <AgentPanel />
              <RailwayPanel token={config.railwayToken} />
              <GitHubPanel
                token={config.githubToken}
                org={config.githubOrg}
                repo={config.githubRepo}
              />
            </div>
          </>
        )}
      </main>
    </div>
  )
}

function NavBtn({ active, onClick, children }) {
  return (
    <button
      onClick={onClick}
      style={{
        background: active ? 'rgba(245,166,35,.12)' : 'none',
        color: active ? 'var(--amber)' : 'var(--muted)',
        border: `1px solid ${active ? 'rgba(245,166,35,.25)' : 'transparent'}`,
        borderRadius: 8,
        padding: '6px 14px',
        fontSize: 13,
        fontWeight: active ? 600 : 400,
        transition: 'all .15s',
      }}
    >
      {children}
    </button>
  )
}
