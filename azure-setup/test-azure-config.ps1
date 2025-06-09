# 🧪 Test konfiguracji Azure po setup
# Sprawdza czy wszystkie zasoby zostały poprawnie skonfigurowane

Write-Host "🧪 Test konfiguracji Azure dla warsztatu Copilot 365 MCP" -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green

$resourceGroup = "copilot-mcp-workshop-rg"
$passed = 0
$failed = 0

function Test-Resource {
    param($Name, $TestCommand, $Description)
    
    Write-Host "`n🔍 Test: $Description" -ForegroundColor Cyan
    Write-Host "   Resource: $Name" -ForegroundColor Gray
    
    try {
        $result = Invoke-Expression $TestCommand
        if ($result) {
            Write-Host "✅ PASS: $Description" -ForegroundColor Green
            $script:passed++
            return $true
        }
        else {
            Write-Host "❌ FAIL: $Description" -ForegroundColor Red
            $script:failed++
            return $false
        }
    }
    catch {
        Write-Host "❌ ERROR: $Description - $($_.Exception.Message)" -ForegroundColor Red
        $script:failed++
        return $false
    }
}

# ============================================================================
# TESTY PODSTAWOWE
# ============================================================================

Write-Host "`n1️⃣ Testy podstawowe..." -ForegroundColor Yellow

# Test 1: Azure CLI i logowanie
Test-Resource "Azure CLI" "az account show" "Azure CLI zalogowany"

# Test 2: Resource Group
Test-Resource $resourceGroup "az group show --name $resourceGroup" "Resource Group istnieje"

# Test 3: Subscription
$currentSub = az account show --query "id" -o tsv 2>$null
if ($currentSub) {
    Write-Host "✅ PASS: Subskrypcja aktywna ($currentSub)" -ForegroundColor Green
    $passed++
}
else {
    Write-Host "❌ FAIL: Brak aktywnej subskrypcji" -ForegroundColor Red
    $failed++
}

# ============================================================================
# TESTY ZASOBÓW AZURE
# ============================================================================

Write-Host "`n2️⃣ Testy zasobów Azure..." -ForegroundColor Yellow

# Zasoby do przetestowania
$resourcesToTest = @(
    @{ Name = "copilotmcpdevai"; Type = "Microsoft.CognitiveServices/accounts"; Description = "Azure AI Services" },
    @{ Name = "copilotmcpdevinsights"; Type = "microsoft.insights/components"; Description = "Application Insights" },
    @{ Name = "copilotmcpdevst"; Type = "Microsoft.Storage/storageAccounts"; Description = "Storage Account" },
    @{ Name = "copilotmcpdevfunc"; Type = "Microsoft.Web/sites"; Description = "Azure Functions" },
    @{ Name = "copilotmcpdevacr"; Type = "Microsoft.ContainerRegistry/registries"; Description = "Container Registry" }
)

foreach ($resource in $resourcesToTest) {
    $testCmd = "az resource show --name $($resource.Name) --resource-group $resourceGroup --resource-type '$($resource.Type)'"
    Test-Resource $resource.Name $testCmd $resource.Description
}

# ============================================================================
# TESTY FUNKCJONALNOŚCI
# ============================================================================

Write-Host "`n3️⃣ Testy funkcjonalności..." -ForegroundColor Yellow

# Test Azure Functions endpoint
$functionAppName = "copilotmcpdevfunc"
$functionUrl = "https://$functionAppName.azurewebsites.net"

Write-Host "`n🔍 Test: Azure Functions endpoint" -ForegroundColor Cyan
Write-Host "   URL: $functionUrl" -ForegroundColor Gray

try {
    $response = Invoke-WebRequest -Uri $functionUrl -TimeoutSec 10 -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ PASS: Azure Functions endpoint odpowiada" -ForegroundColor Green
        $passed++
    }
    else {
        Write-Host "❌ FAIL: Azure Functions endpoint - status $($response.StatusCode)" -ForegroundColor Red
        $failed++
    }
}
catch {
    Write-Host "⚠️ WARNING: Azure Functions endpoint niedostępny (może być wyłączony)" -ForegroundColor Yellow
    Write-Host "   Błąd: $($_.Exception.Message)" -ForegroundColor Gray
}

# Test MCP endpoint
$mcpUrl = "$functionUrl/api/McpServer"

Write-Host "`n🔍 Test: MCP endpoint" -ForegroundColor Cyan
Write-Host "   URL: $mcpUrl" -ForegroundColor Gray

try {
    $headers = @{ "Content-Type" = "application/json" }
    $body = @{
        jsonrpc = "2.0"
        method  = "tools/list"
        id      = 1
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri $mcpUrl -Method POST -Body $body -Headers $headers -TimeoutSec 10
    if ($response.result) {
        Write-Host "✅ PASS: MCP endpoint działa" -ForegroundColor Green
        Write-Host "   Znalezione tools: $($response.result.tools.Count)" -ForegroundColor Gray
        $passed++
    }
    else {
        Write-Host "❌ FAIL: MCP endpoint nie zwraca prawidłowej odpowiedzi" -ForegroundColor Red
        $failed++
    }
}
catch {
    Write-Host "⚠️ WARNING: MCP endpoint niedostępny (może wymagać deployment)" -ForegroundColor Yellow
    Write-Host "   Błąd: $($_.Exception.Message)" -ForegroundColor Gray
}

# ============================================================================
# TESTY PLIKÓW KONFIGURACYJNYCH
# ============================================================================

Write-Host "`n4️⃣ Testy plików konfiguracyjnych..." -ForegroundColor Yellow

$configFiles = @(
    "ai-config.env",
    "setup-variables-fixed.ps1",
    "setup-azure-fixed.ps1"
)

foreach ($file in $configFiles) {
    if (Test-Path $file) {
        Write-Host "✅ PASS: Plik $file istnieje" -ForegroundColor Green
        $passed++
    }
    else {
        Write-Host "❌ FAIL: Plik $file nie istnieje" -ForegroundColor Red
        $failed++
    }
}

# Test zawartości ai-config.env
if (Test-Path "ai-config.env") {
    $configContent = Get-Content "ai-config.env" -Raw
    $requiredKeys = @("AI_ENDPOINT", "AI_KEY", "STORAGE_CONNECTION_STRING")
    
    foreach ($key in $requiredKeys) {
        if ($configContent -match $key) {
            Write-Host "✅ PASS: Klucz $key obecny w konfiguracji" -ForegroundColor Green
            $passed++
        }
        else {
            Write-Host "❌ FAIL: Brak klucza $key w konfiguracji" -ForegroundColor Red
            $failed++
        }
    }
}

# ============================================================================
# TESTY RESOURCE PROVIDERÓW
# ============================================================================

Write-Host "`n5️⃣ Testy resource providerów..." -ForegroundColor Yellow

$providers = @(
    "Microsoft.CognitiveServices",
    "microsoft.insights",
    "Microsoft.Storage",
    "Microsoft.Web"
)

foreach ($provider in $providers) {
    $status = az provider show --namespace $provider --query "registrationState" --output tsv 2>$null
    if ($status -eq "Registered") {
        Write-Host "✅ PASS: Provider $provider zarejestrowany" -ForegroundColor Green
        $passed++
    }
    else {
        Write-Host "❌ FAIL: Provider $provider nie zarejestrowany ($status)" -ForegroundColor Red
        $failed++
    }
}

# ============================================================================
# PODSUMOWANIE
# ============================================================================

Write-Host "`n📊 PODSUMOWANIE TESTÓW" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan

$total = $passed + $failed
$successRate = if ($total -gt 0) { [math]::Round(($passed / $total) * 100, 1) } else { 0 }

Write-Host "`n📈 Wyniki:" -ForegroundColor White
Write-Host "   ✅ Pomyślne: $passed" -ForegroundColor Green
Write-Host "   ❌ Nieudane: $failed" -ForegroundColor Red
Write-Host "   📊 Łącznie: $total" -ForegroundColor White
Write-Host "   🎯 Sukces: $successRate%" -ForegroundColor $(if ($successRate -ge 80) { "Green" } elseif ($successRate -ge 60) { "Yellow" } else { "Red" })

if ($failed -eq 0) {
    Write-Host "`n🎉 WSZYSTKIE TESTY PRZESZŁY!" -ForegroundColor Green
    Write-Host "✅ Konfiguracja Azure jest gotowa do warsztatu!" -ForegroundColor Green
}
elseif ($failed -le 2) {
    Write-Host "`n⚠️ WIĘKSZOŚĆ TESTÓW PRZESZŁA" -ForegroundColor Yellow
    Write-Host "💡 Sprawdź nieudane testy i popraw jeśli potrzeba" -ForegroundColor Yellow
}
else {
    Write-Host "`n❌ WIELE TESTÓW NIE POWIODŁO SIĘ" -ForegroundColor Red
    Write-Host "🔧 Uruchom quick-fix-azure.ps1 -All aby naprawić problemy" -ForegroundColor Yellow
}

Write-Host "`n🚀 Następne kroki:" -ForegroundColor Cyan
if ($failed -gt 0) {
    Write-Host "   1. Uruchom: .\quick-fix-azure.ps1 -All" -ForegroundColor White
    Write-Host "   2. Ponownie: .\test-azure-config.ps1" -ForegroundColor White
    Write-Host "   3. Deploy Azure Functions: cd ..\mcp-servers\azure-function && func azure functionapp publish copilotmcpdevfunc" -ForegroundColor White
}
else {
    Write-Host "   1. Deploy Azure Functions: cd ..\mcp-servers\azure-function && func azure functionapp publish copilotmcpdevfunc" -ForegroundColor White
    Write-Host "   2. Setup Teams Bot: cd ..\teams-bot && npm start" -ForegroundColor White
    Write-Host "   3. Test MCP connections: curl $mcpUrl" -ForegroundColor White
}

Write-Host "`n🔗 Przydatne linki:" -ForegroundColor Cyan
Write-Host "   Azure Portal: https://portal.azure.com" -ForegroundColor White
Write-Host "   Resource Group: https://portal.azure.com/#@/resource/subscriptions/$currentSub/resourceGroups/$resourceGroup" -ForegroundColor White
Write-Host "   Function App: https://portal.azure.com/#@/resource/subscriptions/$currentSub/resourceGroups/$resourceGroup/providers/Microsoft.Web/sites/copilotmcpdevfunc" -ForegroundColor White

Write-Host "`n📋 Status końcowy: $(if ($failed -eq 0) { "READY ✅" } elseif ($failed -le 2) { "MOSTLY READY ⚠️" } else { "NEEDS FIXES ❌" })" -ForegroundColor $(if ($failed -eq 0) { "Green" } elseif ($failed -le 2) { "Yellow" } else { "Red" })
