# Zmienne środowiskowe dla warsztatu Copilot 365 MCP
# Użyj tego pliku do konfiguracji zmiennych przed uruchomieniem skryptów Azure

# ============================================================================
# KONFIGURACJA AZURE
# ============================================================================

# Podstawowe zmienne Azure
$SUBSCRIPTION_ID = "2e539821-ff47-4b8a-9f5a-200de5bb3e8d"
$RESOURCE_GROUP = "copilot-mcp-workshop-rg"
$LOCATION = "West Europe"
$PROJECT_NAME = "copilot-mcp"
$ENVIRONMENT = "dev"

# Zmienne dla zasobów
$AI_SERVICE_NAME = "${PROJECT_NAME}-${ENVIRONMENT}-ai-service"
$APPINSIGHTS_NAME = "${PROJECT_NAME}-${ENVIRONMENT}-ai"
$FUNCTION_APP_NAME = "${PROJECT_NAME}-${ENVIRONMENT}-mcp-func"
$STORAGE_NAME = "${PROJECT_NAME}${ENVIRONMENT}st"
$BOT_NAME = "${PROJECT_NAME}-${ENVIRONMENT}-bot"
$REGISTRY_NAME = "${PROJECT_NAME}${ENVIRONMENT}acr"

# Eksport zmiennych środowiskowych
$env:SUBSCRIPTION_ID = $SUBSCRIPTION_ID
$env:RESOURCE_GROUP = $RESOURCE_GROUP
$env:LOCATION = $LOCATION
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
Write-Host "   Location: $LOCATION" -ForegroundColor Yellow
Write-Host "   Project Name: $PROJECT_NAME" -ForegroundColor Yellow
Write-Host "   Environment: $ENVIRONMENT" -ForegroundColor Yellow

# ============================================================================
# SPRAWDZENIE WYMAGANYCH NARZĘDZI
# ============================================================================

Write-Host "`n🔍 Sprawdzanie wymaganych narzędzi..." -ForegroundColor Cyan

# Sprawdź Azure CLI
try {
    $azVersion = az version --query '"azure-cli"' -o tsv
    Write-Host "✅ Azure CLI: v$azVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Azure CLI nie jest zainstalowane!" -ForegroundColor Red
    Write-Host "   Zainstaluj z: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" -ForegroundColor Yellow
}

# Sprawdź Node.js
try {
    $nodeVersion = node --version
    Write-Host "✅ Node.js: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Node.js nie jest zainstalowane!" -ForegroundColor Red
    Write-Host "   Zainstaluj z: https://nodejs.org/" -ForegroundColor Yellow
}

# Sprawdź npm
try {
    $npmVersion = npm --version
    Write-Host "✅ npm: v$npmVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ npm nie jest dostępne!" -ForegroundColor Red
}

# Sprawdź Python
try {
    $pythonVersion = python --version
    Write-Host "✅ Python: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Python nie jest zainstalowane!" -ForegroundColor Red
    Write-Host "   Zainstaluj z: https://www.python.org/downloads/" -ForegroundColor Yellow
}

# Sprawdź Docker
try {
    $dockerVersion = docker --version
    Write-Host "✅ Docker: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker nie jest zainstalowane!" -ForegroundColor Red
    Write-Host "   Zainstaluj z: https://docs.docker.com/desktop/windows/install/" -ForegroundColor Yellow
}

Write-Host "`n🚀 Gotowy do rozpoczęcia warsztatu!" -ForegroundColor Green
Write-Host "   Następny krok: Uruchom setup-azure.ps1" -ForegroundColor Yellow
