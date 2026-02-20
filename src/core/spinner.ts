// Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
import ora from 'ora'

export function createSpinner(text: string) {
  return ora({ text, color: 'magenta' })
}
