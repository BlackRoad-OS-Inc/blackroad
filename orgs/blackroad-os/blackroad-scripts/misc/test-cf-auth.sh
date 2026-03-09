#!/bin/bash

CF_TOKEN='yP5h0HvsXX0BpHLs01tLmgtTbQurIKPL4YnQfIwy'

curl -s -X GET 'https://api.cloudflare.com/client/v4/zones' \
  -H "Authorization: Bearer ${CF_TOKEN}" \
  -H 'Content-Type: application/json' | jq '.'
