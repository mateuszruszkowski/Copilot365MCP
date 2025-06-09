# 🚀 Warsztat: Copilot 365 MCP Integration dla Junior DevOps

## 📋 Przegląd

Ten projekt zawiera kompletny warsztat dotyczący integracji Microsoft 365 Copilot z Model Context Protocol (MCP) dla junior DevOps engineers. Warsztat obejmuje najnowsze rozwiązania z Microsoft BUILD 2025 i praktyczne implementacje serwerów MCP.

## 🎯 Cele warsztatowe

- 🏗️ Zrozumienie architektury Model Context Protocol
- ☁️ Konfiguracja zasobów Azure
- 🐍 Implementacja serwerów MCP w Python i TypeScript
- 🤖 Integracja z Microsoft Teams Bot
- 🛠️ Praktyczne scenariusze DevOps

## 📁 Struktura projektu

```
D:\Workshops\Copilot365MCP\
├── 📄 README.md                          # Ten plik
├── 🔧 .gitignore                         # Git ignore rules
├── 📊 Copilot365MCP.code-workspace      # VS Code workspace
│
├── 📂 azure-setup/                       # Skrypty konfiguracji Azure
│   ├── setup-variables.ps1              # Zmienne środowiskowe
│   └── setup-azure.ps1                  # Główny skrypt setup
│
├── 📂 mcp-servers/                       # Implementacje serwerów MCP
│   ├── 📂 azure-function/               # Azure Function (JavaScript)
│   ├── 📂 local-devops/                 # Lokalny DevOps (Python)
│   ├── 📂 desktop-commander/            # Desktop Commander (TypeScript)
│   └── 📂 azure-devops/                 # Azure DevOps (Python)
│
├── 📂 teams-bot/                         # Microsoft Teams Bot
│   ├── 📂 src/                          # Kod źródłowy
│   ├── package.json                     # Dependencies
│   └── .env.template                    # Template konfiguracji
│
├── 📂 tests/                             # Testy automatyczne
├── 📂 docs/                             # Dokumentacja i prezentacje
└── 📂 examples/                         # Przykłady użycia
```

## 🛠️ Wymagania systemowe

### Oprogramowanie podstawowe
- **Node.js** >= 18.0.0
- **Python** >= 3.9
- **PowerShell** >= 7.0
- **Azure CLI** >= 2.50.0
- **Docker Desktop** (opcjonalnie)
- **Git** >= 2.30.0

### Konta i subskrypcje
- ✅ **Subskrypcja Azure**: `2e539821-ff47-4b8a-9f5a-200de5bb3e8d`
- 🤖 **Microsoft 365 Developer Program** (dla Teams)
- 🔧 **Azure DevOps** (dla integracji CI/CD)

### VS Code + Rozszerzenia
- **Azure Tools** - zarządzanie zasobami Azure
- **Azure Functions** - rozwój i deployment funkcji
- **PowerShell** - edycja skryptów PS1
- **Python** - development Python MCP servers
- **Teams Toolkit** - rozwój aplikacji Teams
- **Docker** - konteneryzacja aplikacji
- **GitLens** - zaawansowana integracja Git

## 🚀 Szybkie uruchomienie

### 1. Przygotowanie środowiska

```powershell
# Klonowanie repozytorium (jeśli używasz Git)
git clone <your-repo-url>
cd Copilot365MCP

# Otwórz w VS Code
code Copilot365MCP.code-workspace
```

### 2. Konfiguracja Azure

```powershell
# Przejdź do katalogu setup
cd azure-setup

# UŻYJ POPRAWIONYCH PLIKÓW (z naprawami błędów):
.\setup-variables-fixed.ps1     # ← Poprawione nazwy zasobów
.\setup-azure-fixed.ps1         # ← Naprawione błędy Azure

# W razie problemów:
.\diagnose-azure.ps1            # ← Diagnostyka
.\quick-fix-azure.ps1 -All     # ← Automatyczne naprawy
.\test-azure-config.ps1        # ← Test konfiguracji
```

### 3. Instalacja dependencies

```bash
# Azure Function MCP Server
cd mcp-servers/azure-function
npm install

# Teams Bot
cd ../../teams-bot
npm install

# Python MCP Servers
cd ../mcp-servers/local-devops
pip install -r requirements.txt

cd ../azure-devops
pip install -r requirements.txt

# Desktop Commander (TypeScript)
cd ../desktop-commander
npm install
npm run build
```

### 4. Konfiguracja środowisk

```bash
# Skopiuj i wypełnij pliki konfiguracyjne
cp teams-bot/.env.template teams-bot/.env
cp mcp-servers/azure-devops/.env.template mcp-servers/azure-devops/.env

# Edytuj pliki .env swoimi danymi z Azure
```

### 5. Uruchomienie serwerów MCP

```bash
# Azure Function (lokalnie)
cd mcp-servers/azure-function
func start

# Local DevOps MCP Server
cd ../local-devops
python local-mcp-server.py

# Desktop Commander
cd ../desktop-commander
npm start

# Azure DevOps MCP Server
cd ../azure-devops
python azure-devops-mcp.py
```

### 6. Uruchomienie Teams Bot

```bash
cd teams-bot
npm start
```

## 🧪 Testowanie

### Testowanie połączeń MCP

```bash
# Test Azure Function
curl -X GET http://localhost:7071/api/McpServer

# Test Teams Bot
curl -X GET http://localhost:3978/health

# Test MCP connections
curl -X GET http://localhost:3978/api/mcp/test
```

### Testowanie w Teams

1. Zainstaluj bot w Teams używając Teams Toolkit
2. Rozpocznij konwersację z botem
3. Wypróbuj komendy:
   - `help` - lista dostępnych komend
   - `deploy v1.0.0 do staging` - test deploymentu
   - `status pipeline 123` - sprawdzenie statusu
   - `utwórz zadanie: Test task` - tworzenie work item

## 📚 Scenariusze warsztatowe

### Scenariusz 1: Automatyczny deployment
```
Użytkownik: deploy v2.1.0 do staging
Bot: 🚀 Rozpoczęto deployment...
```

### Scenariusz 2: Monitoring pipeline
```
Użytkownik: status pipeline 456
Bot: ✅ Pipeline zakończony pomyślnie
```

### Scenariusz 3: Zarządzanie zadaniami
```
Użytkownik: utwórz zadanie: Fix login bug @john.doe
Bot: 📋 Zadanie #1234 utworzone i przypisane
```

### Scenariusz 4: Komendy systemowe
```
Użytkownik: uruchom docker ps
Bot: 🐳 Lista kontenerów Docker...
```

## 🔧 Konfiguracja VS Code

### Zalecane rozszerzenia

Zainstaluj następujące rozszerzenia VS Code dla optymalnego doświadczenia:

```json
{
  "recommendations": [
    "ms-vscode.azure-account",
    "ms-azuretools.vscode-azurefunctions",
    "ms-vscode.powershell",
    "ms-python.python",
    "TeamsDevApp.ms-teams-vscode-extension",
    "ms-azuretools.vscode-docker",
    "eamodio.gitlens",
    "ms-vscode.vscode-typescript-next",
    "ms-azuretools.vscode-azureresourcegroups",
    "ms-vscode.azure-repos",
    "bradlc.vscode-tailwindcss",
    "ms-vscode.vscode-json"
  ]
}
```

### Konfiguracja workspace

```json
{
  "folders": [
    {
      "path": "."
    }
  ],
  "settings": {
    "python.defaultInterpreterPath": "./venv/bin/python",
    "typescript.preferences.importModuleSpecifier": "relative",
    "azure.cloud": "AzureCloud",
    "azure.tenant": "your-tenant-id"
  },
  "extensions": {
    "recommendations": [
      "ms-vscode.azure-account",
      "ms-azuretools.vscode-azurefunctions",
      "ms-python.python",
      "TeamsDevApp.ms-teams-vscode-extension"
    ]
  }
}
```

## 🔧 Naprawy Azure (jeśli wystąpiły problemy)

### 🚨 Jeśli otrzymałeś błędy podczas setup Azure:

1. **"Subscription not found"** - błędne ID subskrypcji
2. **"Resource provider not registered"** - brak rejestracji providerów  
3. **"Invalid location"** - nieprawidłowa lokacja
4. **"Registry name cannot contain dashes"** - myślniki w nazwach

### ✅ SZYBKA NAPRAWA (1 komenda):
```powershell
cd azure-setup
.\quick-fix-azure.ps1 -All
```

### 📋 Szczegółowy przewodnik napraw:
👉 **[AZURE-FIX-GUIDE.md](AZURE-FIX-GUIDE.md)** - kompletna instrukcja naprawy

---

## 🚨 Troubleshooting

### Częste problemy

**1. Błąd: "Cannot connect to MCP server"**
```bash
# Sprawdź czy serwer działa
curl -X GET http://localhost:7071/health

# Sprawdź logi Azure Functions
func logs
```

**2. Teams Bot nie odpowiada**
```bash
# Sprawdź konfigurację Bot Framework
az bot show --name your-bot-name --resource-group your-rg

# Sprawdź endpoint i ngrok
ngrok http 3978
```

**3. Błędy autoryzacji Azure DevOps**
```bash
# Sprawdź Personal Access Token
az devops configure --defaults organization=https://dev.azure.com/yourorg

# Test połączenia
az devops project list
```

### Przydatne komendy diagnostyczne

```bash
# Status wszystkich usług
docker ps -a
ps aux | grep node
ps aux | grep python

# Sprawdzenie portów
netstat -tlnp | grep :3978
netstat -tlnp | grep :7071

# Logi aplikacji
tail -f logs/app.log
journalctl -u your-service-name
```

## 📖 Dalsze zasoby

### Dokumentacja Microsoft
- [Model Context Protocol](https://docs.anthropic.com/en/docs/agents-and-tools/mcp)
- [Microsoft Build 2025 News](https://news.microsoft.com/build-2025-book-of-news/)
- [Teams AI Library](https://learn.microsoft.com/en-us/microsoftteams/platform/bots/how-to/teams-conversational-ai/)
- [Azure Functions](https://docs.microsoft.com/en-us/azure/azure-functions/)

### Społeczność i wsparcie
- [Microsoft 365 Developer Community](https://developer.microsoft.com/en-us/microsoft-365/community)
- [Azure DevOps Community](https://docs.microsoft.com/en-us/azure/devops/)
- [Model Context Protocol GitHub](https://github.com/modelcontextprotocol)

## 🤝 Współpraca

### Workflow Git
```bash
# Feature branch workflow
git checkout -b feature/new-mcp-server
git commit -m "feat: add new MCP server for monitoring"
git push origin feature/new-mcp-server
```

### Code standards
- **JavaScript/TypeScript**: ESLint + Prettier
- **Python**: Black + Flake8
- **PowerShell**: PSScriptAnalyzer

## 📝 Licencja

MIT License - zobacz plik LICENSE dla szczegółów.

## 👥 Autorzy

- **Workshop Instructor** - *Initial work*
- **Junior DevOps Engineers** - *Workshop participants*

---

## 🎉 Gratulacje!

Jeśli dotarłeś tutaj, jesteś gotowy do rozpoczęcia warsztatu! 

**Next Steps:**
1. Upewnij się, że wszystkie wymagania są spełnione
2. Skonfiguruj środowisko Azure używając skryptów
3. Uruchom wszystkie serwery MCP
4. Przetestuj integrację z Teams
5. Eksperymentuj z własnymi scenariuszami!

---

*💡 **Wskazówka**: Regularnie commituj swoje zmiany i nie wahaj się zadawać pytań podczas warsztatu!*
