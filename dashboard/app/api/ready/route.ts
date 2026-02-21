import { NextResponse } from 'next/server'

export async function GET() {
  const isReady = true

  if (!isReady) {
    return NextResponse.json(
      { ready: false, reason: 'Service dependencies not available' },
      { status: 503 }
    )
  }

  return NextResponse.json({
    ready: true,
    service: 'blackroad-os-operator'
  })
}
