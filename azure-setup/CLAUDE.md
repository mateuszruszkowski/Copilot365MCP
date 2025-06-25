# CLAUDE.md - Azure Setup

## 📋 Opis modułu

Moduł `azure-setup` zawiera skrypty PowerShell do automatycznej konfiguracji infrastruktury Azure potrzebnej do uruchomienia serwera MCP jako Azure Function. Skrypty tworzą wszystkie wymagane zasoby i generują plik konfiguracyjny z kluczami dostępu.

## 🎯 Cel

Zautomatyzować proces tworzenia i konfiguracji zasobów Azure, aby uczestnicy warsztatu mogli szybko przygotować środowisko bez ręcznej konfiguracji w portalu Azure.

## 📁 Struktura plików

```
azure-setup/
├── setup-variables-fixed.ps1    # Definicje zmiennych środowiskowych
├── setup-azure-fixed.ps1        # Główny skrypt tworzący zasoby
├── test-azure-config.ps1        # Skrypt testujący konfigurację
├── quick-fix-azure.ps1          # Skrypt naprawczy
├── ai-config.env               # Wygenerowany plik z konfiguracją (gitignore)
└── CLAUDE.md                   # Ten plik
```

## 🚀 Użycie

### 1. Podstawowa konfiguracja

```powershell
# Ustaw zmienne środowiskowe
.\setup-variables-fixed.ps1

# Utwórz zasoby Azure
.\setup-azure-fixed.ps1

# Zweryfikuj konfigurację
.\test-azure-config.ps1
```

### 2. Parametry

Skrypt `setup-azure-fixed.ps1` akceptuje parametry:
- `-Force` - wymusza recreację istniejących zasobów
- `-SkipLogin` - pomija logowanie do Azure (gdy już zalogowany)

## 🔧 Tworzone zasoby

### Wymagane dla Azure DevOps MCP:
1. **Resource Group** (`mcp-devops-workshop-rg`)
   - Kontener dla wszystkich zasobów
   - Lokalizacja: West Europe

2. **Storage Account** (`mcpdevopsst`)
   - Wymagany dla Azure Functions
   - Typ: Standard_LRS
   - Przechowuje logi i stan funkcji

3. **Function App** (`mcpdevopsfunc`)
   - Hosting dla serwera MCP
   - Runtime: Node.js 18
   - Plan: Consumption (serverless)

### Opcjonalne (dla przyszłych warsztatów):
- **Application Insights** - monitoring i logi
- **Azure AI Services** - dla integracji AI
- **Container Registry** - dla kontenerów Docker

## 📝 Generowany plik konfiguracyjny

Skrypt tworzy plik `ai-config.env`:

```env
# Azure Resources
AZURE_SUBSCRIPTION_ID=your-subscription-id
RESOURCE_GROUP=mcp-devops-workshop-rg
LOCATION=westeurope

# Function App
FUNCTION_APP_NAME=mcpdevopsfunc
FUNCTION_APP_URL=https://mcpdevopsfunc.azurewebsites.net
FUNCTION_APP_KEY=generated-key

# Storage
STORAGE_NAME=mcpdevopsst
STORAGE_CONNECTION_STRING=DefaultEndpointsProtocol=https;...

# Application Insights (opcjonalne)
APPINSIGHTS_KEY=your-key
APPINSIGHTS_CONNECTION_STRING=InstrumentationKey=...
```

## 🛠️ Rozwiązywanie problemów

### Problem: "Resource already exists"
```powershell
# Użyj flagi -Force aby nadpisać
.\setup-azure-fixed.ps1 -Force
```

### Problem: "Not logged into Azure"
```powershell
# Zaloguj się do Azure
az login

# Ustaw właściwą subskrypcję
az account set --subscription "your-subscription-id"
```

### Problem: "Insufficient permissions"
- Upewnij się że masz rolę Contributor lub Owner w subskrypcji
- Sprawdź czy organizacja nie ma polityk blokujących tworzenie zasobów

## 🔍 Weryfikacja

Skrypt `test-azure-config.ps1` sprawdza:
- ✅ Czy wszystkie zasoby zostały utworzone
- ✅ Czy klucze API są poprawne
- ✅ Czy Function App odpowiada
- ✅ Czy Storage Account jest dostępny

## 💡 Wskazówki

1. **Nazewnictwo zasobów**
   - Używaj spójnej konwencji nazw
   - Storage Account może mieć tylko małe litery i cyfry
   - Function App musi mieć globalnie unikalną nazwę

2. **Regiony**
   - Wybierz region blisko uczestników
   - West Europe jest domyślny dla warsztatów w EU
   - Sprawdź dostępność usług w wybranym regionie

3. **Koszty**
   - Consumption Plan jest najtańszy dla warsztatów
   - Pamiętaj o usunięciu Resource Group po warsztacie
   - Monitoruj użycie w Azure Portal

## 🧹 Czyszczenie

Po zakończeniu warsztatu usuń wszystkie zasoby:

```powershell
# Usuń całą grupę zasobów
az group delete --name mcp-devops-workshop-rg --yes --no-wait

# Lub użyj portalu Azure
```

## 📊 Estymowane koszty

Dla typowego warsztatu (8h):
- Function App (Consumption): ~$0.10
- Storage Account: ~$0.05
- Application Insights: ~$0.00 (w ramach free tier)
- **Suma**: < $1 na uczestnika

## 🔒 Bezpieczeństwo

- Nigdy nie commituj pliku `ai-config.env`
- Używaj Azure Key Vault dla produkcji
- Regularnie rotuj klucze dostępu
- Ogranicz uprawnienia do minimum

## 📚 Dodatkowe zasoby

- [Azure Functions dokumentacja](https://docs.microsoft.com/azure/azure-functions/)
- [Azure CLI reference](https://docs.microsoft.com/cli/azure/)
- [PowerShell dla Azure](https://docs.microsoft.com/powershell/azure/)

---
*Moduł jest częścią warsztatu Copilot 365 MCP*