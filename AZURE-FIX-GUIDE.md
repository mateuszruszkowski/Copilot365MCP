# 🔥 INSTRUKCJA NAPRAWY PROBLEMÓW AZURE

## ❌ Problemy które napotkałeś:

1. **Subscription not found** - błędne ID subskrypcji
2. **Resource provider not registered** - brak rejestracji providerów
3. **Invalid location** - nieprawidłowa lokacja dla Azure Functions  
4. **Registry name cannot contain dashes** - myślniki w nazwach

## ✅ ROZWIĄZANIE - 3 kroki:

### 🔧 Krok 1: Diagnostyka (30 sekund)
```powershell
cd D:\Workshops\Copilot365MCP\azure-setup
.\diagnose-azure.ps1
```

### 🚀 Krok 2: Szybka naprawa (2 minuty)
```powershell
# Napraw wszystko automatycznie
.\quick-fix-azure.ps1 -All

# Lub wybiórczo:
.\quick-fix-azure.ps1 -FixSubscription  # Napraw subskrypcję
.\quick-fix-azure.ps1 -FixProviders     # Zarejestruj providerów
```

### ⚡ Krok 3: Pełny setup z poprawkami (5 minut)
```powershell
# Użyj POPRAWIONYCH plików:
.\setup-variables-fixed.ps1    # ← NOWY plik (bez myślników w nazwach)
.\setup-azure-fixed.ps1        # ← NOWY plik (z poprawkami błędów)
```

## 🧪 Test po naprawie:
```powershell
.\test-azure-config.ps1
```

## 📋 Co zostało poprawione:

### ✅ Nazwy zasobów (BEZ myślników):
- ❌ `copilot-mcp-dev-ai-service` → ✅ `copilotmcpdevai`
- ❌ `copilot-mcp-dev-mcp-func` → ✅ `copilotmcpdevfunc`  
- ❌ `copilot-mcp-dev-ai` → ✅ `copilotmcpdevinsights`
- ✅ `copilotmcpdevst` (już OK)
- ✅ `copilotmcpdevacr` (już OK)

### ✅ Resource Providers (automatyczna rejestracja):
- `Microsoft.CognitiveServices`
- `microsoft.insights`
- `microsoft.operationalinsights`  
- `Microsoft.Storage`
- `Microsoft.Web`
- `Microsoft.ContainerRegistry`

### ✅ Subskrypcja (automatyczne sprawdzenie):
- Sprawdza dostępne subskrypcje
- Pozwala wybrać właściwą
- Aktualizuje konfigurację

### ✅ Lokacja (poprawiona):
- Sprawdza dostępne lokacje dla Azure Functions
- Używa `westeurope` jako fallback
- Rozróżnia `"West Europe"` i `"westeurope"`

## 🎯 SZYBKA ŚCIEŻKA (jeśli chcesz od razu działać):

```powershell
# 1. Przejdź do katalogu
cd D:\Workshops\Copilot365MCP\azure-setup

# 2. JEDNĄ komendą napraw wszystko
.\quick-fix-azure.ps1 -All

# 3. Setup z poprawnymi plikami
.\setup-variables-fixed.ps1
.\setup-azure-fixed.ps1

# 4. Test
.\test-azure-config.ps1
```

## 📁 Nowe pliki (używaj tych zamiast starych):

### ✅ UŻYWAJ TYCH:
- `setup-variables-fixed.ps1` ← **Nowy**, zamiast `setup-variables.ps1`
- `setup-azure-fixed.ps1` ← **Nowy**, zamiast `setup-azure.ps1`  
- `diagnose-azure.ps1` ← **Nowy**, diagnostyka
- `quick-fix-azure.ps1` ← **Nowy**, szybkie naprawy
- `test-azure-config.ps1` ← **Nowy**, test konfiguracji

### ❌ NIE UŻYWAJ (stare pliki z błędami):
- ~~`setup-variables.ps1`~~ 
- ~~`setup-azure.ps1`~~

## 🚨 Jeśli nadal problemy:

### Problem: Nadal "Subscription not found"
```powershell
az login
az account list --output table
# Wybierz właściwą subskrypcję z listy
az account set --subscription "CORRECT-SUBSCRIPTION-ID"
```

### Problem: "Provider registration failed"  
```powershell
# Ręczna rejestracja
az provider register --namespace Microsoft.CognitiveServices
az provider register --namespace microsoft.insights
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.Web
```

### Problem: "Location invalid"
```powershell
# Zobacz dostępne lokacje
az functionapp list-consumption-locations --output table
# Użyj jednej z nich w setup-variables-fixed.ps1
```

## ✅ Oczekiwany rezultat:

Po naprawie powinieneś zobaczyć:
```
🎉 Konfiguracja Azure zakończona!
📋 Utworzone zasoby:
   • Grupa zasobów: copilot-mcp-workshop-rg
   • Azure AI Services: copilotmcpdevai
   • Application Insights: copilotmcpdevinsights  
   • Storage Account: copilotmcpdevst
   • Azure Functions: copilotmcpdevfunc
   • Container Registry: copilotmcpdevacr
```

## 🎯 Po udanej naprawie:

1. **Deploy Azure Functions**:
   ```bash
   cd ..\mcp-servers\azure-function
   func azure functionapp publish copilotmcpdevfunc
   ```

2. **Test MCP endpoint**:
   ```bash
   curl https://copilotmcpdevfunc.azurewebsites.net/api/McpServer
   ```

3. **Kontynuuj warsztat** 🚀

---

*💡 **Tip**: Poprawione pliki mają sufiks `-fixed` - używaj tylko ich!*
