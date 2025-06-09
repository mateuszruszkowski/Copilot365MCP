# 🔧 SZYBKA NAPRAWA AZURE - napraw błędy z konfiguracją
# Uruchom ten skrypt aby naprawić najczęstsze problemy

param(
    [switch]$FixSubscription,
    [switch]$FixProviders,
    [switch]$FixNames,
    [switch]$CheckStatus,
    [switch]$All
)

Write-Host "🔧 Szybka naprawa Azure dla warsztatu Copilot 365 MCP" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Green

if ($All) {
    $FixSubscription = $true
    $FixProviders = $true
    $FixNames = $true
    $CheckStatus = $true
}

# ============================================================================
# 1. NAPRAWA SUBSKRYPCJI
# ============================================================================

if ($FixSubscription -or $All) {
    Write-Host "`n1️⃣ Naprawianie subskrypcji..." -ForegroundColor Cyan
    
    # Sprawdź aktualną subskrypcję
    try {
        $currentAccount = az account show 2>$null | ConvertFrom-Json
        if ($currentAccount) {
            Write-Host "✅ Zalogowany jako: $($currentAccount.user.name)" -ForegroundColor Green
            Write-Host "✅ Aktualna subskrypcja: $($currentAccount.name)" -ForegroundColor Green
            Write-Host "✅ ID: $($currentAccount.id)" -ForegroundColor Green
        }
        else {
            Write-Host "❌ Nie jesteś zalogowany!" -ForegroundColor Red
            Write-Host "🔄 Logowanie..." -ForegroundColor Yellow
            az login
        }
    }
    catch {
        Write-Host "❌ Błąd sprawdzania subskrypcji" -ForegroundColor Red
        az login
    }
    
    # Lista dostępnych subskrypcji
    Write-Host "`n📋 Dostępne subskrypcje:" -ForegroundColor Cyan
    az account list --query "[].{Name:name, Id:id, State:state}" --output table
    
    $targetSub = "2e539821-ff47-4b8a-9f5a-200de5bb3e8d"
    $availableSubs = az account list --query "[].id" --output tsv
    
    if ($availableSubs -contains $targetSub) {
        az account set --subscription $targetSub
        Write-Host "✅ Ustawiono subskrypcję docelową" -ForegroundColor Green
    }
    else {
        Write-Host "⚠️ Docelowa subskrypcja niedostępna" -ForegroundColor Yellow
        $newSub = Read-Host "Podaj ID subskrypcji do użycia (lub Enter aby pominąć)"
        if ($newSub) {
            az account set --subscription $newSub
            Write-Host "✅ Ustawiono nową subskrypcję: $newSub" -ForegroundColor Green
            
            # Aktualizuj plik variables
            $variablesFile = "setup-variables-fixed.ps1"
            if (Test-Path $variablesFile) {
                (Get-Content $variablesFile) -replace "2e539821-ff47-4b8a-9f5a-200de5bb3e8d", $newSub | Set-Content $variablesFile
                Write-Host "✅ Zaktualizowano $variablesFile" -ForegroundColor Green
            }
        }
    }
}

# ============================================================================
# 2. NAPRAWA RESOURCE PROVIDERÓW
# ============================================================================

if ($FixProviders -or $All) {
    Write-Host "`n2️⃣ Naprawianie resource providerów..." -ForegroundColor Cyan
    
    $providers = @(
        "Microsoft.CognitiveServices",
        "microsoft.insights", 
        "microsoft.operationalinsights",
        "Microsoft.Storage",
        "Microsoft.Web",
        "Microsoft.ContainerRegistry"
    )
    
    foreach ($provider in $providers) {
        Write-Host "🔍 Sprawdzanie $provider..." -ForegroundColor Gray
        
        $status = az provider show --namespace $provider --query "registrationState" --output tsv 2>$null
        
        if ($status -eq "Registered") {
            Write-Host "✅ $provider - OK" -ForegroundColor Green
        }
        else {
            Write-Host "🔄 Rejestrowanie $provider..." -ForegroundColor Yellow
            az provider register --namespace $provider
            
            # Sprawdź status po rejestracji
            Start-Sleep 3
            $newStatus = az provider show --namespace $provider --query "registrationState" --output tsv 2>$null
            if ($newStatus -eq "Registered") {
                Write-Host "✅ $provider - zarejestrowany" -ForegroundColor Green
            }
            else {
                Write-Host "⏳ $provider - w trakcie rejestracji ($newStatus)" -ForegroundColor Yellow
            }
        }
    }
}

# ============================================================================
# 3. NAPRAWA NAZW ZASOBÓW
# ============================================================================

if ($FixNames -or $All) {
    Write-Host "`n3️⃣ Sprawdzanie nazw zasobów..." -ForegroundColor Cyan
    
    # Mapowanie starych nazw na nowe (bez myślników)
    $nameMapping = @{
        "copilot-mcp-dev-ai-service" = "copilotmcpdevai"
        "copilot-mcp-dev-ai"         = "copilotmcpdevinsights"
        "copilot-mcp-dev-mcp-func"   = "copilotmcpdevfunc"
        "copilotmcpdevst"            = "copilotmcpdevst"  # już OK
        "copilot-mcp-dev-bot"        = "copilotmcpdevbot"
        "copilotmcpdevacr"           = "copilotmcpdevacr"  # już OK
    }
    
    Write-Host "📝 Poprawne nazwy zasobów (bez myślników):" -ForegroundColor Yellow
    foreach ($oldName in $nameMapping.Keys) {
        $newName = $nameMapping[$oldName]
        if ($oldName -ne $newName) {
            Write-Host "   $oldName → $newName" -ForegroundColor White
        }
        else {
            Write-Host "   $newName ✅" -ForegroundColor Green
        }
    }
    
    Write-Host "`n💡 Zaktualizowane zmienne w setup-variables-fixed.ps1" -ForegroundColor Cyan
}

# ============================================================================
# 4. SPRAWDZENIE STATUSU
# ============================================================================

if ($CheckStatus -or $All) {
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
        Write-Host "🔄 Możesz go utworzyć uruchamiając setup-azure-fixed.ps1" -ForegroundColor Yellow
    }
    
    # Sprawdź pliki konfiguracyjne
    Write-Host "`n📁 Pliki konfiguracyjne:" -ForegroundColor Cyan
    
    $configFiles = @(
        "ai-config.env",
        "setup-variables-fixed.ps1",
        "setup-azure-fixed.ps1"
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
}

# ============================================================================
# 5. REKOMENDACJE
# ============================================================================

Write-Host "`n💡 Rekomendacje:" -ForegroundColor Cyan

Write-Host "📝 1. Użyj poprawionych plików:" -ForegroundColor Yellow
Write-Host "   • setup-variables-fixed.ps1 (zamiast setup-variables.ps1)" -ForegroundColor White
Write-Host "   • setup-azure-fixed.ps1 (zamiast setup-azure.ps1)" -ForegroundColor White

Write-Host "`n🔧 2. Komendy naprawcze:" -ForegroundColor Yellow
Write-Host "   • Diagnostyka: .\diagnose-azure.ps1" -ForegroundColor White
Write-Host "   • Setup zmiennych: .\setup-variables-fixed.ps1" -ForegroundColor White
Write-Host "   • Setup Azure: .\setup-azure-fixed.ps1" -ForegroundColor White

Write-Host "`n🚀 3. Pełny setup od nowa:" -ForegroundColor Yellow
Write-Host "   .\setup-variables-fixed.ps1" -ForegroundColor White
Write-Host "   .\setup-azure-fixed.ps1" -ForegroundColor White

Write-Host "`n⚡ 4. Szybki test:" -ForegroundColor Yellow
Write-Host "   curl https://copilotmcpdevfunc.azurewebsites.net/api/McpServer" -ForegroundColor White

Write-Host "`n✅ Naprawa zakończona!" -ForegroundColor Green

# ============================================================================
# PARAMETRY POMOCY
# ============================================================================

if (-not ($FixSubscription -or $FixProviders -or $FixNames -or $CheckStatus -or $All)) {
    Write-Host "`n❓ Użycie:" -ForegroundColor Cyan
    Write-Host "   .\quick-fix-azure.ps1 -All              # Napraw wszystko" -ForegroundColor White
    Write-Host "   .\quick-fix-azure.ps1 -FixSubscription  # Napraw subskrypcję" -ForegroundColor White
    Write-Host "   .\quick-fix-azure.ps1 -FixProviders     # Napraw providerów" -ForegroundColor White
    Write-Host "   .\quick-fix-azure.ps1 -FixNames         # Sprawdź nazwy" -ForegroundColor White
    Write-Host "   .\quick-fix-azure.ps1 -CheckStatus      # Sprawdź status" -ForegroundColor White
}
