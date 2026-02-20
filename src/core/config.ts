// Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
import Conf from 'conf'

interface BrConfig {
  gatewayUrl: string
  defaultAgent: string
  logLevel: string
}

const defaults: BrConfig = {
  gatewayUrl: 'http://127.0.0.1:8787',
  defaultAgent: 'octavia',
  logLevel: 'info',
}

export function loadConfig(): Conf<BrConfig> {
  return new Conf<BrConfig>({
    projectName: 'blackroad',
    defaults,
  })
}
