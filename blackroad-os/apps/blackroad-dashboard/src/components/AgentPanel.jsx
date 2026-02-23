import styles from './AgentPanel.module.css'
import { useAgents } from '../hooks/useAgents'

export default function AgentPanel() {
  const { data, loading, error, reload } = useAgents()

  if (loading) return <Panel title="Agents"><div className={styles.loading}>loading…</div></Panel>
  if (error)   return <Panel title="Agents"><div className={styles.error}>{error}</div></Panel>

  const agents = data?.agents || []
  const online = agents.filter(a => a.status === 'online').length

  return (
    <Panel title="Agents" meta={`${online}/${agents.length} online`} onRefresh={reload}>
      <div className={styles.grid}>
        {agents.map(a => (
          <div key={a.id} className={styles.card}>
            <div className={styles.emoji}>{a.emoji}</div>
            <div className={styles.info}>
              <div className={styles.name}>{a.name}</div>
              <div className={styles.role}>{a.role}</div>
              <div className={styles.model}>{a.model}</div>
            </div>
            <span className={`badge ${a.status}`}>{a.status}</span>
          </div>
        ))}
      </div>
    </Panel>
  )
}

function Panel({ title, meta, onRefresh, children }) {
  return (
    <section className={styles.panel}>
      <header className={styles.header}>
        <span className={styles.title}>◆ {title}</span>
        {meta && <span className="muted" style={{ fontSize: 12 }}>{meta}</span>}
        {onRefresh && <button className={styles.refresh} onClick={onRefresh}>↺</button>}
      </header>
      {children}
    </section>
  )
}
