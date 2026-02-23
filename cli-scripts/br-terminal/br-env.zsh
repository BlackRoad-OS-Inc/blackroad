# ══════════════════════════════════════════════════════════════════════════════
# BlackRoad Terminal OS — Environment Variables
# ══════════════════════════════════════════════════════════════════════════════

# ── Editor ──
export EDITOR="vim"
export VISUAL="vim"

# ── Language ──
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# ── History ──
export HISTSIZE=10000
export SAVEHIST=10000
export HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS      # Don't record duplicates
setopt HIST_FIND_NO_DUPS     # Don't show duplicates in search
setopt HIST_REDUCE_BLANKS    # Remove superfluous blanks
setopt SHARE_HISTORY         # Share history between sessions

# ── Completion ──
setopt AUTO_CD               # cd by typing directory name
setopt AUTO_PUSHD            # Make cd push old directory onto stack
setopt PUSHD_IGNORE_DUPS     # Don't push duplicates
setopt PUSHD_SILENT          # Don't print directory stack
setopt CORRECT               # Suggest command corrections
setopt INTERACTIVE_COMMENTS  # Allow comments in interactive mode

# ── BlackRoad Paths ──
export BLACKROAD_HOME="$HOME/blackroad"
export BLACKROAD_OPERATOR="$HOME/blackroad/blackroad-operator"
export BLACKROAD_DOCS="$HOME/blackroad/blackroad-docs"

# Add br CLI to PATH
export PATH="$BLACKROAD_HOME:$PATH"
export PATH="$BLACKROAD_OPERATOR/cli-scripts:$PATH"

# ── Python ──
export PYTHONPATH="$BLACKROAD_HOME/src:$PYTHONPATH"
export PYTHONDONTWRITEBYTECODE=1  # Don't write .pyc files

# ── Node ──
export NODE_ENV="${NODE_ENV:-development}"

# ── Colors for ls (macOS) ──
export CLICOLOR=1
export LSCOLORS=ExGxBxDxCxEgEdxbxgxcxd

# ── Less pager ──
export LESS="-R -F -X -i"
export LESS_TERMCAP_mb=$'\e[1;31m'     # begin bold
export LESS_TERMCAP_md=$'\e[1;36m'     # begin blink
export LESS_TERMCAP_me=$'\e[0m'        # reset bold/blink
export LESS_TERMCAP_so=$'\e[01;44;33m' # begin reverse video
export LESS_TERMCAP_se=$'\e[0m'        # reset reverse video
export LESS_TERMCAP_us=$'\e[1;32m'     # begin underline
export LESS_TERMCAP_ue=$'\e[0m'        # reset underline

# ── GPG ──
export GPG_TTY=$(tty)

# ── XDG Base Directory ──
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

# ── BlackRoad Branding — official brand palette (BlackRoad OS, Inc.) ──
export BR_AMBER="#F5A623"
export BR_HOT_PINK="#FF1D6C"
export BR_ELECTRIC_BLUE="#2979FF"
export BR_VIOLET="#9C27B0"

# ══════════════════════════════════════════════════════════════════════════════
# End BlackRoad Environment
# ══════════════════════════════════════════════════════════════════════════════
