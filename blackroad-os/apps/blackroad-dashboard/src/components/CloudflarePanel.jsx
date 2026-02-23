import styles from './CloudflarePanel.module.css'
import { useWorkers } from '../hooks/useWorkers'

export default function CloudflarePanel() {
  const { statuses, loading, workers, reload } = useWorkers()

  return (
    <section className={styles.panel}>
      <header className={styles.header}>
        <span className={styles.title}>◆ Workers</span>
        <span className="muted" style={{ fontSize: 12 }}>
          {Object.values(statuses).filter(s => s.ok).length}/{workers.length} up
        </span>
        <button className={styles.refresh} onClick={reload}>↺</button>
      </header>

      <div className={styles.list}>
        {workers.map(w => {
          const s = statuses[w.name]
          const ok = s?.ok
          const latency = s?.latency
          const agents = s?.data?.agents_online

          return (
            <div key={w.name} className={styles.row}>
              <span className={`${styles.dot} ${ok ? styles.up : loading ? styles.loading : styles.down}`} />
              <div className={styles.info}>
                <span className={styles.name}>{w.name}</span>
                {s?.data?.version && (
                  <span className="muted" style={{ fontSize: 11 }}>v{s.data.version}</span>
                )}
              </div>
              <div className={styles.meta}>
                {agents != null && (
                  <span className={styles.pill}>{agents} agents</span>
                )}
                {latency != null && (
                  <span className={`${styles.latency} ${latency < 300 ? styles.fast : latency < 800 ? styles.mid : styles.slow}`}>
                    {latency}ms
                  </span>
                )}
              </div>
            </div>
          )
        })}
      </div>

      <div className={styles.footer}>
        <a href="https://blackroad-os-api.amundsonalexa.workers.dev" target="_blank" rel="noreferrer" className={styles.link}>
          blackroad-os-api ↗
        </a>
        <a href="https://dash.cloudflare.com" target="_blank" rel="noreferrer" className={styles.link}>
          CF Dashboard ↗
        </a>
      </div>
    </section>
  )
}
