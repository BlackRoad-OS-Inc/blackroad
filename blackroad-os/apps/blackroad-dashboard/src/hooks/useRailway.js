import { useState, useEffect, useCallback } from 'react'

const GQL = 'https://backboard.railway.app/graphql/v2'

const PROJECTS_QUERY = `query {
  me {
    projects {
      edges {
        node {
          id name updatedAt
          services { edges { node { id name } } }
          environments { edges { node { id name } } }
        }
      }
    }
  }
}`

const DEPLOYS_QUERY = `query($projectId: String) {
  deployments(input: { projectId: $projectId }) {
    edges {
      node {
        id status createdAt
        meta { branch commitMessage author }
        service { id name }
      }
    }
  }
}`

export function useRailway(token) {
  const [projects, setProjects] = useState(null)
  const [deployments, setDeployments] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  const gql = useCallback(async (query, variables = {}) => {
    const r = await fetch(GQL, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ query, variables }),
    })
    const d = await r.json()
    if (d.errors) throw new Error(d.errors[0].message)
    return d.data
  }, [token])

  const loadProjects = useCallback(async () => {
    if (!token) return
    setLoading(true)
    try {
      const data = await gql(PROJECTS_QUERY)
      const items = data?.me?.projects?.edges?.map(e => ({
        id: e.node.id,
        name: e.node.name,
        services: e.node.services?.edges?.length || 0,
        environments: e.node.environments?.edges?.length || 0,
        updated: e.node.updatedAt,
      })) || []
      setProjects(items)
      // Load deployments for first project
      if (items.length > 0) {
        const ddata = await gql(DEPLOYS_QUERY, { projectId: items[0].id })
        const deps = ddata?.deployments?.edges?.map(e => ({
          id: e.node.id,
          status: e.node.status,
          service: e.node.service?.name,
          branch: e.node.meta?.branch,
          message: e.node.meta?.commitMessage,
          author: e.node.meta?.author,
          created: e.node.createdAt,
        })) || []
        setDeployments(deps)
      }
      setError(null)
    } catch (e) {
      setError(e.message)
    } finally {
      setLoading(false)
    }
  }, [token, gql])

  useEffect(() => {
    if (token) {
      loadProjects()
      const t = setInterval(loadProjects, 60000)
      return () => clearInterval(t)
    }
  }, [token, loadProjects])

  return { projects, deployments, loading, error, reload: loadProjects }
}
