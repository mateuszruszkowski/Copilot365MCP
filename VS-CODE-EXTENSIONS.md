# 📦 Rozszerzenia VS Code dla warsztatu Copilot 365 MCP

## 🎯 WYMAGANE ROZSZERZENIA (zainstaluj wszystkie)

### ☁️ Azure Development
```bash
code --install-extension ms-vscode.azure-account
code --install-extension ms-azuretools.vscode-azurefunctions  
code --install-extension ms-azuretools.vscode-azureresourcegroups
```

### 🤖 Microsoft Teams
```bash
code --install-extension TeamsDevApp.ms-teams-vscode-extension
```

### 🐍 Python Development
```bash
code --install-extension ms-python.python
```

### 💙 PowerShell
```bash
code --install-extension ms-vscode.powershell
```

### 🚀 JavaScript/TypeScript
```bash
code --install-extension ms-vscode.vscode-typescript-next
```

## 🔧 ZALECANE ROZSZERZENIA (opcjonalne ale przydatne)

### 🐳 Containerization & DevOps
```bash
code --install-extension ms-azuretools.vscode-docker
code --install-extension ms-vscode.azure-pipelines
code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools
```

### 📊 Git & Version Control
```bash
code --install-extension eamodio.gitlens
```

### 🛠️ Development Utilities
```bash
code --install-extension humao.rest-client
code --install-extension ms-vscode.vscode-json
```

### ☁️ Infrastructure as Code
```bash
code --install-extension ms-azuretools.vscode-bicep
code --install-extension hashicorp.terraform
```

## ⚡ Instalacja wszystkich naraz

### Kluczowe rozszerzenia (kopiuj i wklej do terminala):
```bash
code --install-extension ms-vscode.azure-account && code --install-extension ms-azuretools.vscode-azurefunctions && code --install-extension ms-vscode.powershell && code --install-extension ms-python.python && code --install-extension TeamsDevApp.ms-teams-vscode-extension && code --install-extension ms-azuretools.vscode-docker && code --install-extension eamodio.gitlens
```

### Wszystkie rozszerzenia (kopiuj i wklej do terminala):
```bash
code --install-extension ms-vscode.azure-account && code --install-extension ms-azuretools.vscode-azurefunctions && code --install-extension ms-azuretools.vscode-azureresourcegroups && code --install-extension TeamsDevApp.ms-teams-vscode-extension && code --install-extension ms-python.python && code --install-extension ms-vscode.powershell && code --install-extension ms-vscode.vscode-typescript-next && code --install-extension ms-azuretools.vscode-docker && code --install-extension ms-vscode.azure-pipelines && code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools && code --install-extension eamodio.gitlens && code --install-extension humao.rest-client && code --install-extension ms-vscode.vscode-json && code --install-extension ms-azuretools.vscode-bicep && code --install-extension hashicorp.terraform
```

## ✅ Weryfikacja instalacji

### Sprawdzenie zainstalowanych rozszerzeń:
```bash
code --list-extensions | findstr -i "azure\|teams\|python\|powershell\|docker\|gitlens"
```

### Sprawdź czy kluczowe rozszerzenia są zainstalowane:
```bash
code --list-extensions | findstr -E "(azure-account|vscode-azurefunctions|ms-teams-vscode-extension|python|powershell)"
```

## 🔧 Konfiguracja po instalacji

### 1. Azure Account
1. Otwórz VS Code
2. Wciśnij `Ctrl+Shift+P`
3. Wpisz: `Azure: Sign In`
4. Zaloguj się kontem z subskrypcją: `2e539821-ff47-4b8a-9f5a-200de5bb3e8d`

### 2. Teams Toolkit
1. Wciśnij `Ctrl+Shift+P`
2. Wpisz: `Teams: Sign in to Microsoft 365`
3. Zaloguj się do konta Developer

### 3. Python
1. Wciśnij `Ctrl+Shift+P`  
2. Wpisz: `Python: Select Interpreter`
3. Wybierz Python 3.9+ (najlepiej w virtual environment)

## 🚨 Troubleshooting

### Problem: "Extension not found"
```bash
# Odśwież VS Code extensions
code --list-extensions --show-versions
# Lub reinstaluj VS Code
```

### Problem: "Azure sign in failed"  
```bash
# Wyloguj i zaloguj ponownie
# Ctrl+Shift+P → Azure: Sign Out → Azure: Sign In
```

### Problem: "Teams Toolkit nie działa"
```bash
# Sprawdź czy masz konto Microsoft 365 Developer
# https://developer.microsoft.com/microsoft-365/dev-program
```

## 📋 Rozszerzenia według funkcji

### **Azure Cloud Development**
- `ms-vscode.azure-account` - Zarządzanie kontami Azure
- `ms-azuretools.vscode-azurefunctions` - Azure Functions
- `ms-azuretools.vscode-azureresourcegroups` - Resource Groups
- `ms-azuretools.vscode-bicep` - Infrastructure as Code

### **Microsoft Teams Development**  
- `TeamsDevApp.ms-teams-vscode-extension` - Teams applications

### **Programming Languages**
- `ms-python.python` - Python development
- `ms-vscode.powershell` - PowerShell scripting
- `ms-vscode.vscode-typescript-next` - TypeScript/JavaScript

### **DevOps & Containers**
- `ms-azuretools.vscode-docker` - Docker containers
- `ms-vscode.azure-pipelines` - CI/CD pipelines
- `ms-kubernetes-tools.vscode-kubernetes-tools` - Kubernetes

### **Git & Collaboration**
- `eamodio.gitlens` - Enhanced Git capabilities

### **Utilities & Testing**
- `humao.rest-client` - HTTP API testing
- `ms-vscode.vscode-json` - Enhanced JSON editing

---

*💡 **Tip**: Otwórz workspace `Copilot365MCP.code-workspace` - VS Code automatycznie zaproponuje instalację rekomendowanych rozszerzeń!*
