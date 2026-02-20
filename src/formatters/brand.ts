// Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
import chalk from 'chalk'

export const brand = {
  hotPink: chalk.hex('#FF1D6C'),
  amber: chalk.hex('#F5A623'),
  violet: chalk.hex('#9C27B0'),
  electricBlue: chalk.hex('#2979FF'),

  logo() {
    return this.hotPink('▙') + this.amber('▟') + ' ' + this.violet('BlackRoad') + ' ' + this.electricBlue('OS')
  },

  header(text: string) {
    return this.hotPink('━'.repeat(60)) + '\n' + chalk.bold(text) + '\n' + this.hotPink('━'.repeat(60))
  },
}
