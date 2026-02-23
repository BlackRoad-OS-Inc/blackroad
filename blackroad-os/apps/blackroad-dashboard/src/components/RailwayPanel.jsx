import styles from './RailwayPanel.module.css'
import { useRailway } from '../hooks/useRailway'

const STATUS_COLOR = {
  SUCCESS: 'success', COMPLETE: 'success',
  FAILED: 'failure', CRASHED: 'failure',
  DEPLOYING: 'in_progress', BUILDING: 'in_progress',
  QUEUED: 'queued',
}

function ago(iso) {
  const s = Math.floor((Date.now() - new Date(iso)) / 1000)
  if (s < 60)   return `${s}s ago`
  if (s < 3600) return `${Math.floor(s/60)}m ago`
  if (s < 86400) return `${Math.floor(s/3600)}h ago`
  return `${Math.floor(s/86400)}d ago`
}

export default function RailwayPanel({ token }) {
  const { projects, deployments, loading, error, reload } = useRailway(token)

  if (!token) return (
    <section className={styles.panel}>
      <header className={styles.header}><span className={styles.title}>◆ Railway</span></header>
      <div className={styles.empty}>Add Railway token in Settings →</div>
    </section>
  )

  return (
    <section className={styles.panel}>
      <header className={styles.header}>
        <span className={styles.title}>◆ Railway</span>
        {projects && <span className="muted" style={{fontSize:12}}>{projects.length} projects</span>}
        <button className={styles.refresh} onClick={reload}>↺</button>
      </header>

      {loading && !projects && <div className={styles.empty}>loading…</div>}
      {error && <div className={styles.error}>{error}</div>}

      {projects && (
        <div className={styles.projects}>
          {projects.map(p => (
            <div key={p.id} className={styles.project}>
              <div className={styles.projectName}>◆ {p.name}</div>
              <div className={styles.projectMeta}>
                {p.services} services · {p.environments} envs · {ago(p.updated)}
              </div>
            </div>
          ))}
        </div>
      )}

      {deployments && deployments.length > 0 && (
        <>
          <div className={styles.sectionLabel}>Recent Deployments</div>
          <div className={styles.deploys}>
            {deployments.slice(0, 6).map(d => (
              <div key={d.id} className={styles.deploy}>
                <span className={`badge ${STATUS_COLOR[d.status] || 'queued'}`}>{d.status}</span>
                <div className={styles.deployInfo}>
                  <span className={styles.deployService}>{d.service}</span>
                  <span className="muted" style={{fontSize:11}}>{d.branch} · {d.message?.slice(0,50)}</span>
                </div>
                <span className="muted" style={{fontSize:11, flexShrink:0}}>{ago(d.created)}</span>
              </div>
            ))}
          </div>
        </>
      )}
    </section>
  )
}
