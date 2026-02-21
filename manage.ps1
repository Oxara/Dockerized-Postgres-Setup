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
#          .\manage.ps1 pull dev all
#          .\manage.ps1 pull dev postgres
#          .\manage.ps1 status prod all
#          .\manage.ps1 purge dev postgres

param(
    [Parameter(Position=0)]
    [ArgumentCompleter({ "start","stop","restart","logs","status","clean","purge","pull" })]
    [string]$Action = "",

    [Parameter(Position=1)]
    [ArgumentCompleter({ "dev","test","prod" })]
    [string]$Environment = "",

    [Parameter(Position=2)]
    [ArgumentCompleter({ "postgres","redis","rabbitmq","elasticsearch","mongodb","monitoring","mssql","keycloak","seq","mailhog","all" })]
    [string]$Service = ""
)

$ErrorActionPreference = "Stop"

# Color functions
function Write-Success      { Write-Host $args -ForegroundColor Green  }
function Write-Info         { Write-Host $args -ForegroundColor Cyan   }
function Write-Warning      { Write-Host $args -ForegroundColor Yellow }
function Write-ErrorMessage { Write-Host $args -ForegroundColor Red    }

# ── Argument validation ────────────────────────────────────────────────────────
$validActions  = @("start","stop","restart","logs","status","clean","purge","pull")
$validEnvs     = @("dev","test","prod")
$validServices = @("postgres","redis","rabbitmq","elasticsearch","mongodb","monitoring","mssql","keycloak","seq","mailhog","all")

$errors = @()

if ($Action -eq "") {
    $errors += "  Action is required.`n  Valid values: $($validActions -join ', ')"
} elseif ($Action -notin $validActions) {
    $prefix  = $Action.Substring(0, [Math]::Min(2, $Action.Length))
    $closest = $validActions | Where-Object { $_ -like "${prefix}*" } | Select-Object -First 1
    $hint    = if ($closest) { " Did you mean '$closest'?" } else { "" }
    $errors += "  Unknown action '$Action'.$hint`n  Valid values: $($validActions -join ', ')"
}

if ($Environment -eq "") {
    $errors += "  Environment is required.`n  Valid values: $($validEnvs -join ', ')"
} elseif ($Environment -notin $validEnvs) {
    $errors += "  Unknown environment '$Environment'.`n  Valid values: $($validEnvs -join ', ')"
}

if ($Service -eq "") {
    $errors += "  Service is required.`n  Valid values: $($validServices -join ', ')"
} elseif ($Service -notin $validServices) {
    $prefix  = $Service.Substring(0, [Math]::Min(2, $Service.Length))
    $closest = $validServices | Where-Object { $_ -like "${prefix}*" } | Select-Object -First 1
    $hint    = if ($closest) { " Did you mean '$closest'?" } else { "" }
    $errors += "  Unknown service '$Service'.$hint`n  Valid values: $($validServices -join ', ')"
}

if ($errors.Count -gt 0) {
    Write-Host ""
    Write-Host "  ERROR: Invalid argument(s):" -ForegroundColor Red
    foreach ($e in $errors) { Write-Host $e -ForegroundColor Yellow }
    Write-Host ""
    Write-Host "  Usage:   .\manage.ps1 <action> <environment> <service>" -ForegroundColor DarkGray
    Write-Host "  Example: .\manage.ps1 start dev postgres" -ForegroundColor DarkGray
    Write-Host ""
    exit 1
}
# ──────────────────────────────────────────────────────────────────────────────

# Checks whether Docker daemon is reachable; if not, offers to start Docker Desktop
function Assert-DockerRunning {
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    docker info 2>&1 | Out-Null
    $dockerExitCode = $LASTEXITCODE
    $ErrorActionPreference = $prev
    if ($dockerExitCode -ne 0) {
        Write-Warning "Docker Desktop is not running!"
        $answer = Read-Host "Start Docker Desktop now? (Y/N)"
        if ($answer -notmatch '^[Yy](es)?$') {
            Write-Info "Operation cancelled. Please start Docker Desktop first."
            exit 0
        }

        Write-Info "Starting Docker Desktop..."
        $dockerExe = "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
        if (-not (Test-Path $dockerExe)) {
            Write-ErrorMessage "Docker Desktop executable not found at: $dockerExe"
            exit 1
        }
        Start-Process $dockerExe

        Write-Info "Waiting for Docker to become ready (max 120 seconds)..."
        $timeout = 120
        $elapsed  = 0
        do {
            Start-Sleep -Seconds 3
            $elapsed += 3
            docker info 2>&1 | Out-Null
        } while ($LASTEXITCODE -ne 0 -and $elapsed -lt $timeout)

        if ($LASTEXITCODE -eq 0) {
            Write-Success "Docker Desktop is ready!"
            Write-Host ""
        } else {
            Write-ErrorMessage "Timeout: Docker Desktop did not start within $timeout seconds. Please start it manually."
            exit 1
        }
    }
}

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
        [string]$svc,
        [switch]$Quiet
    )
    
    $envInfo = $environments[$env]
    $svcInfo = $services[$svc]
    $fullPath = "$($svcInfo.path)/$($envInfo.path)"
    $projectName = "$($svc)_$($env)"

    if (-not (Test-Path "$fullPath/docker-compose.yml")) {
        if (-not $Quiet) { Write-ErrorMessage "ERROR: $fullPath/docker-compose.yml not found!" }
        return @{ Icon = $svcInfo.icon; Name = $svcInfo.name; Env = $envInfo.name; Status = "NotFound"; StatusText = "! Not found" }
    }

    # Check if all containers are already running for this project
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $running = @(docker ps --filter "label=com.docker.compose.project=$projectName" -q 2>&1) |
                   Where-Object { $_ -match '^[a-f0-9]' }
    $ErrorActionPreference = $prev
    if ($running) {
        if (-not $Quiet) { Write-Info "$($svcInfo.icon) $($svcInfo.name) - $($envInfo.name) is already running." }
        return @{ Icon = $svcInfo.icon; Name = $svcInfo.name; Env = $envInfo.name; Status = "AlreadyRunning"; StatusText = "> Already running" }
    }

    # Fail fast if any required image is missing locally
    $prev = $ErrorActionPreference; $ErrorActionPreference = "Continue"
    $composeContent = Get-Content "$fullPath/docker-compose.yml" -Raw
    $imageNames = [regex]::Matches($composeContent, '(?m)^\s*image:\s*(.+)') |
                      ForEach-Object { $_.Groups[1].Value.Trim() -replace '\s*#.*$', '' }
    $missingImages = @($imageNames | Where-Object {
        docker image inspect $_ 2>&1 | Out-Null
        $LASTEXITCODE -ne 0
    })
    $ErrorActionPreference = $prev
    if ($missingImages.Count -gt 0) {
        $missing = $missingImages -join ", "
        if (-not $Quiet) {
            Write-Warning "  Image(s) not found locally: $missing"
            Write-Info    "  Run: .\manage.ps1 pull $env $svc"
        }
        return @{ Icon = $svcInfo.icon; Name = $svcInfo.name; Env = $envInfo.name; Status = "MissingImage"; StatusText = "? Image missing" }
    }

    if (-not $Quiet) { Write-Info "$($svcInfo.icon) $($svcInfo.name) - $($envInfo.name) starting..." }
    
    Push-Location $fullPath
    if ($Quiet) {
        $prev = $ErrorActionPreference; $ErrorActionPreference = "Continue"
        docker-compose -p $projectName up -d --remove-orphans 2>&1 | Out-Null
        $ErrorActionPreference = $prev
    } else {
        docker-compose -p $projectName up -d --remove-orphans
    }
    Pop-Location
    
    if ($LASTEXITCODE -eq 0) {
        if (-not $Quiet) { Write-Success "SUCCESS: $($svcInfo.name) - $($envInfo.name) started!" }
        return @{ Icon = $svcInfo.icon; Name = $svcInfo.name; Env = $envInfo.name; Status = "Started"; StatusText = "+ Started" }
    } else {
        if (-not $Quiet) { Write-ErrorMessage "ERROR: Failed to start $($svcInfo.name) - $($envInfo.name)!" }
        return @{ Icon = $svcInfo.icon; Name = $svcInfo.name; Env = $envInfo.name; Status = "Failed"; StatusText = "x Failed" }
    }
}

function Stop-Environment {
    param(
        [string]$env,
        [string]$svc,
        [switch]$Quiet
    )
    
    $envInfo = $environments[$env]
    $svcInfo = $services[$svc]
    $fullPath = "$($svcInfo.path)/$($envInfo.path)"
    $projectName = "$($svc)_$($env)"

    if (-not (Test-Path "$fullPath/docker-compose.yml")) {
        if (-not $Quiet) { Write-Warning "WARNING: $fullPath not found, skipping..." }
        return @{ Icon = $svcInfo.icon; Name = $svcInfo.name; Env = $envInfo.name; Status = "NotFound"; StatusText = "! Not found" }
    }

    # Check if any containers exist for this project before attempting stop
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $existing = @(docker ps -a --filter "label=com.docker.compose.project=$projectName" -q 2>&1) |
                    Where-Object { $_ -match '^[a-f0-9]' }
    $ErrorActionPreference = $prev
    if (-not $existing) {
        if (-not $Quiet) { Write-Info "$($svcInfo.icon) $($svcInfo.name) - $($envInfo.name) is already stopped." }
        return @{ Icon = $svcInfo.icon; Name = $svcInfo.name; Env = $envInfo.name; Status = "AlreadyStopped"; StatusText = "> Already stopped" }
    }
    
    if (-not $Quiet) { Write-Info "$($svcInfo.icon) $($svcInfo.name) - $($envInfo.name) stopping..." }
    
    Push-Location $fullPath
    if ($Quiet) {
        $prev = $ErrorActionPreference; $ErrorActionPreference = "Continue"
        docker-compose -p $projectName down --remove-orphans 2>&1 | Out-Null
        $ErrorActionPreference = $prev
    } else {
        docker-compose -p $projectName down --remove-orphans
    }
    Pop-Location
    
    if ($LASTEXITCODE -eq 0) {
        if (-not $Quiet) { Write-Success "SUCCESS: $($svcInfo.name) - $($envInfo.name) stopped!" }
        return @{ Icon = $svcInfo.icon; Name = $svcInfo.name; Env = $envInfo.name; Status = "Stopped"; StatusText = "- Stopped" }
    } else {
        if (-not $Quiet) { Write-ErrorMessage "ERROR: Failed to stop $($svcInfo.name) - $($envInfo.name)!" }
        return @{ Icon = $svcInfo.icon; Name = $svcInfo.name; Env = $envInfo.name; Status = "Failed"; StatusText = "x Failed" }
    }
}

function Restart-Environment {
    param(
        [string]$env,
        [string]$svc,
        [switch]$Quiet
    )
    
    $svcInfo = $services[$svc]
    $envInfo = $environments[$env]

    $null = Stop-Environment $env $svc -Quiet:$Quiet
    Start-Sleep -Seconds 2
    $startResult = Start-Environment $env $svc -Quiet:$Quiet

    $failed    = $startResult.Status -in @("Failed", "MissingImage")
    $status    = if ($failed) { $startResult.Status    } else { "Restarted" }
    $statusTxt = if ($failed) { $startResult.StatusText } else { "~ Restarted" }
    return @{ Icon = $svcInfo.icon; Name = $svcInfo.name; Env = $envInfo.name; Status = $status; StatusText = $statusTxt }
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

function Clear-Environment {
    param(
        [string]$env,
        [string]$svc,
        [switch]$Quiet
    )
    
    $envInfo = $environments[$env]
    $svcInfo = $services[$svc]
    $fullPath = "$($svcInfo.path)/$($envInfo.path)"
    $projectName = "$($svc)_$($env)"
    
    Write-Warning "WARNING: ALL DATA in $($svcInfo.name) - $($envInfo.name) will be deleted!"
    $confirm = Read-Host "Do you want to continue? (Y/N)"
    
    if ($confirm -match '^[Yy](es)?$') {
        if (-not $Quiet) { Write-Info "Cleaning $($svcInfo.name) - $($envInfo.name)..." }
        
        if (Test-Path "$fullPath/docker-compose.yml") {
            Push-Location $fullPath
            if ($Quiet) {
                $prev = $ErrorActionPreference; $ErrorActionPreference = "Continue"
                docker-compose -p $projectName down -v --remove-orphans 2>&1 | Out-Null
                $ErrorActionPreference = $prev
            } else {
                docker-compose -p $projectName down -v --remove-orphans
            }
            Pop-Location
            
            if ($LASTEXITCODE -eq 0) {
                if (-not $Quiet) { Write-Success "SUCCESS: $($svcInfo.name) - $($envInfo.name) cleaned!" }
                return @{ Icon = $svcInfo.icon; Name = $svcInfo.name; Env = $envInfo.name; Status = "Cleaned"; StatusText = "+ Cleaned" }
            } else {
                if (-not $Quiet) { Write-ErrorMessage "ERROR: Failed to clean $($svcInfo.name) - $($envInfo.name)!" }
                return @{ Icon = $svcInfo.icon; Name = $svcInfo.name; Env = $envInfo.name; Status = "Failed"; StatusText = "x Failed" }
            }
        } else {
            Write-Warning "WARNING: $fullPath not found!"
            return @{ Icon = $svcInfo.icon; Name = $svcInfo.name; Env = $envInfo.name; Status = "NotFound"; StatusText = "! Not found" }
        }
    } else {
        if (-not $Quiet) { Write-Info "Operation cancelled." }
        return @{ Icon = $svcInfo.icon; Name = $svcInfo.name; Env = $envInfo.name; Status = "Cancelled"; StatusText = "/ Cancelled" }
    }
}

function Remove-Environment {
    param(
        [string]$env,
        [string]$svc,
        [switch]$Quiet
    )

    $envInfo = $environments[$env]
    $svcInfo = $services[$svc]
    $fullPath = "$($svcInfo.path)/$($envInfo.path)"
    $projectName = "$($svc)_$($env)"

    Write-ErrorMessage "DANGER: $($svcInfo.name) - $($envInfo.name) icin TUM VERILER, VOLUME'LER ve IMAGE'LAR silinecek!"
    $confirm = Read-Host "Devam etmek istiyor musunuz? (Y/N)"

    if ($confirm -match '^[Yy](es)?$') {
        if (-not $Quiet) { Write-Info "Purging $($svcInfo.name) - $($envInfo.name)..." }

        if (Test-Path "$fullPath/docker-compose.yml") {
            # Parse image names from compose file before containers are removed
            $composeContent = Get-Content "$fullPath/docker-compose.yml" -Raw
            $imageNames = [regex]::Matches($composeContent, '(?m)^\s*image:\s*(.+)') |
                              ForEach-Object { $_.Groups[1].Value.Trim() -replace '\s*#.*$', '' }

            # Step 1: bring down containers + volumes
            Push-Location $fullPath
            $prev = $ErrorActionPreference; $ErrorActionPreference = "Continue"
            docker-compose -p $projectName down -v --remove-orphans 2>&1 | Out-Null
            $downExit = $LASTEXITCODE
            $ErrorActionPreference = $prev
            Pop-Location

            if ($downExit -ne 0) {
                if (-not $Quiet) { Write-ErrorMessage "ERROR: Failed to purge $($svcInfo.name) - $($envInfo.name)!" }
                return @{ Icon = $svcInfo.icon; Name = $svcInfo.name; Env = $envInfo.name; Status = "Failed"; StatusText = "x Failed" }
            }

            # Step 2: explicitly remove images parsed from the compose file
            if ($imageNames.Count -gt 0) {
                $prev = $ErrorActionPreference; $ErrorActionPreference = "Continue"
                foreach ($img in $imageNames) {
                    docker image rm -f $img 2>&1 | Out-Null
                }
                $ErrorActionPreference = $prev
                if (-not $Quiet) { Write-Info "  Removed images: $($imageNames -join ', ')" }
            }

            if (-not $Quiet) { Write-Success "SUCCESS: $($svcInfo.name) - $($envInfo.name) purged (containers + volumes + images)!" }
            return @{ Icon = $svcInfo.icon; Name = $svcInfo.name; Env = $envInfo.name; Status = "Purged"; StatusText = "+ Purged" }
        } else {
            Write-Warning "WARNING: $fullPath not found!"
            return @{ Icon = $svcInfo.icon; Name = $svcInfo.name; Env = $envInfo.name; Status = "NotFound"; StatusText = "! Not found" }
        }
    } else {
        if (-not $Quiet) { Write-Info "Operation cancelled." }
        return @{ Icon = $svcInfo.icon; Name = $svcInfo.name; Env = $envInfo.name; Status = "Cancelled"; StatusText = "/ Cancelled" }
    }
}

function Initialize-Environment {
    param(
        [string]$env,
        [string]$svc,
        [switch]$Quiet
    )

    $envInfo = $environments[$env]
    $svcInfo = $services[$svc]
    $fullPath = "$($svcInfo.path)/$($envInfo.path)"
    $projectName = "$($svc)_$($env)"

    if (-not (Test-Path "$fullPath/docker-compose.yml")) {
        if (-not $Quiet) { Write-ErrorMessage "ERROR: $fullPath/docker-compose.yml not found!" }
        return @{ Icon = $svcInfo.icon; Name = $svcInfo.name; Env = $envInfo.name; Status = "NotFound"; StatusText = "! Not found" }
    }

    # Skip pull if all images are already present locally
    $composeContent = Get-Content "$fullPath/docker-compose.yml" -Raw
    $imageNames = [regex]::Matches($composeContent, '(?m)^\s*image:\s*(.+)') |
                      ForEach-Object { $_.Groups[1].Value.Trim() -replace '\s*#.*$', '' }
    $prev = $ErrorActionPreference; $ErrorActionPreference = "Continue"
    $allPresent = ($imageNames.Count -gt 0) -and ($imageNames | Where-Object {
        docker image inspect $_ 2>&1 | Out-Null; $LASTEXITCODE -ne 0
    }).Count -eq 0
    $ErrorActionPreference = $prev
    if ($allPresent) {
        if (-not $Quiet) { Write-Info "$($svcInfo.icon) $($svcInfo.name) - $($envInfo.name) images already up-to-date, skipping pull." }
        return @{ Icon = $svcInfo.icon; Name = $svcInfo.name; Env = $envInfo.name; Status = "AlreadyPulled"; StatusText = "= Already exists" }
    }

    if (-not $Quiet) { Write-Info "$($svcInfo.icon) $($svcInfo.name) - $($envInfo.name) pulling images..." }

    Push-Location $fullPath
    if ($Quiet) {
        $prev = $ErrorActionPreference; $ErrorActionPreference = "Continue"
        docker-compose -p $projectName pull 2>&1 | Out-Null
        $ErrorActionPreference = $prev
    } else {
        docker-compose -p $projectName pull
    }
    Pop-Location

    if ($LASTEXITCODE -eq 0) {
        if (-not $Quiet) { Write-Success "SUCCESS: $($svcInfo.name) - $($envInfo.name) images pulled!" }
        return @{ Icon = $svcInfo.icon; Name = $svcInfo.name; Env = $envInfo.name; Status = "Pulled"; StatusText = "+ Pulled" }
    } else {
        if (-not $Quiet) { Write-ErrorMessage "ERROR: Failed to pull $($svcInfo.name) - $($envInfo.name)!" }
        return @{ Icon = $svcInfo.icon; Name = $svcInfo.name; Env = $envInfo.name; Status = "Failed"; StatusText = "x Failed" }
    }
}

function Show-ResultTable {
    param([array]$Results)

    $nameWidth   = [Math]::Max(($Results | ForEach-Object { "$($_.Icon) $($_.Name)".Length } | Measure-Object -Maximum).Maximum, 15)
    $envWidth    = [Math]::Max(($Results | ForEach-Object { $_.Env.Length }                  | Measure-Object -Maximum).Maximum, 20)
    $statusWidth = [Math]::Max(($Results | ForEach-Object { $_.StatusText.Length }            | Measure-Object -Maximum).Maximum, 20)

    $hr = "+-" + ("-" * $nameWidth)   + "-+-" +
                  ("-" * $envWidth)    + "-+-" +
                  ("-" * $statusWidth) + "-+"

    Write-Host ""
    Write-Host $hr -ForegroundColor DarkGray
    Write-Host ("| " + "Service".PadRight($nameWidth)     + " | " +
                       "Environment".PadRight($envWidth)  + " | " +
                       "Status".PadRight($statusWidth)    + " |") -ForegroundColor White
    Write-Host $hr -ForegroundColor DarkGray

    foreach ($r in $Results) {
        $color = switch ($r.Status) {
            { $_ -in @("Started","Stopped","Restarted","Cleaned","Purged","Pulled") } { "Green"  }
            { $_ -in @("AlreadyRunning","AlreadyStopped","AlreadyPulled") }   { "Cyan"   }
            "Cancelled"   { "Yellow" }
            "NotFound"    { "Red"    }
            "MissingImage" { "Red"    }
            "Failed"      { "Red"    }
            default        { "Yellow" }
        }

        Write-Host ("| " + "$($r.Icon) $($r.Name)".PadRight($nameWidth) + " | " +
                          $r.Env.PadRight($envWidth)                    + " | " +
                          $r.StatusText.PadRight($statusWidth)          + " |") -ForegroundColor $color
        Write-Host $hr -ForegroundColor DarkGray
    }
}

# Script block executed inside each parallel job (start / stop / restart)
$parallelActionBlock = {
    param([string]$action, [string]$env, [string]$svc,
          [hashtable]$svcInfo, [hashtable]$envInfo, [string]$projectRoot)

    Set-Location $projectRoot
    $ErrorActionPreference = "Continue"
    $fullPath    = "$($svcInfo.path)/$($envInfo.path)"
    $projectName = "${svc}_${env}"

    function MkResult([string]$status, [string]$text) {
        return @{ Icon=$svcInfo.icon; Name=$svcInfo.name; Env=$envInfo.name; Status=$status; StatusText=$text }
    }

    if (-not (Test-Path "$fullPath/docker-compose.yml")) {
        return MkResult "NotFound" "! Not found"
    }

    switch ($action) {
        "start" {
            $running = @(docker ps --filter "label=com.docker.compose.project=$projectName" -q 2>&1) |
                           Where-Object { $_ -match '^[a-f0-9]' }
            if ($running) { return MkResult "AlreadyRunning" "> Already running" }
            # Fail fast if any required image is missing
            $composeContent = Get-Content "$fullPath/docker-compose.yml" -Raw
            $imageNames = [regex]::Matches($composeContent, '(?m)^\s*image:\s*(.+)') |
                              ForEach-Object { $_.Groups[1].Value.Trim() -replace '\s*#.*$', '' }
            $missingImages = @($imageNames | Where-Object {
                docker image inspect $_ 2>&1 | Out-Null
                $LASTEXITCODE -ne 0
            })
            if ($missingImages.Count -gt 0) { return MkResult "MissingImage" "? Image missing" }
            Push-Location $fullPath
            docker-compose -p $projectName up -d --remove-orphans 2>&1 | Out-Null
            $exit = $LASTEXITCODE
            Pop-Location
            if ($exit -eq 0) { return MkResult "Started"   "+ Started" } else { return MkResult "Failed" "x Failed" }
        }
        "stop" {
            $existing = @(docker ps -a --filter "label=com.docker.compose.project=$projectName" -q 2>&1) |
                            Where-Object { $_ -match '^[a-f0-9]' }
            if (-not $existing) { return MkResult "AlreadyStopped" "> Already stopped" }
            Push-Location $fullPath
            docker-compose -p $projectName down --remove-orphans 2>&1 | Out-Null
            $exit = $LASTEXITCODE
            Pop-Location
            if ($exit -eq 0) { return MkResult "Stopped"  "- Stopped" } else { return MkResult "Failed" "x Failed" }
        }
        "restart" {
            $existing = @(docker ps -a --filter "label=com.docker.compose.project=$projectName" -q 2>&1) |
                            Where-Object { $_ -match '^[a-f0-9]' }
            if ($existing) {
                Push-Location $fullPath
                docker-compose -p $projectName down --remove-orphans 2>&1 | Out-Null
                Pop-Location
            }
            # Fail fast if any required image is missing
            $composeContent = Get-Content "$fullPath/docker-compose.yml" -Raw
            $imageNames = [regex]::Matches($composeContent, '(?m)^\s*image:\s*(.+)') |
                              ForEach-Object { $_.Groups[1].Value.Trim() -replace '\s*#.*$', '' }
            $missingImages = @($imageNames | Where-Object {
                docker image inspect $_ 2>&1 | Out-Null
                $LASTEXITCODE -ne 0
            })
            if ($missingImages.Count -gt 0) { return MkResult "MissingImage" "? Image missing" }
            Start-Sleep -Seconds 2
            Push-Location $fullPath
            docker-compose -p $projectName up -d --remove-orphans 2>&1 | Out-Null
            $exit = $LASTEXITCODE
            Pop-Location
            if ($exit -eq 0) { return MkResult "Restarted" "~ Restarted" } else { return MkResult "Failed" "x Failed" }
        }
        "pull" {
            # Skip pull if all images are already present locally
            $composeContent = Get-Content "$fullPath/docker-compose.yml" -Raw
            $imageNames = [regex]::Matches($composeContent, '(?m)^\s*image:\s*(.+)') |
                              ForEach-Object { $_.Groups[1].Value.Trim() -replace '\s*#.*$', '' }
            $allPresent = ($imageNames.Count -gt 0) -and ($imageNames | Where-Object {
                docker image inspect $_ 2>&1 | Out-Null; $LASTEXITCODE -ne 0
            }).Count -eq 0
            if ($allPresent) { return MkResult "AlreadyPulled" "= Already exists" }
            Push-Location $fullPath
            docker-compose -p $projectName pull 2>&1 | Out-Null
            $exit = $LASTEXITCODE
            Pop-Location
            if ($exit -eq 0) { return MkResult "Pulled" "+ Pulled" } else { return MkResult "Failed" "x Failed" }
        }
    }
}

# Main logic
Write-Info "======================================="
Write-Info "  Multi-Service Docker Manager"
Write-Info "  PG + Redis + RabbitMQ + ES + Mongo + Mon + MSSQL + KC + Seq + MH"
Write-Info "======================================="
Write-Host ""

Assert-DockerRunning

# Determine service list
$servicesToProcess = if ($Service -eq "all") { @("postgres", "redis", "rabbitmq", "elasticsearch", "mongodb", "monitoring", "mssql", "keycloak", "seq", "mailhog") } else { @($Service) }

# Execute operations
$isAll        = $servicesToProcess.Count -gt 1
$tableResults = @()

if ($isAll -and $Action -in @("start", "stop", "restart", "pull")) {
    # ── PARALLEL ─────────────────────────────────────────────────────────────
    $projectRoot = $PWD.Path
    $pendingJobs = [System.Collections.ArrayList]::new()

    $ESC          = [char]27
    $iconOk       = [char]0x2713   # ✓
    $iconFail     = [char]0x2717   # ✗
    $iconWait     = [char]0x25CB   # ○
    $iconWorking  = [char]0x21BB   # ↻
    $pullThresholdSec = 8          # after this many seconds, switch ○ → ↻

    # Print all services as "pending" and launch jobs
    $svcIndex  = @{}
    $startTimes = @{}
    for ($i = 0; $i -lt $servicesToProcess.Count; $i++) {
        $svc = $servicesToProcess[$i]
        $svcIndex[$svc]   = $i
        $startTimes[$svc] = [datetime]::Now
        Write-Host "  $iconWait $($services[$svc].icon) $($services[$svc].name)" -ForegroundColor DarkGray
        $job = Start-Job -ScriptBlock $parallelActionBlock `
                         -ArgumentList $Action, $Environment, $svc,
                                       $services[$svc], $environments[$Environment],
                                       $projectRoot
        [void]$pendingJobs.Add(@{ Job = $job; Svc = $svc })
    }

    # Blank separator line — accounted for in linesUp as +1
    $N = $pendingJobs.Count
    Write-Host ""

    $doneSet     = @{}
    $tookMap     = @{}   # elapsed seconds per service
    $workingSet  = @{}   # services that have crossed the pull threshold (shown as ↻)
    $spinFrames  = @("|", "/", "-", "\")
    $spinIdx     = 0

    while ($doneSet.Count -lt $pendingJobs.Count) {
        foreach ($item in $pendingJobs) {
            $key = $item.Svc
            if ($doneSet.ContainsKey($key)) { continue }

            $elapsed = ([datetime]::Now - $startTimes[$key]).TotalSeconds

            # ○ → ↻ transition when threshold is crossed
            if (-not $workingSet.ContainsKey($key) -and $elapsed -ge $pullThresholdSec) {
                $workingSet[$key] = $true
                $svcInfo = $services[$key]
                $linesUp = ($N - $svcIndex[$key]) + 1
                Write-Host "$ESC[${linesUp}A$ESC[2K$ESC[1G" -NoNewline
                Write-Host "  $iconWorking $($svcInfo.icon) $($svcInfo.name)" -ForegroundColor Yellow -NoNewline
                Write-Host "$ESC[${linesUp}B$ESC[1G" -NoNewline
            }

            if ($item.Job.State -in @("Completed", "Failed", "Stopped")) {
                $raw = Receive-Job $item.Job
                Remove-Job $item.Job -Force
                $doneSet[$key] = $raw

                $status  = if ($raw) { [string]$raw.Status } else { "Failed" }
                $isOk    = $status -notin @("Failed", "NotFound", "MissingImage")
                $icon    = if ($isOk) { $iconOk } else { $iconFail }
                $color   = if ($isOk) { "Green" } else { "Red" }
                $svcInfo = $services[$key]
                $took    = [int]([datetime]::Now - $startTimes[$key]).TotalSeconds
                $tookStr = if ($took -ge 1) { " ($($took)s)" } else { "" }
                $tookMap[$key] = $took

                $linesUp = ($N - $svcIndex[$key]) + 1
                Write-Host "$ESC[${linesUp}A$ESC[2K$ESC[1G" -NoNewline
                Write-Host "  $icon $($svcInfo.icon) $($svcInfo.name)$tookStr" -ForegroundColor $color -NoNewline
                Write-Host "$ESC[${linesUp}B$ESC[1G" -NoNewline
            }
        }

        $remaining = $pendingJobs.Count - $doneSet.Count
        if ($remaining -gt 0) {
            $spin = $spinFrames[$spinIdx % $spinFrames.Count]
            $spinIdx++

            # Build compact "still running" list with elapsed times
            $runningParts = $pendingJobs |
                Where-Object { -not $doneSet.ContainsKey($_.Svc) } |
                ForEach-Object {
                    $sec = [int]([datetime]::Now - $startTimes[$_.Svc]).TotalSeconds
                    "$($services[$_.Svc].icon) $($sec)s"
                }
            $runningStr = $runningParts -join "  "

            Write-Host "`r  $spin  $($doneSet.Count)/$N done  |  $runningStr   " `
                        -ForegroundColor DarkGray -NoNewline
            Start-Sleep -Milliseconds 400
        }
    }
    # Clear spinner line, then move cursor back up to overwrite the live list with the table
    Write-Host "`r$ESC[2K" -NoNewline
    Write-Host ""
    Write-Host "$ESC[$($N + 3)A" -NoNewline

    # Collect results in original service order (append timing to status text)
    foreach ($item in $pendingJobs) {
        $raw = $doneSet[$item.Svc]
        if ($raw) {
            $took    = $tookMap[$item.Svc]
            $tookStr = if ($took -ge 1) { " ($($took)s)" } else { "" }
            $result = @{
                Icon       = [string]$raw.Icon
                Name       = [string]$raw.Name
                Env        = [string]$raw.Env
                Status     = [string]$raw.Status
                StatusText = "$([string]$raw.StatusText)$tookStr"
            }
            $tableResults += $result
        }
    }

    Show-ResultTable $tableResults

} else {
    # ── SEQUENTIAL (clean / purge / logs / status, or single service) ─────────
    foreach ($svc in $servicesToProcess) {
        if ($isAll -and $Action -notin @("logs", "status")) {
            Write-Host "  >> $($services[$svc].icon) $($services[$svc].name)..." -ForegroundColor DarkGray
        }

        $result = switch ($Action) {
            "start"   { Start-Environment   $Environment $svc -Quiet:$isAll }
            "stop"    { Stop-Environment    $Environment $svc -Quiet:$isAll }
            "restart" { Restart-Environment $Environment $svc -Quiet:$isAll }
            "logs"    { Show-Logs           $Environment $svc }
            "clean"   { Clear-Environment   $Environment $svc -Quiet:$isAll }
            "purge"   { Remove-Environment  $Environment $svc -Quiet:$isAll }
            "pull"    { Initialize-Environment $Environment $svc -Quiet:$isAll }
        }

        if ($isAll -and $result -and $Action -notin @("logs", "status")) {
            $tableResults += $result
        } elseif (-not $isAll) {
            Write-Host ""
        }
    }

    if ($tableResults.Count -gt 0) {
        Show-ResultTable $tableResults
    }
}

# Status special handling
if ($Action -eq "status") {
    Show-Status $Service
}

Write-Host ""
Write-Info "======================================="
