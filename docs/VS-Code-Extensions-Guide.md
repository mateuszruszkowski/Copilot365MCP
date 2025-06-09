# 💻 Wymagane rozszerzenia VS Code dla warsztatu

## 🎯 Podstawowe rozszerzenia (WYMAGANE)

### ☁️ Azure Development
- **Azure Account** (`ms-vscode.azure-account`)
  - Zarządzanie kontami Azure i subskrypcjami
  - Logowanie do Azure bezpośrednio z VS Code

- **Azure Functions** (`ms-azuretools.vscode-azurefunctions`)
  - Development, debugging i deployment funkcji Azure
  - Integracja z Azure Functions Core Tools

- **Azure Resource Groups** (`ms-azuretools.vscode-azureresourcegroups`)
  - Przeglądanie i zarządzanie zasobami Azure
  - Tworzenie nowych zasobów

### 🤖 Microsoft Teams Development
- **Teams Toolkit** (`TeamsDevApp.ms-teams-vscode-extension`)
  - Scaffolding aplikacji Teams
  - Local debugging dla Teams Bot
  - Manifest management

### 🐍 Python Development
- **Python** (`ms-python.python`)
  - IntelliSense, debugging, linting
  - Zarządzanie virtual environments
  - Integracja z Jupyter

### 💙 PowerShell & Azure
- **PowerShell** (`ms-vscode.powershell`)
  - Edycja i debugging skryptów PowerShell
  - IntelliSense dla cmdlets Azure
  - PSScriptAnalyzer integration

### 🚀 JavaScript/TypeScript
- **TypeScript** (`ms-vscode.vscode-typescript-next`)
  - Najnowsze TypeScript features
  - Enhanced IntelliSense

## 🔧 Dodatkowe rozszerzenia (ZALECANE)

### 🐳 Containerization
- **Docker** (`ms-azuretools.vscode-docker`)
  - Dockerfile editing
  - Container management
  - Docker Compose support

### 📊 Git & Version Control
- **GitLens** (`eamodio.gitlens`)
  - Enhanced Git capabilities
  - Blame annotations, history
  - Repository insights

### 🌐 DevOps & CI/CD
- **Azure Pipelines** (`ms-vscode.azure-pipelines`)
  - YAML pipeline editing
  - Pipeline management

- **Azure DevOps** (`ms-vscode.azure-repos`)
  - Integration with Azure DevOps
  - Work items management

### ☁️ Infrastructure as Code
- **Bicep** (`ms-azuretools.vscode-bicep`)
  - Azure Bicep templates
  - ARM template alternative

- **Terraform** (`hashicorp.terraform`)
  - Terraform configuration files
  - Syntax highlighting, validation

### 🔧 Kubernetes & Orchestration
- **Kubernetes** (`ms-kubernetes-tools.vscode-kubernetes-tools`)
  - YAML manifest editing
  - Cluster management

### 📦 Additional Azure Services
- **Azure Storage** (`ms-azuretools.vscode-azurestorage`)
  - Blob, Table, Queue management

- **Azure Static Web Apps** (`ms-azuretools.vscode-azurestaticwebapps`)
  - Static web app deployment

- **Azure CLI Tools** (`ms-vscode.azure-cli-tools`)
  - Azure CLI integration
  - Command completion

### 🛠️ Development Utilities
- **REST Client** (`humao.rest-client`)
  - Testing HTTP APIs
  - MCP server testing

- **JSON** (`ms-vscode.vscode-json`)
  - Enhanced JSON editing
  - Schema validation

## 📥 Szybka instalacja

### 1. Za pomocą VS Code Extensions view
1. Otwórz VS Code
2. Wciśnij `Ctrl+Shift+X` (Extensions)
3. Wklej ID rozszerzenia (np. `ms-vscode.azure-account`)
4. Kliknij Install

### 2. Za pomocą Command Palette
1. Wciśnij `Ctrl+Shift+P`
2. Wpisz: `Extensions: Install Extensions`
3. Wyszukaj po nazwie rozszerzenia

### 3. Za pomocą command line
```bash
# Instalacja kluczowych rozszerzeń
code --install-extension ms-vscode.azure-account
code --install-extension ms-azuretools.vscode-azurefunctions
code --install-extension ms-vscode.powershell
code --install-extension ms-python.python
code --install-extension TeamsDevApp.ms-teams-vscode-extension
code --install-extension ms-azuretools.vscode-docker
code --install-extension eamodio.gitlens
```

### 4. Automatyczna instalacja z workspace
Po otwarciu `Copilot365MCP.code-workspace`, VS Code automatycznie zaproponuje instalację rekomendowanych rozszerzeń.

## ⚙️ Konfiguracja po instalacji

### Azure Account
1. Wciśnij `Ctrl+Shift+P`
2. Wpisz: `Azure: Sign In`
3. Zaloguj się do konta z subskrypcją: `2e539821-ff47-4b8a-9f5a-200de5bb3e8d`

### Python
1. Wciśnij `Ctrl+Shift+P`
2. Wpisz: `Python: Select Interpreter`
3. Wybierz Python 3.9+ (preferably w virtual environment)

### Teams Toolkit
1. Wciśnij `Ctrl+Shift+P`
2. Wpisz: `Teams: Sign in to Microsoft 365`
3. Zaloguj się do konta Developer

### PowerShell
1. Sprawdź czy używasz PowerShell 7+: `$PSVersionTable`
2. Zainstaluj Azure PowerShell: `Install-Module Az`

## 🔍 Weryfikacja instalacji

### Sprawdzenie rozszerzeń
```bash
code --list-extensions | grep -E "(azure|teams|python|powershell|docker|gitlens)"
```

### Test Azure connection
1. Otwórz Azure Explorer w VS Code
2. Sprawdź czy widzisz subskrypcję workshop
3. Spróbuj rozwinąć Resource Groups

### Test Teams Toolkit
1. Wciśnij `Ctrl+Shift+P`
2. Wpisz: `Teams: New Project`
3. Sprawdź czy są dostępne templates

## 🚨 Troubleshooting

### Problem z Azure Account
- **Rozwiązanie**: Wyloguj i zaloguj ponownie
- Command: `Azure: Sign Out` → `Azure: Sign In`

### Problem z Python IntelliSense
- **Rozwiązanie**: Upewnij się że wybrany jest właściwy interpreter
- Command: `Python: Select Interpreter`

### Problem z Teams Toolkit
- **Rozwiązanie**: Sprawdź czy masz uprawnienia Developer
- Sprawdź: https://developer.microsoft.com/microsoft-365/dev-program

### Problem z PowerShell
- **Rozwiązanie**: Zaktualizuj do PowerShell 7+
- Download: https://github.com/PowerShell/PowerShell/releases

## 📚 Dokumentacja

- [Azure Tools for VS Code](https://docs.microsoft.com/en-us/azure/developer/dev-tools-and-sdks)
- [Teams Toolkit Documentation](https://docs.microsoft.com/en-us/microsoftteams/platform/toolkit/teams-toolkit-fundamentals)
- [Python in VS Code](https://code.visualstudio.com/docs/python/python-tutorial)
- [PowerShell in VS Code](https://docs.microsoft.com/en-us/powershell/scripting/dev-cross-plat/vscode/using-vscode)

---

*💡 **Wskazówka**: Po zainstalowaniu wszystkich rozszerzeń, restart VS Code dla pełnej funkcjonalności.*
