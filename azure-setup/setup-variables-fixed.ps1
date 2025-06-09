# Poprawione zmienne środowiskowe dla warsztatu Copilot 365 MCP
# Użyj tego pliku do konfiguracji zmiennych przed uruchomieniem skryptów Azure

# ============================================================================
# KONFIGURACJA AZURE
# ============================================================================

# Podstawowe zmienne Azure
$SUBSCRIPTION_ID = "2e539821-ff47-4b8a-9f5a-200de5bb3e8d"  # Zmień jeśli potrzeba
$RESOURCE_GROUP = "copilot-mcp-workshop-rg"
$LOCATION = "West Europe"
$LOCATION_SHORT = "westeurope"
$PROJECT_NAME = "copilot-mcp"
$ENVIRONMENT = "dev"

# Poprawione nazwy zasobów (BEZ MYŚLNIKÓW!)
$AI_SERVICE_NAME = "copilotmcpdevai"         # Bez myślników - Azure AI Services
$APPINSIGHTS_NAME = "copilotmcpdevinsights"  # Bez myślników - Application Insights
$FUNCTION_APP_NAME = "copilotmcpdevfunc"     # Bez myślników - Azure Functions
$STORAGE_NAME = "copilotmcpdevst"            # Krótka nazwa bez myślników - Storage
$BOT_NAME = "copilotmcpdevbot"               # Bez myślników - Bot Service  
$REGISTRY_NAME = "copilotmcpdevacr"          # Bez myślników - Container Registry

# Eksport zmiennych środowiskowych
$env:SUBSCRIPTION_ID = $SUBSCRIPTION_ID
$env:RESOURCE_GROUP = $RESOURCE_GROUP
$env:LOCATION = $LOCATION
$env:LOCATION_SHORT = $LOCATION_SHORT
$env:PROJECT_NAME = $PROJECT_NAME
$env:ENVIRONMENT = $ENVIRONMENT
$env:AI_SERVICE_NAME = $AI_SERVICE_NAME
$env:APPINSIGHTS_NAME = $APPINSIGHTS_NAME
$env:FUNCTION_APP_NAME = $FUNCTION_APP_NAME
$env:STORAGE_NAME = $STORAGE_NAME
$env:BOT_NAME = $BOT_NAME
$env:REGISTRY_NAME = $REGISTRY_NAME

Write-Host "✅ Zmienne środowiskowe zostały ustawione:" -ForegroundColor Green
Write-Host "   Subscription ID: $SUBSCRIPTION_ID" -ForegroundColor Yellow
Write-Host "   Resource Group: $RESOURCE_GROUP" -ForegroundColor Yellow
Write-Host "   Location: $LOCATION ($LOCATION_SHORT)" -ForegroundColor Yellow
Write-Host "   Project Name: $PROJECT_NAME" -ForegroundColor Yellow
Write-Host "   Environment: $ENVIRONMENT" -ForegroundColor Yellow

Write-Host "`n📝 Poprawione nazwy zasobów (bez myślników):" -ForegroundColor Cyan
Write-Host "   AI Service: $AI_SERVICE_NAME" -ForegroundColor White
Write-Host "   App Insights: $APPINSIGHTS_NAME" -ForegroundColor White
Write-Host "   Function App: $FUNCTION_APP_NAME" -ForegroundColor White
Write-Host "   Storage: $STORAGE_NAME" -ForegroundColor White
Write-Host "   Bot Service: $BOT_NAME" -ForegroundColor White
Write-Host "   Container Registry: $REGISTRY_NAME" -ForegroundColor White

# ============================================================================
# SPRAWDZENIE WYMAGANYCH NARZĘDZI
# ============================================================================

Write-Host "`n🔍 Sprawdzanie wymaganych narzędzi..." -ForegroundColor Cyan

# Sprawdź Azure CLI
try {
    $azVersion = az version --query '"azure-cli"' -o tsv
    Write-Host "✅ Azure CLI: v$azVersion" -ForegroundColor Green
}
catch {
    Write-Host "❌ Azure CLI nie jest zainstalowane!" -ForegroundColor Red
    Write-Host "   Zainstaluj z: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" -ForegroundColor Yellow
}

# Sprawdź czy zalogowany do Azure
try {
    $currentAccount = az account show 2>$null | ConvertFrom-Json
    if ($currentAccount) {
        Write-Host "✅ Azure Account: $($currentAccount.user.name)" -ForegroundColor Green
        Write-Host "✅ Current Subscription: $($currentAccount.name)" -ForegroundColor Green
    }
    else {
        Write-Host "⚠️ Nie jesteś zalogowany do Azure" -ForegroundColor Yellow
        Write-Host "   Uruchom: az login" -ForegroundColor Cyan
    }
}
catch {
    Write-Host "⚠️ Sprawdź status logowania Azure" -ForegroundColor Yellow
}

# Sprawdź Node.js
try {
    $nodeVersion = node --version
    Write-Host "✅ Node.js: $nodeVersion" -ForegroundColor Green
}
catch {
    Write-Host "❌ Node.js nie jest zainstalowane!" -ForegroundColor Red
    Write-Host "   Zainstaluj z: https://nodejs.org/" -ForegroundColor Yellow
}

# Sprawdź npm
try {
    $npmVersion = npm --version
    Write-Host "✅ npm: v$npmVersion" -ForegroundColor Green
}
catch {
    Write-Host "❌ npm nie jest dostępne!" -ForegroundColor Red
}

# Sprawdź Python
try {
    $pythonVersion = python --version
    Write-Host "✅ Python: $pythonVersion" -ForegroundColor Green
}
catch {
    Write-Host "❌ Python nie jest zainstalowane!" -ForegroundColor Red
    Write-Host "   Zainstaluj z: https://www.python.org/downloads/" -ForegroundColor Yellow
}

# Sprawdź pip
try {
    $pipVersion = pip --version
    Write-Host "✅ pip: $pipVersion" -ForegroundColor Green
}
catch {
    Write-Host "❌ pip nie jest dostępne!" -ForegroundColor Red
}

# Sprawdź Docker (opcjonalnie)
try {
    $dockerVersion = docker --version
    Write-Host "✅ Docker: $dockerVersion" -ForegroundColor Green
}
catch {
    Write-Host "⚠️ Docker nie jest zainstalowane (opcjonalne)" -ForegroundColor Yellow
    Write-Host "   Zainstaluj z: https://docs.docker.com/desktop/windows/install/" -ForegroundColor Yellow
}

# Sprawdź PowerShell wersję
$psVersion = $PSVersionTable.PSVersion
if ($psVersion.Major -ge 7) {
    Write-Host "✅ PowerShell: $($psVersion.Major).$($psVersion.Minor)" -ForegroundColor Green
}
else {
    Write-Host "⚠️ PowerShell $($psVersion.Major).$($psVersion.Minor) - zalecana wersja 7+" -ForegroundColor Yellow
}

Write-Host "`n🚀 Gotowy do rozpoczęcia konfiguracji!" -ForegroundColor Green
Write-Host "   Następny krok: Uruchom .\setup-azure-fixed.ps1" -ForegroundColor Yellow

# ============================================================================
# DODATKOWE KOMENDY POMOCNICZE
# ============================================================================

Write-Host "`n💡 Pomocne komendy:" -ForegroundColor Cyan
Write-Host "   Diagnostyka Azure: .\diagnose-azure.ps1" -ForegroundColor White
Write-Host "   Konfiguracja Azure: .\setup-azure-fixed.ps1" -ForegroundColor White
Write-Host "   Logowanie Azure: az login" -ForegroundColor White
Write-Host "   Lista subskrypcji: az account list --output table" -ForegroundColor White
Write-Host "   Zmiana subskrypcji: az account set --subscription 'ID'" -ForegroundColor White
