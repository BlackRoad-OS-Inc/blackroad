#!/bin/bash

RAILWAY_TOKEN='rw_Fe26.2**4886aa7f30312f2b5175d740b004556007d92320a2d5d2501815a66a9bb86ae4*iVNo1MLhUpC8uZez5Bu43A*q8GfxbzT1NdUBKxPn5CMAA-bg0uucscc3_vYxVqQAm4j2n9JY8BBR873wpQz2Mr1mnxNYLarT4YHAM6zi6dskQ*1768349176306*1fca5dccd2a52158711982a114fe07f9d0fd7873b1a498d5f29b6852b50f92b5*82uj-X1WnJ50-e4u2W4MflsCi4bdhq3b_EqDnEYcP-g'

curl -s -X POST https://backboard.railway.app/graphql/v2 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${RAILWAY_TOKEN}" \
  -d '{"query":"query { me { id workspaces { edges { node { id name } } } } }"}' | jq '.'
