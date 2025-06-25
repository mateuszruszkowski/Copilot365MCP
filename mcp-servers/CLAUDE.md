# CLAUDE.md - MCP Servers

## 📋 Opis modułu

Katalog `mcp-servers` zawiera różne implementacje serwerów Model Context Protocol (MCP). Każdy serwer udostępnia specyficzne narzędzia (tools) które mogą być wykorzystane przez asystentów AI takich jak Microsoft Copilot Studio.

## 🎯 Cel

Dostarczyć gotowe do użycia serwery MCP dla różnych scenariuszy automatyzacji, od zarządzania Azure DevOps po kontrolę aplikacji desktopowych.

## 📁 Struktura katalogów

```
mcp-servers/
├── azure-devops/        # Serwer Python dla Azure DevOps
│   ├── src/            # Kod źródłowy
│   ├── requirements.txt # Zależności Python
│   └── README.md       # Dokumentacja
│
├── azure-function/      # Serwer TypeScript dla Azure Functions
│   ├── src/            # Kod źródłowy
│   ├── package.json    # Zależności Node.js
│   └── function.json   # Konfiguracja Azure Function
│
├── desktop-commander/   # Kontrola aplikacji desktop
│   └── (w przygotowaniu)
│
├── local-devops/       # Lokalne narzędzia DevOps
│   └── (w przygotowaniu)
│
└── CLAUDE.md           # Ten plik
```

## 🚀 Azure DevOps MCP Server

### Funkcjonalności

Serwer udostępnia narzędzia do:
- **Work Items**: tworzenie, edycja, wyszukiwanie zadań
- **Pipelines**: uruchamianie, monitorowanie statusu
- **Repositories**: przeglądanie commitów, branchy
- **Pull Requests**: tworzenie, review (planowane)

### Dostępne narzędzia

1. **list_work_items**
   - Lista zadań z projektu
   - Filtrowanie po typie, stanie, przypisaniu

2. **get_work_item**
   - Szczegóły konkretnego zadania
   - Historia zmian

3. **create_work_item**
   - Tworzenie nowych zadań (Task, Bug, User Story)
   - Ustawianie pól i przypisań

4. **update_work_item**
   - Aktualizacja istniejących zadań
   - Zmiana stanu, priorytetu, opisu

5. **check_pipeline_status**
   - Status ostatnich buildów
   - Informacje o błędach

6. **trigger_pipeline**
   - Uruchamianie pipeline z parametrami
   - Wybór brancha i środowiska

### Uruchomienie lokalne

```bash
# Przejdź do katalogu
cd mcp-servers/azure-devops

# Zainstaluj zależności
pip install -r requirements.txt

# Skonfiguruj zmienne środowiskowe
cp .env.example .env
# Edytuj .env i dodaj swoje dane

# Uruchom serwer
python src/server.py
```

### Konfiguracja

Wymagane zmienne środowiskowe:
```env
AZURE_DEVOPS_ORG_URL=https://dev.azure.com/your-org
AZURE_DEVOPS_PAT=your-personal-access-token
AZURE_DEVOPS_PROJECT=your-project-name
```

## 🌩️ Azure Function MCP Server

### Różnice od wersji lokalnej

- HTTP endpoint zamiast stdio
- Automatyczne skalowanie
- Integracja z Azure services
- Authentication przez Function Keys

### Deployment

```bash
# Przejdź do katalogu
cd mcp-servers/azure-function

# Build
npm run build

# Deploy
func azure functionapp publish your-function-app-name
```

### Endpoint dla Copilot Studio

```
POST https://your-function.azurewebsites.net/api/mcp
x-functions-key: your-function-key
Content-Type: application/json

{
  "method": "tools/call",
  "params": {
    "name": "list_work_items",
    "arguments": {
      "project": "MyProject"
    }
  }
}
```

## 🖥️ Desktop Commander (Przyszłe warsztaty)

### Planowane funkcjonalności

- Otwieranie aplikacji
- Automatyzacja GUI
- Zrzuty ekranu
- Kontrola okien
- Symulacja klawiatury/myszy

### Scenariusze użycia

- "Otwórz Visual Studio Code"
- "Zrób screenshot aktywnego okna"
- "Przełącz na aplikację Teams"

## 🔧 Local DevOps (Przyszłe warsztaty)

### Planowane funkcjonalności

- Git operations
- Docker management
- Local builds
- File operations
- System monitoring

## 🛠️ Tworzenie własnego serwera MCP

### Szablon podstawowy (Python)

```python
from mcp.server import Server
from mcp.server.models import InitializationOptions
import mcp.types as types

# Inicjalizacja serwera
server = Server("my-mcp-server")

@server.list_tools()
async def handle_list_tools() -> list[types.Tool]:
    return [
        types.Tool(
            name="my_tool",
            description="Opis narzędzia",
            inputSchema={
                "type": "object",
                "properties": {
                "param1": {"type": "string"}
                },
                "required": ["param1"]
            }
        )
    ]

@server.call_tool()
async def handle_call_tool(name: str, arguments: dict) -> list[types.TextContent]:
    if name == "my_tool":
        result = do_something(arguments["param1"])
        return [types.TextContent(type="text", text=str(result))]

# Uruchomienie
async def main():
    async with mcp.server.stdio.stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            InitializationOptions(
                server_name="my-mcp-server",
                server_version="0.1.0"
            )
        )

if __name__ == "__main__":
    import asyncio
    asyncio.run(main())
```

## 🧪 Testowanie serwerów

### Lokalne testowanie

```bash
# Test z przykładowym requestem
echo '{"method": "tools/list"}' | python src/server.py

# Test z narzędziem MCP Inspector
mcp-inspector test azure-devops
```

### Testowanie Azure Function

```powershell
# Test lokalny
func start

# Test zdalny
Invoke-RestMethod -Uri "https://your-function.azurewebsites.net/api/mcp" `
  -Method POST `
  -Headers @{"x-functions-key"="your-key"} `
  -Body (@{
    method = "tools/list"
  } | ConvertTo-Json)
```

## 📊 Monitorowanie

### Logi lokalne
- Serwery zapisują logi do `stderr`
- Użyj `--debug` dla szczegółowych logów

### Application Insights (Azure)
- Automatyczne zbieranie metryk
- Custom events dla każdego wywołania tool
- Dashboard w Azure Portal

## 🔒 Bezpieczeństwo

1. **Nigdy nie hardcoduj sekretów**
   - Używaj zmiennych środowiskowych
   - Azure Key Vault dla produkcji

2. **Waliduj inputy**
   - Sprawdzaj typy i zakresy
   - Sanityzuj stringi

3. **Ogranicz uprawnienia**
   - Minimum potrzebnych scope w PAT
   - Network restrictions dla Functions

## 📚 Zasoby

- [MCP Specification](https://modelcontextprotocol.io)
- [Azure DevOps REST API](https://docs.microsoft.com/azure/devops/rest/)
- [Azure Functions Best Practices](https://docs.microsoft.com/azure/azure-functions/functions-best-practices)

---
*Moduł jest częścią warsztatu Copilot 365 MCP*