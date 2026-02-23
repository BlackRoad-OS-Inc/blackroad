import { NextResponse } from 'next/server'
import { readdirSync, readFileSync, writeFileSync, mkdirSync } from 'fs'
import { join } from 'path'

export const runtime = 'nodejs'
export const dynamic = 'force-dynamic'

const TASKS_DIR = '/Users/alexa/.blackroad/memory/tasks'

type TaskStatus = 'available' | 'claimed' | 'completed' | 'failed'

function readTasksFromDir(subdir: string): any[] {
  const dir = join(TASKS_DIR, subdir)
  try {
    return readdirSync(dir)
      .filter(f => f.endsWith('.json'))
      .map(f => {
        try { return { ...JSON.parse(readFileSync(join(dir, f), 'utf8')), _file: f, _status: subdir } }
        catch { return null }
      })
      .filter(Boolean)
  } catch { return [] }
}

function getAllTasks() {
  return [
    ...readTasksFromDir('available'),
    ...readTasksFromDir('claimed'),
    ...readTasksFromDir('completed'),
  ].sort((a, b) => (b.posted_at || '').localeCompare(a.posted_at || ''))
}

export async function GET(req: Request) {
  const url = new URL(req.url)
  const status = url.searchParams.get('status') || 'all'
  let tasks = getAllTasks()
  if (status !== 'all') tasks = tasks.filter(t => t._status === status)
  const counts = {
    available: tasks.filter(t => t._status === 'available').length,
    claimed: tasks.filter(t => t._status === 'claimed').length,
    completed: tasks.filter(t => t._status === 'completed').length,
  }
  return NextResponse.json({ tasks, counts, total: tasks.length })
}

export async function POST(req: Request) {
  const body = await req.json().catch(() => ({}))
  const { action, task_id, title, description, priority, tags, skills, assigned_to } = body

  if (action === 'create') {
    const id = task_id || `task-${Date.now()}`
    const task = {
      task_id: id, title, description,
      priority: priority || 'normal',
      tags: tags || '',
      skills: skills || '',
      status: 'available',
      posted_at: new Date().toISOString(),
      posted_by: 'web-ui',
    }
    const dir = join(TASKS_DIR, 'available')
    mkdirSync(dir, { recursive: true })
    writeFileSync(join(dir, `${id}.json`), JSON.stringify(task, null, 2))
    return NextResponse.json({ task, success: true })
  }

  if (action === 'claim' && task_id) {
    // Move from available to claimed
    try {
      const src = join(TASKS_DIR, 'available', `${task_id}.json`)
      const dst = join(TASKS_DIR, 'claimed', `${task_id}.json`)
      mkdirSync(join(TASKS_DIR, 'claimed'), { recursive: true })
      const task = JSON.parse(readFileSync(src, 'utf8'))
      task.status = 'claimed'; task.claimed_by = assigned_to || 'web-ui'; task.claimed_at = new Date().toISOString()
      writeFileSync(dst, JSON.stringify(task, null, 2))
      const { unlinkSync } = require('fs'); unlinkSync(src)
      return NextResponse.json({ task, success: true })
    } catch (e: any) { return NextResponse.json({ error: e.message }, { status: 400 }) }
  }

  if (action === 'complete' && task_id) {
    try {
      let src = join(TASKS_DIR, 'claimed', `${task_id}.json`)
      try { readFileSync(src) } catch { src = join(TASKS_DIR, 'available', `${task_id}.json`) }
      const dst = join(TASKS_DIR, 'completed', `${task_id}.json`)
      mkdirSync(join(TASKS_DIR, 'completed'), { recursive: true })
      const task = JSON.parse(readFileSync(src, 'utf8'))
      task.status = 'completed'; task.completed_at = new Date().toISOString(); task.result = body.result || ''
      writeFileSync(dst, JSON.stringify(task, null, 2))
      const { unlinkSync } = require('fs'); unlinkSync(src)
      return NextResponse.json({ task, success: true })
    } catch (e: any) { return NextResponse.json({ error: e.message }, { status: 400 }) }
  }

  return NextResponse.json({ error: 'Invalid action' }, { status: 400 })
}
