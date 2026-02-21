import { NextResponse } from 'next/server'

export async function GET() {
  return NextResponse.json({
    version: '0.0.1',
    service: 'blackroad-os-operator',
    environment: process.env.SERVICE_ENV || 'development',
    node_version: process.version,
    build_time: process.env.BUILD_TIME || new Date().toISOString()
  })
}
