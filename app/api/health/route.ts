import { NextResponse } from 'next/server';

export const runtime = 'edge';

export async function GET() {
  const health = {
    status: 'healthy',
    service: 'blackroad-os-web',
    version: process.env.npm_package_version || '0.1.0',
    timestamp: new Date().toISOString(),
    uptime: process.uptime ? process.uptime() : null,
    environment: process.env.NODE_ENV || 'development',
  };

  return NextResponse.json(health, {
    status: 200,
    headers: {
      'Cache-Control': 'no-cache, no-store, must-revalidate',
    },
  });
}
