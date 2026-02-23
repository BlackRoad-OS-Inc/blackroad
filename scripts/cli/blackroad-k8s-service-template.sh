#!/bin/bash
# ============================================================================
# BLACKROAD OS, INC. - PROPRIETARY AND CONFIDENTIAL
# Copyright (c) 2024-2026 BlackRoad OS, Inc. All Rights Reserved.
# 
# This code is the intellectual property of BlackRoad OS, Inc.
# AI-assisted development does not transfer ownership to AI providers.
# Unauthorized use, copying, or distribution is prohibited.
# NOT licensed for AI training or data extraction.
# ============================================================================
# BlackRoad K8s Service Template
# Usage: blackroad-k8s-service-template.sh <name> <port> [host_ip]
#
# Example: blackroad-k8s-service-template.sh agents 8010
#          blackroad-k8s-service-template.sh salesforce 8011 192.168.4.38

set -e

NAME="${1:?Usage: $0 <name> <port> [host_ip]}"
HOST_PORT="${2:?Usage: $0 <name> <port> [host_ip]}"
HOST_IP="${3:-192.168.4.49}"
PATH_PREFIX="/${NAME}"

echo "🖤 Deploying ${NAME} service..."
echo "   Path: ${PATH_PREFIX}/*"
echo "   Backend: ${HOST_IP}:${HOST_PORT}"
echo ""

kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: ${NAME}
  namespace: default
spec:
  ports:
    - name: http
      port: 80
      targetPort: ${HOST_PORT}
---
apiVersion: v1
kind: Endpoints
metadata:
  name: ${NAME}
  namespace: default
subsets:
  - addresses:
      - ip: ${HOST_IP}
    ports:
      - name: http
        port: ${HOST_PORT}
---
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: ${NAME}-strip
  namespace: default
spec:
  stripPrefix:
    prefixes:
      - ${PATH_PREFIX}
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${NAME}
  namespace: default
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web
    traefik.ingress.kubernetes.io/router.middlewares: default-${NAME}-strip@kubernetescrd
spec:
  ingressClassName: traefik
  rules:
    - http:
        paths:
          - path: ${PATH_PREFIX}
            pathType: Prefix
            backend:
              service:
                name: ${NAME}
                port:
                  number: 80
EOF

echo ""
echo "✅ ${NAME} deployed!"
echo ""
echo "Test: curl http://${HOST_IP}${PATH_PREFIX}/"
echo ""

# Verify
kubectl get ingress,svc,endpoints | grep -E "${NAME}|NAME"
