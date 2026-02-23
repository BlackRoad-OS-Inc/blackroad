#compdef br

_br() {
  local -a commands subcmds
  commands=(
    help
    status
    colors
    agents
    lucidia
    log
    ping
    registry
    export
    ssh
    menu
  )

  case "$words[2]" in
    colors)
      subcmds=(all gradient banner status agents)
      ;;
    lucidia)
      subcmds=(state set)
      ;;
    log)
      subcmds=(append tail)
      ;;
    ping)
      subcmds=(agents alice octavia lucidia anastasia)
      ;;
    registry)
      subcmds=(add list clear)
      ;;
    export)
      subcmds=(agents status)
      ;;
    ssh)
      subcmds=(alice octavia lucidia anastasia pikvm aria64 shellfish)
      ;;
    *)
      subcmds=()
      ;;
  esac

  if [[ $CURRENT -eq 2 ]]; then
    _describe 'command' commands
  else
    _describe 'subcommand' subcmds
  fi
}

_br
