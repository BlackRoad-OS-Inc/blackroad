import { useState } from 'react'
import styles from './Settings.module.css'

export default function Settings({ config, onSave }) {
  const [form, setForm] = useState(config)

  const set = (k, v) => setForm(f => ({ ...f, [k]: v }))

  return (
    <div className={styles.wrap}>
      <div className={styles.card}>
        <div className={styles.title}>
          <span className="grad-text">◆</span> Settings
        </div>
        <p className={styles.sub}>Tokens are saved in your browser only — never sent to any server except the API you're connecting to.</p>

        <Field label="Railway Token" type="password"
          value={form.railwayToken}
          onChange={v => set('railwayToken', v)}
          placeholder="••••••••••••••••" />

        <Field label="GitHub Token" type="password"
          value={form.githubToken}
          onChange={v => set('githubToken', v)}
          placeholder="ghp_••••••••••••••••" />

        <Field label="GitHub Org" type="text"
          value={form.githubOrg}
          onChange={v => set('githubOrg', v)}
          placeholder="BlackRoad-OS-Inc" />

        <Field label="GitHub Repo" type="text"
          value={form.githubRepo}
          onChange={v => set('githubRepo', v)}
          placeholder="blackroad" />

        <button className={styles.save} onClick={() => onSave(form)}>
          Save & Connect
        </button>
      </div>
    </div>
  )
}

function Field({ label, type, value, onChange, placeholder }) {
  return (
    <div style={{ marginBottom: 16 }}>
      <label style={{ display: 'block', fontSize: 12, color: 'var(--muted)', marginBottom: 6 }}>
        {label}
      </label>
      <input
        type={type}
        value={value || ''}
        onChange={e => onChange(e.target.value)}
        placeholder={placeholder}
        autoComplete="off"
      />
    </div>
  )
}
