#!/usr/bin/env bash

# Headscale Management Script

CONTAINER="blackroad-headscale"

case "$1" in
    start)
        docker compose up -d
        echo "✅ Headscale started"
        ;;
    stop)
        docker compose down
        echo "✅ Headscale stopped"
        ;;
    restart)
        docker compose restart
        echo "✅ Headscale restarted"
        ;;
    logs)
        docker logs -f $CONTAINER
        ;;
    namespace)
        if [ -z "$2" ]; then
            echo "Usage: $0 namespace create|list <name>"
            exit 1
        fi
        docker exec $CONTAINER headscale namespaces "$2" "${@:3}"
        ;;
    preauth)
        if [ -z "$2" ]; then
            echo "Usage: $0 preauth <namespace>"
            exit 1
        fi
        docker exec $CONTAINER headscale preauthkeys create --namespace "$2" --expiration 24h
        ;;
    nodes)
        docker exec $CONTAINER headscale nodes list
        ;;
    routes)
        docker exec $CONTAINER headscale routes list
        ;;
    status)
        docker compose ps
        ;;
    *)
        echo "Headscale Management"
        echo ""
        echo "Usage: $0 {start|stop|restart|logs|status|namespace|preauth|nodes|routes}"
        echo ""
        echo "Examples:"
        echo "  $0 start              # Start Headscale"
        echo "  $0 namespace create blackroad  # Create namespace"
        echo "  $0 preauth blackroad  # Generate pre-auth key"
        echo "  $0 nodes              # List registered nodes"
        echo "  $0 logs               # View logs"
        exit 1
        ;;
esac
