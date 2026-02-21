#!/bin/bash

LEVEL="${1:-info}"
MSG="${2:-System notification}"

case "$LEVEL" in
  info)    ICON="ℹ"; COLOR="1;36" ;;
  warn)    ICON="⚠"; COLOR="1;33" ;;
  error)   ICON="✖"; COLOR="1;31" ;;
  success) ICON="✓"; COLOR="1;32" ;;
  *)       ICON="●"; COLOR="1;37" ;;
esac

echo ""
echo -e "  \033[${COLOR}m┌──────────────────────────────────────────────────────────────┐\033[0m"
echo -e "  \033[${COLOR}m│\033[0m  $ICON  \033[1;37m${LEVEL^^}\033[0m                                              \033[${COLOR}m│\033[0m"
echo -e "  \033[${COLOR}m│\033[0m                                                              \033[${COLOR}m│\033[0m"
echo -e "  \033[${COLOR}m│\033[0m  $MSG"
echo -e "  \033[${COLOR}m│\033[0m                                                              \033[${COLOR}m│\033[0m"
echo -e "  \033[${COLOR}m│\033[0m  \033[2m$(date '+%Y-%m-%d %H:%M:%S')\033[0m                                      \033[${COLOR}m│\033[0m"
echo -e "  \033[${COLOR}m└──────────────────────────────────────────────────────────────┘\033[0m"
echo ""
