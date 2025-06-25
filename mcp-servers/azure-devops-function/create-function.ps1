# Create Azure Function App
param(
    [switch]$Force
)

Write-Host "`nCreating Azure Function App" -ForegroundColor Green
Write-Host "===========================" -ForegroundColor Green

# Load configuration
$configPath = "..\..\azure-setup\ai-config.env"
if (-not (Test-Path $configPath)) {
    Write-Host "ERROR: Configuration file not found. Run azure-setup first." -ForegroundColor Red
    exit 1
}

$config = Get-Content $configPath | ConvertFrom-StringData
$functionAppName = $config.FUNCTION_APP_NAME
$resourceGroup = $config.RESOURCE_GROUP
$storageName = $config.STORAGE_NAME
$subscriptionId = $config.SUBSCRIPTION_ID

Write-Host "`nConfiguration:" -ForegroundColor Cyan
Write-Host "   Function App: $functionAppName" -ForegroundColor White
Write-Host "   Resource Group: $resourceGroup" -ForegroundColor White
Write-Host "   Storage: $storageName" -ForegroundColor White

# Set subscription
if ($subscriptionId) {
    Write-Host "`nSetting subscription..." -ForegroundColor Cyan
    az account set --subscription $subscriptionId
}

# Check if function already exists
Write-Host "`nChecking if function exists..." -ForegroundColor Cyan
$funcExists = az functionapp show --name $functionAppName --resource-group $resourceGroup 2>&1

if ($LASTEXITCODE -eq 0 -and -not $Force) {
    Write-Host "Function already exists!" -ForegroundColor Green
    exit 0
}

# Create function app
Write-Host "`nCreating Azure Function..." -ForegroundColor Cyan

try {
    # Python function app configuration
    $createResult = az functionapp create `
        --resource-group $resourceGroup `
        --consumption-plan-location westeurope `
        --runtime python `
        --runtime-version 3.9 `
        --functions-version 4 `
        --name $functionAppName `
        --storage-account $storageName `
        --os-type Linux

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Azure Function created successfully!" -ForegroundColor Green
        
        # Get function URL
        $functionUrl = az functionapp show --name $functionAppName --resource-group $resourceGroup --query defaultHostName -o tsv
        Write-Host "`nFunction URL: https://$functionUrl" -ForegroundColor Cyan
        
        # Update config file
        Write-Host "`nUpdating configuration..." -ForegroundColor Yellow
        
        # Read current config
        $configContent = Get-Content $configPath
        
        # Update FUNCTION_APP_URL
        $configContent = $configContent -replace 'FUNCTION_APP_URL=.*', "FUNCTION_APP_URL=https://$functionUrl"
        $configContent = $configContent -replace 'MCP_ENDPOINT=.*', "MCP_ENDPOINT=https://$functionUrl/api/mcp"
        
        # Save updated config
        $configContent | Set-Content $configPath
        
        Write-Host "Configuration updated" -ForegroundColor Green
        
        # Configure app settings
        Write-Host "`nConfiguring app settings..." -ForegroundColor Cyan
        
        # Get Azure DevOps config
        $devopsEnvPath = "..\azure-devops\.env"
        if (Test-Path $devopsEnvPath) {
            $devopsConfig = Get-Content $devopsEnvPath | ConvertFrom-StringData
            
            az functionapp config appsettings set `
                --name $functionAppName `
                --resource-group $resourceGroup `
                --settings `
                "AZURE_DEVOPS_ORG_URL=$($devopsConfig.AZURE_DEVOPS_ORG_URL)" `
                "AZURE_DEVOPS_PROJECT=$($devopsConfig.AZURE_DEVOPS_PROJECT)" `
                "AZURE_DEVOPS_PAT=$($devopsConfig.AZURE_DEVOPS_PAT)" | Out-Null
                
            Write-Host "Azure DevOps settings configured" -ForegroundColor Green
        }
        
        Write-Host "`nAZURE FUNCTION READY!" -ForegroundColor Green
        Write-Host "=====================" -ForegroundColor Green
        Write-Host "`nNext step: .\deploy.ps1" -ForegroundColor Yellow
        
    } else {
        Write-Host "ERROR: Failed to create function" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    exit 1
}