# 🚀 COPILOT 365 MCP WORKSHOP - GOTOWY DO URUCHOMIENIA!

## ✅ STATUS: WSZYSTKIE PLIKI NAPRAWIONE

**Data naprawy:** 9 czerwca 2025  
**Pliki zaktualizowane:**
- ✅ `azure-function-mcp-schema.yaml` - Schema dla Copilot Studio
- ✅ `mcp-servers/azure-function/package.json` - Usunięto problematyczną dependency
- ✅ `mcp-servers/desktop-commander/src/index.ts` - Dodano displayName do interface
- ✅ `start-workshop.ps1` - Dodano ngrok i instrukcje Copilot Studio
- ✅ `quick-fix.ps1` - Szybka naprawa dependencies
- ✅ `COPILOT-STUDIO-INSTRUKCJA.md` - Kompletna instrukcja integracji

---

## 🎯 SZYBKI START

### Opcja A: Automatyczna naprawa i uruchomienie
```powershell
# 1. Napraw wszystkie dependencies
.\quick-fix.ps1

# 2. Uruchom warsztat z ngrok
.\start-workshop.ps1

# 3. Skopiuj URL ngrok i postępuj według COPILOT-STUDIO-INSTRUKCJA.md
```

### Opcja B: Krok po kroku (jeśli Opcja A nie działa)
```powershell
# 1. Zatrzymaj procesy
Get-Process -Name "node","func","python" -ErrorAction SilentlyContinue | Stop-Process -Force

# 2. Azure Function
cd mcp-servers\azure-function
npm install
cd ..\..

# 3. Desktop Commander  
cd mcp-servers\desktop-commander
npm install && npm run build
cd ..\..

# 4. Teams Bot
cd teams-bot
npm install
cd ..

# 5. Python MCP
cd mcp-servers\local-devops
pip install -r requirements.txt --upgrade
cd ..\azure-devops
pip install -r requirements.txt --upgrade
cd ..\..

# 6. Uruchom
.\start-workshop.ps1
```

---

## 🌐 COPILOT STUDIO INTEGRATION

### Wymagania:
- Microsoft 365 account
- Copilot Studio access
- Agent "DevOps MCP Assistant" utworzony

### Kroki:
1. **Uruchom serwery:** `.\start-workshop.ps1`
2. **Skopiuj ngrok URL** z output skryptu
3. **Postępuj według:** `COPILOT-STUDIO-INSTRUKCJA.md`

---

## 🧪 TESTY

### Test 1: Azure Function MCP
```bash
curl -X POST http://localhost:7071/api/McpServer \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}'
```

**Oczekiwany wynik:**
```json
{
  "jsonrpc": "2.0",
  "id": "1", 
  "result": {
    "tools": [
      {"name": "deploy_to_azure", "description": "Deploy aplikacji do Azure"},
      {"name": "check_pipeline_status", "description": "Sprawdź status pipeline"},
      {"name": "create_work_item", "description": "Utwórz zadanie w Azure DevOps"},
      {"name": "get_resource_usage", "description": "Sprawdź wykorzystanie zasobów"}
    ]
  }
}
```

### Test 2: Teams Bot
```bash
curl http://localhost:3978/health
```

### Test 3: Copilot Studio
W agencie napisz: "What tools do you have?"

---

## 📁 STRUKTURA PROJEKTU (PO NAPRAWACH)

```
D:\Workshops\Copilot365MCP\
├── 📄 azure-function-mcp-schema.yaml       ← Nowy! Schema dla Copilot Studio
├── 📄 COPILOT-STUDIO-INSTRUKCJA.md        ← Nowy! Instrukcja krok po kroku  
├── 📄 quick-fix.ps1                        ← Nowy! Szybka naprawa
├── 📄 start-workshop.ps1                   ← Zaktualizowany! Z ngrok
├── 🗂️ mcp-servers/
│   ├── 🗂️ azure-function/                   
│   │   └── 📄 package.json                 ← Naprawiony! Bez problematycznej dependency
│   ├── 🗂️ desktop-commander/
│   │   └── 📄 src/index.ts                 ← Naprawiony! Z displayName
│   ├── 🗂️ local-devops/
│   └── 🗂️ azure-devops/
├── 🗂️ teams-bot/                           ← Naprawiony wcześniej
└── 🗂️ docs/
```

---

## 🛠️ NARZĘDZIA MCP (DOSTĘPNE W COPILOT STUDIO)

Po integracji będziesz mieć dostęp do:

### 1. **deploy_to_azure**
- Wdraża aplikacje do środowisk Azure
- Parametry: environment (dev/staging/prod), version, serviceName

### 2. **check_pipeline_status** 
- Sprawdza status pipeline w Azure DevOps
- Parametry: pipelineId, project

### 3. **create_work_item**
- Tworzy zadania w Azure DevOps
- Parametry: title, description, type, assignee, priority

### 4. **get_resource_usage**
- Monitoruje zasoby Azure
- Parametry: resourceGroup, timeRange

---

## 🎮 DEMO SCENARIOS

### Scenario 1: Deployment przez Copilot
```
User: "Deploy version 2.1.0 to staging environment"
Copilot: Uruchamia deploy_to_azure tool
```

### Scenario 2: Monitoring pipeline
```  
User: "Check status of pipeline 12345"
Copilot: Uruchamia check_pipeline_status tool
```

### Scenario 3: Tworzenie zadań
```
User: "Create a bug report for login issues"
Copilot: Uruchamia create_work_item tool
```

---

## ❌ TROUBLESHOOTING

### Problem: npm install errors
```powershell
# Rozwiązanie
.\quick-fix.ps1
```

### Problem: TypeScript compilation errors
```powershell
cd mcp-servers\desktop-commander
npm run build
# Sprawdź czy displayName został dodany do interface ServiceStatus
```

### Problem: Port 7071 zajęty
```powershell
Get-NetTCPConnection -LocalPort 7071 | ForEach-Object {
    Stop-Process -Id $_.OwningProcess -Force
}
```

### Problem: Copilot Studio nie widzi connectora
- Sprawdź czy YAML ma tagi "Agentic" i "McpSse"
- Sprawdź czy Generative Orchestration jest włączona
- Sprawdź czy URL jest dostępny publicznie (ngrok)

---

## 🔧 MAINTENANCE

### Regularne aktualizacje:
```powershell
# Aktualizuj MCP SDK
npm update @modelcontextprotocol/sdk

# Aktualizuj Python dependencies  
pip install -r requirements.txt --upgrade
```

### Monitoring:
- Logi Azure Function w terminalu
- Ngrok dashboard: http://localhost:4040
- Application Insights (jeśli skonfigurowane)

---

## 🎯 SUCCESS CRITERIA

Po pomyślnej konfiguracji powinieneś widzieć:

```
🚀 Workshop Start Script - Copilot 365 MCP Integration
=======================================================
✅ Azure Function - Running
   🌐 HTTP 7071 - OK (200)
✅ Ngrok Tunnel - Running  
   🌐 https://abc123.ngrok.io → localhost:7071
✅ Teams Bot - Running
   🌐 HTTP 3978 - OK (200)

🤖 COPILOT STUDIO INTEGRATION
==============================
✅ Publiczny MCP Server URL (dla Copilot Studio):
   https://abc123.ngrok.io/api/McpServer

🧪 MCP TOOLS TEST
=================
✅ MCP Tools dostępne:
   • deploy_to_azure: Deploy aplikacji do Azure
   • check_pipeline_status: Sprawdź status pipeline
   • create_work_item: Utwórz zadanie w Azure DevOps
   • get_resource_usage: Sprawdź wykorzystanie zasobów
```

**🎉 Workshop gotowy do użycia z Copilot Studio! 🎉**

---

*Ostatnia aktualizacja: 9 czerwca 2025 | Status: ✅ PRODUCTION READY*
