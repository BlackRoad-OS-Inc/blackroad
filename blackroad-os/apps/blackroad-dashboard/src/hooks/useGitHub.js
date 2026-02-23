import { useState, useEffect, useCallback } from 'react'

const BASE = 'https://api.github.com'

export function useGitHub(token, org = 'BlackRoad-OS-Inc', repo = 'blackroad') {
  const [runs, setRuns] = useState(null)
  const [repoInfo, setRepoInfo] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  const ghFetch = useCallback(async (path) => {
    const r = await fetch(`${BASE}${path}`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      },
    })
    if (!r.ok) throw new Error(`GitHub ${r.status}: ${r.statusText}`)
    return r.json()
  }, [token])

  const load = useCallback(async () => {
    if (!token) return
    setLoading(true)
    try {
      const [runsData, repoData] = await Promise.all([
        ghFetch(`/repos/${org}/${repo}/actions/runs?per_page=10`),
        ghFetch(`/repos/${org}/${repo}`),
      ])
      setRuns((runsData.workflow_runs || []).map(r => ({
        id: r.id,
        name: r.name,
        status: r.status,
        conclusion: r.conclusion,
        branch: r.head_branch,
        commit: r.head_sha?.slice(0, 7),
        actor: r.actor?.login,
        created: r.created_at,
        url: r.html_url,
      })))
      setRepoInfo({
        name: repoData.full_name,
        stars: repoData.stargazers_count,
        forks: repoData.forks_count,
        issues: repoData.open_issues_count,
        branch: repoData.default_branch,
        updated: repoData.updated_at,
      })
      setError(null)
    } catch (e) {
      setError(e.message)
    } finally {
      setLoading(false)
    }
  }, [token, org, repo, ghFetch])

  useEffect(() => {
    if (token) {
      load()
      const t = setInterval(load, 30000)
      return () => clearInterval(t)
    }
  }, [token, load])

  return { runs, repoInfo, loading, error, reload: load }
}
