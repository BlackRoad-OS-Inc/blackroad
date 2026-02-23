#!/bin/bash

AGENT="${1:-LUCIDIA}"

case "$AGENT" in
  LUCIDIA|lucidia) COLOR="1;31"; ROLE="Chief Intelligence"; PORT="5001"; DESC="Recursive reasoning engine. Philosophical. Questions everything." ;;
  ALICE|alice) COLOR="1;36"; ROLE="Gateway Agent"; PORT="5002"; DESC="Routes all incoming requests. Practical and efficient." ;;
  OCTAVIA|octavia) COLOR="1;32"; ROLE="Compute Worker"; PORT="5003"; DESC="Handles ML inference. Runs on Hailo accelerator." ;;
  PRISM|prism) COLOR="1;33"; ROLE="Analytics Engine"; PORT="5004"; DESC="Pattern detection. Metrics obsessed." ;;
  ECHO|echo) COLOR="1;35"; ROLE="Memory Systems"; PORT="5005"; DESC="Manages vector store. References the past." ;;
  CIPHER|cipher) COLOR="1;34"; ROLE="Security Agent"; PORT="5006"; DESC="Auth and encryption. Paranoid by design." ;;
  *) echo "Unknown agent: $AGENT"; exit 1 ;;
esac

clear
echo ""
echo -e "  \033[${COLOR}m╔══════════════════════════════════════════════════════════════════════════╗\033[0m"
echo -e "  \033[${COLOR}m║\033[0m                                                                          \033[${COLOR}m║\033[0m"
echo -e "  \033[${COLOR}m║\033[0m   \033[1;37m█████████\033[0m                                                            \033[${COLOR}m║\033[0m"
echo -e "  \033[${COLOR}m║\033[0m   \033[1;37m█       █\033[0m     \033[1;37m$AGENT\033[0m                                              \033[${COLOR}m║\033[0m"
echo -e "  \033[${COLOR}m║\033[0m   \033[1;37m█  ◉ ◉  █\033[0m     \033[2m$ROLE\033[0m                                      \033[${COLOR}m║\033[0m"
echo -e "  \033[${COLOR}m║\033[0m   \033[1;37m█   ▽   █\033[0m                                                            \033[${COLOR}m║\033[0m"
echo -e "  \033[${COLOR}m║\033[0m   \033[1;37m█████████\033[0m     \033[1;32m● ONLINE\033[0m                                           \033[${COLOR}m║\033[0m"
echo -e "  \033[${COLOR}m║\033[0m                                                                          \033[${COLOR}m║\033[0m"
echo -e "  \033[${COLOR}m╠══════════════════════════════════════════════════════════════════════════╣\033[0m"
echo -e "  \033[${COLOR}m║\033[0m                                                                          \033[${COLOR}m║\033[0m"
echo -e "  \033[${COLOR}m║\033[0m  \033[1;37mDESCRIPTION\033[0m                                                            \033[${COLOR}m║\033[0m"
echo -e "  \033[${COLOR}m║\033[0m  $DESC       \033[${COLOR}m║\033[0m"
echo -e "  \033[${COLOR}m║\033[0m                                                                          \033[${COLOR}m║\033[0m"
echo -e "  \033[${COLOR}m╠══════════════════════════════════════════════════════════════════════════╣\033[0m"
echo -e "  \033[${COLOR}m║\033[0m                                                                          \033[${COLOR}m║\033[0m"
echo -e "  \033[${COLOR}m║\033[0m  \033[1;37mENDPOINT\033[0m      localhost:$PORT                                        \033[${COLOR}m║\033[0m"
echo -e "  \033[${COLOR}m║\033[0m  \033[1;37mMEMORY\033[0m        $((RANDOM % 300 + 100))MB / 512MB                                       \033[${COLOR}m║\033[0m"
echo -e "  \033[${COLOR}m║\033[0m  \033[1;37mTASKS\033[0m         $((RANDOM % 15)) active, $((RANDOM % 100)) completed                             \033[${COLOR}m║\033[0m"
echo -e "  \033[${COLOR}m║\033[0m  \033[1;37mUPTIME\033[0m        $((RANDOM % 100 + 50))h $((RANDOM % 60))m                                          \033[${COLOR}m║\033[0m"
echo -e "  \033[${COLOR}m║\033[0m  \033[1;37mLAST ACTIVE\033[0m   $(date +%H:%M:%S)                                          \033[${COLOR}m║\033[0m"
echo -e "  \033[${COLOR}m║\033[0m                                                                          \033[${COLOR}m║\033[0m"
echo -e "  \033[${COLOR}m╠══════════════════════════════════════════════════════════════════════════╣\033[0m"
echo -e "  \033[${COLOR}m║\033[0m                                                                          \033[${COLOR}m║\033[0m"
echo -e "  \033[${COLOR}m║\033[0m  \033[1;37mRECENT EVENTS\033[0m                                                          \033[${COLOR}m║\033[0m"
echo -e "  \033[${COLOR}m║\033[0m  \033[2m$(date +%H:%M:%S)\033[0m  task.complete     \033[2m#$(printf '%04x' $RANDOM)\033[0m                             \033[${COLOR}m║\033[0m"
echo -e "  \033[${COLOR}m║\033[0m  \033[2m$(date +%H:%M:%S)\033[0m  message.received  \033[2m#$(printf '%04x' $RANDOM)\033[0m                             \033[${COLOR}m║\033[0m"
echo -e "  \033[${COLOR}m║\033[0m  \033[2m$(date +%H:%M:%S)\033[0m  heartbeat.sent    \033[2m#$(printf '%04x' $RANDOM)\033[0m                             \033[${COLOR}m║\033[0m"
echo -e "  \033[${COLOR}m║\033[0m                                                                          \033[${COLOR}m║\033[0m"
echo -e "  \033[${COLOR}m╚══════════════════════════════════════════════════════════════════════════╝\033[0m"
echo ""
echo -e "  \033[2mUsage: ./inspect.sh [LUCIDIA|ALICE|OCTAVIA|PRISM|ECHO|CIPHER]\033[0m"
