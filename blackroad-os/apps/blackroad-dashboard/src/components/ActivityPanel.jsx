import styles from './ActivityPanel.module.css'

function ago(iso) {
  const s = Math.floor((Date.now() - new Date(iso)) / 1000)
  if (s < 60)    return `${s}s ago`
  if (s < 3600)  return `${Math.floor(s/60)}m ago`
  if (s < 86400) return `${Math.floor(s/3600)}h ago`
  return `${Math.floor(s/86400)}d ago`
}

const ICONS = {
  gh_run:    '⚙',
  gh_push:   '◆',
  deploy:    '🚂',
  worker:    '⚡',
}

export default function ActivityPanel({ githubRuns, deployments }) {
  // Merge and sort events from GitHub runs + Railway deployments
  const events = [
    ...(githubRuns || []).slice(0, 5).map(r => ({
      id: `gh-${r.id}`,
      type: 'gh_run',
      title: r.name,
      sub: `${r.branch} · ${r.actor}`,
      status: r.conclusion || r.status,
      time: r.created,
      url: r.url,
    })),
    ...(deployments || []).slice(0, 5).map(d => ({
      id: `rail-${d.id}`,
      type: 'deploy',
      title: d.service || 'Railway',
      sub: `${d.branch || ''} ${d.message ? '· ' + d.message.slice(0, 40) : ''}`.trim(),
      status: d.status,
      time: d.created,
      url: null,
    })),
  ].sort((a, b) => new Date(b.time) - new Date(a.time)).slice(0, 10)

  const statusColor = (s) => {
    if (!s) return 'queued'
    s = s.toLowerCase()
    if (['success','complete','succeeded'].includes(s)) return styles.success
    if (['failure','failed','crashed'].includes(s)) return styles.failure
    if (['in_progress','deploying','building'].includes(s)) return styles.running
    return styles.neutral
  }

  if (!events.length) {
    return (
      <section className={styles.panel}>
        <header className={styles.header}><span className={styles.title}>◆ Activity</span></header>
        <div className={styles.empty}>Connect Railway + GitHub to see activity</div>
      </section>
    )
  }

  return (
    <section className={styles.panel}>
      <header className={styles.header}>
        <span className={styles.title}>◆ Activity</span>
        <span className="muted" style={{ fontSize: 12 }}>{events.length} events</span>
      </header>
      <div className={styles.feed}>
        {events.map(e => (
          <div key={e.id} className={styles.event} onClick={() => e.url && window.open(e.url)}>
            <span className={styles.icon}>{ICONS[e.type]}</span>
            <div className={styles.body}>
              <span className={styles.title2}>{e.title}</span>
              {e.sub && <span className={styles.sub}>{e.sub}</span>}
            </div>
            <div className={styles.right}>
              <span className={`${styles.dot} ${statusColor(e.status)}`} />
              <span className="muted" style={{ fontSize: 11 }}>{ago(e.time)}</span>
            </div>
          </div>
        ))}
      </div>
    </section>
  )
}
