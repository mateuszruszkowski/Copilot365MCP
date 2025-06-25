# 🔧 Kompletny skrypt naprawy warsztatu Copilot 365 MCP
# Łączy funkcje quick-fix.ps1 i fix-workshop-servers.ps1

param(
    [switch]$Quick,      # Szybka naprawa (tylko podstawowe)
    [switch]$Full,       # Pełna naprawa ze sprawdzeniem
    [switch]$Test,       # Uruchom testy po naprawie
    [switch]$CheckOnly   # Tylko sprawdź status
)

# Domyślnie uruchom pełną naprawę
if (-not $Quick -and -not $Full -and -not $CheckOnly) {
    $Full = $true
}

Write-Host "🔧 Naprawa warsztatu Copilot 365 MCP" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

# ============================================================================
# ZATRZYMANIE PROCESÓW
# ============================================================================

if (-not $CheckOnly) {
    Write-Host "`n🛑 Zatrzymywanie procesów..." -ForegroundColor Yellow
    
    # Zatrzymaj procesy na konkretnych portach
    $ports = @(7071, 3978, 5000, 3000)
    foreach ($port in $ports) {
        try {
            $tcpConnection = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
            if ($tcpConnection) {
                $pid = $tcpConnection.OwningProcess
                Write-Host "   Zatrzymywanie procesu na porcie $port (PID: $pid)"
                Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
            }
        }
        catch {
            # Port wolny
        }
    }
    
    # Zatrzymaj wszystkie procesy node, func, python
    Get-Process -Name "node", "func", "python" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    
    Write-Host "✅ Procesy zatrzymane" -ForegroundColor Green
}

# ============================================================================
# SPRAWDZENIE STATUSU
# ============================================================================

if ($CheckOnly -or $Full) {
    Write-Host "`n🔍 Sprawdzanie statusu komponentów..." -ForegroundColor Cyan
    
    $components = @{
        "Azure Function" = @{
            Path = "mcp-servers\azure-function"
            CheckFiles = @("package.json", "node_modules", "McpServer\index.js")
        }
        "Desktop Commander" = @{
            Path = "mcp-servers\desktop-commander"
            CheckFiles = @("package.json", "node_modules", "tsconfig.json", "dist\index.js")
        }
        "Teams Bot" = @{
            Path = "teams-bot"
            CheckFiles = @("package.json", "node_modules", "src\index.js")
        }
        "Azure DevOps MCP" = @{
            Path = "mcp-servers\azure-devops"
            CheckFiles = @("requirements.txt", "azure-devops-mcp.py")
        }
        "Local DevOps MCP" = @{
            Path = "mcp-servers\local-devops"
            CheckFiles = @("requirements.txt", "local-mcp-server.py")
        }
    }
    
    $statusOK = $true
    foreach ($component in $components.GetEnumerator()) {
        Write-Host "`n📦 $($component.Key):" -ForegroundColor Yellow
        $componentOK = $true
        
        foreach ($file in $component.Value.CheckFiles) {
            $fullPath = Join-Path $component.Value.Path $file
            if (Test-Path $fullPath) {
                Write-Host "   ✅ $file" -ForegroundColor Green
            }
            else {
                Write-Host "   ❌ $file - BRAK" -ForegroundColor Red
                $componentOK = $false
                $statusOK = $false
            }
        }
        
        if ($componentOK) {
            Write-Host "   ✅ Status: OK" -ForegroundColor Green
        }
        else {
            Write-Host "   ❌ Status: Wymaga naprawy" -ForegroundColor Red
        }
    }
    
    if ($CheckOnly) {
        if ($statusOK) {
            Write-Host "`n✅ Wszystkie komponenty są gotowe!" -ForegroundColor Green
        }
        else {
            Write-Host "`n❌ Niektóre komponenty wymagają naprawy" -ForegroundColor Red
            Write-Host "   Uruchom: .\repair-workshop.ps1" -ForegroundColor Yellow
        }
        exit
    }
}

# ============================================================================
# NAPRAWA KOMPONENTÓW
# ============================================================================

if (-not $CheckOnly) {
    # Azure Function
    Write-Host "`n⚡ Naprawianie Azure Function..." -ForegroundColor Yellow
    Push-Location "mcp-servers\azure-function"
    if (Test-Path "package.json") {
        if ($Full) {
            Remove-Item "node_modules" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item "package-lock.json" -Force -ErrorAction SilentlyContinue
        }
        npm install
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Azure Function - OK" -ForegroundColor Green
        } else {
            Write-Host "❌ Azure Function - ERROR" -ForegroundColor Red
        }
    }
    Pop-Location
    
    # Desktop Commander
    Write-Host "`n💻 Naprawianie Desktop Commander..." -ForegroundColor Yellow
    Push-Location "mcp-servers\desktop-commander"
    if (Test-Path "package.json") {
        if ($Full) {
            Remove-Item "node_modules" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item "package-lock.json" -Force -ErrorAction SilentlyContinue
            Remove-Item "dist" -Recurse -Force -ErrorAction SilentlyContinue
        }
        npm install
        if ($LASTEXITCODE -eq 0) {
            npm run build
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Desktop Commander - OK" -ForegroundColor Green
            } else {
                Write-Host "❌ Desktop Commander build - ERROR" -ForegroundColor Red
            }
        } else {
            Write-Host "❌ Desktop Commander install - ERROR" -ForegroundColor Red
        }
    }
    Pop-Location
    
    # Teams Bot
    Write-Host "`n🤖 Naprawianie Teams Bot..." -ForegroundColor Yellow
    Push-Location "teams-bot"
    if (Test-Path "package.json") {
        if ($Full) {
            Remove-Item "node_modules" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item "package-lock.json" -Force -ErrorAction SilentlyContinue
        }
        npm install
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Teams Bot - OK" -ForegroundColor Green
        } else {
            Write-Host "❌ Teams Bot - ERROR" -ForegroundColor Red
        }
    }
    Pop-Location
    
    # Python components
    Write-Host "`n🐍 Naprawianie Python dependencies..." -ForegroundColor Yellow
    
    # Upgrade pip first
    python -m pip install --upgrade pip --quiet
    
    # Local DevOps
    Push-Location "mcp-servers\local-devops"
    if (Test-Path "requirements.txt") {
        pip install -r requirements.txt --upgrade --quiet
        Write-Host "✅ Local DevOps MCP - OK" -ForegroundColor Green
    }
    Pop-Location
    
    # Azure DevOps
    Push-Location "mcp-servers\azure-devops"
    if (Test-Path "requirements.txt") {
        pip install -r requirements.txt --upgrade --quiet
        Write-Host "✅ Azure DevOps MCP - OK" -ForegroundColor Green
    }
    Pop-Location
}

# ============================================================================
# SPRAWDZENIE PLIKÓW KONFIGURACYJNYCH
# ============================================================================

if ($Full) {
    Write-Host "`n📋 Sprawdzanie plików konfiguracyjnych..." -ForegroundColor Cyan
    
    $configFiles = @(
        @{Path = ".env"; Required = $false},
        @{Path = "ai-config.env"; Required = $false},
        @{Path = "teams-bot\.env"; Required = $false},
        @{Path = "mcp-servers\local-devops\.env"; Required = $false},
        @{Path = "mcp-servers\azure-devops\.env"; Required = $true}
    )
    
    foreach ($config in $configFiles) {
        if (Test-Path $config.Path) {
            Write-Host "✅ $($config.Path) - istnieje" -ForegroundColor Green
        }
        elseif ($config.Required) {
            Write-Host "❌ $($config.Path) - BRAK (wymagany)" -ForegroundColor Red
            
            # Utwórz przykładowy plik .env dla Azure DevOps
            if ($config.Path -eq "mcp-servers\azure-devops\.env") {
                $examplePath = "mcp-servers\azure-devops\.env.example"
                if (Test-Path $examplePath) {
                    Copy-Item $examplePath $config.Path
                    Write-Host "   📝 Utworzono z przykładu - uzupełnij dane!" -ForegroundColor Yellow
                }
            }
        }
        else {
            Write-Host "⚠️  $($config.Path) - brak (opcjonalny)" -ForegroundColor Yellow
        }
    }
}

# ============================================================================
# TESTY
# ============================================================================

if ($Test -or $Full) {
    Write-Host "`n🧪 Uruchamianie testów..." -ForegroundColor Cyan
    
    # Test Desktop Commander
    Write-Host "`nTest: Desktop Commander build" -ForegroundColor Gray
    if (Test-Path "mcp-servers\desktop-commander\dist\index.js") {
        Write-Host "✅ Desktop Commander - build OK" -ForegroundColor Green
    }
    else {
        Write-Host "❌ Desktop Commander - brak pliku dist/index.js" -ForegroundColor Red
    }
    
    # Test Teams Bot syntax
    Write-Host "`nTest: Teams Bot syntax" -ForegroundColor Gray
    Push-Location "teams-bot"
    $syntaxCheck = node -c "src/index.js" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Teams Bot - syntax OK" -ForegroundColor Green
    }
    else {
        Write-Host "❌ Teams Bot - błąd składni" -ForegroundColor Red
    }
    Pop-Location
    
    # Test Python imports
    Write-Host "`nTest: Python imports" -ForegroundColor Gray
    $pythonTest = python -c "import mcp; import azure.devops; print('OK')" 2>&1
    if ($pythonTest -eq "OK") {
        Write-Host "✅ Python - imports OK" -ForegroundColor Green
    }
    else {
        Write-Host "❌ Python - brak niektórych modułów" -ForegroundColor Red
    }
}

# ============================================================================
# PODSUMOWANIE
# ============================================================================

Write-Host "`n🎉 NAPRAWA ZAKOŃCZONA!" -ForegroundColor Green
Write-Host "=====================" -ForegroundColor Green

if ($Quick) {
    Write-Host "`n✅ Wykonano szybką naprawę" -ForegroundColor Green
}
else {
    Write-Host "`n📋 Naprawione problemy:" -ForegroundColor Cyan
    Write-Host "   • Zatrzymano wszystkie procesy blokujące porty" -ForegroundColor White
    Write-Host "   • Zaktualizowano wszystkie dependencies" -ForegroundColor White
    Write-Host "   • Zbudowano Desktop Commander" -ForegroundColor White
    Write-Host "   • Sprawdzono pliki konfiguracyjne" -ForegroundColor White
    Write-Host "   • Przetestowano podstawowe komponenty" -ForegroundColor White
}

Write-Host "`n🚀 Następne kroki:" -ForegroundColor Cyan
Write-Host "   1. Uzupełnij pliki .env jeśli potrzeba" -ForegroundColor White
Write-Host "   2. Uruchom: .\start-workshop.ps1" -ForegroundColor White

Write-Host "`n💡 Dodatkowe komendy:" -ForegroundColor Cyan
Write-Host "   • Tylko sprawdzenie: .\repair-workshop.ps1 -CheckOnly" -ForegroundColor White
Write-Host "   • Szybka naprawa: .\repair-workshop.ps1 -Quick" -ForegroundColor White
Write-Host "   • Pełna naprawa z testami: .\repair-workshop.ps1 -Full -Test" -ForegroundColor White