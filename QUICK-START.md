# 🚀 SZYBKA INSTRUKCJA URUCHOMIENIA - Warsztat Copilot 365 MCP

## 📋 Przegląd
Ten przewodnik pomoże Ci szybko uruchomić wszystkie komponenty warsztatu Copilot 365 MCP Integration.

## ⚡ Wymagania wstępne

### 💻 Oprogramowanie
- **Node.js** >= 18.0.0 (sprawdź: `node --version`)
- **Python** >= 3.9 (sprawdź: `python --version`)
- **PowerShell** >= 7.0 (sprawdź: `$PSVersionTable.PSVersion`)
- **Azure CLI** >= 2.50.0 (sprawdź: `az --version`)
- **Git** >= 2.30.0 (sprawdź: `git --version`)

### 🔑 Konta i dostępy
- ✅ Subskrypcja Azure (2e539821-ff47-4b8a-9f5a-200de5bb3e8d)
- 🤖 Microsoft 365 Developer Account
- 🔧 Azure DevOps (opcjonalnie)

### 🛠️ VS Code Extensions (automatycznie zaproponowane)
```bash
# Szybka instalacja kluczowych rozszerzeń
code --install-extension ms-vscode.azure-account
code --install-extension ms-azuretools.vscode-azurefunctions
code --install-extension ms-vscode.powershell
code --install-extension ms-python.python
code --install-extension TeamsDevApp.ms-teams-vscode-extension
```

## 🚀 Szybkie uruchomienie (5 minut)

### 1️⃣ Klon i otwarcie projektu
```bash
# Przejdź do katalogu projektu
cd D:\Workshops\Copilot365MCP

# Otwórz workspace w VS Code
code Copilot365MCP.code-workspace
```

### 2️⃣ Konfiguracja Azure (automatyczna)
```powershell
# Przejdź do katalogu azure-setup
cd azure-setup

# Ustaw zmienne środowiskowe
.\setup-variables.ps1

# Skonfiguruj wszystkie zasoby Azure (5-10 minut)
.\setup-azure.ps1
```

**Co się dzieje:**
- ✅ Tworzenie grupy zasobów
- ✅ Azure AI Services
- ✅ Application Insights  
- ✅ Storage Account
- ✅ Azure Functions
- ✅ Container Registry
- ✅ Generowanie pliku `ai-config.env`

### 3️⃣ Instalacja zależności (wszystkie naraz)
```powershell
# Z głównego katalogu projektu - uruchom w PowerShell jako Administrator
# Azure Function
cd mcp-servers\azure-function
npm install

# Teams Bot
cd ..\..\teams-bot
npm install

# Python servers (local-devops)
cd ..\mcp-servers\local-devops
pip install -r requirements.txt

# Python servers (azure-devops)
cd ..\azure-devops
pip install -r requirements.txt

# Desktop Commander (TypeScript)
cd ..\desktop-commander
npm install
npm run build

# Powrót do głównego katalogu
cd ..\..
```

### 4️⃣ Konfiguracja plików .env
```bash
# Teams Bot - skopiuj i wypełnij
copy teams-bot\.env.template teams-bot\.env

# Azure DevOps MCP - skopiuj i wypełnij
copy mcp-servers\azure-devops\.env.template mcp-servers\azure-devops\.env
```

**Wypełnij pliki .env danymi z `azure-setup/ai-config.env`**

### 5️⃣ Uruchomienie ALL-IN-ONE (NAJŁATWIEJSZE):

```powershell
# JEDNA KOMENDA uruchamia wszystko:
.\start-workshop.ps1

# Lub z opcjami:
.\start-workshop.ps1 -QuickStart     # Szybkie uruchomienie
.\start-workshop.ps1 -TestOnly       # Tylko testy
.\start-workshop.ps1 -SkipPython     # Bez Python servers
```

### 5️⃣ Alternative: Manual start (każdy w osobnym terminalu)

**Terminal 1 - Azure Functions:**
```bash
cd mcp-servers/azure-function
func start  # http://localhost:7071
```

**Terminal 2 - Teams Bot:**
```bash
cd teams-bot
npm start   # http://localhost:3978
```

**Terminal 3 - Local DevOps MCP:**
```bash
cd mcp-servers/local-devops
python local-mcp-server.py
```

**Terminal 4 - Azure DevOps MCP:**
```bash
cd mcp-servers/azure-devops
python azure-devops-mcp.py
```

**Terminal 5 - Desktop Commander:**
```bash
cd mcp-servers/desktop-commander
npm start
```

## 🧪 Szybkie testy

### Test 1: All-in-One Health Check
```powershell
# Test wszystkich komponentów jednocześnie:
.\start-workshop.ps1 -TestOnly

# Lub ręcznie:
curl http://localhost:7071/api/McpServer     # Azure Function
curl http://localhost:3978/health           # Teams Bot
curl http://localhost:3978/api/mcp/test     # MCP connections
curl http://localhost:3978/api/config       # Konfiguracja
```

### Test 2: MCP Tools (PowerShell)
```powershell
# Test Azure Function MCP
$body = @{
    jsonrpc = "2.0"
    method = "tools/list"
    id = 1
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:7071/api/McpServer" -Method POST -Body $body -ContentType "application/json"
```

### Test 3: Teams Bot (ngrok wymagany dla Teams)
```bash
# Zainstaluj ngrok (jeśli nie masz)
npm install -g ngrok

# Uruchom tunnel
ngrok http 3978

# Użyj HTTPS URL w Teams App Studio
```

## 🛠️ VS Code - Szybka konfiguracja

### Tasks (Ctrl+Shift+P → "Tasks: Run Task")
- **Setup Azure Resources** - automatyczne setup Azure
- **Start Azure Functions** - uruchom Azure Functions
- **Start Teams Bot** - uruchom Teams Bot  
- **Install All Dependencies** - zainstaluj wszystko
- **Test MCP Connections** - test połączeń

### Debug Configurations (F5)
- **Debug Azure Functions** - debug Azure Functions
- **Debug Teams Bot** - debug Teams Bot
- **Debug Python MCP Server** - debug Python serwer

## 📊 Monitorowanie

### Application Insights
```bash
# Sprawdź logi w Azure Portal
# https://portal.azure.com → Application Insights → copilot-mcp-dev-ai
```

### Lokalne logi
```bash
# Azure Functions
func logs

# Teams Bot  
npm run logs

# Python servers
tail -f logs/app.log
```

## 🚨 Najczęstsze problemy

### Problem 1: "Cannot connect to Azure"
**Rozwiązanie:**
```powershell
az login
az account set --subscription 2e539821-ff47-4b8a-9f5a-200de5bb3e8d
```

### Problem 2: "MCP Server not responding"
**Rozwiązanie:**
```bash
# Sprawdź czy serwer działa
curl http://localhost:7071/health

# Sprawdź porty
netstat -tlnp | grep :7071
netstat -tlnp | grep :3978
```

### Problem 3: "Teams Bot not found"
**Rozwiązanie:**
```bash
# Sprawdź konfigurację
curl http://localhost:3978/api/config

# Sprawdź ngrok
ngrok http 3978
```

### Problem 4: "Python module not found"
**Rozwiązanie:**
```bash
# Upewnij się że używasz właściwego środowiska
python -m pip install -r requirements.txt

# Lub utwórz virtual environment
python -m venv venv
venv\Scripts\activate  # Windows
pip install -r requirements.txt
```

### Problem 5: "PowerShell execution policy"
**Rozwiązanie:**
```powershell
# Ustaw policy dla sesji
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## 🎯 Szybkie scenariusze testowe

### Scenariusz 1: Deployment test
```bash
# W Teams chat z botem:
"deploy v1.0.0 do staging"
```

### Scenariusz 2: System info
```bash
# W Teams chat z botem:
"sprawdź info systemu"
```

### Scenariusz 3: Pipeline status  
```bash
# W Teams chat z botem:
"status pipeline 123"
```

### Scenariusz 4: Create work item
```bash
# W Teams chat z botem:
"utwórz zadanie: Test new feature"
```

## 📚 Dokumentacja

### Pliki konfiguracyjne
- `azure-setup/ai-config.env` - klucze Azure (po setup)
- `teams-bot/.env` - konfiguracja Teams Bot
- `mcp-servers/azure-devops/.env` - Azure DevOps

### Logi i debugging
- Azure Functions: http://localhost:7071/admin/host/status
- Teams Bot: http://localhost:3978/health
- Application Insights: Azure Portal

### MCP Endpoints
- Azure Function: http://localhost:7071/api/McpServer
- Local DevOps: stdio (lokalny proces)
- Desktop Commander: stdio (lokalny proces)  
- Azure DevOps: stdio (lokalny proces)

## ✅ Checklist sukcesu

- [ ] ✅ Azure Resources utworzone (sprawdź: `az group show --name copilot-mcp-workshop-rg`)
- [ ] ✅ Azure Function działa (sprawdź: `curl http://localhost:7071/api/McpServer`)
- [ ] ✅ Teams Bot odpowiada (sprawdź: `curl http://localhost:3978/health`)
- [ ] ✅ MCP servers uruchomione (sprawdź procesy Python/Node.js)
- [ ] ✅ Test All-in-One (`.\.\start-workshop.ps1 -TestOnly`)
- [ ] ✅ VS Code workspace załadowany z rozszerzeniami
- [ ] ✅ Pliki .env skonfigurowane
- [ ] ✅ Tests passing (sprawdź: `curl http://localhost:3978/api/mcp/test`)

## 🎉 Gotowe!

Teraz masz pełne środowisko Copilot 365 MCP:
- 🔥 **Azure Functions** - serwer MCP w chmurze
- 🤖 **Teams Bot** - interfejs konwersacyjny  
- 🐍 **Python MCP Servers** - lokalne narzędzia DevOps
- 💻 **Desktop Commander** - zarządzanie systemem Windows
- ☁️ **Azure Services** - AI, monitoring, storage

**Następne kroki:**
1. Przetestuj scenariusze w Teams
2. Dostosuj narzędzia MCP do swoich potrzeb
3. Eksperymentuj z AI capabilities
4. Rozbuduj o własne serwery MCP

---

*💡 **Wskazówka**: Użyj VS Code Tasks (Ctrl+Shift+P) dla szybkich operacji!*

*🚨 **Bezpieczeństwo**: Pliki .env zawierają poufne dane - nie commituj ich do Git!*
