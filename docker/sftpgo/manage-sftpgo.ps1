#!/usr/bin/env pwsh
param([string]$Action)

$CONTAINER_NAME = "wordpress-docker-starter-sftpgo-1"

switch ($Action) {
    "start" { docker compose up -d sftpgo }
    "stop" { docker compose stop sftpgo }
    "restart" { docker compose restart sftpgo }
    "status" { docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}" }
    "logs" { docker logs $CONTAINER_NAME --tail 50 -f }
    "add-user" {
        $username = Read-Host "Username"
        $password = Read-Host "Password"
        $body = @{
            username = $username
            password = $password
            status = 1
            home_dir = "/srv/sftpgo/data/$username"
            permissions = @{
                "/" = @("*")
            }
        } | ConvertTo-Json -Depth 3
        
        Invoke-RestMethod -Uri "http://localhost:8080/api/v2/users" -Method POST -Body $body -ContentType "application/json"
        Write-Host "User '$username' created successfully"
    }
    default {
        Write-Host "Usage: .\manage-sftpgo.ps1 [start|stop|restart|status|logs|add-user]"
    }
}
