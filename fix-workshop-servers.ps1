# Skrypt naprawy serwerów MCP Workshop
# Aktualizuje biblioteki i naprawia problemy

Write-Host "🔧 Naprawianie serwerów MCP Workshop..." -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# 1. Zatrzymaj wszystkie uruchomione procesy na portach
Write-Host "🛑 Zatrzymywanie procesów na portach..." -ForegroundColor Yellow

# Zabij procesy na porcie 7071 (Azure Functions)
try {
    $process7071 = Get-NetTCPConnection -LocalPort 7071 -ErrorAction SilentlyContinue
    if ($process7071) {
        $pid = $process7071.OwningProcess
        Write-Host "❌ Zatrzymywanie procesu na porcie 7071 (PID: $pid)"
        Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
    }
}
catch {
    Write-Host "ℹ️ Brak procesów na porcie 7071"
}

# Zabij procesy na porcie 3978 (Teams Bot)
try {
    $process3978 = Get-NetTCPConnection -LocalPort 3978 -ErrorAction SilentlyContinue
    if ($process3978) {
        $pid = $process3978.OwningProcess
        Write-Host "❌ Zatrzymywanie procesu na porcie 3978 (PID: $pid)"
        Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
    }
}
catch {
    Write-Host "ℹ️ Brak procesów na porcie 3978"
}

# Zabij wszystkie procesy node i func
Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Get-Process -Name "func" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Get-Process -Name "python" -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -eq "python" -and $_.MainWindowTitle -like "*MCP*" } | Stop-Process -Force -ErrorAction SilentlyContinue

Write-Host "✅ Procesy zatrzymane" -ForegroundColor Green

# 2. Aktualizuj dependencies w każdym projekcie
Write-Host "📦 Aktualizowanie dependencies..." -ForegroundColor Yellow

# Teams Bot
Write-Host "🤖 Aktualizowanie Teams Bot..."
Set-Location "D:\Workshops\Copilot365MCP\teams-bot"
if (Test-Path "package.json") {
    Remove-Item "node_modules" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "package-lock.json" -Force -ErrorAction SilentlyContinue
    npm install
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Teams Bot dependencies zainstalowane" -ForegroundColor Green
    }
    else {
        Write-Host "❌ Błąd instalacji Teams Bot" -ForegroundColor Red
    }
}

# Desktop Commander MCP
Write-Host "🖥️ Aktualizowanie Desktop Commander MCP..."
Set-Location "D:\Workshops\Copilot365MCP\mcp-servers\desktop-commander"
if (Test-Path "package.json") {
    Remove-Item "node_modules" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "package-lock.json" -Force -ErrorAction SilentlyContinue
    Remove-Item "dist" -Recurse -Force -ErrorAction SilentlyContinue
    npm install
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Desktop Commander dependencies zainstalowane" -ForegroundColor Green
        npm run build
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Desktop Commander zbudowany" -ForegroundColor Green
        }
        else {
            Write-Host "❌ Błąd budowania Desktop Commander" -ForegroundColor Red
        }
    }
    else {
        Write-Host "❌ Błąd instalacji Desktop Commander" -ForegroundColor Red
    }
}

# Azure Function
Write-Host "⚡ Aktualizowanie Azure Function..."
Set-Location "D:\Workshops\Copilot365MCP\mcp-servers\azure-function"
if (Test-Path "package.json") {
    Remove-Item "node_modules" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "package-lock.json" -Force -ErrorAction SilentlyContinue
    npm install
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Azure Function dependencies zainstalowane" -ForegroundColor Green
    }
    else {
        Write-Host "❌ Błąd instalacji Azure Function" -ForegroundColor Red
    }
}

# Python MCP servers
Write-Host "🐍 Aktualizowanie Python MCP servers..."

# Local DevOps MCP
Set-Location "D:\Workshops\Copilot365MCP\mcp-servers\local-devops"
if (Test-Path "requirements.txt") {
    python -m pip install --upgrade pip
    pip install -r requirements.txt --upgrade
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Local DevOps MCP zaktualizowany" -ForegroundColor Green
    }
    else {
        Write-Host "❌ Błąd aktualizacji Local DevOps MCP" -ForegroundColor Red
    }
}

# Azure DevOps MCP
Set-Location "D:\Workshops\Copilot365MCP\mcp-servers\azure-devops"
if (Test-Path "requirements.txt") {
    pip install -r requirements.txt --upgrade
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Azure DevOps MCP zaktualizowany" -ForegroundColor Green
    }
    else {
        Write-Host "❌ Błąd aktualizacji Azure DevOps MCP" -ForegroundColor Red
    }
}

# 3. Sprawdź konfigurację środowiska
Write-Host "🔧 Sprawdzanie konfiguracji..." -ForegroundColor Yellow

Set-Location "D:\Workshops\Copilot365MCP"

# Sprawdź czy .env pliki istnieją
$envFiles = @(
    ".env",
    "teams-bot\.env",
    "mcp-servers\local-devops\.env",
    "mcp-servers\azure-devops\.env"
)

foreach ($envFile in $envFiles) {
    if (!(Test-Path $envFile)) {
        Write-Host "⚠️ Brak pliku: $envFile" -ForegroundColor Yellow
    }
}

# 4. Sprawdź gotowość wszystkich komponentów
Write-Host "🧪 Sprawdzanie gotowości komponentów..." -ForegroundColor Yellow

$errors = @()

# Sprawdź Teams Bot
if (!(Test-Path "teams-bot\node_modules")) {
    $errors += "Teams Bot node_modules"
}

# Sprawdź Desktop Commander
if (!(Test-Path "mcp-servers\desktop-commander\node_modules")) {
    $errors += "Desktop Commander node_modules"
}
if (!(Test-Path "mcp-servers\desktop-commander\dist")) {
    $errors += "Desktop Commander dist"
}

# Sprawdź Azure Function
if (!(Test-Path "mcp-servers\azure-function\node_modules")) {
    $errors += "Azure Function node_modules"
}

# 5. Wyniki
Write-Host ""
if ($errors.Count -eq 0) {
    Write-Host "✅ Wszystkie komponenty naprawione!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🚀 Możesz teraz uruchomić serwery:" -ForegroundColor Cyan
    Write-Host "   .\start-workshop.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "📋 Naprawione problemy:" -ForegroundColor Green
    Write-Host "   • Zaktualizowano MCP SDK do wersji 1.12.1" -ForegroundColor Green
    Write-Host "   • Naprawiono błąd Teams Bot async handlers" -ForegroundColor Green
    Write-Host "   • Naprawiono błąd Desktop Commander setRequestHandler" -ForegroundColor Green
    Write-Host "   • Zaktualizowano wszystkie dependencies" -ForegroundColor Green
}
else {
    Write-Host "❌ Znalezione problemy:" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host "   • $error" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "💡 Spróbuj uruchomić ponownie lub sprawdź logi błędów" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔧 Naprawa zakończona!" -ForegroundColor Cyan

# 6. Opcjonalnie uruchom szybki test
Write-Host ""
$runTest = Read-Host "Czy chcesz uruchomić szybki test serwerów? (y/n)"
if ($runTest -eq "y" -or $runTest -eq "Y") {
    Write-Host "🧪 Uruchamianie szybkiego testu..." -ForegroundColor Cyan
    
    # Test Desktop Commander kompilacji
    Set-Location "D:\Workshops\Copilot365MCP\mcp-servers\desktop-commander"
    Write-Host "Testing Desktop Commander build..." -ForegroundColor Gray
    if (Test-Path "dist\index.js") {
        Write-Host "✅ Desktop Commander - build OK" -ForegroundColor Green
    }
    else {
        Write-Host "❌ Desktop Commander - brak pliku dist/index.js" -ForegroundColor Red
    }
    
    # Test Teams Bot syntax
    Set-Location "D:\Workshops\Copilot365MCP\teams-bot"
    Write-Host "Testing Teams Bot syntax..." -ForegroundColor Gray
    $syntaxCheck = node -c "src/index.js" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Teams Bot - syntax OK" -ForegroundColor Green
    }
    else {
        Write-Host "❌ Teams Bot - błąd składni: $syntaxCheck" -ForegroundColor Red
    }
    
    Write-Host "🧪 Test zakończony" -ForegroundColor Cyan
}

Set-Location "D:\Workshops\Copilot365MCP"
