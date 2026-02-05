# BlackRoad CLI

> Command-line interface for BlackRoad OS

## Quick Reference

| Property | Value |
|----------|-------|
| **Runtime** | Node.js 18+ |
| **Binary** | `br` / `blackroad` |
| **Package** | @blackroad/cli |
| **Type** | CLI Tool |

## Installation

```bash
# Global install
npm install -g @blackroad/cli

# Or run directly
npx @blackroad/cli

# Development
npm install
npm link
```

## Commands

```bash
br --help           # Show all commands
br status           # System status
br agents           # List agents
br agents:wake      # Wake an agent
br deploy           # Deploy to cloud
br mesh             # Check infrastructure mesh
br memory           # Memory operations
```

## Project Structure

```
bin/
└── br.js           # Main entry point

src/
├── commands/       # CLI commands
├── utils/          # Helpers
├── config/         # Configuration
└── api/            # API client

lib/
└── ...             # Compiled output
```

## Development

```bash
npm run dev         # Watch mode
npm run build       # Build
npm run test        # Run tests
npm run lint        # Lint check
```

## Command Development

Adding a new command:

```javascript
// src/commands/mycommand.js
export default {
  name: 'mycommand',
  description: 'Does something cool',
  options: [
    { flag: '-v, --verbose', description: 'Verbose output' }
  ],
  action: async (options) => {
    // Command logic
  }
}
```

## Configuration

Config file: `~/.blackroadrc` or `~/.config/blackroad/config.json`

```json
{
  "apiUrl": "https://api.blackroad.io",
  "defaultOrg": "blackboxprogramming",
  "theme": "dark"
}
```

## Environment Variables

```env
BLACKROAD_API_KEY=     # API authentication
BLACKROAD_ORG=         # Default organization
BLACKROAD_DEBUG=1      # Enable debug logging
```

## Publishing

```bash
npm version patch
npm publish --access public
```

## Related Repos

- `blackroad-os-web` - Web interface
- `blackroad-os-core` - Core engine
- `blackroad-os-docs` - Documentation
