# PostgreSQL Docker Environment Yönetim Scripti
# Kullanım: .\manage.ps1 [komut] [ortam]
# Örnek: .\manage.ps1 start dev
#        .\manage.ps1 start all
#        .\manage.ps1 stop test

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("start", "stop", "restart", "logs", "status", "clean")]
    [string]$Action,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("dev", "test", "prod", "all")]
    [string]$Environment
)

$ErrorActionPreference = "Stop"

# Renk fonksiyonları
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }
function Write-Error { Write-Host $args -ForegroundColor Red }

# Ortam bilgileri
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
    param([string]$env)
    
    $envInfo = $environments[$env]
    $envPath = $envInfo.path
    
    Write-Info "🚀 $($envInfo.name) ortamı başlatılıyor..."
    
    if (-not (Test-Path "$envPath/docker-compose.yml")) {
        Write-Error "❌ $envPath/docker-compose.yml dosyası bulunamadı!"
        exit 1
    }
    
    Push-Location $envPath
    docker-compose up -d
    Pop-Location
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "✅ $($envInfo.name) ortamı başarıyla başlatıldı!"
    } else {
        Write-Error "❌ $($envInfo.name) ortamı başlatılırken hata oluştu!"
    }
}

function Stop-Environment {
    param([string]$env)
    
    $envInfo = $environments[$env]
    $envPath = $envInfo.path
    
    Write-Info "🛑 $($envInfo.name) ortamı durduruluyor..."
    
    Push-Location $envPath
    docker-compose down
    Pop-Location
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "✅ $($envInfo.name) ortamı başarıyla durduruldu!"
    } else {
        Write-Error "❌ $($envInfo.name) ortamı durdurulurken hata oluştu!"
    }
}

function Restart-Environment {
    param([string]$env)
    
    Stop-Environment $env
    Start-Sleep -Seconds 2
    Start-Environment $env
}

function Show-Logs {
    param([string]$env)
    
    $envInfo = $environments[$env]
    $envPath = $envInfo.path
    
    Write-Info "📋 $($envInfo.name) ortamı logları gösteriliyor..."
    
    Push-Location $envPath
    docker-compose logs -f
    Pop-Location
}

function Show-Status {
    Write-Info "📊 Container durumları:"
    Write-Host ""
    
    foreach ($env in @("dev", "test", "prod")) {
        $envInfo = $environments[$env]
        Write-Host "=== $($envInfo.name) ===" -ForegroundColor Yellow
        
        Push-Location $envInfo.path
        docker-compose ps
        Pop-Location
        Write-Host ""
    }
}

function Clean-Environment {
    param([string]$env)
    
    $envInfo = $environments[$env]
    $envPath = $envInfo.path
    
    Write-Warning "⚠️  $($envInfo.name) ortamının TÜM VERİLERİ silinecek!"
    $confirm = Read-Host "Devam etmek istiyor musunuz? (yes/no)"
    
    if ($confirm -eq "yes") {
        Write-Info "🗑️  $($envInfo.name) ortamı temizleniyor..."
        
        Push-Location $envPath
        docker-compose down -v
        Pop-Location
        
        Write-Success "✅ $($envInfo.name) ortamı temizlendi!"
    } else {
        Write-Info "İşlem iptal edildi."
    }
}

# Ana mantık
Write-Info "═══════════════════════════════════════"
Write-Info "  PostgreSQL Docker Ortam Yöneticisi"
Write-Info "═══════════════════════════════════════"
Write-Host ""

if ($Environment -eq "all") {
    foreach ($env in @("dev", "test", "prod")) {
        switch ($Action) {
            "start"   { Start-Environment $env }
            "stop"    { Stop-Environment $env }
            "restart" { Restart-Environment $env }
            "clean"   { Clean-Environment $env }
        }
        Write-Host ""
    }
    
    if ($Action -eq "status") {
        Show-Status
    }
} else {
    switch ($Action) {
        "start"   { Start-Environment $Environment }
        "stop"    { Stop-Environment $Environment }
        "restart" { Restart-Environment $Environment }
        "logs"    { Show-Logs $Environment }
        "status"  { Show-Status }
        "clean"   { Clean-Environment $Environment }
    }
}

Write-Host ""
Write-Info "═══════════════════════════════════════"
