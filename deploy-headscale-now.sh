#!/bin/bash
cd /Users/alexa/blackroad-priority-stack/headscale
docker compose up -d --wait
docker ps | grep blackroad
