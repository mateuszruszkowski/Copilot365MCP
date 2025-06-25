# Deploy Azure DevOps MCP Server to Azure Function
param(
    [switch]$Force,
    [switch]$TestOnly
)

Write-Host "`n🚀 Azure DevOps MCP Function Deployment Script" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

# Check for Azure CLI
Write-Host "`n🔍 Sprawdzanie Azure CLI..." -ForegroundColor Cyan
try {
    $azVersion = az --version 2>&1
    Write-Host "✅ Azure CLI zainstalowane" -ForegroundColor Green
} catch {
    Write-Host "❌ Azure CLI nie znalezione. Zainstaluj z: https://aka.ms/installazurecli" -ForegroundColor Red
    exit 1
}

# Check for Azure Functions Core Tools
Write-Host "`n🔍 Sprawdzanie Azure Functions Core Tools..." -ForegroundColor Cyan
try {
    $funcVersion = func --version 2>&1
    Write-Host "✅ Azure Functions Core Tools: $funcVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Azure Functions Core Tools nie znalezione." -ForegroundColor Red
    Write-Host "   Zainstaluj z: npm install -g azure-functions-core-tools@4" -ForegroundColor Yellow
    exit 1
}

# Load configuration
Write-Host "`n📋 Ładowanie konfiguracji..." -ForegroundColor Cyan
$configPath = "..\..\azure-setup\ai-config.env"
if (-not (Test-Path $configPath)) {
    Write-Host "❌ Brak pliku konfiguracji. Uruchom najpierw azure-setup." -ForegroundColor Red
    exit 1
}

$config = Get-Content $configPath | ConvertFrom-StringData
$functionAppName = $config.FUNCTION_APP_NAME
$resourceGroup = $config.RESOURCE_GROUP

# Fallback to default resource group if not in config
if (-not $resourceGroup) {
    $resourceGroup = "copilot-mcp-workshop-rg"
    Write-Host "⚠️  Używam domyślnej resource group: $resourceGroup" -ForegroundColor Yellow
}

if (-not $functionAppName) {
    Write-Host "❌ Brak Function App Name w konfiguracji" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Function App: $functionAppName" -ForegroundColor Green
Write-Host "✅ Resource Group: $resourceGroup" -ForegroundColor Green

# Check Azure login
Write-Host "`n🔐 Sprawdzanie logowania Azure..." -ForegroundColor Cyan
$account = az account show 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Nie zalogowano do Azure. Logowanie..." -ForegroundColor Yellow
    az login
}

# Set correct subscription
if ($config.SUBSCRIPTION_ID) {
    Write-Host "`n🔄 Ustawianie subskrypcji..." -ForegroundColor Cyan
    az account set --subscription $config.SUBSCRIPTION_ID
    Write-Host "✅ Subskrypcja ustawiona" -ForegroundColor Green
}

# Test mode
if ($TestOnly) {
    Write-Host "`n🧪 TEST MODE - Sprawdzanie funkcji..." -ForegroundColor Yellow
    
    $testUrl = "https://$functionAppName.azurewebsites.net/api/mcp"
    Write-Host "Testing: $testUrl" -ForegroundColor Gray
    
    try {
        $response = Invoke-WebRequest -Uri $testUrl -Method OPTIONS -TimeoutSec 10
        Write-Host "✅ Funkcja odpowiada (status: $($response.StatusCode))" -ForegroundColor Green
    } catch {
        Write-Host "❌ Funkcja nie odpowiada" -ForegroundColor Red
    }
    
    Write-Host "`n🔑 Pobieranie Function Key..." -ForegroundColor Cyan
    $functionKey = az functionapp keys list --name $functionAppName --resource-group $resourceGroup --query "functionKeys.default" -o tsv
    if ($functionKey) {
        Write-Host "✅ Function Key: $functionKey" -ForegroundColor Green
    } else {
        Write-Host "❌ Nie można pobrać Function Key" -ForegroundColor Red
    }
    
    exit 0
}

# Deploy function
Write-Host "`n📦 Deploying Azure Function..." -ForegroundColor Cyan
Write-Host "To może potrwać kilka minut..." -ForegroundColor Gray

# Set app settings first
Write-Host "`n⚙️  Konfigurowanie ustawień aplikacji..." -ForegroundColor Yellow

# Get Azure DevOps config from local .env
$localEnvPath = "..\azure-devops\.env"
if (Test-Path $localEnvPath) {
    $devopsConfig = Get-Content $localEnvPath | ConvertFrom-StringData
    
    # Set app settings
    az functionapp config appsettings set `
        --name $functionAppName `
        --resource-group $resourceGroup `
        --settings `
        "AZURE_DEVOPS_ORG_URL=$($devopsConfig.AZURE_DEVOPS_ORG_URL)" `
        "AZURE_DEVOPS_PROJECT=$($devopsConfig.AZURE_DEVOPS_PROJECT)" `
        "AZURE_DEVOPS_PAT=$($devopsConfig.AZURE_DEVOPS_PAT)" | Out-Null
        
    Write-Host "✅ Ustawienia Azure DevOps skonfigurowane" -ForegroundColor Green
} else {
    Write-Host "⚠️  Brak pliku .env z konfiguracją Azure DevOps" -ForegroundColor Yellow
    Write-Host "   Skonfiguruj ręcznie w Azure Portal" -ForegroundColor Yellow
}

# Deploy the function
Write-Host "`n🚀 Wdrażanie kodu funkcji..." -ForegroundColor Cyan

$deployResult = func azure functionapp publish $functionAppName --python 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ DEPLOYMENT ZAKOŃCZONY SUKCESEM!" -ForegroundColor Green
    
    # Get function URL and key
    Write-Host "`n🔑 Pobieranie informacji o funkcji..." -ForegroundColor Cyan
    
    $functionUrl = "https://$functionAppName.azurewebsites.net/api/mcp"
    $functionKey = az functionapp keys list --name $functionAppName --resource-group $resourceGroup --query "functionKeys.default" -o tsv
    
    Write-Host "`n📋 INFORMACJE O FUNKCJI:" -ForegroundColor Green
    Write-Host "========================" -ForegroundColor Green
    Write-Host "URL: $functionUrl" -ForegroundColor Cyan
    Write-Host "Key: $functionKey" -ForegroundColor Cyan
    
    # Generate YAML for Copilot Studio
    Write-Host "`n📄 Generowanie YAML dla Copilot Studio..." -ForegroundColor Yellow
    
    & "$PSScriptRoot\..\..\scripts\generate-copilot-yaml.ps1" `
        -FunctionAppName $functionAppName `
        -FunctionKey $functionKey `
        -OutputPath "$PSScriptRoot\copilot-custom-connection.yaml"
    
    Write-Host "`n🎉 WSZYSTKO GOTOWE!" -ForegroundColor Green
    Write-Host "==================" -ForegroundColor Green
    Write-Host "`nNastępne kroki:" -ForegroundColor Yellow
    Write-Host "1. Otwórz Microsoft Copilot Studio" -ForegroundColor White
    Write-Host "2. Przejdź do Settings > Custom Connectors" -ForegroundColor White
    Write-Host "3. Import: copilot-custom-connection.yaml" -ForegroundColor White
    Write-Host "4. Test w Copilot: 'What tools do you have?'" -ForegroundColor White
    
} else {
    Write-Host "`n❌ DEPLOYMENT NIEUDANY" -ForegroundColor Red
    Write-Host "Sprawdź logi powyżej" -ForegroundColor Yellow
    
    # Show deployment output
    Write-Host "`nOutput:" -ForegroundColor Gray
    Write-Host $deployResult
}