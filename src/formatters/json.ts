// Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
import chalk from 'chalk'

export function formatJson(data: unknown): string {
  const raw = JSON.stringify(data, null, 2)
  return raw
    .replace(/"([^"]+)":/g, `${chalk.cyan('"$1"')}:`)
    .replace(/: "([^"]+)"/g, `: ${chalk.green('"$1"')}`)
    .replace(/: (\d+)/g, `: ${chalk.yellow('$1')}`)
    .replace(/: (true|false)/g, `: ${chalk.magenta('$1')}`)
    .replace(/: (null)/g, `: ${chalk.gray('$1')}`)
}
