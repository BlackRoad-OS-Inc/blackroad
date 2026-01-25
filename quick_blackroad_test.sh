#!/bin/bash

echo "\ud83d\ude80 QUICK BLACKROAD STATUS CHECK..."
echo "\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\n
# Test all components quickly
echo "\ud83e\udd13 Lucidia:"
curl -I -s https://blackroad.io/lucidia/ | head -1

echo -e "\n\ud83d\uddef\ufe0f Guardian:"
curl -I -s https://blackroad.io/guardian/ | head -1

echo -e "\n\ud83d\udcda Codex:"
curl -I -s https://blackroad.io/codex/ | head -1

echo -e "\n\ud83d\udd10 Login:"
curl -I -s https://blackroad.io/login/ | head -1

echo -e "\n\ud83c\udfe0 Main Site:"
curl -I -s https://blackroad.io/ | head -1

echo -e "\n\ud83d\udcca Dashboard:"
curl -I -s https://blackroad.io/dashboard.html | head -1

# Quick success count
echo -e "\n\ud83c\udf1f SUCCESS COUNT:"
success=0

if curl -I -s https://blackroad.io/lucidia/ | grep -q "200"; then
    echo "\u2705 Lucidia working"
    ((success++))
fi

if curl -I -s https://blackroad.io/guardian/ | grep -q "200"; then
    echo "\u2705 Guardian working"
    ((success++))
fi

if curl -I -s https://blackroad.io/codex/ | grep -q "200"; then
    echo "\u2705 Codex working"
    ((success++))
fi

if curl -I -s https://blackroad.io/login/ | grep -q "200"; then
    echo "\u2705 Login working"
    ((success++))
fi

if curl -I -s https://blackroad.io/ | grep -q "200"; then
    echo "\u2705 Main Site working"
    ((success++))
fi

if curl -I -s https://blackroad.io/dashboard.html | grep -q "200"; then
    echo "\u2705 Dashboard working"
    ((success++))
fi

echo -e "\n\ud83c\udf3e RESULT: $success/6 components online!"

if [ $success -eq 6 ]; then
    echo -e "\n\ud83c\udf89 COMPLETE SUCCESS! ALL BLACKROAD APPS WORKING!"
elif [ $success -ge 4 ]; then
    echo -e "\n\ud83c\udf89 MAJOR SUCCESS! Most apps working!"
elif [ $success -ge 2 ]; then
    echo -e "\n\ud83c\udf1f Good progress! Core apps working!"
else
    echo -e "\n\ud83d\udd27 Still working on getting more online..."
fi

echo -e "\n\ud83c\udf10 Access your working components at:"

if curl -I -s https://blackroad.io/lucidia/ | grep -q "200"; then
    echo "  \ud83e\udd13 https://blackroad.io/lucidia/"
fi
if curl -I -s https://blackroad.io/guardian/ | grep -q "200"; then
    echo "  \ud83d\uddef\ufe0f https://blackroad.io/guardian/"
fi
if curl -I -s https://blackroad.io/codex/ | grep -q "200"; then
    echo "  \ud83d\udcda https://blackroad.io/codex/"
fi
if curl -I -s https://blackroad.io/login/ | grep -q "200"; then
    echo "  \ud83d\udd10 https://blackroad.io/login/"
fi
if curl -I -s https://blackroad.io/ | grep -q "200"; then
    echo "  \ud83c\udfe0 https://blackroad.io/"
fi
if curl -I -s https://blackroad.io/dashboard.html | grep -q "200"; then
    echo "  \ud83d\udcca https://blackroad.io/dashboard.html"
fi
