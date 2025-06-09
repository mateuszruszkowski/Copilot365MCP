# 🚀 WORKSHOP START SCRIPT - Uruchom wszystkie komponenty
# Automatycznie uruchamia wszystkie serwery MCP i Teams Bot w odpowiedniej kolejności

param(
    [switch]$TestOnly, # Tylko testy, bez uruchamiania
    [switch]$SkipPython, # Pomiń Python MCP servers  
    [switch]$SkipTeams, # Pomiń Teams Bot
    [switch]$QuickStart     # Szybkie uruchomienie bez testów
)

Write-Host "🚀 Workshop Start Script - Copilot 365 MCP Integration" -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green

# ============================================================================
# PRE-START CHECKS
# ============================================================================

if (-not $QuickStart) {
    Write-Host "`n1️⃣ Pre-start checks..." -ForegroundColor Cyan
    
    # Sprawdź czy jesteśmy w odpowiednim katalogu
    if (-not (Test-Path "Copilot365MCP.code-workspace")) {
        Write-Host "❌ Uruchom skrypt z głównego katalogu projektu!" -ForegroundColor Red
        Write-Host "   cd D:\Workshops\Copilot365MCP" -ForegroundColor Yellow
        exit 1
    }
    
    # Sprawdź Azure konfigurację
    if (Test-Path "azure-setup\ai-config.env") {
        Write-Host "✅ Azure konfiguracja znaleziona" -ForegroundColor Green
    }
    else {
        Write-Host "⚠️ Brak konfiguracji Azure - uruchom najpierw azure-setup" -ForegroundColor Yellow
        $continue = Read-Host "Kontynuować bez Azure? (y/N)"
        if ($continue -ne "y" -and $continue -ne "Y") {
            Write-Host "❌ Anulowano. Uruchom najpierw: cd azure-setup && .\setup-azure-fixed.ps1" -ForegroundColor Red
            exit 1
        }
    }
    
    # Sprawdź node_modules
    $nodeModulesPaths = @(
        "mcp-servers\azure-function\node_modules",
        "mcp-servers\desktop-commander\node_modules", 
        "teams-bot\node_modules"
    )
    
    $missingNodeModules = @()
    foreach ($path in $nodeModulesPaths) {
        if (-not (Test-Path $path)) {
            $missingNodeModules += $path
        }
    }
    
    if ($missingNodeModules.Count -gt 0) {
        Write-Host "⚠️ Brak node_modules w:" -ForegroundColor Yellow
        $missingNodeModules | ForEach-Object { Write-Host "   $_" -ForegroundColor White }
        $install = Read-Host "Zainstalować dependencies automatycznie? (Y/n)"
        if ($install -ne "n" -and $install -ne "N") {
            Write-Host "📦 Instalowanie dependencies..." -ForegroundColor Cyan
            
            # Azure Function
            if (-not (Test-Path "mcp-servers\azure-function\node_modules")) {
                Write-Host "Installing Azure Function dependencies..." -ForegroundColor Gray
                cd mcp-servers\azure-function
                npm install --silent
                cd ..\..
            }
            
            # Desktop Commander  
            if (-not (Test-Path "mcp-servers\desktop-commander\node_modules")) {
                Write-Host "Installing Desktop Commander dependencies..." -ForegroundColor Gray
                cd mcp-servers\desktop-commander
                npm install --silent
                cd ..\..
            }
            
            # Teams Bot
            if (-not (Test-Path "teams-bot\node_modules")) {
                Write-Host "Installing Teams Bot dependencies..." -ForegroundColor Gray
                cd teams-bot
                npm install --silent
                cd ..
            }
            
            Write-Host "✅ Dependencies zainstalowane" -ForegroundColor Green
        }
    }
}

# ============================================================================
# TEST MODE
# ============================================================================

if ($TestOnly) {
    Write-Host "`n🧪 Test Mode - sprawdzanie komponentów..." -ForegroundColor Cyan
    
    # Test Azure Function
    Write-Host "`n📡 Test Azure Function MCP..." -ForegroundColor Yellow
    try {
        $response = Invoke-WebRequest -Uri "https://copilotmcpdevfunc.azurewebsites.net/api/McpServer" -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ Azure Function MCP - OK" -ForegroundColor Green
        }
        else {
            Write-Host "⚠️ Azure Function MCP - Status $($response.StatusCode)" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "❌ Azure Function MCP - Niedostępny" -ForegroundColor Red
    }
    
    # Test lokalnych komponentów
    Write-Host "`n📂 Test lokalnych komponentów..." -ForegroundColor Yellow
    
    $components = @(
        @{ Path = "mcp-servers\azure-function"; Name = "Azure Function (local)" },
        @{ Path = "mcp-servers\local-devops"; Name = "Local DevOps MCP" },
        @{ Path = "mcp-servers\desktop-commander"; Name = "Desktop Commander MCP" },
        @{ Path = "mcp-servers\azure-devops"; Name = "Azure DevOps MCP" },
        @{ Path = "teams-bot"; Name = "Teams Bot" }
    )
    
    foreach ($component in $components) {
        if (Test-Path $component.Path) {
            Write-Host "✅ $($component.Name) - ścieżka OK" -ForegroundColor Green
        }
        else {
            Write-Host "❌ $($component.Name) - brak ścieżki" -ForegroundColor Red
        }
    }
    
    Write-Host "`n✅ Test zakończony - sprawdź wyniki powyżej" -ForegroundColor Green
    exit 0
}

# ============================================================================
# START SERVERS
# ============================================================================

Write-Host "`n2️⃣ Uruchamianie serwerów MCP..." -ForegroundColor Cyan

$jobs = @()

# Azure Functions Local
Write-Host "⚡ Uruchamianie Azure Functions (local)..." -ForegroundColor Yellow
$azureFunctionJob = Start-Job -ScriptBlock {
    Set-Location "D:\Workshops\Copilot365MCP\mcp-servers\azure-function"
    func start
} -Name "AzureFunction"
$jobs += @{ Job = $azureFunctionJob; Name = "Azure Function"; Port = 7071 }

Start-Sleep 3

# Local DevOps MCP (Python)
if (-not $SkipPython) {
    Write-Host "🐍 Uruchamianie Local DevOps MCP..." -ForegroundColor Yellow
    $localDevOpsJob = Start-Job -ScriptBlock {
        Set-Location "D:\Workshops\Copilot365MCP\mcp-servers\local-devops"
        python local-mcp-server.py
    } -Name "LocalDevOps"
    $jobs += @{ Job = $localDevOpsJob; Name = "Local DevOps MCP"; Port = "stdio" }
}

Start-Sleep 2

# Desktop Commander MCP (TypeScript)
Write-Host "💻 Uruchamianie Desktop Commander MCP..." -ForegroundColor Yellow
$desktopCommanderJob = Start-Job -ScriptBlock {
    Set-Location "D:\Workshops\Copilot365MCP\mcp-servers\desktop-commander"
    npm start
} -Name "DesktopCommander"
$jobs += @{ Job = $desktopCommanderJob; Name = "Desktop Commander MCP"; Port = "stdio" }

Start-Sleep 2

# Azure DevOps MCP (Python)
if (-not $SkipPython) {
    Write-Host "🔧 Uruchamianie Azure DevOps MCP..." -ForegroundColor Yellow
    $azureDevOpsJob = Start-Job -ScriptBlock {
        Set-Location "D:\Workshops\Copilot365MCP\mcp-servers\azure-devops"
        python azure-devops-mcp.py
    } -Name "AzureDevOps"
    $jobs += @{ Job = $azureDevOpsJob; Name = "Azure DevOps MCP"; Port = "stdio" }
}

Start-Sleep 3

# Teams Bot
if (-not $SkipTeams) {
    Write-Host "🤖 Uruchamianie Teams Bot..." -ForegroundColor Yellow
    $teamsBotJob = Start-Job -ScriptBlock {
        Set-Location "D:\Workshops\Copilot365MCP\teams-bot"
        npm start
    } -Name "TeamsBot"
    $jobs += @{ Job = $teamsBotJob; Name = "Teams Bot"; Port = 3978 }
}

# ============================================================================
# WAIT FOR STARTUP
# ============================================================================

Write-Host "`n3️⃣ Czekanie na uruchomienie serwerów..." -ForegroundColor Cyan

Start-Sleep 10

# Sprawdź status zadań
Write-Host "`n📊 Status serwerów:" -ForegroundColor Yellow

foreach ($jobInfo in $jobs) {
    $job = $jobInfo.Job
    $name = $jobInfo.Name
    $port = $jobInfo.Port
    
    if ($job.State -eq "Running") {
        Write-Host "✅ $name - Running" -ForegroundColor Green
        
        # Test HTTP endpoints jeśli mają porty
        if ($port -match "^\d+$") {
            try {
                $testUrl = "http://localhost:$port"
                $response = Invoke-WebRequest -Uri $testUrl -TimeoutSec 3 -ErrorAction Stop
                Write-Host "   🌐 HTTP $port - OK ($($response.StatusCode))" -ForegroundColor Green
            }
            catch {
                Write-Host "   ⚠️ HTTP $port - Not ready yet" -ForegroundColor Yellow
            }
        }
        else {
            Write-Host "   📡 $port connection" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "❌ $name - $($job.State)" -ForegroundColor Red
        if ($job.ChildJobs[0].Error) {
            Write-Host "   Error: $($job.ChildJobs[0].Error)" -ForegroundColor Red
        }
    }
}

# ============================================================================
# QUICK TESTS
# ============================================================================

Write-Host "`n4️⃣ Szybkie testy endpoints..." -ForegroundColor Cyan

# Test Azure Function
Write-Host "🧪 Azure Function Local..." -ForegroundColor Gray
try {
    $response = Invoke-WebRequest -Uri "http://localhost:7071/api/McpServer" -TimeoutSec 5
    Write-Host "✅ Azure Function - OK" -ForegroundColor Green
}
catch {
    Write-Host "⚠️ Azure Function - Not ready" -ForegroundColor Yellow
}

# Test Teams Bot
if (-not $SkipTeams) {
    Write-Host "🧪 Teams Bot Health..." -ForegroundColor Gray
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3978/health" -TimeoutSec 5
        Write-Host "✅ Teams Bot - OK" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️ Teams Bot - Not ready" -ForegroundColor Yellow
    }
}

# ============================================================================
# SUMMARY & MONITORING
# ============================================================================

Write-Host "`n🎉 Startup Complete!" -ForegroundColor Green
Write-Host "===================" -ForegroundColor Green

Write-Host "`n📊 Uruchomione komponenty:" -ForegroundColor Cyan
foreach ($jobInfo in $jobs) {
    $status = if ($jobInfo.Job.State -eq "Running") { "✅ Running" } else { "❌ $($jobInfo.Job.State)" }
    $portInfo = if ($jobInfo.Port -match "^\d+$") { "Port: $($jobInfo.Port)" } else { $jobInfo.Port }
    Write-Host "   $status $($jobInfo.Name) ($portInfo)" -ForegroundColor White
}

Write-Host "`n🔗 Endpoints:" -ForegroundColor Cyan
Write-Host "   • Azure Function: http://localhost:7071/api/McpServer" -ForegroundColor White
if (-not $SkipTeams) {
    Write-Host "   • Teams Bot Health: http://localhost:3978/health" -ForegroundColor White
    Write-Host "   • Teams Bot Config: http://localhost:3978/api/config" -ForegroundColor White
    Write-Host "   • MCP Test: http://localhost:3978/api/mcp/test" -ForegroundColor White
}

Write-Host "`n🎯 Workshop Commands:" -ForegroundColor Cyan
Write-Host "   • Test Azure: curl http://localhost:7071/api/McpServer" -ForegroundColor White
if (-not $SkipTeams) {
    Write-Host "   • Test Teams: curl http://localhost:3978/health" -ForegroundColor White
}
Write-Host "   • Monitor Jobs: Get-Job" -ForegroundColor White
Write-Host "   • Stop All: Get-Job | Stop-Job" -ForegroundColor White

Write-Host "`n💡 VS Code Commands:" -ForegroundColor Cyan
Write-Host "   • Open Project: code Copilot365MCP.code-workspace" -ForegroundColor White
Write-Host "   • Debug Azure Function: F5 → 'Debug Azure Functions'" -ForegroundColor White
Write-Host "   • Debug Teams Bot: F5 → 'Debug Teams Bot'" -ForegroundColor White

Write-Host "`n🎮 Demo Scenarios:" -ForegroundColor Cyan
Write-Host "   1. Test MCP Tools: [POST] http://localhost:7071/api/McpServer" -ForegroundColor White
Write-Host "      Body: {\"jsonrpc\":\"2.0\",\"method\":\"tools/list\",\"id\":1}" -ForegroundColor Gray
if (-not $SkipTeams) {
    Write-Host "   2. Teams Bot Help: Send 'help' in Teams" -ForegroundColor White
    Write-Host "   3. Deploy Demo: Send 'deploy v1.0.0 do staging' in Teams" -ForegroundColor White
}

# ============================================================================
# MONITORING LOOP
# ============================================================================

Write-Host "`n🔄 Monitoring (Ctrl+C aby zatrzymać)..." -ForegroundColor Yellow

try {
    while ($true) {
        Start-Sleep 30
        
        # Sprawdź status zadań
        $runningCount = 0
        $failedJobs = @()
        
        foreach ($jobInfo in $jobs) {
            if ($jobInfo.Job.State -eq "Running") {
                $runningCount++
            }
            elseif ($jobInfo.Job.State -eq "Failed") {
                $failedJobs += $jobInfo.Name
            }
        }
        
        $timestamp = Get-Date -Format "HH:mm:ss"
        Write-Host "[$timestamp] 📊 Running: $runningCount/$($jobs.Count) servers" -ForegroundColor Gray
        
        if ($failedJobs.Count -gt 0) {
            Write-Host "[$timestamp] ❌ Failed: $($failedJobs -join ', ')" -ForegroundColor Red
        }
    }
}
catch {
    Write-Host "`n🛑 Monitoring zatrzymany" -ForegroundColor Yellow
}

# ============================================================================
# CLEANUP
# ============================================================================

Write-Host "`n🧹 Cleanup..." -ForegroundColor Cyan

$cleanup = Read-Host "Zatrzymać wszystkie serwery? (Y/n)"
if ($cleanup -ne "n" -and $cleanup -ne "N") {
    Write-Host "🛑 Zatrzymywanie serwerów..." -ForegroundColor Yellow
    
    foreach ($jobInfo in $jobs) {
        if ($jobInfo.Job.State -eq "Running") {
            Write-Host "   Stopping $($jobInfo.Name)..." -ForegroundColor Gray
            Stop-Job $jobInfo.Job
            Remove-Job $jobInfo.Job
        }
    }
    
    Write-Host "✅ Wszystkie serwery zatrzymane" -ForegroundColor Green
}

Write-Host "`n🎉 Workshop Script zakończony!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host "💡 Aby uruchomić ponownie: .\start-workshop.ps1" -ForegroundColor Cyan
