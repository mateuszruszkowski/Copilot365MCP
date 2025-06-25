# Azure DevOps MCP Server - Azure Function

Ten folder zawiera wersję serwera MCP dla Azure DevOps przygotowaną do wdrożenia jako Azure Function.

## 📋 Opis

Serwer MCP implementuje protokół Model Context Protocol dla integracji z Azure DevOps, umożliwiając:
- Zarządzanie work items (tworzenie, aktualizacja, listowanie)
- Uruchamianie i monitorowanie pipeline'ów
- Integrację z Microsoft Copilot Studio przez HTTP API

## 🚀 Szybki start

### 1. Wymagania
- Python 3.8+
- Azure CLI
- Azure Functions Core Tools v4
- Konto Azure z aktywną subskrypcją

### 2. Deployment

```powershell
# Deploy do Azure
.\deploy.ps1

# Tylko test połączenia
.\deploy.ps1 -TestOnly
```

### 3. Lokalne testowanie

```bash
# Zainstaluj zależności
pip install -r requirements.txt

# Uruchom lokalnie
func start
```

## 🛠️ Struktura

```
azure-devops-function/
├── __init__.py          # Główny kod funkcji
├── function.json        # Konfiguracja Azure Function
├── requirements.txt     # Zależności Python
├── host.json           # Konfiguracja hosta
├── deploy.ps1          # Skrypt deployment
└── README.md           # Ten plik
```

## 📡 API Endpoints

### POST /api/mcp

Główny endpoint MCP obsługujący następujące metody:

#### `tools/list`
Zwraca listę dostępnych narzędzi.

```json
{
  "method": "tools/list",
  "params": {}
}
```

#### `tools/call`
Wykonuje wybrane narzędzie.

```json
{
  "method": "tools/call",
  "params": {
    "name": "list_work_items",
    "arguments": {
      "project": "MyProject",
      "limit": 10
    }
  }
}
```

## 🔧 Dostępne narzędzia

### 1. `list_work_items`
Lista work items z projektu.

Parametry:
- `project` (string, required) - nazwa projektu
- `query` (string, optional) - zapytanie WIQL
- `limit` (integer, optional) - maksymalna liczba wyników

### 2. `get_work_item`
Pobiera szczegóły work item.

Parametry:
- `id` (integer, required) - ID work item

### 3. `create_work_item`
Tworzy nowy work item.

Parametry:
- `project` (string, required) - nazwa projektu
- `type` (string, required) - typ (Task, Bug, User Story)
- `title` (string, required) - tytuł
- `description` (string, optional) - opis
- `assigned_to` (string, optional) - przypisany do (email)
- `priority` (integer, optional) - priorytet (1-4)

### 4. `update_work_item`
Aktualizuje istniejący work item.

Parametry:
- `id` (integer, required) - ID work item
- `title` (string, optional) - nowy tytuł
- `state` (string, optional) - nowy stan
- `assigned_to` (string, optional) - nowy przypisany
- `priority` (integer, optional) - nowy priorytet

### 5. `run_pipeline`
Uruchamia pipeline.

Parametry:
- `project` (string, required) - nazwa projektu
- `pipeline_id` (integer, required) - ID pipeline
- `branch` (string, optional) - branch (domyślnie: main)

### 6. `get_pipeline_status`
Sprawdza status ostatnich uruchomień pipeline.

Parametry:
- `project` (string, required) - nazwa projektu
- `pipeline_id` (integer, required) - ID pipeline
- `limit` (integer, optional) - liczba wyników (domyślnie: 5)

## ⚙️ Konfiguracja

### Zmienne środowiskowe (App Settings)

```
AZURE_DEVOPS_ORG_URL=https://dev.azure.com/your-org
AZURE_DEVOPS_PAT=your-personal-access-token
AZURE_DEVOPS_PROJECT=DefaultProject
```

### Personal Access Token (PAT)

1. Przejdź do Azure DevOps > User Settings > Personal Access Tokens
2. Utwórz nowy token z uprawnieniami:
   - Work Items (Read, Write, Manage)
   - Build (Read, Execute)
   - Code (Read)

## 🔗 Integracja z Copilot Studio

1. Po deployment uruchom `.\deploy.ps1` - automatycznie wygeneruje plik YAML
2. W Copilot Studio:
   - Settings > Custom Connectors
   - Import OpenAPI file
   - Wybierz `copilot-custom-connection.yaml`
3. Skonfiguruj połączenie używając Function Key
4. Test: "What tools do you have?"

## 🐛 Rozwiązywanie problemów

### Funkcja nie odpowiada
```powershell
# Sprawdź logi
az functionapp logs tail --name <function-app-name> --resource-group <rg-name>

# Sprawdź ustawienia
az functionapp config appsettings list --name <function-app-name> --resource-group <rg-name>
```

### Błąd autoryzacji
- Sprawdź czy PAT token jest aktualny
- Zweryfikuj uprawnienia tokena
- Upewnij się że URL organizacji jest poprawny

### Problemy z deployment
```powershell
# Wyczyść i spróbuj ponownie
func azure functionapp publish <function-app-name> --python --build remote
```

## 📚 Przykłady użycia

### Test lokalny
```bash
curl -X POST http://localhost:7071/api/mcp \
  -H "Content-Type: application/json" \
  -d '{"method":"tools/list","params":{}}'
```

### Test produkcyjny
```bash
curl -X POST https://your-function.azurewebsites.net/api/mcp \
  -H "x-functions-key: your-function-key" \
  -H "Content-Type: application/json" \
  -d '{"method":"tools/list","params":{}}'
```

## 📄 Licencja

MIT License