#!/bin/bash

CONTAINER_NAME="wordpress-docker-starter-sftpgo-1"

case "$1" in
    start)
        docker compose up -d sftpgo
        ;;
    stop)
        docker compose stop sftpgo
        ;;
    restart)
        docker compose restart sftpgo
        ;;
    status)
        docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}"
        ;;
    logs)
        docker logs $CONTAINER_NAME --tail 50 -f
        ;;
    add-user)
        read -p "Username: " username
        read -s -p "Password: " password
        echo
        
        curl -X POST http://localhost:8080/api/v2/users \
             -H "Content-Type: application/json" \
             -d "{
                 \"username\": \"$username\",
                 \"password\": \"$password\",
                 \"status\": 1,
                 \"home_dir\": \"/srv/sftpgo/data/$username\",
                 \"permissions\": {\"/\": [\"*\"]}
             }"
        echo "User '$username' created successfully"
        ;;
    *)
        echo "Usage: $0 [start|stop|restart|status|logs|add-user]"
        ;;
esac
