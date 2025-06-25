# Azure DevOps MCP - Instrukcja instalacji i konfiguracji

## 📋 Spis treści

1. [Wymagania systemowe](#wymagania-systemowe)
2. [Instalacja na Windows](#instalacja-na-windows)
3. [Instalacja na Ubuntu/Linux](#instalacja-na-ubuntulinux)
4. [Konfiguracja Azure DevOps](#konfiguracja-azure-devops)
5. [Uruchomienie lokalne](#uruchomienie-lokalne)
6. [Deployment na Azure Functions](#deployment-na-azure-functions)
7. [Integracja z Copilot Studio](#integracja-z-copilot-studio)
8. [Rozwiązywanie problemów](#rozwiązywanie-problemów)

## 🖥️ Wymagania systemowe

### Minimalne wymagania

| Komponent | Windows | Ubuntu/Linux |
|-----------|---------|--------------|
| System | Windows 10/11 | Ubuntu 20.04+ |
| Node.js | 18.x lub nowszy | 18.x lub nowszy |
| Python | 3.8+ | 3.8+ |
| PowerShell | 7.0+ | - |
| Azure CLI | 2.50+ | 2.50+ |
| Git | 2.30+ | 2.30+ |

### Dodatkowe wymagania

- Konto Azure z aktywną subskrypcją
- Organizacja Azure DevOps z projektem
- Personal Access Token (PAT) z Azure DevOps
- Dostęp do Microsoft Copilot Studio

## 💻 Instalacja na Windows

### 1. Instalacja podstawowych narzędzi

```powershell
# Sprawdź czy masz Chocolatey
choco --version

# Jeśli nie, zainstaluj Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Zainstaluj wymagane pakiety
choco install nodejs-lts python git azure-cli powershell-core -y

# Zrestartuj terminal PowerShell
```

### 2. Weryfikacja instalacji

```powershell
# Sprawdź wersje
node --version    # Powinno pokazać v18.x lub nowsze
npm --version     # Powinno pokazać 9.x lub nowsze
python --version  # Powinno pokazać Python 3.8+
az --version      # Powinno pokazać 2.50+
git --version     # Powinno pokazać 2.30+
```

### 3. Instalacja Azure Functions Core Tools

```powershell
# Instalacja przez npm
npm install -g azure-functions-core-tools@4 --unsafe-perm true

# Weryfikacja
func --version
```

### 4. Klonowanie repozytorium

```powershell
# Utwórz katalog roboczy
mkdir C:\Workshops
cd C:\Workshops

# Sklonuj repozytorium
git clone https://github.com/[your-repo]/Copilot365MCP.git
cd Copilot365MCP
```

## 🐧 Instalacja na Ubuntu/Linux

### 1. Automatyczna instalacja

```bash
# Pobierz i uruchom skrypt instalacyjny
cd ~/Copilot365MCP
chmod +x setup-ubuntu.sh
./setup-ubuntu.sh
```

### 2. Manualna instalacja (jeśli preferujesz)

```bash
# Aktualizacja systemu
sudo apt update && sudo apt upgrade -y

# Node.js 18.x
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Python i pip
sudo apt install -y python3 python3-pip python3-venv

# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Azure Functions Core Tools
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-$(lsb_release -cs)-prod $(lsb_release -cs) main" > /etc/apt/sources.list.d/dotnetdev.list'
sudo apt update
sudo apt install -y azure-functions-core-tools-4

# Git
sudo apt install -y git
```

### 3. Weryfikacja instalacji

```bash
node --version
npm --version
python3 --version
az --version
func --version
git --version
```

## 🔑 Konfiguracja Azure DevOps

### 1. Uzyskanie Personal Access Token (PAT)

1. Zaloguj się do Azure DevOps: https://dev.azure.com/your-organization
2. Kliknij na ikonę użytkownika (prawy górny róg) → **Personal access tokens**
3. Kliknij **+ New Token**
4. Wypełnij:
   - **Name**: `MCP Workshop Token`
   - **Organization**: Wybierz swoją organizację
   - **Expiration**: 90 dni (lub custom)
   - **Scopes**: 
     - ✅ Work Items (Read, Write, Manage)
     - ✅ Build (Read, Execute)
     - ✅ Code (Read)
     - ✅ Project and Team (Read)
5. Kliknij **Create**
6. **SKOPIUJ TOKEN** - zobaczysz go tylko raz!

### 2. Konfiguracja zmiennych środowiskowych

#### Windows (PowerShell)

```powershell
# Uruchom skrypt konfiguracyjny
cd C:\Workshops\Copilot365MCP
.\setup-azure-devops.ps1

# Lub ręcznie ustaw zmienne
$env:AZURE_DEVOPS_ORG_URL = "https://dev.azure.com/your-organization"
$env:AZURE_DEVOPS_PAT = "your-pat-token"
$env:AZURE_DEVOPS_PROJECT = "your-project-name"

# Zapisz do pliku .env
@"
AZURE_DEVOPS_ORG_URL=$env:AZURE_DEVOPS_ORG_URL
AZURE_DEVOPS_PAT=$env:AZURE_DEVOPS_PAT
AZURE_DEVOPS_PROJECT=$env:AZURE_DEVOPS_PROJECT
"@ | Out-File -FilePath "mcp-servers\azure-devops\.env" -Encoding UTF8
```

#### Linux (Bash)

```bash
# Uruchom skrypt konfiguracyjny
cd ~/Copilot365MCP
./setup-azure-devops.sh

# Lub ręcznie
export AZURE_DEVOPS_ORG_URL="https://dev.azure.com/your-organization"
export AZURE_DEVOPS_PAT="your-pat-token"
export AZURE_DEVOPS_PROJECT="your-project-name"

# Zapisz do .env
cat > mcp-servers/azure-devops/.env << EOF
AZURE_DEVOPS_ORG_URL=$AZURE_DEVOPS_ORG_URL
AZURE_DEVOPS_PAT=$AZURE_DEVOPS_PAT
AZURE_DEVOPS_PROJECT=$AZURE_DEVOPS_PROJECT
EOF
```

## 🚀 Uruchomienie lokalne

### 1. Instalacja zależności

```bash
# Przejdź do katalogu serwera
cd mcp-servers/azure-devops

# Utwórz środowisko wirtualne Python
python -m venv venv

# Aktywuj środowisko
# Windows:
.\venv\Scripts\activate
# Linux:
source venv/bin/activate

# Zainstaluj zależności
pip install -r requirements.txt
```

### 2. Test serwera

```bash
# Uruchom serwer w trybie debug
python src/server.py --debug

# W nowym terminalu, test komunikacji
echo '{"jsonrpc": "2.0", "method": "initialize", "params": {"capabilities": {}}, "id": 1}' | python src/server.py
```

### 3. Uruchomienie przez skrypt warsztatowy

```powershell
# Windows
cd C:\Workshops\Copilot365MCP
.\start-workshop.ps1

# Linux
cd ~/Copilot365MCP
./start-workshop.sh
```

## ☁️ Deployment na Azure Functions

### 1. Przygotowanie infrastruktury Azure

```powershell
# Zaloguj się do Azure
az login

# Ustaw subskrypcję
az account set --subscription "your-subscription-id"

# Uruchom setup Azure
cd azure-setup
.\setup-azure-fixed.ps1
```

### 2. Build i deployment funkcji

```bash
# Przejdź do katalogu Azure Function
cd mcp-servers/azure-function

# Zainstaluj zależności
npm install

# Build
npm run build

# Deploy
func azure functionapp publish mcpdevopsfunc --typescript

# Zapisz URL funkcji
# Przykład: https://mcpdevopsfunc.azurewebsites.net/api/mcp
```

### 3. Konfiguracja Function App

```powershell
# Ustaw zmienne środowiskowe w Azure
az functionapp config appsettings set `
  --name mcpdevopsfunc `
  --resource-group mcp-devops-workshop-rg `
  --settings `
    AZURE_DEVOPS_ORG_URL=$env:AZURE_DEVOPS_ORG_URL `
    AZURE_DEVOPS_PAT=$env:AZURE_DEVOPS_PAT `
    AZURE_DEVOPS_PROJECT=$env:AZURE_DEVOPS_PROJECT
```

## 🤖 Integracja z Copilot Studio

### 1. Utworzenie Custom Connector

1. Zaloguj się do [Copilot Studio](https://copilotstudio.microsoft.com)
2. Przejdź do **Connectors** → **Custom connectors** → **+ New custom connector**
3. Wybierz **Import an OpenAPI file**
4. Wgraj plik `mcp-devops-connector.yaml`:

```yaml
swagger: '2.0'
info:
  title: Azure DevOps MCP Server
  description: MCP Server for Azure DevOps integration
  version: 1.0.0
host: mcpdevopsfunc.azurewebsites.net
basePath: /api
schemes:
  - https
securityDefinitions:
  apiKey:
    type: apiKey
    name: x-functions-key
    in: header
paths:
  /mcp:
    post:
      summary: MCP Protocol Handler
      operationId: InvokeMCP
      x-ms-agentic-protocol: mcp-streamable-1.0
      security:
        - apiKey: []
      parameters:
        - in: body
          name: body
          required: true
          schema:
            type: object
      responses:
        '200':
          description: Success
          schema:
            type: object
```

### 2. Konfiguracja Security

1. W Custom Connector, przejdź do zakładki **Security**
2. Wybierz **API Key**
3. Parameter label: `Function Key`
4. Parameter name: `x-functions-key`
5. Location: `Header`

### 3. Test połączenia

1. Przejdź do zakładki **Test**
2. Utwórz nowe połączenie
3. Podaj Function Key (znajdziesz w Azure Portal)
4. Test operation z przykładowym request:

```json
{
  "jsonrpc": "2.0",
  "method": "tools/list",
  "id": "test-1"
}
```

### 4. Utworzenie Copilot Agent

1. W Copilot Studio utwórz nowego agenta
2. Dodaj Custom Connector jako Action
3. Skonfiguruj prompty dla każdego narzędzia
4. Testuj w oknie czatu

## 🔧 Rozwiązywanie problemów

### Problem: "PAT token is invalid or expired"

```powershell
# Sprawdź token
$headers = @{
    Authorization = "Basic $([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($env:AZURE_DEVOPS_PAT)")))"
}
Invoke-RestMethod -Uri "$env:AZURE_DEVOPS_ORG_URL/_apis/projects?api-version=6.0" -Headers $headers

# Jeśli błąd, wygeneruj nowy token
```

### Problem: "Python module 'mcp' not found"

```bash
# Upewnij się że jesteś w wirtualnym środowisku
which python  # Powinno pokazać ścieżkę do venv

# Reinstaluj zależności
pip install --upgrade pip
pip install -r requirements.txt --force-reinstall
```

### Problem: "Function returns 401 Unauthorized"

```powershell
# Pobierz klucz funkcji
$functionKey = az functionapp function keys list `
  --name mcpdevopsfunc `
  --resource-group mcp-devops-workshop-rg `
  --function-name mcp `
  --query "default" -o tsv

Write-Host "Function Key: $functionKey"
```

### Problem: "Cannot connect to Azure DevOps"

1. Sprawdź czy URL organizacji jest poprawny
2. Zweryfikuj uprawnienia PAT
3. Sprawdź czy projekt istnieje i masz do niego dostęp
4. Test z curl:

```bash
curl -u :$AZURE_DEVOPS_PAT \
  "$AZURE_DEVOPS_ORG_URL/$AZURE_DEVOPS_PROJECT/_apis/wit/workitems?api-version=6.0"
```

## 📚 Dodatkowe zasoby

- [MCP Documentation](https://modelcontextprotocol.io/docs)
- [Azure DevOps REST API](https://docs.microsoft.com/en-us/rest/api/azure/devops/)
- [Copilot Studio Docs](https://learn.microsoft.com/en-us/microsoft-copilot-studio/)
- [Azure Functions Best Practices](https://docs.microsoft.com/en-us/azure/azure-functions/functions-best-practices)

## 💡 Wskazówki

1. **Zacznij od testów lokalnych** - łatwiej debugować
2. **Używaj przykładowego projektu** w Azure DevOps z testowymi danymi
3. **Monitoruj logi** w Application Insights
4. **Zapisuj konfigurację** do pliku `.ai-config.env`
5. **Rób backupy** PAT token i kluczy

---
*Dokument jest częścią warsztatu Copilot 365 MCP*