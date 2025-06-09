# Diagnostyka i naprawa problemów Azure
# Uruchom ten skrypt aby zdiagnozować i naprawić problemy

Write-Host "🔍 Diagnostyka Azure..." -ForegroundColor Cyan

# Sprawdź aktualną subskrypcję
Write-Host "`n1️⃣ Sprawdzanie subskrypcji..." -ForegroundColor Yellow
try {
    $currentAccount = az account show | ConvertFrom-Json
    if ($currentAccount) {
        Write-Host "✅ Zalogowany jako: $($currentAccount.user.name)" -ForegroundColor Green
        Write-Host "✅ Aktualna subskrypcja: $($currentAccount.name) ($($currentAccount.id))" -ForegroundColor Green
    }
}
catch {
    Write-Host "❌ Nie jesteś zalogowany do Azure!" -ForegroundColor Red
    Write-Host "Uruchom: az login" -ForegroundColor Yellow
    exit 1
}

# Lista dostępnych subskrypcji
Write-Host "`n📋 Dostępne subskrypcje:" -ForegroundColor Cyan
az account list --query "[].{Name:name, Id:id, State:state}" --output table

# Sprawdź czy docelowa subskrypcja istnieje
$targetSubscription = "2e539821-ff47-4b8a-9f5a-200de5bb3e8d"
$availableSubscriptions = az account list --query "[].id" --output tsv

if ($availableSubscriptions -contains $targetSubscription) {
    Write-Host "✅ Docelowa subskrypcja $targetSubscription jest dostępna" -ForegroundColor Green
    az account set --subscription $targetSubscription
}
else {
    Write-Host "❌ Subskrypcja $targetSubscription nie jest dostępna!" -ForegroundColor Red
    Write-Host "📋 Wybierz jedną z dostępnych subskrypcji:" -ForegroundColor Yellow
    az account list --query "[].{Name:name, Id:id}" --output table
    
    $selectedSub = Read-Host "Podaj ID subskrypcji do użycia"
    if ($selectedSub) {
        az account set --subscription $selectedSub
        Write-Host "✅ Ustawiono subskrypcję: $selectedSub" -ForegroundColor Green
        
        # Aktualizuj zmienne
        $env:SUBSCRIPTION_ID = $selectedSub
        Write-Host "💡 Zaktualizuj setup-variables.ps1 z nowym ID subskrypcji: $selectedSub" -ForegroundColor Yellow
    }
    else {
        Write-Host "❌ Nie wybrano subskrypcji" -ForegroundColor Red
        exit 1
    }
}

# Sprawdź i zarejestruj wymaganych resource providerów
Write-Host "`n2️⃣ Sprawdzanie resource providerów..." -ForegroundColor Yellow

$requiredProviders = @(
    "Microsoft.CognitiveServices",
    "microsoft.insights", 
    "microsoft.operationalinsights",
    "Microsoft.Storage",
    "Microsoft.Web",
    "Microsoft.ContainerRegistry"
)

foreach ($provider in $requiredProviders) {
    Write-Host "Sprawdzanie $provider..." -ForegroundColor Gray
    
    $registration = az provider show --namespace $provider --query "registrationState" --output tsv 2>$null
    
    if ($registration -eq "Registered") {
        Write-Host "✅ $provider - zarejestrowany" -ForegroundColor Green
    }
    else {
        Write-Host "🔄 Rejestrowanie $provider..." -ForegroundColor Yellow
        az provider register --namespace $provider
        Write-Host "✅ $provider - zarejestrowany" -ForegroundColor Green
    }
}

# Sprawdź dostępne lokacje
Write-Host "`n3️⃣ Sprawdzanie dostępnych lokacji..." -ForegroundColor Yellow

Write-Host "📍 Dostępne lokacje dla Azure Functions:" -ForegroundColor Cyan
az functionapp list-consumption-locations --output table

Write-Host "`n📍 Dostępne lokacje dla zasobów:" -ForegroundColor Cyan
az account list-locations --query "[?displayName].{DisplayName:displayName, Name:name}" --output table

# Sugerowane poprawki
Write-Host "`n4️⃣ Sugerowane poprawki:" -ForegroundColor Yellow

Write-Host "💡 Poprawiona konfiguracja zmiennych:" -ForegroundColor Cyan
Write-Host '$LOCATION = "West Europe"  # lub "westeurope"' -ForegroundColor White
Write-Host '$STORAGE_NAME = "copilotmcpdevst"  # bez myślników' -ForegroundColor White
Write-Host '$REGISTRY_NAME = "copilotmcpdevacr"  # bez myślników' -ForegroundColor White
Write-Host '$FUNCTION_APP_NAME = "copilotmcpdevfunc"  # bez myślników' -ForegroundColor White

Write-Host "`n🔧 Poprawione nazwy zasobów (bez myślników):" -ForegroundColor Yellow
Write-Host "Storage Account: copilotmcpdevst" -ForegroundColor White
Write-Host "Function App: copilotmcpdevfunc" -ForegroundColor White
Write-Host "Container Registry: copilotmcpdevacr" -ForegroundColor White

Write-Host "`n✅ Diagnostyka zakończona!" -ForegroundColor Green
Write-Host "🚀 Teraz możesz uruchomić poprawiony setup-azure-fixed.ps1" -ForegroundColor Cyan
