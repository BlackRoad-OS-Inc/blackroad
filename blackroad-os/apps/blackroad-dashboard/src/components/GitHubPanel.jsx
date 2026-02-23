import styles from './GitHubPanel.module.css'
import { useGitHub } from '../hooks/useGitHub'

const CONCLUSION_CLASS = {
  success: 'success', failure: 'failure', cancelled: 'queued',
  skipped: 'queued', timed_out: 'failure', action_required: 'standby',
}

function ago(iso) {
  const s = Math.floor((Date.now() - new Date(iso)) / 1000)
  if (s < 60)    return `${s}s ago`
  if (s < 3600)  return `${Math.floor(s/60)}m ago`
  if (s < 86400) return `${Math.floor(s/3600)}h ago`
  return `${Math.floor(s/86400)}d ago`
}

export default function GitHubPanel({ token, org, repo }) {
  const { runs, repoInfo, loading, error, reload } = useGitHub(token, org, repo)

  if (!token) return (
    <section className={styles.panel}>
      <header className={styles.header}><span className={styles.title}>◆ GitHub</span></header>
      <div className={styles.empty}>Add GitHub token in Settings →</div>
    </section>
  )

  return (
    <section className={styles.panel}>
      <header className={styles.header}>
        <span className={styles.title}>◆ GitHub</span>
        {repoInfo && <span className="muted" style={{fontSize:12}}>{repoInfo.name}</span>}
        <button className={styles.refresh} onClick={reload}>↺</button>
      </header>

      {repoInfo && (
        <div className={styles.repoStats}>
          <Stat label="★ Stars"  value={repoInfo.stars} />
          <Stat label="Forks"   value={repoInfo.forks} />
          <Stat label="Issues"  value={repoInfo.issues} />
          <Stat label="Branch"  value={repoInfo.branch} />
        </div>
      )}

      {loading && !runs && <div className={styles.empty}>loading…</div>}
      {error && <div className={styles.error}>{error}</div>}

      {runs && runs.length > 0 && (
        <>
          <div className={styles.sectionLabel}>Actions</div>
          <div className={styles.runs}>
            {runs.map(r => {
              const badgeClass = r.status === 'in_progress' ? 'in_progress'
                : (CONCLUSION_CLASS[r.conclusion] || 'queued')
              const label = r.status === 'in_progress' ? 'running'
                : (r.conclusion || r.status)
              return (
                <a key={r.id} className={styles.run} href={r.url} target="_blank" rel="noreferrer">
                  <span className={`badge ${badgeClass}`}>{label}</span>
                  <div className={styles.runInfo}>
                    <span className={styles.runName}>{r.name}</span>
                    <span className="muted" style={{fontSize:11}}>{r.branch} · {r.actor}</span>
                  </div>
                  <span className="muted" style={{fontSize:11, flexShrink:0}}>{ago(r.created)}</span>
                </a>
              )
            })}
          </div>
        </>
      )}
    </section>
  )
}

function Stat({ label, value }) {
  return (
    <div style={{ textAlign: 'center' }}>
      <div style={{ fontSize: 16, fontWeight: 700 }}>{value}</div>
      <div style={{ fontSize: 11, color: 'var(--muted)' }}>{label}</div>
    </div>
  )
}
