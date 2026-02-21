# Multi-Service Docker Environment Management Script
# Services: PostgreSQL, Redis, RabbitMQ, Elasticsearch, MongoDB, Monitoring (Prometheus + Grafana)
#           MSSQL (SQL Server), Keycloak, Seq, MailHog
# Usage: .\manage.ps1 [action] [environment] [service]
# Example: .\manage.ps1 start dev postgres
#          .\manage.ps1 start dev redis
#          .\manage.ps1 start dev rabbitmq
#          .\manage.ps1 start dev elasticsearch
#          .\manage.ps1 start dev mongodb
#          .\manage.ps1 start dev monitoring
#          .\manage.ps1 start dev mssql
#          .\manage.ps1 start dev keycloak
#          .\manage.ps1 start dev seq
#          .\manage.ps1 start dev mailhog
#          .\manage.ps1 start dev all
#          .\manage.ps1 stop test all
#          .\manage.ps1 status prod all
#          .\manage.ps1 purge dev postgres

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("start", "stop", "restart", "logs", "status", "clean", "purge")]
    [string]$Action,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("dev", "test", "prod")]
    [string]$Environment,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("postgres", "redis", "rabbitmq", "elasticsearch", "mongodb", "monitoring", "mssql", "keycloak", "seq", "mailhog", "all")]
    [string]$Service
)

$ErrorActionPreference = "Stop"

# Color functions
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }
function Write-ErrorMessage { Write-Host $args -ForegroundColor Red }

# Service information
$services = @{
    "postgres" = @{
        "name" = "PostgreSQL"
        "path" = "postgres"
        "icon" = "[PG]"
    }
    "redis" = @{
        "name" = "Redis"
        "path" = "redis"
        "icon" = "[RD]"
    }
    "rabbitmq" = @{
        "name" = "RabbitMQ"
        "path" = "rabbitmq"
        "icon" = "[MQ]"
    }
    "elasticsearch" = @{
        "name" = "Elasticsearch"
        "path" = "elasticsearch"
        "icon" = "[ES]"
    }
    "mongodb" = @{
        "name" = "MongoDB"
        "path" = "mongodb"
        "icon" = "[DB]"
    }
    "monitoring" = @{
        "name" = "Monitoring"
        "path" = "monitoring"
        "icon" = "[MT]"
    }
    "mssql" = @{
        "name" = "MSSQL"
        "path" = "mssql"
        "icon" = "[MS]"
    }
    "keycloak" = @{
        "name" = "Keycloak"
        "path" = "keycloak"
        "icon" = "[KC]"
    }
    "seq" = @{
        "name" = "Seq"
        "path" = "seq"
        "icon" = "[SQ]"
    }
    "mailhog" = @{
        "name" = "MailHog"
        "path" = "mailhog"
        "icon" = "[MH]"
    }
}

# Environment information
$environments = @{
    "dev" = @{
        "path" = "environments/dev"
        "name" = "Development"
    }
    "test" = @{
        "path" = "environments/test"
        "name" = "Test"
    }
    "prod" = @{
        "path" = "environments/prod"
        "name" = "Production"
    }
}

function Start-Environment {
    param(
        [string]$env,
        [string]$svc
    )
    
    $envInfo = $environments[$env]
    $svcInfo = $services[$svc]
    $fullPath = "$($svcInfo.path)/$($envInfo.path)"
    $projectName = "$($svc)_$($env)"
    
    Write-Info "$($svcInfo.icon) $($svcInfo.name) - $($envInfo.name) starting..."
    
    if (-not (Test-Path "$fullPath/docker-compose.yml")) {
        Write-ErrorMessage "ERROR: $fullPath/docker-compose.yml not found!"
        return
    }
    
    Push-Location $fullPath
    docker-compose -p $projectName up -d --remove-orphans
    Pop-Location
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "SUCCESS: $($svcInfo.name) - $($envInfo.name) started!"
    } else {
        Write-ErrorMessage "ERROR: Failed to start $($svcInfo.name) - $($envInfo.name)!"
    }
}

function Stop-Environment {
    param(
        [string]$env,
        [string]$svc
    )
    
    $envInfo = $environments[$env]
    $svcInfo = $services[$svc]
    $fullPath = "$($svcInfo.path)/$($envInfo.path)"
    $projectName = "$($svc)_$($env)"
    
    Write-Info "$($svcInfo.icon) $($svcInfo.name) - $($envInfo.name) stopping..."
    
    if (-not (Test-Path "$fullPath/docker-compose.yml")) {
        Write-Warning "WARNING: $fullPath not found, skipping..."
        return
    }
    
    Push-Location $fullPath
    docker-compose -p $projectName down --remove-orphans
    Pop-Location
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "SUCCESS: $($svcInfo.name) - $($envInfo.name) stopped!"
    } else {
        Write-ErrorMessage "ERROR: Failed to stop $($svcInfo.name) - $($envInfo.name)!"
    }
}

function Restart-Environment {
    param(
        [string]$env,
        [string]$svc
    )
    
    Stop-Environment $env $svc
    Start-Sleep -Seconds 2
    Start-Environment $env $svc
}

function Show-Logs {
    param(
        [string]$env,
        [string]$svc
    )
    
    $envInfo = $environments[$env]
    $svcInfo = $services[$svc]
    $fullPath = "$($svcInfo.path)/$($envInfo.path)"
    $projectName = "$($svc)_$($env)"
    
    Write-Info "$($svcInfo.icon) $($svcInfo.name) - $($envInfo.name) logs..."
    
    if (-not (Test-Path "$fullPath/docker-compose.yml")) {
        Write-ErrorMessage "ERROR: $fullPath not found!"
        return
    }
    
    Push-Location $fullPath
    docker-compose -p $projectName logs -f
    Pop-Location
}

function Show-Status {
    param([string]$svc)
    
    Write-Info "Container Status:"
    Write-Host ""
    
    $servicesToCheck = if ($svc -eq "all") { @("postgres", "redis", "rabbitmq", "elasticsearch", "mongodb", "monitoring", "mssql", "keycloak", "seq", "mailhog") } else { @($svc) }
    
    foreach ($service in $servicesToCheck) {
        $svcInfo = $services[$service]
        Write-Host "=== $($svcInfo.icon) $($svcInfo.name) ===" -ForegroundColor Magenta
        
        foreach ($env in @("dev", "test", "prod")) {
            $envInfo = $environments[$env]
            $fullPath = "$($svcInfo.path)/$($envInfo.path)"
            
            Write-Host "  $($envInfo.name):" -ForegroundColor Yellow
            
            if (Test-Path "$fullPath/docker-compose.yml") {
                $projectName = "$($service)_$($env)"
                Push-Location $fullPath
                docker-compose -p $projectName ps
                Pop-Location
            } else {
                Write-Host "    (Not configured)" -ForegroundColor DarkGray
            }
        }
        Write-Host ""
    }
}

function Clean-Environment {
    param(
        [string]$env,
        [string]$svc
    )
    
    $envInfo = $environments[$env]
    $svcInfo = $services[$svc]
    $fullPath = "$($svcInfo.path)/$($envInfo.path)"
    $projectName = "$($svc)_$($env)"
    
    Write-Warning "WARNING: ALL DATA in $($svcInfo.name) - $($envInfo.name) will be deleted!"
    $confirm = Read-Host "Do you want to continue? (Y/N)"
    
    if ($confirm -match '^[Yy](es)?$') {
        Write-Info "Cleaning $($svcInfo.name) - $($envInfo.name)..."
        
        if (Test-Path "$fullPath/docker-compose.yml") {
            Push-Location $fullPath
            docker-compose -p $projectName down -v --remove-orphans
            Pop-Location
            
            Write-Success "SUCCESS: $($svcInfo.name) - $($envInfo.name) cleaned!"
        } else {
            Write-Warning "WARNING: $fullPath not found!"
        }
    } else {
        Write-Info "Operation cancelled."
    }
}

function Purge-Environment {
    param(
        [string]$env,
        [string]$svc
    )

    $envInfo = $environments[$env]
    $svcInfo = $services[$svc]
    $fullPath = "$($svcInfo.path)/$($envInfo.path)"
    $projectName = "$($svc)_$($env)"

    Write-ErrorMessage "DANGER: $($svcInfo.name) - $($envInfo.name) icin TUM VERILER, VOLUME'LER ve IMAGE'LAR silinecek!"
    $confirm = Read-Host "Devam etmek istiyor musunuz? (Y/N)"

    if ($confirm -match '^[Yy](es)?$') {
        Write-Info "Purging $($svcInfo.name) - $($envInfo.name)..."

        if (Test-Path "$fullPath/docker-compose.yml") {
            Push-Location $fullPath
            docker-compose -p $projectName down -v --rmi all --remove-orphans
            Pop-Location

            Write-Success "SUCCESS: $($svcInfo.name) - $($envInfo.name) purged (containers + volumes + images)!"
        } else {
            Write-Warning "WARNING: $fullPath not found!"
        }
    } else {
        Write-Info "Operation cancelled."
    }
}

# Main logic
Write-Info "======================================="
Write-Info "  Multi-Service Docker Manager"
Write-Info "  PG + Redis + RabbitMQ + ES + Mongo + Mon + MSSQL + KC + Seq + MH"
Write-Info "======================================="
Write-Host ""

# Determine service list
$servicesToProcess = if ($Service -eq "all") { @("postgres", "redis", "rabbitmq", "elasticsearch", "mongodb", "monitoring", "mssql", "keycloak", "seq", "mailhog") } else { @($Service) }

# Execute operations
foreach ($svc in $servicesToProcess) {
    switch ($Action) {
        "start"   { Start-Environment $Environment $svc }
        "stop"    { Stop-Environment $Environment $svc }
        "restart" { Restart-Environment $Environment $svc }
        "logs"    { Show-Logs $Environment $svc }
        "clean"   { Clean-Environment $Environment $svc }
        "purge"   { Purge-Environment $Environment $svc }
    }
    
    if ($servicesToProcess.Count -gt 1) {
        Write-Host ""
    }
}

# Status special handling
if ($Action -eq "status") {
    Show-Status $Service
}

Write-Host ""
Write-Info "======================================="
