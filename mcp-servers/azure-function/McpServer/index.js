const { app } = require('@azure/functions');
const appInsights = require('applicationinsights');

// Inicjalizacja Application Insights
if (process.env.APPINSIGHTS_INSTRUMENTATIONKEY) {
    appInsights.setup(process.env.APPINSIGHTS_INSTRUMENTATIONKEY);
    appInsights.start();
}

// Model Context Protocol server implementation for Azure
class AzureMCPServer {
    constructor() {
        this.name = 'azure-devops-mcp';
        this.version = '1.0.0';
        this.capabilities = {
            tools: {},
            resources: {}
        };
        
        // Dostępne narzędzia
        this.tools = [
            {
                name: 'deploy_to_azure',
                description: 'Deploy aplikacji do Azure',
                inputSchema: {
                    type: 'object',
                    properties: {
                        environment: { 
                            type: 'string', 
                            enum: ['dev', 'staging', 'prod'],
                            description: 'Środowisko docelowe'
                        },
                        version: { 
                            type: 'string',
                            description: 'Wersja aplikacji do wdrożenia'
                        },
                        serviceName: {
                            type: 'string',
                            description: 'Nazwa serwisu (opcjonalne)'
                        }
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
                        pipelineId: { 
                            type: 'string',
                            description: 'ID pipeline do sprawdzenia'
                        },
                        project: {
                            type: 'string',
                            description: 'Nazwa projektu (opcjonalne)'
                        }
                    },
                    required: ['pipelineId']
                }
            },
            {
                name: 'create_work_item',
                description: 'Utwórz nowe zadanie w Azure DevOps',
                inputSchema: {
                    type: 'object',
                    properties: {
                        title: { 
                            type: 'string',
                            description: 'Tytuł zadania'
                        },
                        description: { 
                            type: 'string',
                            description: 'Opis zadania'
                        },
                        type: { 
                            type: 'string', 
                            enum: ['Bug', 'Task', 'Feature', 'User Story'],
                            description: 'Typ zadania'
                        },
                        assignee: {
                            type: 'string',
                            description: 'Osoba przypisana (email)'
                        },
                        priority: {
                            type: 'number',
                            minimum: 1,
                            maximum: 4,
                            description: 'Priorytet (1-4, gdzie 1 to najwyższy)'
                        }
                    },
                    required: ['title', 'type']
                }
            },
            {
                name: 'get_resource_usage',
                description: 'Sprawdź wykorzystanie zasobów Azure',
                inputSchema: {
                    type: 'object',
                    properties: {
                        resourceGroup: {
                            type: 'string',
                            description: 'Nazwa grupy zasobów'
                        },
                        timeRange: {
                            type: 'string',
                            enum: ['1h', '24h', '7d', '30d'],
                            description: 'Przedział czasowy'
                        }
                    },
                    required: ['resourceGroup']
                }
            }
        ];
    }

    async handleRequest(request) {
        const { method, params } = request;
        
        try {
            switch (method) {
                case 'initialize':
                    return await this.handleInitialize(params);
                case 'tools/list':
                    return await this.handleToolsList();
                case 'tools/call':
                    return await this.handleToolsCall(params);
                case 'resources/list':
                    return await this.handleResourcesList();
                case 'resources/read':
                    return await this.handleResourcesRead(params);
                default:
                    throw new Error(`Nieznana metoda: ${method}`);
            }
        } catch (error) {
            console.error('MCP Server Error:', error);
            throw error;
        }
    }

    async handleInitialize(params) {
        return {
            protocolVersion: '2024-11-05',
            capabilities: this.capabilities,
            serverInfo: {
                name: this.name,
                version: this.version
            }
        };
    }

    async handleToolsList() {
        return {
            tools: this.tools
        };
    }

    async handleToolsCall(params) {
        const { name, arguments: args } = params;
        
        console.log(`Wywołanie narzędzia: ${name}`, args);
        
        switch (name) {
            case 'deploy_to_azure':
                return await this.deployToAzure(args);
            case 'check_pipeline_status':
                return await this.checkPipelineStatus(args);
            case 'create_work_item':
                return await this.createWorkItem(args);
            case 'get_resource_usage':
                return await this.getResourceUsage(args);
            default:
                throw new Error(`Nieznane narzędzie: ${name}`);
        }
    }

    async handleResourcesList() {
        return {
            resources: [
                {
                    uri: 'azure://subscriptions',
                    name: 'Azure Subscriptions',
                    description: 'Lista dostępnych subskrypcji Azure'
                },
                {
                    uri: 'azure://resource-groups',
                    name: 'Resource Groups',
                    description: 'Lista grup zasobów'
                },
                {
                    uri: 'devops://projects',
                    name: 'Azure DevOps Projects',
                    description: 'Lista projektów w Azure DevOps'
                }
            ]
        };
    }

    async handleResourcesRead(params) {
        const { uri } = params;
        
        // Symulacja odczytu zasobów
        switch (uri) {
            case 'azure://subscriptions':
                return {
                    contents: [{
                        type: 'text',
                        text: 'Dostępne subskrypcje:\n- Workshop Subscription (2e539821-ff47-4b8a-9f5a-200de5bb3e8d)'
                    }]
                };
            case 'azure://resource-groups':
                return {
                    contents: [{
                        type: 'text',
                        text: 'Grupy zasobów:\n- copilot-mcp-workshop-rg\n- DefaultResourceGroup-WEU'
                    }]
                };
            case 'devops://projects':
                return {
                    contents: [{
                        type: 'text',
                        text: 'Projekty Azure DevOps:\n- CopilotMCPWorkshop\n- DemoProject'
                    }]
                };
            default:
                throw new Error(`Nieznany zasób: ${uri}`);
        }
    }

    // Implementacje narzędzi
    async deployToAzure({ environment, version, serviceName = 'default-service' }) {
        const deploymentId = `deploy-${Date.now()}`;
        const timestamp = new Date().toISOString();
        
        // Symulacja procesu deploymentu
        const deploymentSteps = [
            'Inicjalizacja deploymentu',
            'Walidacja konfiguracji',
            'Build artefaktów',
            'Testy jednostkowe',
            'Deploy do środowiska',
            'Testy smoke',
            'Finalizacja'
        ];
        
        console.log(`Deployment ${deploymentId}: ${version} -> ${environment}`);
        
        // W rzeczywistej implementacji tutaj byłoby wywołanie Azure API
        
        return {
            content: [{
                type: 'text',
                text: `🚀 Deployment ${deploymentId} rozpoczęty!
                
📦 **Szczegóły:**
- Wersja: ${version}
- Środowisko: ${environment}
- Serwis: ${serviceName}
- Rozpoczęcie: ${timestamp}

📋 **Status kroków:**
${deploymentSteps.map((step, index) => 
    index < 3 ? `✅ ${step}` : `⏳ ${step}`
).join('\n')}

🔗 **Linki:**
- [Zobacz w Azure Portal](https://portal.azure.com)
- [Azure DevOps Pipeline](https://dev.azure.com)

⏱️ **Szacowany czas:** 5-10 minut`
            }]
        };
    }

    async checkPipelineStatus({ pipelineId, project = 'CopilotMCPWorkshop' }) {
        const timestamp = new Date().toISOString();
        
        // Symulacja sprawdzenia statusu
        const mockStatuses = ['Running', 'Succeeded', 'Failed', 'Canceled', 'Pending'];
        const randomStatus = mockStatuses[Math.floor(Math.random() * mockStatuses.length)];
        
        const statusIcon = {
            'Running': '🔄',
            'Succeeded': '✅',
            'Failed': '❌',
            'Canceled': '⏹️',
            'Pending': '⏳'
        };
        
        console.log(`Checking pipeline ${pipelineId} status: ${randomStatus}`);
        
        return {
            content: [{
                type: 'text',
                text: `${statusIcon[randomStatus]} **Pipeline Status: ${randomStatus}**

📋 **Szczegóły pipeline:**
- ID: ${pipelineId}
- Projekt: ${project}
- Status: ${randomStatus}
- Ostatnia aktualizacja: ${timestamp}

📊 **Metryki:**
- Czas wykonania: ${Math.floor(Math.random() * 15 + 5)} minut
- Testy: ${Math.floor(Math.random() * 100 + 80)}% sukces
- Pokrycie kodu: ${Math.floor(Math.random() * 20 + 75)}%

🔗 **Linki:**
- [Zobacz pipeline w Azure DevOps](https://dev.azure.com/${project}/_build/results?buildId=${pipelineId})`
            }]
        };
    }

    async createWorkItem({ title, description = '', type, assignee, priority = 2 }) {
        const workItemId = Math.floor(Math.random() * 10000) + 1000;
        const timestamp = new Date().toISOString();
        
        // W rzeczywistej implementacji tutaj byłoby wywołanie Azure DevOps API
        
        console.log(`Creating work item: ${title} (${type})`);
        
        const priorityText = {
            1: 'Krytyczny 🔴',
            2: 'Wysoki 🟠',
            3: 'Średni 🟡',
            4: 'Niski 🟢'
        };
        
        return {
            content: [{
                type: 'text',
                text: `✅ **Zadanie utworzone pomyślnie!**

📋 **Szczegóły zadania:**
- ID: #${workItemId}
- Tytuł: ${title}
- Typ: ${type}
- Priorytet: ${priorityText[priority]}
${assignee ? `- Przypisane do: ${assignee}` : ''}
- Utworzono: ${timestamp}

📝 **Opis:**
${description || 'Brak opisu'}

🔗 **Akcje:**
- [Otwórz w Azure DevOps](https://dev.azure.com/_workitems/edit/${workItemId})
- [Edytuj zadanie](https://dev.azure.com/_workitems/edit/${workItemId})`
            }]
        };
    }

    async getResourceUsage({ resourceGroup, timeRange = '24h' }) {
        const timestamp = new Date().toISOString();
        
        // Symulacja danych o wykorzystaniu zasobów
        const mockData = {
            compute: Math.floor(Math.random() * 40 + 30),
            memory: Math.floor(Math.random() * 50 + 40),
            storage: Math.floor(Math.random() * 30 + 20),
            network: Math.floor(Math.random() * 60 + 20)
        };
        
        console.log(`Getting resource usage for ${resourceGroup} (${timeRange})`);
        
        return {
            content: [{
                type: 'text',
                text: `📊 **Wykorzystanie zasobów: ${resourceGroup}**

⏱️ **Okres:** Ostatnie ${timeRange}
🕒 **Aktualizacja:** ${timestamp}

📈 **Metryki:**
- 💻 CPU: ${mockData.compute}% średnio
- 🧠 Pamięć: ${mockData.memory}% średnio  
- 💾 Storage: ${mockData.storage}% wykorzystania
- 🌐 Sieć: ${mockData.network} GB transferu

⚠️ **Alerty:**
${mockData.memory > 80 ? '- Wysokie wykorzystanie pamięci!' : ''}
${mockData.compute > 70 ? '- Wysokie wykorzystanie CPU!' : ''}
${mockData.storage > 85 ? '- Niski poziom miejsca na dysku!' : ''}

🔗 **Linki:**
- [Azure Monitor](https://portal.azure.com/#blade/Microsoft_Azure_Monitoring/AzureMonitoringBrowseBlade)
- [Cost Management](https://portal.azure.com/#blade/Microsoft_Azure_CostManagement/Menu/overview)`
            }]
        };
    }
}

// Azure Function handler
app.http('McpServer', {
    methods: ['POST', 'GET', 'OPTIONS'],
    authLevel: 'function',
    handler: async (request, context) => {
        // CORS headers
        const headers = {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization'
        };

        // Handle preflight OPTIONS request
        if (request.method === 'OPTIONS') {
            return {
                status: 200,
                headers
            };
        }

        // Handle GET request (for health check)
        if (request.method === 'GET') {
            return {
                status: 200,
                headers,
                body: JSON.stringify({
                    name: 'Azure MCP Server',
                    version: '1.0.0',
                    status: 'healthy',
                    timestamp: new Date().toISOString()
                })
            };
        }

        try {
            const mcpServer = new AzureMCPServer();
            const body = await request.json();
            
            console.log('MCP Request:', JSON.stringify(body, null, 2));
            
            // Obsługa żądania MCP
            const response = await mcpServer.handleRequest(body);
            
            const result = {
                jsonrpc: '2.0',
                id: body.id,
                result: response
            };

            console.log('MCP Response:', JSON.stringify(result, null, 2));

            return {
                status: 200,
                headers,
                body: JSON.stringify(result)
            };
        } catch (error) {
            console.error('Error handling MCP request:', error);

            const errorResponse = {
                jsonrpc: '2.0',
                id: request.body?.id || null,
                error: {
                    code: -32603,
                    message: 'Internal error',
                    data: error.message
                }
            };

            return {
                status: 500,
                headers,
                body: JSON.stringify(errorResponse)
            };
        }
    }
});
