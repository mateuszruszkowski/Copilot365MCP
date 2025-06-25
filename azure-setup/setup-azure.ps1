# 🚀 Kompletny skrypt konfiguracji infrastruktury Azure dla warsztatu Copilot 365 MCP
# Uruchom jako Administrator w PowerShell
# Przed uruchomieniem: .\setup-variables.ps1

param(
    [switch]$Force,
    [switch]$SkipLogin,
    [switch]$DiagnoseOnly,
    [switch]$FixProviders,
    [switch]$CheckStatus
)

# Import zmiennych środowiskowych
if (-not $env:SUBSCRIPTION_ID) {
    Write-Host "❌ Zmienne środowiskowe nie są ustawione!" -ForegroundColor Red
    Write-Host "   Uruchom najpierw: .\setup-variables.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host "🚀 Rozpoczęcie konfiguracji Azure dla warsztatu Copilot 365 MCP" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Green

# ============================================================================
# DIAGNOSTYKA
# ============================================================================

if ($DiagnoseOnly) {
    Write-Host "🔍 Tryb diagnostyki..." -ForegroundColor Cyan
    if (Test-Path ".\diagnose-azure.ps1") {
        .\diagnose-azure.ps1
    } else {
        Write-Host "❌ Brak pliku diagnose-azure.ps1" -ForegroundColor Red
    }
    exit 0
}

# ============================================================================
# SPRAWDZENIE STATUSU
# ============================================================================

if ($CheckStatus) {
    Write-Host "`n4️⃣ Sprawdzanie statusu zasobów..." -ForegroundColor Cyan
    
    $resourceGroup = "copilot-mcp-workshop-rg"
    
    # Sprawdź czy Resource Group istnieje
    $rgExists = az group exists --name $resourceGroup
    if ($rgExists -eq "true") {
        Write-Host "✅ Resource Group: $resourceGroup istnieje" -ForegroundColor Green
        
        # Lista zasobów w grupie
        Write-Host "`n📦 Zasoby w grupie:" -ForegroundColor Cyan
        az resource list --resource-group $resourceGroup --query "[].{Name:name, Type:type, Status:provisioningState}" --output table
        
    }
    else {
        Write-Host "❌ Resource Group: $resourceGroup nie istnieje" -ForegroundColor Red
        Write-Host "🔄 Możesz go utworzyć uruchamiając ten skrypt bez parametru -CheckStatus" -ForegroundColor Yellow
    }
    
    # Sprawdź pliki konfiguracyjne
    Write-Host "`n📁 Pliki konfiguracyjne:" -ForegroundColor Cyan
    
    $configFiles = @(
        "ai-config.env",
        "setup-variables.ps1",
        "setup-azure.ps1"
    )
    
    foreach ($file in $configFiles) {
        if (Test-Path $file) {
            Write-Host "✅ $file istnieje" -ForegroundColor Green
        }
        else {
            Write-Host "❌ $file nie istnieje" -ForegroundColor Red
        }
    }
    
    # Sprawdź konfigurację AI
    if (Test-Path "ai-config.env") {
        Write-Host "`n🧠 Konfiguracja AI Services:" -ForegroundColor Cyan
        Get-Content "ai-config.env" | Where-Object { $_ -match "^[^#]" } | ForEach-Object {
            Write-Host "   $_" -ForegroundColor White
        }
    }
    
    exit 0
}

# ============================================================================
# LOGOWANIE DO AZURE I SPRAWDZENIE SUBSKRYPCJI
# ============================================================================

if (-not $SkipLogin) {
    Write-Host "`n🔑 Logowanie do Azure..." -ForegroundColor Cyan
    try {
        # Sprawdź czy już zalogowany
        $currentAccount = az account show 2>$null | ConvertFrom-Json
        if (-not $currentAccount) {
            az login
        }
        
        # Sprawdź dostępne subskrypcje
        $availableSubscriptions = az account list --query "[].id" --output tsv
        
        if ($availableSubscriptions -contains $env:SUBSCRIPTION_ID) {
            az account set --subscription $env:SUBSCRIPTION_ID
            $currentSub = az account show --query name -o tsv
            Write-Host "✅ Zalogowano do subskrypcji: $currentSub" -ForegroundColor Green
        }
        else {
            Write-Host "❌ Subskrypcja $env:SUBSCRIPTION_ID nie jest dostępna!" -ForegroundColor Red
            Write-Host "📋 Dostępne subskrypcje:" -ForegroundColor Yellow
            az account list --query "[].{Name:name, Id:id}" --output table
            
            $selectedSub = Read-Host "Podaj ID subskrypcji do użycia (lub Enter aby anulować)"
            if ($selectedSub) {
                $env:SUBSCRIPTION_ID = $selectedSub
                az account set --subscription $selectedSub
                Write-Host "✅ Ustawiono subskrypcję: $selectedSub" -ForegroundColor Green
                
                # Aktualizuj plik variables
                $variablesFile = "setup-variables.ps1"
                if (Test-Path $variablesFile) {
                    (Get-Content $variablesFile) -replace "SUBSCRIPTION_ID = .*", "SUBSCRIPTION_ID = `"$selectedSub`"" | Set-Content $variablesFile
                    Write-Host "✅ Zaktualizowano $variablesFile" -ForegroundColor Green
                }
            }
            else {
                Write-Host "❌ Anulowano przez użytkownika" -ForegroundColor Red
                exit 1
            }
        }
    }
    catch {
        Write-Host "❌ Błąd logowania do Azure!" -ForegroundColor Red
        exit 1
    }
}

# ============================================================================
# REJESTRACJA RESOURCE PROVIDERÓW
# ============================================================================

Write-Host "`n🔧 Rejestracja resource providerów..." -ForegroundColor Cyan

$requiredProviders = @(
    "Microsoft.CognitiveServices",
    "microsoft.insights", 
    "microsoft.operationalinsights",
    "Microsoft.Storage",
    "Microsoft.Web",
    "Microsoft.ContainerRegistry"
)

foreach ($provider in $requiredProviders) {
    try {
        $registration = az provider show --namespace $provider --query "registrationState" --output tsv 2>$null
        
        if ($registration -eq "Registered") {
            Write-Host "✅ $provider już zarejestrowany" -ForegroundColor Green
        }
        else {
            Write-Host "🔄 Rejestrowanie $provider..." -ForegroundColor Yellow
            az provider register --namespace $provider
            
            # Czekaj na rejestrację (max 2 minuty)
            $timeout = 120
            $elapsed = 0
            do {
                Start-Sleep 5
                $elapsed += 5
                $status = az provider show --namespace $provider --query "registrationState" --output tsv 2>$null
                Write-Host "   Status: $status..." -ForegroundColor Gray
            } while ($status -ne "Registered" -and $elapsed -lt $timeout)
            
            if ($status -eq "Registered") {
                Write-Host "✅ $provider zarejestrowany pomyślnie" -ForegroundColor Green
            }
            else {
                Write-Host "⚠️ $provider może wymagać więcej czasu na rejestrację" -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Host "⚠️ Nie udało się zarejestrować $provider (może być niedostępny)" -ForegroundColor Yellow
    }
}

# Jeśli tylko naprawiamy providerów, zakończ tutaj
if ($FixProviders) {
    Write-Host "`n✅ Naprawa providerów zakończona!" -ForegroundColor Green
    exit 0
}

# ============================================================================
# POPRAWIONE NAZWY ZASOBÓW (BEZ MYŚLNIKÓW)
# ============================================================================

Write-Host "`n📝 Konfiguracja nazw zasobów..." -ForegroundColor Cyan

# Poprawione nazwy bez myślników i z odpowiednią długością
$RESOURCE_GROUP = "copilot-mcp-workshop-rg"  # Resource groups mogą mieć myślniki
$AI_SERVICE_NAME = "copilotmcpdevai"         # Bez myślników
$APPINSIGHTS_NAME = "copilotmcpdevinsights"  # Bez myślników  
$STORAGE_NAME = "copilotmcpdevst"            # Krótka nazwa, bez myślników
$FUNCTION_APP_NAME = "copilotmcpdevfunc"     # Bez myślników
$REGISTRY_NAME = "copilotmcpdevacr"          # Bez myślników

# Sprawdź lokację
$LOCATION = "West Europe"
$LOCATION_SHORT = "westeurope"

Write-Host "📍 Używana lokacja: $LOCATION ($LOCATION_SHORT)" -ForegroundColor Yellow

# ============================================================================
# TWORZENIE GRUPY ZASOBÓW
# ============================================================================

Write-Host "`n📦 Tworzenie grupy zasobów..." -ForegroundColor Cyan

$existingRG = az group exists --name $RESOURCE_GROUP
if ($existingRG -eq "true" -and -not $Force) {
    Write-Host "⚠️  Grupa zasobów $RESOURCE_GROUP już istnieje!" -ForegroundColor Yellow
    $continue = Read-Host "Czy chcesz kontynuować? (y/N)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        Write-Host "❌ Anulowano przez użytkownika" -ForegroundColor Red
        exit 1
    }
}

try {
    az group create `
        --name $RESOURCE_GROUP `
        --location $LOCATION_SHORT `
        --tags Environment=$env:ENVIRONMENT Project=$env:PROJECT_NAME Workshop=Copilot365MCP
    Write-Host "✅ Grupa zasobów utworzona: $RESOURCE_GROUP" -ForegroundColor Green
}
catch {
    Write-Host "❌ Błąd tworzenia grupy zasobów!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# ============================================================================
# AZURE AI SERVICES
# ============================================================================

Write-Host "`n🧠 Tworzenie Azure AI Services..." -ForegroundColor Cyan

try {
    $existingAI = az cognitiveservices account show --name $AI_SERVICE_NAME --resource-group $RESOURCE_GROUP 2>$null
    
    if ($existingAI) {
        Write-Host "⚠️ Azure AI Services $AI_SERVICE_NAME już istnieje" -ForegroundColor Yellow
    }
    else {
        $aiServiceResult = az cognitiveservices account create `
            --name $AI_SERVICE_NAME `
            --resource-group $RESOURCE_GROUP `
            --kind CognitiveServices `
            --sku S0 `
            --location $LOCATION_SHORT `
            --tags Environment=$env:ENVIRONMENT Project=$env:PROJECT_NAME `
            --yes | ConvertFrom-Json

        Write-Host "✅ Azure AI Services utworzony: $AI_SERVICE_NAME" -ForegroundColor Green
    }
    
    # Pobierz endpoint i klucz
    $AI_ENDPOINT = az cognitiveservices account show `
        --name $AI_SERVICE_NAME `
        --resource-group $RESOURCE_GROUP `
        --query properties.endpoint -o tsv

    $AI_KEY = az cognitiveservices account keys list `
        --name $AI_SERVICE_NAME `
        --resource-group $RESOURCE_GROUP `
        --query key1 -o tsv

    # Zapisz do pliku konfiguracyjnego
    @"
# Azure AI Services Configuration
AI_ENDPOINT=$AI_ENDPOINT
AI_KEY=$AI_KEY
AI_SERVICE_NAME=$AI_SERVICE_NAME
"@ | Out-File -FilePath ".\ai-config.env" -Encoding UTF8

    Write-Host "✅ Konfiguracja AI zapisana do ai-config.env" -ForegroundColor Green

}
catch {
    Write-Host "❌ Błąd tworzenia Azure AI Services!" -ForegroundColor Red
    Write-Host "   Sprawdź czy masz odpowiednie uprawnienia i quota" -ForegroundColor Yellow
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

# ============================================================================
# APPLICATION INSIGHTS (z poprawką dla resource providerów)
# ============================================================================

Write-Host "`n📊 Tworzenie Application Insights..." -ForegroundColor Cyan

try {
    # Sprawdź czy extension jest zainstalowany
    $extensionCheck = az extension list --query "[?name=='application-insights'].name" -o tsv
    if (-not $extensionCheck) {
        Write-Host "🔧 Instalowanie rozszerzenia application-insights..." -ForegroundColor Yellow
        az extension add --name application-insights --only-show-errors
    }

    $existingAppInsights = az monitor app-insights component show --app $APPINSIGHTS_NAME --resource-group $RESOURCE_GROUP 2>$null
    
    if ($existingAppInsights) {
        Write-Host "⚠️ Application Insights $APPINSIGHTS_NAME już istnieje" -ForegroundColor Yellow
        $appInsightsData = $existingAppInsights | ConvertFrom-Json
    }
    else {
        $appInsightsResult = az monitor app-insights component create `
            --app $APPINSIGHTS_NAME `
            --location $LOCATION_SHORT `
            --resource-group $RESOURCE_GROUP `
            --tags Environment=$env:ENVIRONMENT Project=$env:PROJECT_NAME | ConvertFrom-Json

        Write-Host "✅ Application Insights utworzony: $APPINSIGHTS_NAME" -ForegroundColor Green
        $appInsightsData = $appInsightsResult
    }
    
    $APPINSIGHTS_KEY = $appInsightsData.instrumentationKey
    $APPINSIGHTS_CONNECTION_STRING = $appInsightsData.connectionString

    # Dodaj do konfiguracji
    @"

# Application Insights Configuration
APPINSIGHTS_INSTRUMENTATIONKEY=$APPINSIGHTS_KEY
APPINSIGHTS_CONNECTION_STRING=$APPINSIGHTS_CONNECTION_STRING
APPINSIGHTS_NAME=$APPINSIGHTS_NAME
"@ | Add-Content -Path ".\ai-config.env" -Encoding UTF8

    Write-Host "✅ Konfiguracja Application Insights dodana" -ForegroundColor Green

}
catch {
    Write-Host "⚠️ Nie udało się utworzyć Application Insights" -ForegroundColor Yellow
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "💡 Możesz kontynuować bez Application Insights" -ForegroundColor Cyan
}

# ============================================================================
# STORAGE ACCOUNT
# ============================================================================

Write-Host "`n💾 Tworzenie Storage Account..." -ForegroundColor Cyan

try {
    $existingStorage = az storage account show --name $STORAGE_NAME --resource-group $RESOURCE_GROUP 2>$null
    
    if ($existingStorage) {
        Write-Host "⚠️ Storage Account $STORAGE_NAME już istnieje" -ForegroundColor Yellow
    }
    else {
        $storageResult = az storage account create `
            --name $STORAGE_NAME `
            --resource-group $RESOURCE_GROUP `
            --location $LOCATION_SHORT `
            --sku Standard_LRS `
            --tags Environment=$env:ENVIRONMENT Project=$env:PROJECT_NAME | ConvertFrom-Json

        Write-Host "✅ Storage Account utworzony: $STORAGE_NAME" -ForegroundColor Green
    }
    
    $STORAGE_CONNECTION_STRING = az storage account show-connection-string `
        --name $STORAGE_NAME `
        --resource-group $RESOURCE_GROUP `
        --query connectionString -o tsv

    # Dodaj do konfiguracji
    @"

# Storage Account Configuration
STORAGE_NAME=$STORAGE_NAME
STORAGE_CONNECTION_STRING=$STORAGE_CONNECTION_STRING
"@ | Add-Content -Path ".\ai-config.env" -Encoding UTF8

    Write-Host "✅ Konfiguracja Storage Account dodana" -ForegroundColor Green

}
catch {
    Write-Host "❌ Błąd tworzenia Storage Account!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

# ============================================================================
# AZURE FUNCTIONS (z poprawioną lokacją)
# ============================================================================

Write-Host "`n⚡ Tworzenie Azure Functions..." -ForegroundColor Cyan

try {
    # Sprawdź dostępne lokacje dla Functions
    $functionLocations = az functionapp list-consumption-locations --query "[].name" -o tsv
    $validLocation = $LOCATION_SHORT
    
    if ($functionLocations -notcontains $LOCATION_SHORT) {
        Write-Host "⚠️ Lokacja $LOCATION_SHORT nie jest dostępna dla Azure Functions" -ForegroundColor Yellow
        $validLocation = "westeurope"  # Fallback
        Write-Host "💡 Używam lokacji fallback: $validLocation" -ForegroundColor Cyan
    }

    $existingFunction = az functionapp show --name $FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP 2>$null
    
    if ($existingFunction) {
        Write-Host "⚠️ Azure Functions $FUNCTION_APP_NAME już istnieje" -ForegroundColor Yellow
        $functionData = $existingFunction | ConvertFrom-Json
    }
    else {
        $functionAppArgs = @(
            "--resource-group", $RESOURCE_GROUP,
            "--consumption-plan-location", $validLocation,
            "--runtime", "node",
            "--runtime-version", "18",
            "--functions-version", "4",
            "--name", $FUNCTION_APP_NAME,
            "--storage-account", $STORAGE_NAME,
            "--tags", "Environment=$($env:ENVIRONMENT)", "Project=$($env:PROJECT_NAME)"
        )
        
        # Dodaj Application Insights jeśli istnieje
        if ($APPINSIGHTS_NAME) {
            $functionAppArgs += "--app-insights", $APPINSIGHTS_NAME
        }
        
        $functionAppResult = az functionapp create @functionAppArgs | ConvertFrom-Json
        Write-Host "✅ Azure Functions utworzony: $FUNCTION_APP_NAME" -ForegroundColor Green
        $functionData = $functionAppResult
    }
    
    $FUNCTION_APP_URL = $functionData.defaultHostName
    
    # Dodaj do konfiguracji
    @"

# Azure Functions Configuration
FUNCTION_APP_NAME=$FUNCTION_APP_NAME
FUNCTION_APP_URL=https://$FUNCTION_APP_URL
MCP_ENDPOINT=https://$FUNCTION_APP_URL/api/McpServer
RESOURCE_GROUP=$RESOURCE_GROUP
SUBSCRIPTION_ID=$env:SUBSCRIPTION_ID
"@ | Add-Content -Path ".\ai-config.env" -Encoding UTF8

    Write-Host "✅ Konfiguracja Azure Functions dodana" -ForegroundColor Green

}
catch {
    Write-Host "❌ Błąd tworzenia Azure Functions!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

# ============================================================================
# CONTAINER REGISTRY (z poprawioną nazwą)
# ============================================================================

Write-Host "`n🐳 Tworzenie Azure Container Registry..." -ForegroundColor Cyan

try {
    $existingACR = az acr show --name $REGISTRY_NAME --resource-group $RESOURCE_GROUP 2>$null
    
    if ($existingACR) {
        Write-Host "⚠️ Azure Container Registry $REGISTRY_NAME już istnieje" -ForegroundColor Yellow
        $acrData = $existingACR | ConvertFrom-Json
    }
    else {
        $acrResult = az acr create `
            --resource-group $RESOURCE_GROUP `
            --name $REGISTRY_NAME `
            --sku Basic `
            --location $LOCATION_SHORT `
            --tags Environment=$env:ENVIRONMENT Project=$env:PROJECT_NAME | ConvertFrom-Json

        Write-Host "✅ Azure Container Registry utworzony: $REGISTRY_NAME" -ForegroundColor Green
        $acrData = $acrResult
    }
    
    # Włącz admin user
    az acr update --name $REGISTRY_NAME --admin-enabled true | Out-Null

    $ACR_LOGIN_SERVER = $acrData.loginServer
    $acrCredentials = az acr credential show --name $REGISTRY_NAME | ConvertFrom-Json
    $ACR_USERNAME = $acrCredentials.username
    $ACR_PASSWORD = $acrCredentials.passwords[0].value

    # Dodaj do konfiguracji
    @"

# Azure Container Registry Configuration
REGISTRY_NAME=$REGISTRY_NAME
ACR_LOGIN_SERVER=$ACR_LOGIN_SERVER
ACR_USERNAME=$ACR_USERNAME
ACR_PASSWORD=$ACR_PASSWORD
"@ | Add-Content -Path ".\ai-config.env" -Encoding UTF8

    Write-Host "✅ Konfiguracja ACR dodana" -ForegroundColor Green

}
catch {
    Write-Host "⚠️ Nie udało się utworzyć Azure Container Registry" -ForegroundColor Yellow
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "💡 Container Registry jest opcjonalny dla warsztatu" -ForegroundColor Cyan
}

# ============================================================================
# PODSUMOWANIE
# ============================================================================

Write-Host "`n🎉 Konfiguracja Azure zakończona!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

Write-Host "`n📋 Utworzone zasoby:" -ForegroundColor Cyan
Write-Host "   • Grupa zasobów: $RESOURCE_GROUP" -ForegroundColor White
Write-Host "   • Azure AI Services: $AI_SERVICE_NAME" -ForegroundColor White
Write-Host "   • Application Insights: $APPINSIGHTS_NAME" -ForegroundColor White
Write-Host "   • Storage Account: $STORAGE_NAME" -ForegroundColor White
Write-Host "   • Azure Functions: $FUNCTION_APP_NAME" -ForegroundColor White
Write-Host "   • Container Registry: $REGISTRY_NAME" -ForegroundColor White

Write-Host "`n📁 Pliki konfiguracyjne:" -ForegroundColor Cyan
Write-Host "   • ai-config.env - zawiera wszystkie klucze i endpointy" -ForegroundColor White

Write-Host "`n🔗 Ważne URLe:" -ForegroundColor Cyan
if ($FUNCTION_APP_URL) {
    Write-Host "   • Azure Function: https://$FUNCTION_APP_URL" -ForegroundColor White
    Write-Host "   • MCP Endpoint: https://$FUNCTION_APP_URL/api/McpServer" -ForegroundColor White
}
if ($ACR_LOGIN_SERVER) {
    Write-Host "   • Container Registry: $ACR_LOGIN_SERVER" -ForegroundColor White
}

Write-Host "`n🔒 WAŻNE - Bezpieczeństwo:" -ForegroundColor Red
Write-Host "   • Plik ai-config.env zawiera poufne dane!" -ForegroundColor Yellow
Write-Host "   • Dodaj go do .gitignore!" -ForegroundColor Yellow
Write-Host "   • Nie udostępniaj go publicznie!" -ForegroundColor Yellow

Write-Host "`n🚀 Następne kroki:" -ForegroundColor Cyan
Write-Host "   1. Sprawdź plik ai-config.env" -ForegroundColor White
Write-Host "   2. Przejdź do katalogu mcp-servers" -ForegroundColor White
Write-Host "   3. Skonfiguruj serwery MCP" -ForegroundColor White
Write-Host "   4. Wdróż Azure Functions" -ForegroundColor White

Write-Host "`n🧪 Test konfiguracji:" -ForegroundColor Cyan
Write-Host "   .\test-azure-config.ps1" -ForegroundColor White
Write-Host "   curl https://$FUNCTION_APP_URL/api/McpServer" -ForegroundColor White

Write-Host "`n💡 Dodatkowe komendy:" -ForegroundColor Cyan
Write-Host "   • Sprawdź status: .\setup-azure.ps1 -CheckStatus" -ForegroundColor White
Write-Host "   • Napraw providerów: .\setup-azure.ps1 -FixProviders" -ForegroundColor White
Write-Host "   • Pełna reinstalacja: .\setup-azure.ps1 -Force" -ForegroundColor White

Write-Host "`n✨ Konfiguracja Azure zakończona pomyślnie!" -ForegroundColor Green