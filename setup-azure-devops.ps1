#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Konfiguruje zmienne środowiskowe dla Azure DevOps MCP Server
.DESCRIPTION
    Ten skrypt pomoże skonfigurować połączenie z Azure DevOps poprzez
    interaktywne pytania o organizację, projekt i Personal Access Token.
.EXAMPLE
    .\setup-azure-devops.ps1
#>

param(
    [switch]$SkipPrompts,
    [string]$OrgUrl,
    [string]$Project,
    [string]$Pat
)

Write-Host @"
╔═══════════════════════════════════════════════════════════════╗
║           Azure DevOps MCP Server - Konfiguracja              ║
╚═══════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

# Funkcja do walidacji URL organizacji
function Test-AzureDevOpsOrgUrl {
    param([string]$url)
    
    if ($url -match '^https://dev\.azure\.com/[\w-]+/?$') {
        return $true
    }
    return $false
}

# Funkcja do testowania połączenia
function Test-AzureDevOpsConnection {
    param(
        [string]$orgUrl,
        [string]$pat,
        [string]$project
    )
    
    $headers = @{
        Authorization = "Basic $([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat")))"
    }
    
    try {
        # Test dostępu do organizacji
        $uri = "$orgUrl/_apis/projects?api-version=6.0"
        $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get -ErrorAction Stop
        
        # Sprawdź czy projekt istnieje
        $projectExists = $response.value | Where-Object { $_.name -eq $project }
        
        if (-not $projectExists) {
            Write-Host "⚠️  Projekt '$project' nie został znaleziony w organizacji" -ForegroundColor Yellow
            Write-Host "Dostępne projekty:" -ForegroundColor Yellow
            $response.value | ForEach-Object { Write-Host "  - $($_.name)" -ForegroundColor Gray }
            return $false
        }
        
        return $true
    }
    catch {
        Write-Host "❌ Błąd połączenia: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Zbieranie danych od użytkownika
if (-not $SkipPrompts) {
    Write-Host "`n📋 Potrzebuję kilku informacji do konfiguracji Azure DevOps:" -ForegroundColor Green
    
    # URL organizacji
    if (-not $OrgUrl) {
        do {
            Write-Host "`n1️⃣  URL Twojej organizacji Azure DevOps" -ForegroundColor Yellow
            Write-Host "   Przykład: https://dev.azure.com/mycompany" -ForegroundColor Gray
            $OrgUrl = Read-Host "   Podaj URL"
            
            if (-not (Test-AzureDevOpsOrgUrl $OrgUrl)) {
                Write-Host "   ❌ Nieprawidłowy format URL. Spróbuj ponownie." -ForegroundColor Red
                $OrgUrl = ""
            }
        } while (-not $OrgUrl)
    }
    
    # Nazwa projektu
    if (-not $Project) {
        Write-Host "`n2️⃣  Nazwa projektu w Azure DevOps" -ForegroundColor Yellow
        Write-Host "   Projekt musi już istnieć w Twojej organizacji" -ForegroundColor Gray
        $Project = Read-Host "   Podaj nazwę projektu"
    }
    
    # Personal Access Token
    if (-not $Pat) {
        Write-Host "`n3️⃣  Personal Access Token (PAT)" -ForegroundColor Yellow
        Write-Host "   Jak uzyskać PAT:" -ForegroundColor Gray
        Write-Host "   1. Przejdź do: $OrgUrl/_usersSettings/tokens" -ForegroundColor Gray
        Write-Host "   2. Kliknij '+ New Token'" -ForegroundColor Gray
        Write-Host "   3. Nadaj uprawnienia: Work Items (R/W), Build (R/E), Code (R)" -ForegroundColor Gray
        Write-Host "   4. Skopiuj wygenerowany token" -ForegroundColor Gray
        Write-Host ""
        $PatSecure = Read-Host "   Wklej PAT token" -AsSecureString
        $Pat = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($PatSecure)
        )
    }
}

# Testowanie połączenia
Write-Host "`n🔍 Testuję połączenie z Azure DevOps..." -ForegroundColor Cyan
if (Test-AzureDevOpsConnection -orgUrl $OrgUrl -pat $Pat -project $Project) {
    Write-Host "✅ Połączenie udane!" -ForegroundColor Green
} else {
    Write-Host "❌ Nie mogę połączyć się z Azure DevOps. Sprawdź dane i spróbuj ponownie." -ForegroundColor Red
    exit 1
}

# Tworzenie plików konfiguracyjnych
Write-Host "`n📝 Zapisuję konfigurację..." -ForegroundColor Cyan

# Zapisz do .env dla serwera Python
$envPath = Join-Path $PSScriptRoot "mcp-servers\azure-devops\.env"
$envContent = @"
# Azure DevOps Configuration
AZURE_DEVOPS_ORG_URL=$OrgUrl
AZURE_DEVOPS_PAT=$Pat
AZURE_DEVOPS_PROJECT=$Project

# Optional: Default values for operations
AZURE_DEVOPS_DEFAULT_WORK_ITEM_TYPE=Task
AZURE_DEVOPS_DEFAULT_AREA_PATH=$Project
AZURE_DEVOPS_DEFAULT_ITERATION_PATH=$Project
"@

# Utwórz katalog jeśli nie istnieje
$envDir = Split-Path $envPath -Parent
if (-not (Test-Path $envDir)) {
    New-Item -ItemType Directory -Path $envDir -Force | Out-Null
}

$envContent | Out-File -FilePath $envPath -Encoding UTF8 -Force
Write-Host "✅ Utworzono: $envPath" -ForegroundColor Green

# Zapisz do .ai-config.env dla głównego projektu
$aiConfigPath = Join-Path $PSScriptRoot ".ai-config.env"
$aiConfigContent = @"
# Azure DevOps Configuration
AZURE_DEVOPS_ORG_URL=$OrgUrl
AZURE_DEVOPS_PAT=$Pat
AZURE_DEVOPS_PROJECT=$Project

# Generowane automatycznie: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@

# Dodaj do istniejącego pliku lub utwórz nowy
if (Test-Path $aiConfigPath) {
    # Usuń stare wpisy Azure DevOps jeśli istnieją
    $existingContent = Get-Content $aiConfigPath | Where-Object { 
        $_ -notmatch "AZURE_DEVOPS_" -and $_.Trim() -ne ""
    }
    $finalContent = $existingContent + "`n" + $aiConfigContent
    $finalContent | Out-File -FilePath $aiConfigPath -Encoding UTF8 -Force
} else {
    $aiConfigContent | Out-File -FilePath $aiConfigPath -Encoding UTF8 -Force
}

Write-Host "✅ Zaktualizowano: $aiConfigPath" -ForegroundColor Green

# Eksportuj zmienne dla bieżącej sesji
$env:AZURE_DEVOPS_ORG_URL = $OrgUrl
$env:AZURE_DEVOPS_PAT = $Pat
$env:AZURE_DEVOPS_PROJECT = $Project

# Podsumowanie
Write-Host "`n" -NoNewline
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              ✅ Konfiguracja zakończona!                      ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Green

Write-Host "`n📋 Podsumowanie konfiguracji:" -ForegroundColor Cyan
Write-Host "   Organizacja: $OrgUrl" -ForegroundColor White
Write-Host "   Projekt:     $Project" -ForegroundColor White
Write-Host "   PAT Token:   ****$(if($Pat.Length -gt 4){$Pat.Substring($Pat.Length-4)}else{'****'})" -ForegroundColor White

Write-Host "`n🚀 Następne kroki:" -ForegroundColor Yellow
Write-Host "   1. Uruchom warsztat:     .\start-workshop.ps1" -ForegroundColor White
Write-Host "   2. Lub testuj lokalnie:  cd mcp-servers\azure-devops && python src\server.py" -ForegroundColor White

Write-Host "`n💡 Wskazówka:" -ForegroundColor Blue
Write-Host "   Możesz edytować plik .env w mcp-servers\azure-devops\" -ForegroundColor Gray
Write-Host "   aby zmienić konfigurację w przyszłości." -ForegroundColor Gray

# Test przykładowego wywołania
Write-Host "`n🧪 Test API (opcjonalny):" -ForegroundColor Cyan
$testChoice = Read-Host "Czy chcesz przetestować pobieranie work items? (T/n)"

if ($testChoice -ne 'n' -and $testChoice -ne 'N') {
    $headers = @{
        Authorization = "Basic $([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$Pat")))"
    }
    
    try {
        $uri = "$OrgUrl/$Project/_apis/wit/wiql?api-version=6.0"
        $wiql = @{
            query = "SELECT [System.Id], [System.Title], [System.State] FROM WorkItems WHERE [System.TeamProject] = '$Project' ORDER BY [System.Id] DESC"
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $wiql -ContentType "application/json"
        
        Write-Host "`n📊 Znaleziono $($response.workItems.Count) work items w projekcie" -ForegroundColor Green
        
        if ($response.workItems.Count -gt 0) {
            Write-Host "Pierwsze 5 items:" -ForegroundColor Gray
            $response.workItems | Select-Object -First 5 | ForEach-Object {
                Write-Host "  - ID: $($_.id)" -ForegroundColor Gray
            }
        }
    }
    catch {
        Write-Host "⚠️  Nie udało się pobrać work items: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host "`n✨ Gotowe! Możesz teraz używać Azure DevOps MCP Server." -ForegroundColor Green