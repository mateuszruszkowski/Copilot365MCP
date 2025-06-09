# ✅ CHECKLIST GOTOWOŚCI WARSZTATU - Copilot 365 MCP

## 🎯 PRE-WORKSHOP CHECKLIST

### 📋 Przed warsztatem (instruktor):

- [ ] ✅ **Prezentacja PowerPoint gotowa**
  - `docs/Copilot365-MCP-Workshop-Presentation.pptx`
  - 12 slajdów z kompletną agendą

- [ ] ✅ **Azure Resources skonfigurowane**
  ```powershell
  cd azure-setup
  .\test-azure-config.ps1  # Sprawdź status
  ```
  - Resource Group: `copilot-mcp-workshop-rg`
  - Azure AI Services: `copilotmcpdevai`
  - Azure Functions: `copilotmcpdevfunc`
  - Storage: `copilotmcpdevst`
  - App Insights: `copilotmcpdevinsights`

- [ ] ✅ **MCP Servers wdrożone**
  ```bash
  # Azure Function MCP
  cd mcp-servers/azure-function
  func azure functionapp publish copilotmcpdevfunc
  ```

- [ ] ✅ **Demo scenarios przygotowane**
  - Deployment scenario
  - Pipeline status check
  - Work item creation
  - System commands

### 💻 Uczestnicy (przed warsztatem):

- [ ] **VS Code z rozszerzeniami**
  ```bash
  # Szybka instalacja kluczowych:
  code --install-extension ms-vscode.azure-account
  code --install-extension ms-azuretools.vscode-azurefunctions  
  code --install-extension ms-python.python
  code --install-extension TeamsDevApp.ms-teams-vscode-extension
  ```

- [ ] **Wymagane oprogramowanie**
  - [ ] Node.js >= 18.0.0
  - [ ] Python >= 3.9
  - [ ] PowerShell >= 7.0
  - [ ] Azure CLI >= 2.50.0
  - [ ] Git >= 2.30.0

- [ ] **Konta i dostępy**
  - [ ] Azure Subscription (access)
  - [ ] Microsoft 365 Developer (opcjonalnie)

## 🚀 WORKSHOP DAY CHECKLIST

### 🎬 Setup Live (5 minut):

- [ ] **1. Quick start projektu**
  ```bash
  cd D:\Workshops\Copilot365MCP
  code Copilot365MCP.code-workspace
  ```

- [ ] **2. Azure verification**
  ```powershell
  cd azure-setup
  .\test-azure-config.ps1
  ```

- [ ] **3. Install dependencies (demo)**
  ```bash
  # VS Code Task: "Install All Dependencies"
  # Lub manualnie w każdym katalogu
  ```

### 📱 Demo Scenarios Checklist:

#### **Scenario 1: Azure Function MCP**
- [ ] **Test endpoint**: `curl https://copilotmcpdevfunc.azurewebsites.net/api/McpServer`
- [ ] **Tools available**: deploy_to_azure, check_pipeline_status, get_resource_usage
- [ ] **Demo commands**:
  - List tools: `{"jsonrpc":"2.0","method":"tools/list","id":1}`
  - Deploy: `{"jsonrpc":"2.0","method":"tools/call","params":{"name":"deploy_to_azure","arguments":{"version":"v1.0.0","environment":"staging"}},"id":2}`

#### **Scenario 2: Local DevOps MCP**
- [ ] **Server running**: `python mcp-servers/local-devops/local-mcp-server.py`
- [ ] **Tools available**: docker_build, kubectl_apply, git_status
- [ ] **Demo commands**:
  - Docker list: `docker_ps`
  - Git status: `git_status`

#### **Scenario 3: Desktop Commander MCP**
- [ ] **Server running**: `npm start` w `mcp-servers/desktop-commander`
- [ ] **Tools available**: run_powershell, manage_services, get_system_info
- [ ] **Demo commands**:
  - System info: `get_system_info`
  - PowerShell: `run_powershell` z `Get-Process`

#### **Scenario 4: Teams Bot Integration**
- [ ] **Bot running**: `npm start` w `teams-bot`
- [ ] **Health check**: `curl http://localhost:3978/health`
- [ ] **MCP test**: `curl http://localhost:3978/api/mcp/test`
- [ ] **Demo commands** (w Teams):
  - "help"
  - "deploy v1.0.0 do staging"
  - "status pipeline 123"
  - "utwórz zadanie: Demo task"

### 🧪 Live Testing Checklist:

#### **Test 1: Azure Function MCP**
```bash
curl -X POST https://copilotmcpdevfunc.azurewebsites.net/api/McpServer \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}'
```
- [ ] **Expected**: Lista tools (deploy_to_azure, check_pipeline_status, etc.)

#### **Test 2: Teams Bot Health**
```bash
curl http://localhost:3978/health
```
- [ ] **Expected**: `{"status":"healthy","timestamp":"...","version":"1.0.0"}`

#### **Test 3: MCP Connections Test**
```bash
curl http://localhost:3978/api/mcp/test
```
- [ ] **Expected**: Status wszystkich skonfigurowanych MCP servers

#### **Test 4: End-to-End Teams**
- [ ] **W Teams**: Send message "help" to bot
- [ ] **Expected**: Adaptive card z dostępnymi komendami
- [ ] **W Teams**: Send "deploy v1.0.0 do staging"
- [ ] **Expected**: Deployment card z progress monitoring

### 📊 Monitoring & Diagnostics:

#### **Azure Application Insights**
- [ ] Portal link: `https://portal.azure.com → copilotmcpdevinsights`
- [ ] **Check**: Recent requests, errors, performance

#### **Local Logs**
- [ ] **Azure Functions**: `func logs` w `mcp-servers/azure-function`
- [ ] **Teams Bot**: Console output w VS Code terminal
- [ ] **Python MCP**: stdout w terminalach

### 🎯 Success Criteria:

- [ ] **Wszystkie MCP servers responding** (4/4)
- [ ] **Teams Bot komunikuje się z MCP** 
- [ ] **Azure Function deployed i działa**
- [ ] **Demo scenarios działają** (4/4)
- [ ] **Uczestnicy mogą powtórzyć setup**

## 🚨 Backup Plans:

### **Jeśli Azure nie działa:**
- [ ] **Plan B**: Użyj tylko lokalnych MCP servers
- [ ] **Mock responses**: Włącz `MOCK_MCP_RESPONSES=true` w Teams Bot

### **Jeśli Teams Bot problematyczny:**
- [ ] **Plan B**: Direct MCP testing z curl/Postman
- [ ] **Demo**: Pokaż tylko konsole outputs

### **Jeśli network issues:**
- [ ] **Plan B**: Przygotowane screenshots i recordings
- [ ] **Offline demo**: Pre-recorded video scenarios

## 📝 Post-Workshop:

- [ ] **Feedback collection**: Jak się sprawdziło?
- [ ] **Issues log**: Co wymagało poprawek?
- [ ] **Improvements**: Co można ulepszyć następnym razem?
- [ ] **Resource cleanup**: Czy usunąć Azure resources?

---

## 🎉 READY TO GO!

**Status**: ✅ Wszystkie checkboxy zaznaczone? **WARSZTAT GOTOWY!** 🚀

**Last minute checks**:
```bash
# Quick verification (30 sekund):
cd azure-setup && .\test-azure-config.ps1
cd ../teams-bot && curl http://localhost:3978/health  
cd ../mcp-servers/azure-function && curl https://copilotmcpdevfunc.azurewebsites.net/api/McpServer
```

**Emergency contacts**:
- Azure Support: https://portal.azure.com → Help + Support
- VS Code issues: Help → Toggle Developer Tools  
- Teams Bot issues: https://docs.microsoft.com/en-us/microsoftteams/platform/

---

*💡 **Pro tip**: Wydrukuj ten checklist i używaj podczas warsztatu!*
