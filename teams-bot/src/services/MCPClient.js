/**
 * MCP Client - Klient do komunikacji z serwerami Model Context Protocol
 */

const axios = require('axios');

class MCPClient {
    constructor(endpoints = {}) {
        this.endpoints = {
            'azure-function': endpoints.azureFunctionEndpoint,
            'local-devops': endpoints.localDevOpsEndpoint,
            'desktop-commander': endpoints.desktopCommanderEndpoint,
            'azure-devops': endpoints.azureDevOpsEndpoint
        };
        
        this.requestId = 0;
        
        // Konfiguracja timeout i retry
        this.config = {
            timeout: 30000, // 30 sekund
            retries: 3,
            retryDelay: 1000 // 1 sekunda
        };
        
        console.log('🔌 MCP Client initialized with endpoints:', 
            Object.keys(this.endpoints).filter(key => this.endpoints[key])
        );
    }

    /**
     * Wywołaj narzędzie na określonym serwerze MCP
     */
    async callTool(serverName, toolName, parameters = {}) {
        const endpoint = this.endpoints[serverName];
        if (!endpoint) {
            throw new Error(`MCP server '${serverName}' nie jest skonfigurowany`);
        }

        const requestId = ++this.requestId;
        const request = {
            jsonrpc: '2.0',
            method: 'tools/call',
            params: {
                name: toolName,
                arguments: parameters
            },
            id: requestId
        };

        console.log(`📤 MCP Request to ${serverName}:`, JSON.stringify(request, null, 2));

        try {
            const response = await this.makeRequest(endpoint, request);
            
            if (response.error) {
                throw new Error(`MCP Error: ${response.error.message} (Code: ${response.error.code})`);
            }

            console.log(`📥 MCP Response from ${serverName}:`, JSON.stringify(response.result, null, 2));
            return response.result;

        } catch (error) {
            console.error(`❌ MCP Call failed for ${serverName}.${toolName}:`, error.message);
            throw error;
        }
    }

    /**
     * Pobierz listę dostępnych narzędzi z serwera
     */
    async listTools(serverName) {
        const endpoint = this.endpoints[serverName];
        if (!endpoint) {
            throw new Error(`MCP server '${serverName}' nie jest skonfigurowany`);
        }

        const requestId = ++this.requestId;
        const request = {
            jsonrpc: '2.0',
            method: 'tools/list',
            params: {},
            id: requestId
        };

        try {
            const response = await this.makeRequest(endpoint, request);
            
            if (response.error) {
                throw new Error(`MCP Error: ${response.error.message}`);
            }

            return response.result.tools || [];

        } catch (error) {
            console.error(`❌ Failed to list tools from ${serverName}:`, error.message);
            throw error;
        }
    }

    /**
     * Pobierz listę dostępnych zasobów z serwera
     */
    async listResources(serverName) {
        const endpoint = this.endpoints[serverName];
        if (!endpoint) {
            throw new Error(`MCP server '${serverName}' nie jest skonfigurowany`);
        }

        const requestId = ++this.requestId;
        const request = {
            jsonrpc: '2.0',
            method: 'resources/list',
            params: {},
            id: requestId
        };

        try {
            const response = await this.makeRequest(endpoint, request);
            
            if (response.error) {
                throw new Error(`MCP Error: ${response.error.message}`);
            }

            return response.result.resources || [];

        } catch (error) {
            console.error(`❌ Failed to list resources from ${serverName}:`, error.message);
            throw error;
        }
    }

    /**
     * Odczytaj zasób z serwera
     */
    async readResource(serverName, uri) {
        const endpoint = this.endpoints[serverName];
        if (!endpoint) {
            throw new Error(`MCP server '${serverName}' nie jest skonfigurowany`);
        }

        const requestId = ++this.requestId;
        const request = {
            jsonrpc: '2.0',
            method: 'resources/read',
            params: {
                uri: uri
            },
            id: requestId
        };

        try {
            const response = await this.makeRequest(endpoint, request);
            
            if (response.error) {
                throw new Error(`MCP Error: ${response.error.message}`);
            }

            return response.result;

        } catch (error) {
            console.error(`❌ Failed to read resource ${uri} from ${serverName}:`, error.message);
            throw error;
        }
    }

    /**
     * Sprawdź połączenia ze wszystkimi serwerami
     */
    async testConnections() {
        const results = {};
        
        for (const [serverName, endpoint] of Object.entries(this.endpoints)) {
            if (!endpoint) {
                results[serverName] = {
                    status: 'not_configured',
                    message: 'Endpoint nie jest skonfigurowany'
                };
                continue;
            }

            try {
                // Sprawdź czy to Azure Function (ma endpoint health)
                if (serverName === 'azure-function' && endpoint.includes('azurewebsites.net')) {
                    const healthResponse = await axios.get(endpoint.replace('/api/McpServer', ''), {
                        timeout: 5000
                    });
                    
                    results[serverName] = {
                        status: 'healthy',
                        message: 'Azure Function is running',
                        response: healthResponse.data
                    };
                } else {
                    // Dla innych serwerów spróbuj wywołać tools/list
                    const tools = await this.listTools(serverName);
                    
                    results[serverName] = {
                        status: 'healthy',
                        message: `Connected successfully. Found ${tools.length} tools`,
                        tools: tools.map(t => t.name)
                    };
                }
            } catch (error) {
                results[serverName] = {
                    status: 'error',
                    message: error.message,
                    error: error.response?.data || error.code
                };
            }
        }

        return results;
    }

    /**
     * Wykonaj request HTTP z retry logic
     */
    async makeRequest(endpoint, request, attempt = 1) {
        try {
            const response = await axios.post(endpoint, request, {
                timeout: this.config.timeout,
                headers: {
                    'Content-Type': 'application/json',
                    'User-Agent': 'Teams-MCP-Bot/1.0'
                }
            });

            return response.data;

        } catch (error) {
            console.error(`❌ Request attempt ${attempt} failed:`, error.message);

            // Retry logic
            if (attempt < this.config.retries && this.shouldRetry(error)) {
                console.log(`🔄 Retrying in ${this.config.retryDelay}ms...`);
                await this.delay(this.config.retryDelay * attempt);
                return this.makeRequest(endpoint, request, attempt + 1);
            }

            // Polepszenie komunikatów błędów
            if (error.code === 'ECONNREFUSED') {
                throw new Error(`Nie można połączyć się z serwerem MCP: ${endpoint}`);
            } else if (error.code === 'ETIMEDOUT' || error.response?.status === 408) {
                throw new Error(`Timeout podczas łączenia z serwerem MCP: ${endpoint}`);
            } else if (error.response?.status === 404) {
                throw new Error(`Endpoint MCP nie został znaleziony: ${endpoint}`);
            } else if (error.response?.status >= 500) {
                throw new Error(`Błąd serwera MCP (${error.response.status}): ${endpoint}`);
            } else {
                throw new Error(`Błąd MCP: ${error.message}`);
            }
        }
    }

    /**
     * Sprawdź czy błąd kwalifikuje się do retry
     */
    shouldRetry(error) {
        // Retry dla błędów sieci i niektórych statusów HTTP
        return (
            error.code === 'ECONNREFUSED' ||
            error.code === 'ETIMEDOUT' ||
            error.code === 'ENOTFOUND' ||
            (error.response?.status >= 500 && error.response?.status < 600) ||
            error.response?.status === 429 // Rate limit
        );
    }

    /**
     * Opóźnienie w milisekundach
     */
    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    /**
     * Pobierz status wszystkich serwerów
     */
    getServersStatus() {
        const status = {};
        
        for (const [serverName, endpoint] of Object.entries(this.endpoints)) {
            status[serverName] = {
                configured: !!endpoint,
                endpoint: endpoint || 'Not configured'
            };
        }
        
        return status;
    }

    /**
     * Wykryj najlepszy serwer dla danego typu operacji
     */
    detectBestServer(operation) {
        const serverMap = {
            // Azure operations
            'deploy': 'azure-function',
            'pipeline': 'azure-function',
            'resource_check': 'azure-function',
            
            // Azure DevOps operations
            'work_item': 'azure-devops',
            'pull_request': 'azure-devops',
            'repository': 'azure-devops',
            
            // Local operations
            'docker': 'local-devops',
            'kubernetes': 'local-devops',
            'git': 'local-devops',
            
            // System operations
            'powershell': 'desktop-commander',
            'service': 'desktop-commander',
            'system': 'desktop-commander'
        };

        const suggestedServer = serverMap[operation];
        
        // Sprawdź czy sugerowany serwer jest skonfigurowany
        if (suggestedServer && this.endpoints[suggestedServer]) {
            return suggestedServer;
        }

        // Znajdź pierwszy dostępny serwer
        for (const [serverName, endpoint] of Object.entries(this.endpoints)) {
            if (endpoint) {
                return serverName;
            }
        }

        throw new Error('Brak skonfigurowanych serwerów MCP');
    }

    /**
     * Batch wywołanie wielu narzędzi
     */
    async callMultipleTools(calls) {
        const results = [];
        
        for (const call of calls) {
            try {
                const result = await this.callTool(call.server, call.tool, call.parameters);
                results.push({
                    success: true,
                    server: call.server,
                    tool: call.tool,
                    result: result
                });
            } catch (error) {
                results.push({
                    success: false,
                    server: call.server,
                    tool: call.tool,
                    error: error.message
                });
            }
        }
        
        return results;
    }
}

module.exports = { MCPClient };
