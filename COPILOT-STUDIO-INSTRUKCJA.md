# 🤖 INSTRUKCJA COPILOT STUDIO MCP - KROK PO KROKU

## ✅ WYMAGANIA WSTĘPNE

1. ✅ Microsoft 365 account z dostępem do Copilot Studio
2. ✅ Agent "DevOps MCP Assistant" utworzony w Copilot Studio  
3. ✅ Uruchomiony Azure Function MCP (localhost:7071)
4. ✅ Plik `azure-function-mcp-schema.yaml` (już utworzony)

---

## 🚀 KROK 1: URUCHOM SERWERY MCP

```powershell
# Uruchom wszystkie serwery z ngrok
.\start-workshop.ps1

# LUB bez ngrok (lokalnie)
.\start-workshop.ps1 -SkipNgrok
```

**Sprawdź czy Azure Function działa:**
```powershell
curl http://localhost:7071/api/McpServer
```

---

## 🌐 KROK 2: PRZYGOTUJ PUBLICZNY URL (OPCJA A - NGROK)

Jeśli masz ngrok:
```powershell
# Ngrok uruchomi się automatycznie w start-workshop.ps1
# Skopiuj URL który pokaże skrypt, np:
# https://abc123-def456.ngrok-free.app
```

**Zaktualizuj plik YAML:**
1. Otwórz `azure-function-mcp-schema.yaml`
2. Zmień linię `host: localhost:7071` na `host: abc123-def456.ngrok-free.app`
3. Zmień `schemes: - http` na `schemes: - https`

---

## 🌐 KROK 2: PRZYGOTUJ PUBLICZNY URL (OPCJA B - AZURE DEPLOYMENT)

Jeśli nie masz ngrok, deploy do Azure:
```powershell
cd mcp-servers\azure-function
func azure functionapp publish your-function-name

# Potem zaktualizuj YAML:
# host: your-function-name.azurewebsites.net
```

---

## 🔧 KROK 3: UTWÓRZ CUSTOM CONNECTOR

### 3.1 Przejdź do Copilot Studio
1. Otwórz https://copilotstudio.microsoft.com
2. Zaloguj się swoim kontem Microsoft 365

### 3.2 Otwórz swojego agenta
1. W lewym menu kliknij **"Agents"**
2. Znajdź i kliknij **"DevOps MCP Assistant"**

### 3.3 Dodaj Custom Connector  
1. Kliknij kartę **"Actions"** (lub **"Akcje"**)
2. Kliknij **"Add an action"** (lub **"Dodaj akcję"**)
3. Wybierz **"New action"**
4. Wybierz **"New custom connector"**

### 3.4 Power Apps - Import OpenAPI
**Zostaniesz przekierowany do Power Apps:**

1. Kliknij **"New custom connector"**
2. Wybierz **"Import OpenAPI file"**
3. Kliknij **"Import"** i wybierz plik `azure-function-mcp-schema.yaml`
4. Kliknij **"Continue"**

### 3.5 Konfiguracja w Power Apps
1. **General tab:**
   - Description: "DevOps MCP Server for automation"
   - Host: Twój URL (ngrok lub Azure)

2. **Security tab:**
   - Authentication type: "No authentication"

3. **Definition tab:**
   - Sprawdź czy endpoints są poprawnie zaimportowane
   - Powinny być tagi: "Agentic" i "McpSse"

4. **Test tab:**
   - Kliknij **"New connection"**
   - Kliknij **"Create connector"**

---

## 🔗 KROK 4: DODAJ MCP DO AGENTA

### 4.1 Wróć do Copilot Studio
1. Wróć do karty z Copilot Studio
2. Odśwież stronę jeśli potrzeba

### 4.2 Dodaj MCP Connector
1. W agencie **"DevOps MCP Assistant"**
2. Karta **"Actions"** → **"Add an action"**
3. Wybierz **"Connector"**
4. Znajdź swój connector **"DevOps MCP Assistant"**
5. Kliknij **"Next"**
6. **"Add to agent"**

---

## 🧪 KROK 5: TEST INTEGRACJI

### 5.1 Test w Copilot Studio
W agencie napisz:
```
What tools do you have?
```

### 5.2 Test narzędzi MCP
```
Deploy version 1.2.3 to staging environment
```

```
Check status of pipeline 12345
```

```
Create a new bug report titled "Login issue"
```

### 5.3 Sprawdź logi
W terminalu gdzie działa Azure Function zobaczysz logi MCP calls.

---

## ❌ TROUBLESHOOTING

### Problem 1: Connector nie pojawia się w liście
**Rozwiązanie:**
- Sprawdź czy connector ma tagi "Agentic" i "McpSse"
- Odśwież Copilot Studio
- Sprawdź czy Generative Orchestration jest włączona

### Problem 2: "SystemError" w Copilot Studio  
**Rozwiązanie:**
- Sprawdź czy Azure Function odpowiada: `curl YOUR_URL/api/McpServer`
- Sprawdź logi Azure Function
- Sprawdź czy YAML schema jest poprawny

### Problem 3: Tools nie działają
**Rozwiązanie:**
- Test MCP bezpośrednio:
```bash
curl -X POST YOUR_URL/api/McpServer \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}'
```

### Problem 4: Ngrok URL się zmienia
**Rozwiązanie:**
- Zaktualizuj host w YAML schema
- Reimport connector w Power Apps

---

## 🎯 SUKCES!

Jeśli wszystko działa, powinieneś widzieć:
- ✅ Agent odpowiada na pytania o narzędzia
- ✅ Agent wykonuje komendy deploy/status/create
- ✅ Logi MCP pojawiają się w terminalu
- ✅ W Copilot Studio widać "MCP tools available"

---

## 📋 NASTĘPNE KROKI

1. **Rozbuduj narzędzia MCP** - dodaj więcej funkcji do Azure Function
2. **Dodaj autentykację** - Azure AD, API keys
3. **Deploy do produkcji** - Azure App Service, security hardening
4. **Teams integration** - dodaj bota do Teams
5. **Monitoring** - Application Insights, logging

---

🎉 **Gratulacje! Masz działającą integrację MCP + Copilot Studio!** 🎉
