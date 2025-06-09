# Skrypt konfiguracji infrastruktury Azure dla warsztatu Copilot 365 MCP
# Uruchom jako Administrator w PowerShell
# Przed uruchomieniem: .\setup-variables.ps1

param(
    [switch]$Force,
    [switch]$SkipLogin
)

# Import zmiennych środowiskowych
if (-not $env:SUBSCRIPTION_ID) {
    Write-Host "❌ Zmienne środowiskowe nie są ustawione!" -ForegroundColor Red
    Write-Host "   Uruchom najpierw: .\setup-variables.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host "🚀 Rozpoczęcie konfiguracji Azure dla warsztatu Copilot 365 MCP" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green

# ============================================================================
# LOGOWANIE DO AZURE
# ============================================================================

if (-not $SkipLogin) {
    Write-Host "`n🔑 Logowanie do Azure..." -ForegroundColor Cyan
    try {
        az login
        az account set --subscription $env:SUBSCRIPTION_ID
        $currentSub = az account show --query name -o tsv
        Write-Host "✅ Zalogowano do subskrypcji: $currentSub" -ForegroundColor Green
    } catch {
        Write-Host "❌ Błąd logowania do Azure!" -ForegroundColor Red
        exit 1
    }
}

# ============================================================================
# TWORZENIE GRUPY ZASOBÓW
# ============================================================================

Write-Host "`n📦 Tworzenie grupy zasobów..." -ForegroundColor Cyan

$existingRG = az group exists --name $env:RESOURCE_GROUP
if ($existingRG -eq "true" -and -not $Force) {
    Write-Host "⚠️  Grupa zasobów $env:RESOURCE_GROUP już istnieje!" -ForegroundColor Yellow
    $continue = Read-Host "Czy chcesz kontynuować? (y/N)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        Write-Host "❌ Anulowano przez użytkownika" -ForegroundColor Red
        exit 1
    }
}

try {
    az group create `
        --name $env:RESOURCE_GROUP `
        --location $env:LOCATION `
        --tags Environment=$env:ENVIRONMENT Project=$env:PROJECT_NAME Workshop=Copilot365MCP
    Write-Host "✅ Grupa zasobów utworzona: $env:RESOURCE_GROUP" -ForegroundColor Green
} catch {
    Write-Host "❌ Błąd tworzenia grupy zasobów!" -ForegroundColor Red
    exit 1
}

# ============================================================================
# AZURE AI SERVICES
# ============================================================================

Write-Host "`n🧠 Tworzenie Azure AI Services..." -ForegroundColor Cyan

try {
    $aiServiceResult = az cognitiveservices account create `
        --name $env:AI_SERVICE_NAME `
        --resource-group $env:RESOURCE_GROUP `
        --kind CognitiveServices `
        --sku S0 `
        --location $env:LOCATION `
        --tags Environment=$env:ENVIRONMENT Project=$env:PROJECT_NAME `
        --yes | ConvertFrom-Json

    if ($aiServiceResult) {
        Write-Host "✅ Azure AI Services utworzony: $env:AI_SERVICE_NAME" -ForegroundColor Green
        
        # Pobierz endpoint i klucz
        $AI_ENDPOINT = az cognitiveservices account show `
            --name $env:AI_SERVICE_NAME `
            --resource-group $env:RESOURCE_GROUP `
            --query properties.endpoint -o tsv

        $AI_KEY = az cognitiveservices account keys list `
            --name $env:AI_SERVICE_NAME `
            --resource-group $env:RESOURCE_GROUP `
            --query key1 -o tsv

        # Zapisz do pliku konfiguracyjnego
        @"
# Azure AI Services Configuration
AI_ENDPOINT=$AI_ENDPOINT
AI_KEY=$AI_KEY
AI_SERVICE_NAME=$env:AI_SERVICE_NAME
"@ | Out-File -FilePath ".\ai-config.env" -Encoding UTF8

        Write-Host "✅ Konfiguracja AI zapisana do ai-config.env" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Błąd tworzenia Azure AI Services!" -ForegroundColor Red
    Write-Host "   Sprawdź czy masz odpowiednie uprawnienia i quota" -ForegroundColor Yellow
}

# ============================================================================
# APPLICATION INSIGHTS
# ============================================================================

Write-Host "`n📊 Tworzenie Application Insights..." -ForegroundColor Cyan

try {
    # Dodaj rozszerzenie Application Insights jeśli nie ma
    az extension add --name application-insights --only-show-errors

    $appInsightsResult = az monitor app-insights component create `
        --app $env:APPINSIGHTS_NAME `
        --location $env:LOCATION `
        --resource-group $env:RESOURCE_GROUP `
        --tags Environment=$env:ENVIRONMENT Project=$env:PROJECT_NAME | ConvertFrom-Json

    if ($appInsightsResult) {
        Write-Host "✅ Application Insights utworzony: $env:APPINSIGHTS_NAME" -ForegroundColor Green
        
        $APPINSIGHTS_KEY = $appInsightsResult.instrumentationKey
        $APPINSIGHTS_CONNECTION_STRING = $appInsightsResult.connectionString

        # Dodaj do konfiguracji
        @"

# Application Insights Configuration
APPINSIGHTS_INSTRUMENTATIONKEY=$APPINSIGHTS_KEY
APPINSIGHTS_CONNECTION_STRING=$APPINSIGHTS_CONNECTION_STRING
APPINSIGHTS_NAME=$env:APPINSIGHTS_NAME
"@ | Add-Content -Path ".\ai-config.env" -Encoding UTF8

        Write-Host "✅ Konfiguracja Application Insights dodana" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Błąd tworzenia Application Insights!" -ForegroundColor Red
}

# ============================================================================
# STORAGE ACCOUNT
# ============================================================================

Write-Host "`n💾 Tworzenie Storage Account..." -ForegroundColor Cyan

try {
    $storageResult = az storage account create `
        --name $env:STORAGE_NAME `
        --resource-group $env:RESOURCE_GROUP `
        --location $env:LOCATION `
        --sku Standard_LRS `
        --tags Environment=$env:ENVIRONMENT Project=$env:PROJECT_NAME | ConvertFrom-Json

    if ($storageResult) {
        Write-Host "✅ Storage Account utworzony: $env:STORAGE_NAME" -ForegroundColor Green
        
        $STORAGE_CONNECTION_STRING = az storage account show-connection-string `
            --name $env:STORAGE_NAME `
            --resource-group $env:RESOURCE_GROUP `
            --query connectionString -o tsv

        # Dodaj do konfiguracji
        @"

# Storage Account Configuration
STORAGE_NAME=$env:STORAGE_NAME
STORAGE_CONNECTION_STRING=$STORAGE_CONNECTION_STRING
"@ | Add-Content -Path ".\ai-config.env" -Encoding UTF8

        Write-Host "✅ Konfiguracja Storage Account dodana" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Błąd tworzenia Storage Account!" -ForegroundColor Red
}

# ============================================================================
# AZURE FUNCTIONS
# ============================================================================

Write-Host "`n⚡ Tworzenie Azure Functions..." -ForegroundColor Cyan

try {
    $functionAppResult = az functionapp create `
        --resource-group $env:RESOURCE_GROUP `
        --consumption-plan-location $env:LOCATION `
        --runtime node `
        --runtime-version 18 `
        --functions-version 4 `
        --name $env:FUNCTION_APP_NAME `
        --storage-account $env:STORAGE_NAME `
        --app-insights $env:APPINSIGHTS_NAME `
        --tags Environment=$env:ENVIRONMENT Project=$env:PROJECT_NAME | ConvertFrom-Json

    if ($functionAppResult) {
        Write-Host "✅ Azure Functions utworzony: $env:FUNCTION_APP_NAME" -ForegroundColor Green
        
        $FUNCTION_APP_URL = $functionAppResult.defaultHostName
        
        # Dodaj do konfiguracji
        @"

# Azure Functions Configuration
FUNCTION_APP_NAME=$env:FUNCTION_APP_NAME
FUNCTION_APP_URL=https://$FUNCTION_APP_URL
MCP_ENDPOINT=https://$FUNCTION_APP_URL/api/McpServer
"@ | Add-Content -Path ".\ai-config.env" -Encoding UTF8

        Write-Host "✅ Konfiguracja Azure Functions dodana" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Błąd tworzenia Azure Functions!" -ForegroundColor Red
}

# ============================================================================
# CONTAINER REGISTRY (opcjonalnie)
# ============================================================================

Write-Host "`n🐳 Tworzenie Azure Container Registry..." -ForegroundColor Cyan

try {
    $acrResult = az acr create `
        --resource-group $env:RESOURCE_GROUP `
        --name $env:REGISTRY_NAME `
        --sku Basic `
        --location $env:LOCATION `
        --tags Environment=$env:ENVIRONMENT Project=$env:PROJECT_NAME | ConvertFrom-Json

    if ($acrResult) {
        Write-Host "✅ Azure Container Registry utworzony: $env:REGISTRY_NAME" -ForegroundColor Green
        
        # Włącz admin user
        az acr update --name $env:REGISTRY_NAME --admin-enabled true

        $ACR_LOGIN_SERVER = $acrResult.loginServer
        $acrCredentials = az acr credential show --name $env:REGISTRY_NAME | ConvertFrom-Json
        $ACR_USERNAME = $acrCredentials.username
        $ACR_PASSWORD = $acrCredentials.passwords[0].value

        # Dodaj do konfiguracji
        @"

# Azure Container Registry Configuration
REGISTRY_NAME=$env:REGISTRY_NAME
ACR_LOGIN_SERVER=$ACR_LOGIN_SERVER
ACR_USERNAME=$ACR_USERNAME
ACR_PASSWORD=$ACR_PASSWORD
"@ | Add-Content -Path ".\ai-config.env" -Encoding UTF8

        Write-Host "✅ Konfiguracja ACR dodana" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️  Nie udało się utworzyć Azure Container Registry (opcjonalne)" -ForegroundColor Yellow
}

# ============================================================================
# PODSUMOWANIE
# ============================================================================

Write-Host "`n🎉 Konfiguracja Azure zakończona!" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green

Write-Host "`n📋 Utworzone zasoby:" -ForegroundColor Cyan
Write-Host "   • Grupa zasobów: $env:RESOURCE_GROUP" -ForegroundColor White
Write-Host "   • Azure AI Services: $env:AI_SERVICE_NAME" -ForegroundColor White
Write-Host "   • Application Insights: $env:APPINSIGHTS_NAME" -ForegroundColor White
Write-Host "   • Storage Account: $env:STORAGE_NAME" -ForegroundColor White
Write-Host "   • Azure Functions: $env:FUNCTION_APP_NAME" -ForegroundColor White
Write-Host "   • Container Registry: $env:REGISTRY_NAME" -ForegroundColor White

Write-Host "`n📁 Pliki konfiguracyjne:" -ForegroundColor Cyan
Write-Host "   • ai-config.env - zawiera wszystkie klucze i endpointy" -ForegroundColor White

Write-Host "`n🔒 WAŻNE - Bezpieczeństwo:" -ForegroundColor Red
Write-Host "   • Plik ai-config.env zawiera poufne dane!" -ForegroundColor Yellow
Write-Host "   • Dodaj go do .gitignore!" -ForegroundColor Yellow
Write-Host "   • Nie udostępniaj go publicznie!" -ForegroundColor Yellow

Write-Host "`n🚀 Następne kroki:" -ForegroundColor Cyan
Write-Host "   1. Sprawdź plik ai-config.env" -ForegroundColor White
Write-Host "   2. Przejdź do katalogu mcp-servers" -ForegroundColor White
Write-Host "   3. Skonfiguruj serwery MCP" -ForegroundColor White
Write-Host "   4. Wdróż Azure Functions" -ForegroundColor White

Write-Host "`n✨ Miłego warsztatowania!" -ForegroundColor Green
