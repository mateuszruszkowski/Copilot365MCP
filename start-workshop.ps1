# 🚀 WORKSHOP START SCRIPT - Uruchom wszystkie komponenty + ngrok dla Copilot Studio
# Automatycznie uruchamia wszystkie serwery MCP i Teams Bot w odpowiedniej kolejności

param(
    [switch]$TestOnly, # Tylko testy, bez uruchamiania
    [switch]$SkipPython, # Pomiń Python MCP servers  
    [switch]$SkipTeams, # Pomiń Teams Bot
    [switch]$QuickStart, # Szybkie uruchomienie bez testów
    [switch]$SkipNgrok,  # Pomiń ngrok (dla rozwoju lokalnego)
    [switch]$Repair,  # Uruchom naprawę przed startem
    [switch]$AllServers  # Uruchom wszystkie serwery (domyślnie tylko Azure DevOps MCP)
)

Write-Host "🚀 Workshop Start Script - Copilot 365 MCP Integration" -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green

# Domyślnie uruchom tylko Azure DevOps MCP dla warsztatu
if (-not $AllServers) {
    Write-Host "📌 Tryb warsztatowy: Tylko Azure DevOps MCP Server" -ForegroundColor Yellow
    Write-Host "   Użyj -AllServers aby uruchomić wszystkie komponenty" -ForegroundColor Gray
    $SkipTeams = $true
}

# ============================================================================
# REPAIR MODE
# ============================================================================

if ($Repair) {
    Write-Host "`n🔧 Uruchamianie naprawy przed startem..." -ForegroundColor Yellow
    if (Test-Path ".\repair-workshop.ps1") {
        & .\repair-workshop.ps1 -Full
        Write-Host "`n✅ Naprawa zakończona, kontynuacja startu..." -ForegroundColor Green
    }
    else {
        Write-Host "❌ Brak pliku repair-workshop.ps1!" -ForegroundColor Red
        exit 1
    }
}

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
    
    # Sprawdź ngrok (dla Copilot Studio)
    if (-not $SkipNgrok) {
        Write-Host "🌐 Sprawdzanie ngrok..." -ForegroundColor Yellow
        try {
            $ngrokVersion = ngrok version 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ ngrok znaleziony: $($ngrokVersion | Select-String 'version')" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "⚠️ ngrok nie znaleziony!" -ForegroundColor Yellow
            Write-Host "   Pobierz z: https://ngrok.com/download" -ForegroundColor Cyan
            Write-Host "   Lub pomiń: .\start-workshop.ps1 -SkipNgrok" -ForegroundColor Cyan
            $continue = Read-Host "Kontynuować bez ngrok? (y/N)"
            if ($continue -ne "y" -and $continue -ne "Y") {
                Write-Host "❌ Anulowano. Zainstaluj ngrok aby używać z Copilot Studio" -ForegroundColor Red
                exit 1
            }
            $SkipNgrok = $true
        }
    }
    
    # Sprawdź Azure konfigurację
    if (Test-Path "azure-setup\ai-config.env") {
        Write-Host "✅ Azure konfiguracja znaleziona" -ForegroundColor Green
    }
    else {
        Write-Host "⚠️ Brak konfiguracji Azure - uruchom najpierw azure-setup" -ForegroundColor Yellow
        $continue = Read-Host "Kontynuować bez Azure? (y/N)"
        if ($continue -ne "y" -and $continue -ne "Y") {
            Write-Host "❌ Anulowano. Uruchom najpierw: cd azure-setup && .\setup-azure.ps1" -ForegroundColor Red
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
            Write-Host "🔧 Uruchamianie naprawy..." -ForegroundColor Cyan
            if (Test-Path ".\repair-workshop.ps1") {
                & .\repair-workshop.ps1 -Quick
                Write-Host "✅ Dependencies naprawione" -ForegroundColor Green
            }
            else {
                Write-Host "❌ Brak pliku repair-workshop.ps1!" -ForegroundColor Red
                Write-Host "   Instalacja ręczna..." -ForegroundColor Yellow
                
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

# Azure Functions Local - WYŁĄCZONE DLA WARSZTATU
if ($AllServers) {
    Write-Host "⚡ Uruchamianie Azure Functions (local)..." -ForegroundColor Yellow
    $azureFunctionJob = Start-Job -ScriptBlock {
        Set-Location "D:\Workshops\Copilot365MCP\mcp-servers\azure-function"
        func start
    } -Name "AzureFunction"
    $jobs += @{ Job = $azureFunctionJob; Name = "Azure Function"; Port = 7071 }
    
    Start-Sleep 3
} else {
    Write-Host "⏭️  Azure Functions - pominięte (tryb warsztatowy)" -ForegroundColor Gray
}

# ngrok Tunnel (dla Copilot Studio) - WYŁĄCZONE DLA WARSZTATU  
$ngrokUrl = $null
if (-not $SkipNgrok -and $AllServers) {
    Write-Host "🌐 Uruchamianie ngrok tunnel..." -ForegroundColor Yellow
    try {
        # Sprawdź czy ngrok już działa na porcie 7071
        $existingNgrok = Get-Process -Name "ngrok" -ErrorAction SilentlyContinue
        if ($existingNgrok) {
            Write-Host "⚠️ ngrok już działa - zatrzymywanie..." -ForegroundColor Yellow
            Stop-Process -Name "ngrok" -Force -ErrorAction SilentlyContinue
            Start-Sleep 2
        }
        
        # Uruchom ngrok
        $ngrokJob = Start-Job -ScriptBlock {
            ngrok http 7071 --log=stdout
        } -Name "Ngrok"
        
        $jobs += @{ Job = $ngrokJob; Name = "Ngrok Tunnel"; Port = "tunnel" }
        
        # Czekaj na uruchomienie ngrok i pobierz URL
        Start-Sleep 5
        try {
            $ngrokApi = Invoke-RestMethod -Uri "http://localhost:4040/api/tunnels" -TimeoutSec 5
            if ($ngrokApi.tunnels) {
                $ngrokUrl = $ngrokApi.tunnels[0].public_url
                Write-Host "✅ Ngrok tunnel utworzony: $ngrokUrl" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "⚠️ Nie udało się pobrać ngrok URL - sprawdź ręcznie na http://localhost:4040" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "❌ Błąd uruchamiania ngrok: $($_.Exception.Message)" -ForegroundColor Red
        $SkipNgrok = $true
    }
} elseif (-not $AllServers) {
    Write-Host "⏭️  Ngrok - pominięte (tryb warsztatowy)" -ForegroundColor Gray
}

# Local DevOps MCP (Python) - WYŁĄCZONE DLA WARSZTATU
if (-not $SkipPython -and $AllServers) {
    Write-Host "🐍 Uruchamianie Local DevOps MCP..." -ForegroundColor Yellow
    $localDevOpsJob = Start-Job -ScriptBlock {
        Set-Location "D:\Workshops\Copilot365MCP\mcp-servers\local-devops"
        python local-mcp-server.py
    } -Name "LocalDevOps"
    $jobs += @{ Job = $localDevOpsJob; Name = "Local DevOps MCP"; Port = "stdio" }
    Start-Sleep 2
} elseif (-not $AllServers) {
    Write-Host "⏭️  Local DevOps MCP - pominięte (tryb warsztatowy)" -ForegroundColor Gray
}

# Desktop Commander MCP (TypeScript) - WYŁĄCZONE DLA WARSZTATU
if ($AllServers) {
    Write-Host "💻 Uruchamianie Desktop Commander MCP..." -ForegroundColor Yellow
    $desktopCommanderJob = Start-Job -ScriptBlock {
        Set-Location "D:\Workshops\Copilot365MCP\mcp-servers\desktop-commander"
        npm start
    } -Name "DesktopCommander"
    $jobs += @{ Job = $desktopCommanderJob; Name = "Desktop Commander MCP"; Port = "stdio" }
    Start-Sleep 2
} else {
    Write-Host "⏭️  Desktop Commander MCP - pominięte (tryb warsztatowy)" -ForegroundColor Gray
}

# Azure DevOps MCP (Python) - GŁÓWNY SERWER DLA WARSZTATU
Write-Host "`n🎯 URUCHAMIANIE GŁÓWNEGO SERWERA WARSZTATOWEGO" -ForegroundColor Green
Write-Host "🔧 Uruchamianie Azure DevOps MCP..." -ForegroundColor Yellow
$azureDevOpsJob = Start-Job -ScriptBlock {
    Set-Location "D:\Workshops\Copilot365MCP\mcp-servers\azure-devops"
    python azure-devops-mcp.py
} -Name "AzureDevOps"
$jobs += @{ Job = $azureDevOpsJob; Name = "Azure DevOps MCP"; Port = "stdio" }

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
# WORKSHOP MODE INFO
# ============================================================================

if (-not $AllServers) {
    Write-Host "`n🎓 TRYB WARSZTATOWY - AZURE DEVOPS MCP" -ForegroundColor Green
    Write-Host "======================================" -ForegroundColor Green
    
    Write-Host "✅ Uruchomiony serwer:" -ForegroundColor Green
    Write-Host "   • Azure DevOps MCP Server (Python)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📋 MOŻLIWOŚCI SERWERA:" -ForegroundColor Yellow
    Write-Host "   • Zarządzanie work items w Azure DevOps" -ForegroundColor White
    Write-Host "   • Uruchamianie i monitorowanie pipeline'ów" -ForegroundColor White
    Write-Host "   • Przeglądanie repozytoriów i commitów" -ForegroundColor White
    Write-Host "   • Integracja z Claude Desktop lub VS Code" -ForegroundColor White
    Write-Host ""
    Write-Host "🔧 WYMAGANA KONFIGURACJA:" -ForegroundColor Yellow
    Write-Host "   1. Plik .env w mcp-servers/azure-devops/" -ForegroundColor White
    Write-Host "   2. Personal Access Token (PAT) z Azure DevOps" -ForegroundColor White
    Write-Host "   3. URL organizacji i nazwa projektu" -ForegroundColor White
} else {
    # Oryginalna sekcja Copilot Studio
    Write-Host "`n🤖 COPILOT STUDIO INTEGRATION" -ForegroundColor Green
    Write-Host "==============================" -ForegroundColor Green
    
    if ($ngrokUrl) {
        Write-Host "✅ Publiczny MCP Server URL (dla Copilot Studio):" -ForegroundColor Green
        Write-Host "   $ngrokUrl/api/McpServer" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "📋 KONFIGURACJA COPILOT STUDIO:" -ForegroundColor Yellow
        Write-Host "   1. Otwórz swojego agenta 'DevOps MCP Assistant'" -ForegroundColor White
        Write-Host "   2. Idź do: Settings → Actions → Model Context Protocol" -ForegroundColor White
        Write-Host "   3. Dodaj MCP Server:" -ForegroundColor White
        Write-Host "      URL: $ngrokUrl/api/McpServer" -ForegroundColor Cyan
        Write-Host "      Method: POST" -ForegroundColor White
        Write-Host "   4. Test: Napisz 'What tools do you have?'" -ForegroundColor White
    } else {
        Write-Host "⚠️ Ngrok nie działa - dla Copilot Studio potrzebujesz publiczny URL" -ForegroundColor Yellow
        Write-Host "   Opcje:" -ForegroundColor White
        Write-Host "   • Zainstaluj ngrok: https://ngrok.com/download" -ForegroundColor Cyan
        Write-Host "   • Użyj Azure Function w chmurze" -ForegroundColor Cyan
        Write-Host "   • Test lokalnie: curl http://localhost:7071/api/McpServer" -ForegroundColor Cyan
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

if (-not $AllServers) {
    Write-Host "`n🔗 Tryb warsztatowy - Azure DevOps MCP:" -ForegroundColor Cyan
    Write-Host "   • Serwer: Azure DevOps MCP (stdio)" -ForegroundColor White
    Write-Host "   • Integracja: Claude Desktop / VS Code" -ForegroundColor White
} else {
    Write-Host "`n🔗 Endpoints:" -ForegroundColor Cyan
    Write-Host "   • Azure Function (local): http://localhost:7071/api/McpServer" -ForegroundColor White
    if ($ngrokUrl) {
        Write-Host "   • Azure Function (public): $ngrokUrl/api/McpServer" -ForegroundColor Cyan
        Write-Host "   • Ngrok Dashboard: http://localhost:4040" -ForegroundColor White
    }
    if (-not $SkipTeams) {
        Write-Host "   • Teams Bot Health: http://localhost:3978/health" -ForegroundColor White
        Write-Host "   • Teams Bot Config: http://localhost:3978/api/config" -ForegroundColor White
        Write-Host "   • MCP Test: http://localhost:3978/api/mcp/test" -ForegroundColor White
    }
}

Write-Host "`n🎯 Workshop Commands:" -ForegroundColor Cyan
if (-not $AllServers) {
    Write-Host "   • Sprawdź status: Get-Job" -ForegroundColor White
    Write-Host "   • Logi serwera: Receive-Job AzureDevOps" -ForegroundColor White
    Write-Host "   • Zatrzymaj: Stop-Job AzureDevOps" -ForegroundColor White
} else {
    Write-Host "   • Test Azure: curl http://localhost:7071/api/McpServer" -ForegroundColor White
    if ($ngrokUrl) {
        Write-Host "   • Test Public: curl $ngrokUrl/api/McpServer" -ForegroundColor Cyan
    }
    if (-not $SkipTeams) {
        Write-Host "   • Test Teams: curl http://localhost:3978/health" -ForegroundColor White
    }
}
Write-Host "   • Monitor Jobs: Get-Job" -ForegroundColor White
Write-Host "   • Stop All: Get-Job | Stop-Job" -ForegroundColor White

Write-Host "`n💡 VS Code Commands:" -ForegroundColor Cyan
Write-Host "   • Open Project: code Copilot365MCP.code-workspace" -ForegroundColor White
if (-not $AllServers) {
    Write-Host "   • Debug Azure DevOps MCP: F5 → 'Debug Python MCP'" -ForegroundColor White
} else {
    Write-Host "   • Debug Azure Function: F5 → 'Debug Azure Functions'" -ForegroundColor White
    Write-Host "   • Debug Teams Bot: F5 → 'Debug Teams Bot'" -ForegroundColor White
}

Write-Host "`n🎮 Demo Scenarios:" -ForegroundColor Cyan
if (-not $AllServers) {
    Write-Host "   1. Konfiguracja Claude Desktop:" -ForegroundColor White
    Write-Host "      • Dodaj serwer MCP w ustawieniach" -ForegroundColor Gray
    Write-Host "      • Command: python" -ForegroundColor Gray
    Write-Host "      • Args: D:\\Workshops\\Copilot365MCP\\mcp-servers\\azure-devops\\azure-devops-mcp.py" -ForegroundColor Gray
    Write-Host "   2. Test w Claude: 'List my work items'" -ForegroundColor White
    Write-Host "   3. Utwórz task: 'Create a new bug about login issue'" -ForegroundColor White
} else {
    Write-Host "   1. Test MCP Tools: [POST] http://localhost:7071/api/McpServer" -ForegroundColor White
    Write-Host "      Body: {\"jsonrpc\":\"2.0\",\"method\":\"tools/list\",\"id\":1}" -ForegroundColor Gray
    if ($ngrokUrl) {
        Write-Host "   2. Copilot Studio: Użyj URL $ngrokUrl/api/McpServer" -ForegroundColor Cyan
    }
    if (-not $SkipTeams) {
        Write-Host "   3. Teams Bot Help: Send 'help' in Teams" -ForegroundColor White
        Write-Host "   4. Deploy Demo: Send 'deploy v1.0.0 do staging' in Teams" -ForegroundColor White
    }
}

# ============================================================================
# MCP TOOLS TEST
# ============================================================================

if ($AllServers) {
    Write-Host "`n🧪 MCP TOOLS TEST" -ForegroundColor Yellow
    Write-Host "=================" -ForegroundColor Yellow
    
    if ($ngrokUrl -or (Test-NetConnection -ComputerName "localhost" -Port 7071 -InformationLevel Quiet)) {
        $testUrl = if ($ngrokUrl) { "$ngrokUrl/api/McpServer" } else { "http://localhost:7071/api/McpServer" }
        
        Write-Host "Testing MCP tools list..." -ForegroundColor Gray
        try {
            $mcpTest = Invoke-RestMethod -Uri $testUrl -Method POST -ContentType "application/json" -Body '{"jsonrpc":"2.0","method":"tools/list","id":1}' -TimeoutSec 10
            
            if ($mcpTest.result -and $mcpTest.result.tools) {
                Write-Host "✅ MCP Tools dostępne:" -ForegroundColor Green
                foreach ($tool in $mcpTest.result.tools) {
                    Write-Host "   • $($tool.name): $($tool.description)" -ForegroundColor White
                }
            } else {
                Write-Host "⚠️ MCP odpowiada ale brak tools" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "❌ Błąd testowania MCP: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "⚠️ Azure Function nie odpowiada - pomiń test MCP" -ForegroundColor Yellow
    }
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
        
        # Sprawdź ngrok co 5 minut
        if (-not $SkipNgrok -and $ngrokUrl -and ((Get-Date).Minute % 5 -eq 0)) {
            try {
                $ngrokStatus = Invoke-RestMethod -Uri "http://localhost:4040/api/tunnels" -TimeoutSec 3
                if ($ngrokStatus.tunnels -and $ngrokStatus.tunnels[0].public_url -ne $ngrokUrl) {
                    $ngrokUrl = $ngrokStatus.tunnels[0].public_url
                    Write-Host "[$timestamp] 🌐 Ngrok URL updated: $ngrokUrl" -ForegroundColor Cyan
                }
            }
            catch {
                Write-Host "[$timestamp] ⚠️ Ngrok status check failed" -ForegroundColor Yellow
            }
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

$cleanup = Read-Host "Zatrzymać wszystkie serwery (włącznie z ngrok)? (Y/n)"
if ($cleanup -ne "n" -and $cleanup -ne "N") {
    Write-Host "🛑 Zatrzymywanie serwerów..." -ForegroundColor Yellow
    
    foreach ($jobInfo in $jobs) {
        if ($jobInfo.Job.State -eq "Running") {
            Write-Host "   Stopping $($jobInfo.Name)..." -ForegroundColor Gray
            Stop-Job $jobInfo.Job
            Remove-Job $jobInfo.Job
        }
    }
    
    # Zatrzymaj ngrok osobno
    Get-Process -Name "ngrok" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    
    Write-Host "✅ Wszystkie serwery zatrzymane" -ForegroundColor Green
}

Write-Host "`n🎉 Workshop Script zakończony!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host "💡 Komendy:" -ForegroundColor Cyan
Write-Host "   • Uruchom ponownie: .\start-workshop.ps1" -ForegroundColor White
Write-Host "   • Napraw problemy: .\repair-workshop.ps1" -ForegroundColor White
Write-Host "   • Szybki start: .\start-workshop.ps1 -QuickStart" -ForegroundColor White
Write-Host "   • Z naprawą: .\start-workshop.ps1 -Repair" -ForegroundColor White
if ($ngrokUrl) {
    Write-Host "🌐 Zapamiętaj URL dla Copilot Studio: $ngrokUrl/api/McpServer" -ForegroundColor Yellow
}
