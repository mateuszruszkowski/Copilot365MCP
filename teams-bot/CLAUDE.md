# CLAUDE.md - Teams Bot

## 📋 Opis modułu

Moduł `teams-bot` zawiera implementację bota Microsoft Teams z integracją Model Context Protocol (MCP). Bot umożliwia interakcję z narzędziami DevOps bezpośrednio z czatu Teams, wykorzystując te same serwery MCP co Copilot Studio.

## 🎯 Cel

Zapewnić alternatywny interfejs do narzędzi MCP poprzez Microsoft Teams, umożliwiając zespołom współpracę i automatyzację bez opuszczania środowiska komunikacyjnego.

## 📁 Struktura plików

```
teams-bot/
├── src/
│   ├── index.ts         # Główny plik bota
│   ├── bot.ts           # Logika bota Teams
│   ├── mcp-client.ts    # Klient MCP
│   └── cards/           # Adaptive Cards templates
├── package.json         # Zależności Node.js
├── tsconfig.json       # Konfiguracja TypeScript
├── .env.example        # Przykładowa konfiguracja
├── manifest/           # Teams App manifest
│   ├── manifest.json   # Definicja aplikacji Teams
│   └── icons/          # Ikony aplikacji
└── CLAUDE.md           # Ten plik
```

## 🤖 Funkcjonalności

### Komendy czatu

1. **@BotName help**
   - Wyświetla dostępne komendy
   - Pokazuje przykłady użycia

2. **@BotName list tasks**
   - Wyświetla zadania z Azure DevOps
   - Filtrowanie po stanie i przypisaniu

3. **@BotName create task [title]**
   - Tworzy nowe zadanie
   - Zwraca link do zadania

4. **@BotName check pipeline [name]**
   - Sprawdza status pipeline
   - Pokazuje ostatnie wykonania

5. **@BotName deploy to [environment]**
   - Uruchamia deployment
   - Wymaga potwierdzenia

### Adaptive Cards

Bot używa interaktywnych kart do:
- Wyświetlania szczegółów zadań
- Potwierdzania akcji
- Pokazywania statusów pipeline
- Formularzy tworzenia zadań

### Notyfikacje

- Powiadomienia o zakończonych buildach
- Alerty o błędach pipeline
- Przypomnienia o zadaniach

## 🚀 Konfiguracja

### 1. Rejestracja aplikacji Teams

```powershell
# Utwórz App Registration w Azure AD
az ad app create --display-name "MCP DevOps Bot"

# Zapisz App ID i Secret
$appId = "your-app-id"
$appSecret = "your-app-secret"
```

### 2. Zmienne środowiskowe

```env
# Bot Framework
MicrosoftAppId=your-app-id
MicrosoftAppPassword=your-app-secret
MicrosoftAppTenantId=your-tenant-id

# MCP Server
MCP_SERVER_URL=https://your-mcp-function.azurewebsites.net
MCP_SERVER_KEY=your-function-key

# Azure DevOps (jeśli bot łączy się bezpośrednio)
AZURE_DEVOPS_ORG_URL=https://dev.azure.com/your-org
AZURE_DEVOPS_PAT=your-pat-token
```

### 3. Lokalne uruchomienie

```bash
# Instalacja zależności
npm install

# Build
npm run build

# Uruchomienie z ngrok
npm run start:tunnel

# Bot będzie dostępny na:
# https://your-ngrok-url.ngrok.io/api/messages
```

### 4. Instalacja w Teams

1. Otwórz Teams Developer Portal
2. Import app package z `manifest/` 
3. Dodaj bot do zespołu lub czatu

## 🌩️ Deployment

### Azure Web App

```bash
# Build dla produkcji
npm run build:prod

# Deploy do Azure
az webapp deployment source config-zip \
  --resource-group mcp-workshop-rg \
  --name mcp-teams-bot \
  --src dist.zip
```

### Docker

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --production
COPY dist/ ./dist/
EXPOSE 3978
CMD ["node", "dist/index.js"]
```

## 🔧 Integracja z MCP

### Architektura

```
Teams Client
    ↓
Teams Bot (Node.js)
    ↓
MCP Client SDK
    ↓
MCP Server (Azure Function)
    ↓
Azure DevOps API
```

### Przykład wywołania MCP

```typescript
// W bot.ts
import { MCPClient } from './mcp-client';

async function handleListTasks(context: TurnContext) {
  const mcp = new MCPClient(process.env.MCP_SERVER_URL);
  
  const result = await mcp.callTool('list_work_items', {
    project: 'MyProject',
    assignedTo: context.activity.from.name
  });
  
  // Konwersja na Adaptive Card
  const card = createTaskListCard(result);
  await context.sendActivity({ attachments: [card] });
}
```

## 🧪 Testowanie

### Bot Framework Emulator

1. Pobierz [Bot Framework Emulator](https://github.com/Microsoft/BotFramework-Emulator)
2. Połącz z `http://localhost:3978/api/messages`
3. Ustaw App ID i Password

### Testy jednostkowe

```bash
# Uruchom testy
npm test

# Z coverage
npm run test:coverage
```

### Testy w Teams

1. Użyj Teams Developer Portal
2. Upload manifest jako "Custom app"
3. Testuj w prywatnym zespole

## 📊 Monitorowanie

### Application Insights

Bot automatycznie loguje:
- Wszystkie konwersacje
- Wywołania MCP
- Błędy i wyjątki
- Custom events

### Dashboardy

Przykładowe KQL queries:

```kql
// Najpopularniejsze komendy
customEvents
| where name == "BotCommand"
| summarize count() by tostring(customDimensions.command)
| render piechart

// Czas odpowiedzi MCP
dependencies
| where name == "MCP Call"
| summarize avg(duration) by bin(timestamp, 1h)
| render timechart
```

## 🔒 Bezpieczeństwo

### Autentykacja

1. **Service-to-Service**
   - Bot używa Managed Identity
   - MCP Server weryfikuje tokeny

2. **User Authentication** 
   - OAuth dla dostępu do zasobów użytkownika
   - SSO z Teams

### Best Practices

- Szyfruj sekrety w Key Vault
- Waliduj wszystkie inputy
- Rate limiting dla komend
- Audit log wszystkich akcji

## 🎨 Dostosowywanie

### Własne komendy

```typescript
// Dodaj do bot.ts
botAdapter.onCommand("custom-command", async (context, args) => {
  // Twoja logika
  const result = await customLogic(args);
  await context.sendActivity(result);
});
```

### Adaptive Cards

Użyj [Adaptive Cards Designer](https://adaptivecards.io/designer/) do tworzenia kart.

## 📚 Zasoby

- [Teams Bot Documentation](https://docs.microsoft.com/microsoftteams/platform/bots/)
- [Bot Framework SDK](https://docs.microsoft.com/azure/bot-service/)
- [Adaptive Cards](https://adaptivecards.io/)
- [MCP Integration Guide](https://modelcontextprotocol.io/docs)

## 🚧 Przyszłe funkcjonalności

- [ ] Wsparcie dla wiadomości głosowych
- [ ] Integracja z Teams Meetings
- [ ] Workflow automation
- [ ] Scheduled tasks
- [ ] Multi-język support

---
*Moduł jest częścią warsztatu Copilot 365 MCP*