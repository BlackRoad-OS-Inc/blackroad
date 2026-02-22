# 🚗 BlackRoad Terminal OS v0.4 "Emoji Edition"

**An OS within the OS** — A complete terminal environment with neon branding, intelligent prompt, and productivity aliases.

---

## ✨ Features

### 🎨 Neon-Branded Prompt
- **Status indicator:** 💚 (success) / 🔥 (failure)
- **Timestamp:** 🕒 HH:MM
- **Git branch:** 🌿 branch-name
- **Python venv:** (venv:name)
- **Current directory:** with ~ shortening
- **λ sigil:** BlackRoad's functional identity
- **Full neon palette:** `#FF9D00 #FF6B00 #FF0066 #FF006B #D600AA #7700FF #0066FF`

### ⚡ Productivity Aliases
- **Navigation:** `br`, `bro`, `brd` (jump to BlackRoad repos)
- **Git shortcuts:** `gs`, `ga`, `gc`, `gp`, `gl`, `gd`, etc.
- **Python:** `py`, `pip`, `venv`, `activate`
- **Node/pnpm:** `pn`, `pni`, `pnd`, `pnb`, `pnt`
- **Railway:** `rs`, `rlk`, `rd`, `rlogs`
- **Cloudflare:** `cfl`, `cfd`, `cfp`
- **Docker:** `d`, `dc`, `dps`, `dimg`, `dex`, `dlog`

### 🛠️ Utility Functions
- `serve [port]` — Quick HTTP server
- `mkcd <dir>` — Make directory and cd
- `port <number>` — Find process on port
- `killport <number>` — Kill process on port
- `extract <file>` — Extract any archive
- `gacp "message"` — Git add + commit + push
- `gnb <branch>` — Create and switch to new branch
- `topcpu [n]` — Top processes by CPU
- `topmem [n]` — Top processes by memory

### 🌍 Environment
- **BlackRoad paths:** `$BLACKROAD_HOME`, `$BLACKROAD_OPERATOR`, `$BLACKROAD_DOCS`
- **Brand colors:** `$BR_ORANGE`, `$BR_PINK`, `$BR_PURPLE`, `$BR_BLUE`
- **History:** 10,000 commands, no duplicates, shared between sessions
- **Completion:** Auto-cd, auto-pushd, command correction

---

## 🚀 Quick Install

```bash
cd ~/blackroad-sandbox/br-terminal
chmod +x install.sh
./install.sh
source ~/.zshrc  # or: reload
```

**That's it!** Your terminal is now running BlackRoad OS.

---

## 📦 What Gets Installed

The installer adds the following to your `~/.zshrc` (or `~/.bashrc`):

```zsh
# BlackRoad Terminal OS — v0.4 Emoji Edition
[ -f "~/blackroad-sandbox/br-terminal/br-env.zsh" ] && source "~/blackroad-sandbox/br-terminal/br-env.zsh"
[ -f "~/blackroad-sandbox/br-terminal/br-aliases.zsh" ] && source "~/blackroad-sandbox/br-terminal/br-aliases.zsh"
[ -f "~/blackroad-sandbox/br-terminal/br-prompt.zsh" ] && source "~/blackroad-sandbox/br-terminal/br-prompt.zsh"
```

Your original config is backed up to `~/.zshrc.backup.YYYYMMDD_HHMMSS`.

---

## 🎨 Components

### `br-prompt.zsh`
The heart of the system — neon-branded prompt with:
- Exit code indicator (💚/🔥)
- Timestamp (🕒)
- Git branch (🌿)
- Python venv
- Current directory
- λ sigil (or optional "-1 0 1" trinary)
- Welcome banner on shell startup

### `br-aliases.zsh`
Productivity aliases and functions:
- Navigation shortcuts
- Git workflow helpers
- Language-specific aliases (Python, Node, etc.)
- Infrastructure tools (Railway, Cloudflare, Docker)
- Utility functions

### `br-env.zsh`
Environment configuration:
- Editor and language settings
- History optimization
- BlackRoad path exports
- Brand color variables
- XDG directory structure
- Python and Node defaults

### `install.sh`
Automated installer:
- Detects Bash/Zsh automatically
- Backs up existing config
- Prevents duplicate installations
- Adds clean, modular imports

---

## 🎯 Customization

### Change the Sigil
Edit `br-prompt.zsh`, find `_br_trinary()`:

```zsh
# Option 1: Lambda (default)
printf "%sλ%s" "$(_br_rgb 0x${BR_ORANGE#\#})" "$BR_RESET"

# Option 2: Trinary
printf "%s-1 0 1%s" "$(_br_rgb 0x${BR_ORANGE#\#})" "$BR_RESET"

# Option 3: Your own
printf "%s🚗%s" "$(_br_rgb 0x${BR_ORANGE#\#})" "$BR_RESET"
```

### Change Colors
Edit the palette at the top of `br-prompt.zsh`:

```zsh
BR_ORANGE="#FF9D00"     # Your color here
BR_PINK="#FF0066"       # Your color here
BR_PURPLE="#7700FF"     # Your color here
BR_BLUE="#0066FF"       # Your color here
```

### Add Your Own Aliases
Edit `br-aliases.zsh` and add to the bottom:

```zsh
# My custom aliases
alias myalias="command"
myfunction() {
  # your code
}
```

Then reload:

```bash
reload
```

---

## 🔧 Uninstall

```bash
# Remove BlackRoad Terminal OS from your shell config
sed -i.bak '/# BlackRoad Terminal OS/,/# End BlackRoad Terminal OS/d' ~/.zshrc

# Reload shell
source ~/.zshrc

# Optional: restore from backup
cp ~/.zshrc.backup.YYYYMMDD_HHMMSS ~/.zshrc
```

---

## 🌐 Integration with BlackRoad Ecosystem

This terminal environment is designed to integrate seamlessly with:

- **blackroad-os-core** — Core library and truth engine
- **blackroad-os-operator** — Orchestration layer
- **blackroad-os-api** — REST API services
- **Railway** — Cloud deployment
- **Cloudflare** — Pages, Workers, KV, D1
- **Raspberry Pi Mesh** — Local agent network

All path shortcuts and environment variables are pre-configured.

---

## 🎓 Learning the Shortcuts

After installation, try these:

```bash
# Navigation
br          # Jump to blackroad-sandbox
bro         # Jump to blackroad-os-operator
..          # Up one directory
...         # Up two directories

# Git
gs          # git status
ga .        # git add .
gc "feat: add feature"   # git commit -m
gp          # git push
gl          # git log (pretty, last 10)

# Quick tasks
serve 3000  # HTTP server on port 3000
mkcd newfolder   # Make and cd into folder
killport 8080    # Kill process on port 8080

# Development
pni         # pnpm install
pnd         # pnpm dev
pnb         # pnpm build

# Infrastructure
rs          # railway status
cfd         # cloudflare pages deploy
dps         # docker ps
```

---

## 📊 Prompt Preview

```
💚 λ 🕒 14:23 🌿 main (venv:blackroad) ~/blackroad-sandbox
❯
```

After a failed command:

```
🔥 λ 🕒 14:24 🌿 main ~/blackroad-sandbox
❯
```

---

## 🤝 Contributing

This terminal environment is part of the BlackRoad OS ecosystem.

To suggest improvements:
1. Edit the relevant `.zsh` file
2. Test in your shell
3. Commit with `gc "feat: improve prompt"`
4. Share with the team

---

## 📄 License

Part of BlackRoad OS — Built with neon dreams and terminal love.

**Maintained by:** Alexa Amundson
**Version:** 0.4 "Emoji Edition"
**Updated:** 2025-12-15

---

## 🎉 Welcome to BlackRoad Terminal OS!

You're now running an OS within the OS. Enjoy the neon vibes and productivity boost! 🚗💨
