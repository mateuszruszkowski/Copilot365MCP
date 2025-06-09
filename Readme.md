# Szczegółowa instrukcja warsztatowa: Integracja Copilot 365 w Teams z MCP dla Junior DevOps

## Wprowadzenie i kontekst BUILD 2025

Microsoft BUILD 2025 wprowadził przełomowe rozwiązania w zakresie integracji AI z narzędziami DevOps. Kluczowym ogłoszeniem jest **natywne wsparcie dla Model Context Protocol (MCP)** w całym ekosystemie Microsoft, włączając Copilot Studio, Teams, Azure AI Foundry i Windows 11. MCP działa jak "USB-C dla AI" - uniwersalny protokół umożliwiający komunikację między asystentami AI a zewnętrznymi narzędziami.

## 1. Najnowsze rozwiązania z Microsoft BUILD 2025

### 1.1 Copilot 365 - Kluczowe nowości

**Microsoft 365 Copilot Tuning (czerwiec 2025)**
- Możliwość dostosowania modeli AI do specyficznych potrzeb organizacji
- Low-code customization dla organizacji z 5000+ licencjami
- Integracja z danymi firmowymi z zachowaniem bezpieczeństwa

**Multi-Agent Orchestration**
- Współpraca wielu wyspecjalizowanych agentów AI
- Protokół Agent2Agent (A2A) dla bezpiecznej komunikacji peer-to-peer
- Wsparcie dla agentów z Copilot Studio, Azure AI Foundry i Microsoft 365 Agents SDK

**Teams AI Library (GA)**
- Uproszczone tworzenie aplikacji AI dla Teams
- Natywne wsparcie dla MCP
- Pamięć długoterminowa dla ciągłości konwersacji

### 1.2 MCP - Model Context Protocol

**Architektura MCP:**
```
[Aplikacja AI] ←→ [Klient MCP] ←→ [Serwer MCP] ←→ [Systemy zewnętrzne]
   (Copilot)       (Protokół)      (Adapter)        (API/Dane)
```

**Kluczowe komponenty:**
- **Tools**: Funkcje wywoływane przez AI
- **Resources**: Źródła danych dostępne dla kontekstu
- **Prompts**: Predefiniowane szablony interakcji

## 2. Konfiguracja zasobów Azure - krok po kroku

### 2.1 Przygotowanie środowiska

```bash
# Instalacja wymaganych narzędzi
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
npm install -g azure-functions-core-tools@4 --unsafe-perm true
npm install -g @microsoft/teams-toolkit-cli

# Logowanie do Azure
az login
az account set --subscription "your-subscription-id"
```

### 2.2 Tworzenie podstawowej infrastruktury

```bash
# Zmienne środowiskowe
export RESOURCE_GROUP="copilot-mcp-workshop-rg"
export LOCATION="West Europe"
export PROJECT_NAME="copilot-mcp"
export ENVIRONMENT="dev"

# Tworzenie grupy zasobów
az group create \
  --name $RESOURCE_GROUP \
  --location "$LOCATION" \
  --tags Environment=$ENVIRONMENT Project=$PROJECT_NAME

# Application Insights dla monitoringu
az extension add --name application-insights
APPINSIGHTS_NAME="${PROJECT_NAME}-${ENVIRONMENT}-ai"

az monitor app-insights component create \
  --app $APPINSIGHTS_NAME \
  --location "$LOCATION" \
  --resource-group $RESOURCE_GROUP \
  --tags Environment=$ENVIRONMENT Project=$PROJECT_NAME

# Pobranie klucza instrumentacji
APPINSIGHTS_KEY=$(az monitor app-insights component show \
  --app $APPINSIGHTS_NAME \
  --resource-group $RESOURCE_GROUP \
  --query instrumentationKey -o tsv)
```

### 2.3 Konfiguracja Azure AI Services

```bash
# Tworzenie Azure AI Services
AI_SERVICE_NAME="${PROJECT_NAME}-${ENVIRONMENT}-ai-service"

az cognitiveservices account create \
  --name $AI_SERVICE_NAME \
  --resource-group $RESOURCE_GROUP \
  --kind CognitiveServices \
  --sku S0 \
  --location "$LOCATION" \
  --tags Environment=$ENVIRONMENT Project=$PROJECT_NAME

# Pobranie endpoint i klucza
AI_ENDPOINT=$(az cognitiveservices account show \
  --name $AI_SERVICE_NAME \
  --resource-group $RESOURCE_GROUP \
  --query properties.endpoint -o tsv)

AI_KEY=$(az cognitiveservices account keys list \
  --name $AI_SERVICE_NAME \
  --resource-group $RESOURCE_GROUP \
  --query key1 -o tsv)
```

## 3. Konfiguracja serwerów MCP

### 3.1 Uruchamianie serwera MCP w chmurze (Azure Functions)

**Struktura projektu:**
```
mcp-azure-function/
├── host.json
├── local.settings.json
├── package.json
└── McpServer/
    ├── function.json
    └── index.js
```

**package.json:**
```json
{
  "name": "mcp-azure-function",
  "version": "1.0.0",
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.0.0",
    "@azure/functions": "^4.0.0"
  }
}
```

**McpServer/index.js:**
```javascript
const { app } = require('@azure/functions');
const { Server } = require('@modelcontextprotocol/sdk/server/index.js');

// Inicjalizacja serwera MCP
const mcpServer = new Server(
  {
    name: 'azure-devops-mcp',
    version: '1.0.0'
  },
  {
    capabilities: {
      tools: {},
      resources: {}
    }
  }
);

// Rejestracja narzędzi DevOps
mcpServer.setRequestHandler('tools/list', async () => {
  return {
    tools: [
      {
        name: 'deploy_to_azure',
        description: 'Deploy aplikacji do Azure',
        inputSchema: {
          type: 'object',
          properties: {
            environment: { type: 'string', enum: ['dev', 'staging', 'prod'] },
            version: { type: 'string' }
          },
          required: ['environment', 'version']
        }
      },
      {
        name: 'check_pipeline_status',
        description: 'Sprawdź status pipeline w Azure DevOps',
        inputSchema: {
          type: 'object',
          properties: {
            pipelineId: { type: 'string' }
          },
          required: ['pipelineId']
        }
      }
    ]
  };
});

// Obsługa wywołań narzędzi
mcpServer.setRequestHandler('tools/call', async (request) => {
  const { name, arguments: args } = request.params;
  
  switch (name) {
    case 'deploy_to_azure':
      return await deployToAzure(args);
    case 'check_pipeline_status':
      return await checkPipelineStatus(args);
    default:
      throw new Error(`Nieznane narzędzie: ${name}`);
  }
});

// Funkcja Azure
app.http('McpServer', {
  methods: ['POST'],
  authLevel: 'function',
  handler: async (request, context) => {
    const body = await request.json();
    
    // Przetwarzanie żądania MCP
    const response = await mcpServer.handleRequest(body);
    
    return {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(response)
    };
  }
});

// Funkcje pomocnicze
async function deployToAzure({ environment, version }) {
  // Logika deploymentu
  const deploymentId = `deploy-${Date.now()}`;
  
  return {
    content: [{
      type: 'text',
      text: `Rozpoczęto deployment wersji ${version} do środowiska ${environment}. ID: ${deploymentId}`
    }]
  };
}

async function checkPipelineStatus({ pipelineId }) {
  // Sprawdzanie statusu pipeline
  return {
    content: [{
      type: 'text',
      text: `Pipeline ${pipelineId} - Status: Success, Ostatnie uruchomienie: 5 minut temu`
    }]
  };
}
```

**Deployment do Azure:**
```bash
# Tworzenie Function App
FUNCTION_APP_NAME="${PROJECT_NAME}-${ENVIRONMENT}-mcp-func"
STORAGE_NAME="${PROJECT_NAME}${ENVIRONMENT}st"

# Storage Account
az storage account create \
  --name $STORAGE_NAME \
  --resource-group $RESOURCE_GROUP \
  --location "$LOCATION" \
  --sku Standard_LRS

# Function App
az functionapp create \
  --resource-group $RESOURCE_GROUP \
  --consumption-plan-location "$LOCATION" \
  --runtime node \
  --runtime-version 18 \
  --functions-version 4 \
  --name $FUNCTION_APP_NAME \
  --storage-account $STORAGE_NAME \
  --app-insights $APPINSIGHTS_NAME

# Konfiguracja zmiennych środowiskowych
az functionapp config appsettings set \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --settings \
    "AI_ENDPOINT=$AI_ENDPOINT" \
    "AI_KEY=$AI_KEY" \
    "AZURE_DEVOPS_ORG=https://dev.azure.com/yourorg" \
    "AZURE_DEVOPS_PAT=your-personal-access-token"

# Deployment
cd mcp-azure-function
func azure functionapp publish $FUNCTION_APP_NAME
```

### 3.2 Uruchamianie serwera MCP lokalnie

**Lokalny serwer MCP (Python):**
```python
#!/usr/bin/env python3
import asyncio
import os
from mcp.server import Server
from mcp.server.stdio import stdio_server
import mcp.types as types

# Inicjalizacja serwera
server = Server("local-devops-mcp")

@server.list_tools()
async def handle_list_tools() -> list[types.Tool]:
    return [
        types.Tool(
            name="docker_build",
            description="Zbuduj obraz Docker",
            inputSchema={
                "type": "object",
                "properties": {
                    "dockerfile": {"type": "string"},
                    "tag": {"type": "string"}
                },
                "required": ["dockerfile", "tag"]
            }
        ),
        types.Tool(
            name="kubectl_apply",
            description="Zastosuj konfigurację Kubernetes",
            inputSchema={
                "type": "object",
                "properties": {
                    "manifest": {"type": "string"},
                    "namespace": {"type": "string"}
                },
                "required": ["manifest"]
            }
        )
    ]

@server.call_tool()
async def handle_call_tool(name: str, arguments: dict) -> list[types.TextContent]:
    if name == "docker_build":
        dockerfile = arguments["dockerfile"]
        tag = arguments["tag"]
        # Wykonaj build Docker
        result = f"Budowanie obrazu {tag} z {dockerfile}"
        return [types.TextContent(type="text", text=result)]
    
    elif name == "kubectl_apply":
        manifest = arguments["manifest"]
        namespace = arguments.get("namespace", "default")
        # Zastosuj manifest
        result = f"Zastosowano {manifest} w namespace {namespace}"
        return [types.TextContent(type="text", text=result)]
    
    raise ValueError(f"Nieznane narzędzie: {name}")

async def main():
    async with stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            server.create_initialization_options()
        )

if __name__ == "__main__":
    asyncio.run(main())
```

**Konfiguracja dla Claude Desktop:**
```json
{
  "mcpServers": {
    "local-devops": {
      "command": "python",
      "args": ["/path/to/local-mcp-server.py"],
      "env": {
        "KUBECONFIG": "/home/user/.kube/config"
      }
    }
  }
}
```

### 3.3 Desktop Commander lokalnie

**Desktop Commander MCP Server:**
```typescript
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

const server = new Server(
  {
    name: 'desktop-commander',
    version: '1.0.0'
  },
  {
    capabilities: {
      tools: {}
    }
  }
);

// Lista narzędzi desktop
server.setRequestHandler('tools/list', async () => {
  return {
    tools: [
      {
        name: 'run_powershell',
        description: 'Wykonaj komendę PowerShell',
        inputSchema: {
          type: 'object',
          properties: {
            command: { type: 'string' }
          },
          required: ['command']
        }
      },
      {
        name: 'manage_services',
        description: 'Zarządzaj usługami Windows',
        inputSchema: {
          type: 'object',
          properties: {
            action: { type: 'string', enum: ['start', 'stop', 'restart'] },
            service: { type: 'string' }
          },
          required: ['action', 'service']
        }
      }
    ]
  };
});

// Obsługa wywołań
server.setRequestHandler('tools/call', async (request) => {
  const { name, arguments: args } = request.params;
  
  if (name === 'run_powershell') {
    try {
      const { stdout, stderr } = await execAsync(
        `powershell -Command "${args.command}"`
      );
      return {
        content: [{
          type: 'text',
          text: stdout || stderr
        }]
      };
    } catch (error) {
      return {
        content: [{
          type: 'text',
          text: `Błąd: ${error.message}`
        }]
      };
    }
  }
  
  if (name === 'manage_services') {
    const command = {
      start: `Start-Service -Name ${args.service}`,
      stop: `Stop-Service -Name ${args.service}`,
      restart: `Restart-Service -Name ${args.service}`
    }[args.action];
    
    try {
      await execAsync(`powershell -Command "${command}"`);
      return {
        content: [{
          type: 'text',
          text: `Usługa ${args.service} - akcja ${args.action} wykonana pomyślnie`
        }]
      };
    } catch (error) {
      return {
        content: [{
          type: 'text',
          text: `Błąd: ${error.message}`
        }]
      };
    }
  }
  
  throw new Error(`Nieznane narzędzie: ${name}`);
});

// Uruchomienie serwera
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('Desktop Commander MCP Server uruchomiony');
}

main().catch(console.error);
```

### 3.4 MCP do obsługi zadań w Azure DevOps

**Azure DevOps MCP Server:**
```python
import asyncio
import aiohttp
from mcp.server import Server
from mcp.server.stdio import stdio_server
import mcp.types as types
import base64
import os

class AzureDevOpsMCPServer:
    def __init__(self):
        self.server = Server("azure-devops-mcp")
        self.org_url = os.getenv("AZURE_DEVOPS_ORG")
        self.pat = os.getenv("AZURE_DEVOPS_PAT")
        self.headers = {
            "Authorization": f"Basic {base64.b64encode(f':{self.pat}'.encode()).decode()}",
            "Content-Type": "application/json"
        }
        
        # Rejestracja handlerów
        self.server.list_tools()(self.handle_list_tools)
        self.server.call_tool()(self.handle_call_tool)
        self.server.list_resources()(self.handle_list_resources)
        self.server.read_resource()(self.handle_read_resource)
    
    async def handle_list_tools(self) -> list[types.Tool]:
        return [
            types.Tool(
                name="create_work_item",
                description="Utwórz nowe zadanie w Azure DevOps",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "title": {"type": "string"},
                        "description": {"type": "string"},
                        "type": {"type": "string", "enum": ["Bug", "Task", "Feature"]},
                        "assignee": {"type": "string"}
                    },
                    "required": ["title", "type"]
                }
            ),
            types.Tool(
                name="run_pipeline",
                description="Uruchom pipeline CI/CD",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "pipelineId": {"type": "string"},
                        "branch": {"type": "string"}
                    },
                    "required": ["pipelineId"]
                }
            ),
            types.Tool(
                name="query_work_items",
                description="Wyszukaj zadania w Azure DevOps",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "query": {"type": "string"}
                    },
                    "required": ["query"]
                }
            )
        ]
    
    async def handle_call_tool(self, name: str, arguments: dict) -> list[types.TextContent]:
        async with aiohttp.ClientSession() as session:
            if name == "create_work_item":
                return await self.create_work_item(session, arguments)
            elif name == "run_pipeline":
                return await self.run_pipeline(session, arguments)
            elif name == "query_work_items":
                return await self.query_work_items(session, arguments)
            else:
                raise ValueError(f"Nieznane narzędzie: {name}")
    
    async def create_work_item(self, session, args):
        url = f"{self.org_url}/_apis/wit/workitems/${args['type']}?api-version=7.1"
        
        operations = [
            {
                "op": "add",
                "path": "/fields/System.Title",
                "value": args["title"]
            }
        ]
        
        if "description" in args:
            operations.append({
                "op": "add",
                "path": "/fields/System.Description",
                "value": args["description"]
            })
        
        if "assignee" in args:
            operations.append({
                "op": "add",
                "path": "/fields/System.AssignedTo",
                "value": args["assignee"]
            })
        
        async with session.post(
            url,
            json=operations,
            headers={**self.headers, "Content-Type": "application/json-patch+json"}
        ) as response:
            if response.status == 200:
                data = await response.json()
                return [types.TextContent(
                    type="text",
                    text=f"Utworzono zadanie #{data['id']}: {data['fields']['System.Title']}"
                )]
            else:
                return [types.TextContent(
                    type="text",
                    text=f"Błąd tworzenia zadania: {response.status}"
                )]
    
    async def run_pipeline(self, session, args):
        url = f"{self.org_url}/_apis/pipelines/{args['pipelineId']}/runs?api-version=7.1"
        
        body = {
            "resources": {
                "repositories": {
                    "self": {
                        "refName": f"refs/heads/{args.get('branch', 'main')}"
                    }
                }
            }
        }
        
        async with session.post(url, json=body, headers=self.headers) as response:
            if response.status in [200, 201]:
                data = await response.json()
                return [types.TextContent(
                    type="text",
                    text=f"Uruchomiono pipeline: {data['name']} (Run #{data['id']})"
                )]
            else:
                return [types.TextContent(
                    type="text",
                    text=f"Błąd uruchamiania pipeline: {response.status}"
                )]
    
    async def handle_list_resources(self) -> list[types.Resource]:
        return [
            types.Resource(
                uri="azuredevops://projects",
                name="Projekty Azure DevOps",
                description="Lista projektów w organizacji"
            ),
            types.Resource(
                uri="azuredevops://pipelines",
                name="Pipelines CI/CD",
                description="Lista dostępnych pipelines"
            )
        ]
    
    async def handle_read_resource(self, uri: str) -> str:
        async with aiohttp.ClientSession() as session:
            if uri == "azuredevops://projects":
                url = f"{self.org_url}/_apis/projects?api-version=7.1"
                async with session.get(url, headers=self.headers) as response:
                    if response.status == 200:
                        data = await response.json()
                        projects = [p["name"] for p in data["value"]]
                        return f"Projekty: {', '.join(projects)}"
                    else:
                        return f"Błąd pobierania projektów: {response.status}"
            
            elif uri == "azuredevops://pipelines":
                # Pobierz pierwszy projekt
                url = f"{self.org_url}/_apis/projects?api-version=7.1"
                async with session.get(url, headers=self.headers) as response:
                    if response.status == 200:
                        data = await response.json()
                        if data["value"]:
                            project = data["value"][0]["name"]
                            # Pobierz pipelines
                            url = f"{self.org_url}/{project}/_apis/pipelines?api-version=7.1"
                            async with session.get(url, headers=self.headers) as resp:
                                if resp.status == 200:
                                    pipeline_data = await resp.json()
                                    pipelines = [p["name"] for p in pipeline_data["value"]]
                                    return f"Pipelines: {', '.join(pipelines)}"
                return "Brak dostępnych pipelines"
            
            raise ValueError(f"Nieznany zasób: {uri}")
    
    async def run(self):
        async with stdio_server() as (read_stream, write_stream):
            await self.server.run(
                read_stream,
                write_stream,
                self.server.create_initialization_options()
            )

if __name__ == "__main__":
    server = AzureDevOpsMCPServer()
    asyncio.run(server.run())
```

**Konfiguracja dla środowiska chmurowego:**
```yaml
# azure-devops-mcp-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: azure-devops-mcp-server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: azure-devops-mcp
  template:
    metadata:
      labels:
        app: azure-devops-mcp
    spec:
      containers:
      - name: mcp-server
        image: your-registry.azurecr.io/azure-devops-mcp:latest
        ports:
        - containerPort: 8080
        env:
        - name: AZURE_DEVOPS_ORG
          valueFrom:
            secretKeyRef:
              name: azure-devops-secrets
              key: org-url
        - name: AZURE_DEVOPS_PAT
          valueFrom:
            secretKeyRef:
              name: azure-devops-secrets
              key: pat
```

## 4. Integracja z Teams i Copilot 365

### 4.1 Konfiguracja Bot Service dla Teams

```bash
# Tworzenie Bot Service
BOT_NAME="${PROJECT_NAME}-${ENVIRONMENT}-bot"
BOT_ENDPOINT="https://${FUNCTION_APP_NAME}.azurewebsites.net/api/messages"

# Rejestracja aplikacji
APP_ID=$(az ad app create \
  --display-name $BOT_NAME \
  --sign-in-audience AzureADandPersonalMicrosoftAccount \
  --query appId -o tsv)

# Tworzenie hasła aplikacji
APP_SECRET=$(az ad app credential reset \
  --id $APP_ID \
  --query password -o tsv)

# Tworzenie Bot Service
az bot create \
  --resource-group $RESOURCE_GROUP \
  --name $BOT_NAME \
  --kind azurebot \
  --appid $APP_ID \
  --password $APP_SECRET \
  --endpoint $BOT_ENDPOINT

# Włączenie kanału Teams
az bot msteams create \
  --resource-group $RESOURCE_GROUP \
  --name $BOT_NAME
```

### 4.2 Teams Bot z integracją MCP

**teams-mcp-bot/index.js:**
```javascript
const { TeamsActivityHandler, CardFactory } = require('botbuilder');
const { Application, AI, ActionPlanner } = require('@microsoft/teams-ai');
const axios = require('axios');

class TeamsMCPBot extends TeamsActivityHandler {
    constructor(mcpEndpoint) {
        super();
        this.mcpEndpoint = mcpEndpoint;
        
        this.onMessage(async (context, next) => {
            const userMessage = context.activity.text;
            
            // Analiza intencji użytkownika
            const intent = await this.analyzeIntent(userMessage);
            
            // Wywołanie odpowiedniego narzędzia MCP
            if (intent.tool) {
                const result = await this.callMCPTool(intent.tool, intent.parameters);
                await context.sendActivity(this.createAdaptiveCard(result));
            } else {
                await context.sendActivity("Nie rozumiem polecenia. Spróbuj: 'deploy do staging' lub 'sprawdź status pipeline'");
            }
            
            await next();
        });
    }
    
    async analyzeIntent(message) {
        // Prosta analiza intencji (w produkcji użyj Azure Language Service)
        if (message.toLowerCase().includes('deploy')) {
            const match = message.match(/deploy (.+) do (.+)/i);
            if (match) {
                return {
                    tool: 'deploy_to_azure',
                    parameters: {
                        version: match[1],
                        environment: match[2]
                    }
                };
            }
        } else if (message.toLowerCase().includes('status pipeline')) {
            const match = message.match(/pipeline (\d+)/i);
            if (match) {
                return {
                    tool: 'check_pipeline_status',
                    parameters: {
                        pipelineId: match[1]
                    }
                };
            }
        }
        
        return { tool: null };
    }
    
    async callMCPTool(toolName, parameters) {
        try {
            const response = await axios.post(`${this.mcpEndpoint}/tools/call`, {
                jsonrpc: '2.0',
                method: 'tools/call',
                params: {
                    name: toolName,
                    arguments: parameters
                },
                id: Date.now()
            });
            
            return response.data.result;
        } catch (error) {
            console.error('MCP call error:', error);
            return { content: [{ type: 'text', text: 'Wystąpił błąd podczas wykonywania operacji.' }] };
        }
    }
    
    createAdaptiveCard(mcpResult) {
        const text = mcpResult.content[0].text;
        
        return CardFactory.adaptiveCard({
            type: 'AdaptiveCard',
            version: '1.5',
            body: [
                {
                    type: 'TextBlock',
                    text: '🤖 Wynik operacji DevOps',
                    weight: 'bolder',
                    size: 'medium'
                },
                {
                    type: 'TextBlock',
                    text: text,
                    wrap: true
                }
            ],
            actions: [
                {
                    type: 'Action.OpenUrl',
                    title: 'Zobacz w Azure DevOps',
                    url: 'https://dev.azure.com/yourorg'
                }
            ]
        });
    }
}

// Inicjalizacja aplikacji Teams AI
const app = new Application({
    storage: new MemoryStorage(),
    ai: {
        planner: new ActionPlanner({
            model: 'gpt-4',
            apiKey: process.env.OPENAI_API_KEY,
            defaultPrompt: 'DevOps Assistant'
        })
    }
});

// Rejestracja akcji AI
app.ai.action('deployToAzure', async (context, state, parameters) => {
    const bot = new TeamsMCPBot(process.env.MCP_ENDPOINT);
    const result = await bot.callMCPTool('deploy_to_azure', parameters);
    await context.sendActivity(bot.createAdaptiveCard(result));
    return true;
});

module.exports = { TeamsMCPBot };
```

### 4.3 Manifest aplikacji Teams

**manifest.json:**
```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/teams/v1.16/MicrosoftTeams.schema.json",
  "manifestVersion": "1.16",
  "version": "1.0.0",
  "id": "your-app-id",
  "packageName": "com.company.copilot.mcp.integration",
  "developer": {
    "name": "Your Company",
    "websiteUrl": "https://yourcompany.com",
    "privacyUrl": "https://yourcompany.com/privacy",
    "termsOfUseUrl": "https://yourcompany.com/terms"
  },
  "name": {
    "short": "DevOps Copilot",
    "full": "DevOps Copilot z MCP"
  },
  "description": {
    "short": "AI-powered DevOps assistant z MCP",
    "full": "Asystent DevOps wykorzystujący Copilot 365 i Model Context Protocol do automatyzacji zadań"
  },
  "icons": {
    "outline": "icon-outline.png",
    "color": "icon-color.png"
  },
  "accentColor": "#FFFFFF",
  "bots": [
    {
      "botId": "your-bot-id",
      "scopes": ["personal", "team", "groupchat"],
      "supportsFiles": false,
      "isNotificationOnly": false,
      "commandLists": [
        {
          "scopes": ["personal", "team", "groupchat"],
          "commands": [
            {
              "title": "deploy",
              "description": "Deploy aplikacji do środowiska"
            },
            {
              "title": "status",
              "description": "Sprawdź status pipeline"
            },
            {
              "title": "create task",
              "description": "Utwórz zadanie w Azure DevOps"
            }
          ]
        }
      ]
    }
  ],
  "composeExtensions": [
    {
      "botId": "your-bot-id",
      "commands": [
        {
          "id": "searchWorkItems",
          "title": "Szukaj zadań",
          "description": "Wyszukaj zadania w Azure DevOps",
          "type": "query",
          "parameters": [
            {
              "name": "searchQuery",
              "title": "Zapytanie",
              "description": "Wpisz zapytanie wyszukiwania"
            }
          ]
        }
      ]
    }
  ],
  "permissions": [
    "identity",
    "messageTeamMembers"
  ],
  "validDomains": [
    "*.azurewebsites.net",
    "dev.azure.com"
  ]
}
```

## 5. Praktyczne przykłady użycia

### 5.1 Scenariusz 1: Automatyczny deployment przez chat

**Przykład konwersacji:**
```
Użytkownik: @DevOps Copilot deploy wersji 2.3.1 do staging
Bot: 🤖 Rozpoczęto deployment wersji 2.3.1 do środowiska staging. ID: deploy-1699876543
     
     ✅ Build: Sukces
     ✅ Testy jednostkowe: 98% pokrycia
     ⏳ Deploy do staging: W trakcie...
     
     [Zobacz szczegóły w Azure DevOps]
```

**Implementacja flow:**
```javascript
// Rozszerzenie bota o monitoring deploymentu
class DeploymentMonitor {
    constructor(bot, mcpEndpoint) {
        this.bot = bot;
        this.mcpEndpoint = mcpEndpoint;
        this.activeDeployments = new Map();
    }
    
    async startDeployment(context, version, environment) {
        // Inicjacja deploymentu
        const deploymentId = `deploy-${Date.now()}`;
        
        // Wywołanie MCP
        const result = await this.bot.callMCPTool('deploy_to_azure', {
            version,
            environment
        });
        
        // Utwórz monitoring
        this.activeDeployments.set(deploymentId, {
            context,
            version,
            environment,
            startTime: new Date()
        });
        
        // Rozpocznij monitoring
        this.monitorDeployment(deploymentId);
        
        return result;
    }
    
    async monitorDeployment(deploymentId) {
        const deployment = this.activeDeployments.get(deploymentId);
        
        const checkStatus = async () => {
            const status = await this.getDeploymentStatus(deploymentId);
            
            // Aktualizuj kartę w Teams
            const card = this.createProgressCard(deployment, status);
            await deployment.context.updateActivity({
                type: 'message',
                attachments: [card]
            });
            
            if (status.isComplete) {
                this.activeDeployments.delete(deploymentId);
                
                // Wyślij podsumowanie
                await deployment.context.sendActivity(
                    this.createCompletionCard(deployment, status)
                );
            } else {
                // Kontynuuj monitoring
                setTimeout(checkStatus, 5000);
            }
        };
        
        setTimeout(checkStatus, 5000);
    }
    
    createProgressCard(deployment, status) {
        return CardFactory.adaptiveCard({
            type: 'AdaptiveCard',
            version: '1.5',
            body: [
                {
                    type: 'TextBlock',
                    text: `🚀 Deployment: ${deployment.version} → ${deployment.environment}`,
                    weight: 'bolder',
                    size: 'medium'
                },
                {
                    type: 'TextBlock',
                    text: `Status: ${status.phase}`,
                    color: status.isError ? 'attention' : 'good'
                },
                {
                    type: 'FactSet',
                    facts: [
                        {
                            title: 'Build',
                            value: status.build ? '✅ Sukces' : '⏳ W trakcie'
                        },
                        {
                            title: 'Testy',
                            value: status.tests ? '✅ Zaliczone' : '⏳ W trakcie'
                        },
                        {
                            title: 'Deploy',
                            value: status.deploy ? '✅ Ukończony' : '⏳ W trakcie'
                        }
                    ]
                }
            ],
            actions: [
                {
                    type: 'Action.OpenUrl',
                    title: 'Zobacz w Azure DevOps',
                    url: `https://dev.azure.com/yourorg/_build/results?buildId=${status.buildId}`
                }
            ]
        });
    }
}
```

### 5.2 Scenariusz 2: Inteligentne monitorowanie z auto-remediacją

**System auto-remediacji:**
```python
class IntelligentMonitoringMCP:
    def __init__(self):
        self.server = Server("intelligent-monitoring-mcp")
        self.alerts = []
        self.remediation_history = []
        
    async def handle_alert(self, alert_data):
        # Analiza alertu przy użyciu AI
        analysis = await self.analyze_with_ai(alert_data)
        
        if analysis['auto_remediate']:
            # Automatyczna naprawa
            result = await self.auto_remediate(alert_data, analysis)
            
            # Powiadomienie Teams
            await self.notify_teams({
                'type': 'auto_remediation',
                'alert': alert_data,
                'action_taken': result['action'],
                'result': result['status']
            })
        else:
            # Żądanie interwencji człowieka
            await self.request_human_intervention(alert_data, analysis)
    
    async def analyze_with_ai(self, alert_data):
        prompt = f"""
        Przeanalizuj następujący alert:
        Typ: {alert_data['type']}
        Severity: {alert_data['severity']}
        Opis: {alert_data['description']}
        Metryki: {alert_data['metrics']}
        
        Określ:
        1. Prawdopodobną przyczynę
        2. Czy można automatycznie naprawić (tak/nie)
        3. Sugerowane działania
        """
        
        # Wywołanie Azure OpenAI
        response = await self.call_ai(prompt)
        
        return {
            'root_cause': response['root_cause'],
            'auto_remediate': response['can_auto_fix'],
            'suggested_actions': response['actions']
        }
    
    async def auto_remediate(self, alert_data, analysis):
        action_map = {
            'high_cpu': self.scale_out,
            'memory_leak': self.restart_service,
            'disk_full': self.cleanup_disk,
            'network_timeout': self.reset_connection_pool
        }
        
        action = action_map.get(alert_data['type'])
        if action:
            result = await action(alert_data['resource'])
            
            # Zapisz w historii
            self.remediation_history.append({
                'timestamp': datetime.now(),
                'alert': alert_data,
                'action': action.__name__,
                'result': result
            })
            
            return result
        
        return {'status': 'no_action_available'}
```

### 5.3 Scenariusz 3: GitOps z konwersacyjnym AI

**Konwersacyjny GitOps:**
```javascript
class GitOpsCopilot {
    constructor(mcpEndpoint, gitProvider) {
        this.mcpEndpoint = mcpEndpoint;
        this.gitProvider = gitProvider;
    }
    
    async processInfrastructureRequest(userRequest) {
        // Przykład: "Potrzebuję klastra Kubernetes z 3 nodami dla aplikacji Node.js"
        
        // 1. Generuj architekturę
        const architecture = await this.generateArchitecture(userRequest);
        
        // 2. Wygeneruj kod IaC
        const terraformCode = await this.generateTerraform(architecture);
        
        // 3. Walidacja
        const validation = await this.validateInfrastructure(terraformCode);
        
        // 4. Utwórz PR
        if (validation.passed) {
            const pr = await this.createPullRequest(terraformCode, userRequest);
            
            return {
                success: true,
                message: `Utworzono PR #${pr.number} z konfiguracją infrastruktury`,
                pr_url: pr.url,
                estimated_cost: validation.cost_estimate
            };
        } else {
            return {
                success: false,
                message: 'Walidacja nie powiodła się',
                errors: validation.errors
            };
        }
    }
    
    async generateArchitecture(request) {
        const prompt = `
        Na podstawie wymagań: "${request}"
        
        Wygeneruj architekturę cloud-native zawierającą:
        1. Komponenty infrastruktury
        2. Konfigurację sieci
        3. Wymagania bezpieczeństwa
        4. Skalowanie
        
        Format: JSON
        `;
        
        const response = await this.callAI(prompt);
        return JSON.parse(response);
    }
    
    async generateTerraform(architecture) {
        const prompt = `
        Wygeneruj kod Terraform dla następującej architektury:
        ${JSON.stringify(architecture, null, 2)}
        
        Uwzględnij:
        - Best practices
        - Modularność
        - Parametryzację
        - Tagi zasobów
        `;
        
        return await this.callAI(prompt);
    }
}
```

## 6. Troubleshooting i najlepsze praktyki

### 6.1 Częste problemy i rozwiązania

**Problem 1: Błąd połączenia MCP**
```bash
# Diagnostyka
curl -X POST https://your-mcp-server.azurewebsites.net/api/McpServer \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}'

# Sprawdzenie logów
az functionapp log tail --name $FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP
```

**Problem 2: Błędy autentykacji Teams**
```javascript
// Dodaj middleware do debugowania
app.use(async (context, next) => {
    console.log(`Activity Type: ${context.activity.type}`);
    console.log(`From: ${context.activity.from.name}`);
    
    if (context.activity.type === 'message') {
        console.log(`Message: ${context.activity.text}`);
    }
    
    await next();
});
```

**Problem 3: Timeout w Azure Functions**
```json
// host.json - zwiększ timeout
{
  "version": "2.0",
  "functionTimeout": "00:10:00",
  "extensions": {
    "http": {
      "routePrefix": "api",
      "maxConcurrentRequests": 100,
      "maxOutstandingRequests": 200
    }
  }
}
```

### 6.2 Najlepsze praktyki

**1. Bezpieczeństwo:**
```python
# Zawsze waliduj dane wejściowe
def validate_mcp_request(request):
    required_fields = ['jsonrpc', 'method', 'id']
    
    for field in required_fields:
        if field not in request:
            raise ValueError(f"Brak wymaganego pola: {field}")
    
    if request['jsonrpc'] != '2.0':
        raise ValueError("Nieprawidłowa wersja JSON-RPC")
    
    # Waliduj metodę
    allowed_methods = ['tools/list', 'tools/call', 'resources/list', 'resources/read']
    if request['method'] not in allowed_methods:
        raise ValueError(f"Nieznana metoda: {request['method']}")
```

**2. Monitoring i logi:**
```javascript
// Application Insights integration
const appInsights = require('applicationinsights');
appInsights.setup(process.env.APPINSIGHTS_INSTRUMENTATIONKEY);
appInsights.start();

class MonitoredMCPClient {
    async callTool(toolName, params) {
        const startTime = Date.now();
        const client = appInsights.defaultClient;
        
        try {
            const result = await this.mcpClient.callTool(toolName, params);
            
            client.trackMetric({
                name: 'MCP.ToolCall.Duration',
                value: Date.now() - startTime
            });
            
            client.trackEvent({
                name: 'MCP.ToolCall.Success',
                properties: { toolName }
            });
            
            return result;
        } catch (error) {
            client.trackException({ exception: error });
            client.trackEvent({
                name: 'MCP.ToolCall.Failure',
                properties: { toolName, error: error.message }
            });
            throw error;
        }
    }
}
```

**3. Rate limiting:**
```python
from asyncio import Semaphore
from datetime import datetime, timedelta

class RateLimiter:
    def __init__(self, max_requests=10, time_window=60):
        self.max_requests = max_requests
        self.time_window = time_window
        self.requests = []
        self.semaphore = Semaphore(max_requests)
    
    async def acquire(self):
        async with self.semaphore:
            now = datetime.now()
            # Usuń stare requesty
            self.requests = [
                req for req in self.requests 
                if now - req < timedelta(seconds=self.time_window)
            ]
            
            if len(self.requests) >= self.max_requests:
                wait_time = (self.requests[0] + timedelta(seconds=self.time_window) - now).total_seconds()
                await asyncio.sleep(wait_time)
            
            self.requests.append(now)
```

**4. Obsługa błędów:**
```javascript
class ResilientMCPClient {
    constructor(endpoint, maxRetries = 3) {
        this.endpoint = endpoint;
        this.maxRetries = maxRetries;
    }
    
    async callWithRetry(method, params) {
        let lastError;
        
        for (let attempt = 0; attempt < this.maxRetries; attempt++) {
            try {
                return await this.call(method, params);
            } catch (error) {
                lastError = error;
                
                // Exponential backoff
                const delay = Math.pow(2, attempt) * 1000;
                console.log(`Attempt ${attempt + 1} failed, retrying in ${delay}ms...`);
                
                await new Promise(resolve => setTimeout(resolve, delay));
            }
        }
        
        throw new Error(`Failed after ${this.maxRetries} attempts: ${lastError.message}`);
    }
}
```

### 6.3 Testowanie integracji

**Testy jednostkowe MCP:**
```python
import pytest
from unittest.mock import AsyncMock, patch

class TestAzureDevOpsMCP:
    @pytest.fixture
    def mcp_server(self):
        return AzureDevOpsMCPServer()
    
    @pytest.mark.asyncio
    async def test_create_work_item(self, mcp_server):
        # Mock HTTP response
        with patch('aiohttp.ClientSession.post') as mock_post:
            mock_response = AsyncMock()
            mock_response.status = 200
            mock_response.json = AsyncMock(return_value={
                'id': 123,
                'fields': {
                    'System.Title': 'Test Task'
                }
            })
            mock_post.return_value.__aenter__.return_value = mock_response
            
            # Test
            result = await mcp_server.handle_call_tool(
                'create_work_item',
                {
                    'title': 'Test Task',
                    'type': 'Task'
                }
            )
            
            assert len(result) == 1
            assert 'Utworzono zadanie #123' in result[0].text
```

**Testy integracyjne:**
```javascript
// teams-bot.test.js
const { TestAdapter } = require('botbuilder');
const { TeamsMCPBot } = require('../src/bot');

describe('Teams MCP Bot Integration', () => {
    let adapter;
    let bot;
    
    beforeEach(() => {
        adapter = new TestAdapter();
        bot = new TeamsMCPBot('http://localhost:7071/api/McpServer');
    });
    
    test('Should handle deployment request', async () => {
        await adapter.send('deploy v1.2.3 do staging')
            .assertReply((activity) => {
                expect(activity.attachments).toHaveLength(1);
                expect(activity.attachments[0].contentType).toBe('application/vnd.microsoft.card.adaptive');
                
                const card = activity.attachments[0].content;
                expect(card.body[0].text).toContain('Wynik operacji DevOps');
            });
    });
});
```

## Podsumowanie

Ta instrukcja warsztatowa przedstawia kompleksowe podejście do integracji Copilot 365 w Teams z Model Context Protocol dla DevOps. Kluczowe elementy to:

1. **Wykorzystanie najnowszych technologii z BUILD 2025** - natywne wsparcie MCP w ekosystemie Microsoft
2. **Modułowa architektura** - łatwa do rozbudowy i utrzymania
3. **Praktyczne przykłady** - od prostego ChatOps po zaawansowaną auto-remediację
4. **Bezpieczeństwo i monitoring** - wbudowane od początku
5. **Skalowalność** - od lokalnego developmentu po deployment w chmurze

Pamiętaj o regularnym aktualizowaniu komponentów i śledzeniu rozwoju MCP oraz nowych możliwości Copilot 365. Społeczność Microsoft szybko rozwija te technologie, więc warto być na bieżąco z najnowszymi praktykami i wzorcami.

### Następne kroki

1. Zacznij od prostego bota w Teams z jednym narzędziem MCP
2. Stopniowo dodawaj kolejne integracje (Azure DevOps, monitoring)
3. Eksperymentuj z AI-powered features używając Azure OpenAI
4. Rozważ utworzenie własnych serwerów MCP dla specyficznych narzędzi
5. Dziel się swoimi doświadczeniami ze społecznością!

Powodzenia w implementacji! 🚀