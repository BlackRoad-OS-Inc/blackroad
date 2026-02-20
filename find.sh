#!/bin/bash

QUERY="$1"

if [ -z "$QUERY" ]; then
  echo ""
  echo -e "  \033[1;35mUsage:\033[0m ./find.sh <search term>"
  echo -e "  \033[2mSearches all BlackRoad OS commands\033[0m"
  echo ""
  exit 0
fi

echo ""
echo -e "  \033[1;35m┌──────────────────────────────────────────────────────────────────────────┐\033[0m"
echo -e "  \033[1;35m│\033[0m  \033[1;37mSEARCH RESULTS FOR:\033[0m $QUERY                                           \033[1;35m│\033[0m"
echo -e "  \033[1;35m├──────────────────────────────────────────────────────────────────────────┤\033[0m"

COMMANDS=(
  "hub.sh:Main menu launcher"
  "intro.sh:Animated intro sequence"
  "boot.sh:System boot animation"
  "god.sh:All-in-one overview dashboard"
  "mission.sh:Mission control display"
  "dash.sh:Standard dashboard"
  "monitor.sh:System resource monitor"
  "spark.sh:Sparkline metrics charts"
  "health.sh:System health check"
  "logs.sh:Live log stream"
  "events.sh:Event stream viewer"
  "timeline.sh:Event timeline"
  "net.sh:Network topology diagram"
  "wire.sh:Live message wire"
  "traffic.sh:Traffic flow visualization"
  "roster.sh:Live agent roster"
  "inspect.sh:Detailed agent view"
  "soul.sh:Agent personality profile"
  "office.sh:Visual office with walking agents"
  "chat.sh:Interactive chat with agents"
  "focus.sh:One-on-one with single agent"
  "convo.sh:Watch agents converse"
  "broadcast.sh:Send message to all agents"
  "think.sh:All agents respond to query"
  "debate.sh:LUCIDIA vs CIPHER debate"
  "story.sh:Collaborative storytelling"
  "council.sh:Agent voting council"
  "whisper.sh:Private agent message"
  "thoughts.sh:Agent internal monologue"
  "mem.sh:Memory usage breakdown"
  "tasks.sh:Task queue status"
  "queue.sh:Live message queue"
  "config.sh:Configuration viewer"
  "report.sh:Daily system report"
  "alert.sh:Show alert notification"
  "skills.sh:Agent capabilities matrix"
  "bonds.sh:Agent relationships"
  "mood.sh:Agent mood tracker"
  "clock.sh:Digital clock display"
  "pulse.sh:Minimal pulse animation"
  "matrix.sh:Matrix rain screensaver"
  "saver.sh:Bouncing logo screensaver"
  "demo.sh:Full system demo"
)

found=0
for cmd in "${COMMANDS[@]}"; do
  name="${cmd%%:*}"
  desc="${cmd#*:}"
  if echo "$name $desc" | grep -qi "$QUERY"; then
    echo -e "  \033[1;35m│\033[0m  \033[1;36m./$name\033[0m"
    echo -e "  \033[1;35m│\033[0m  \033[2m$desc\033[0m"
    echo -e "  \033[1;35m│\033[0m                                                                          \033[1;35m│\033[0m"
    ((found++))
  fi
done

if [ $found -eq 0 ]; then
  echo -e "  \033[1;35m│\033[0m  \033[2mNo commands found matching '$QUERY'\033[0m                                   \033[1;35m│\033[0m"
fi

echo -e "  \033[1;35m├──────────────────────────────────────────────────────────────────────────┤\033[0m"
echo -e "  \033[1;35m│\033[0m  \033[2m$found result(s)\033[0m                                                         \033[1;35m│\033[0m"
echo -e "  \033[1;35m└──────────────────────────────────────────────────────────────────────────┘\033[0m"
