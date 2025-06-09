#!/usr/bin/env node
/**
 * Desktop Commander MCP Server - Simplified JavaScript Version
 * Warsztat Copilot 365 MCP Integration
 */

const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const { exec } = require('child_process');
const { promisify } = require('util');
const os = require('os');

const execAsync = promisify(exec);

// Serwer MCP
const server = new Server(
    {
        name: 'desktop-commander',
        version: '1.0.0'
    },
    {
        capabilities: {
            tools: {},
            resources: {}
        }
    }
);

// Lista narzędzi
server.setRequestHandler('tools/list', async () => {
    return {
        tools: [
            {
                name: 'run_powershell',
                description: 'Wykonaj komendę PowerShell',
                inputSchema: {
                    type: 'object',
                    properties: {
                        command: { 
                            type: 'string',
                            description: 'Komenda PowerShell do wykonania'
                        }
                    },
                    required: ['command']
                }
            },
            {
                name: 'get_system_info',
                description: 'Pobierz informacje o systemie',
                inputSchema: {
                    type: 'object',
                    properties: {
                        detailed: {
                            type: 'boolean',
                            description: 'Czy pokazać szczegółowe informacje',
                            default: false
                        }
                    }
                }
            },
            {
                name: 'list_processes',
                description: 'Lista uruchomionych procesów',
                inputSchema: {
                    type: 'object',
                    properties: {
                        filter: {
                            type: 'string',
                            description: 'Filtr nazwy procesu'
                        }
                    }
                }
            },
            {
                name: 'manage_service',
                description: 'Zarządzaj usługami Windows',
                inputSchema: {
                    type: 'object',
                    properties: {
                        action: {
                            type: 'string',
                            enum: ['start', 'stop', 'restart', 'status'],
                            description: 'Akcja do wykonania'
                        },
                        service: {
                            type: 'string',
                            description: 'Nazwa usługi'
                        }
                    },
                    required: ['action', 'service']
                }
            }
        ]
    };
});

// Obsługa wywołań narzędzi
server.setRequestHandler('tools/call', async (request) => {
    const { name, arguments: args } = request.params;
    
    try {
        switch (name) {
            case 'run_powershell':
                return await runPowerShell(args);
            case 'get_system_info':
                return await getSystemInfo(args);
            case 'list_processes':
                return await listProcesses(args);
            case 'manage_service':
                return await manageService(args);
            default:
                throw new Error(`Nieznane narzędzie: ${name}`);
        }
    } catch (error) {
        return {
            content: [{
                type: 'text',
                text: `❌ Błąd: ${error.message}`
            }]
        };
    }
});

// Implementacje funkcji
async function runPowerShell(args) {
    const { command } = args;
    
    // Podstawowe bezpieczeństwo
    const dangerousCommands = [
        'Remove-Item', 'rd ', 'rmdir', 'del ', 'erase',
        'Format-Volume', 'Clear-Disk', 'Remove-Computer',
        'Stop-Computer', 'Restart-Computer'
    ];
    
    if (dangerousCommands.some(cmd => command.includes(cmd))) {
        throw new Error('Komenda odrzucona ze względów bezpieczeństwa');
    }
    
    try {
        const { stdout, stderr } = await execAsync(`powershell -Command "${command}"`);
        
        return {
            content: [{
                type: 'text',
                text: `🔷 **PowerShell Result:**\n\`\`\`\n${stdout || stderr}\n\`\`\``
            }]
        };
    } catch (error) {
        throw new Error(`PowerShell error: ${error.message}`);
    }
}

async function getSystemInfo(args) {
    const { detailed = false } = args;
    
    try {
        const info = {
            platform: os.platform(),
            arch: os.arch(),
            release: os.release(),
            hostname: os.hostname(),
            uptime: Math.floor(os.uptime() / 3600), // hours
            totalMemory: Math.round(os.totalmem() / 1024 / 1024 / 1024), // GB
            freeMemory: Math.round(os.freemem() / 1024 / 1024 / 1024), // GB
            cpus: os.cpus().length
        };
        
        let text = `🖥️ **System Information:**\n\n`;
        text += `• **Platform:** ${info.platform} ${info.arch}\n`;
        text += `• **Release:** ${info.release}\n`;
        text += `• **Hostname:** ${info.hostname}\n`;
        text += `• **Uptime:** ${info.uptime} hours\n`;
        text += `• **CPUs:** ${info.cpus} cores\n`;
        text += `• **Memory:** ${info.freeMemory}GB free / ${info.totalMemory}GB total\n`;
        
        if (detailed) {
            const { stdout } = await execAsync('powershell -Command "Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, TotalPhysicalMemory | ConvertTo-Json"');
            try {
                const detailedInfo = JSON.parse(stdout);
                text += `\n**Windows Details:**\n`;
                text += `• **Edition:** ${detailedInfo.WindowsProductName}\n`;
                text += `• **Version:** ${detailedInfo.WindowsVersion}\n`;
            } catch (e) {
                // Ignore JSON parse errors
            }
        }
        
        return {
            content: [{
                type: 'text',
                text: text
            }]
        };
    } catch (error) {
        throw new Error(`System info error: ${error.message}`);
    }
}

async function listProcesses(args) {
    const { filter } = args;
    
    try {
        let command = 'powershell -Command "Get-Process';
        if (filter) {
            command += ` | Where-Object {$_.ProcessName -like "*${filter}*"}`;
        }
        command += ' | Select-Object ProcessName, Id, CPU, WorkingSet | Sort-Object CPU -Descending | Select-Object -First 10 | ConvertTo-Json"';
        
        const { stdout } = await execAsync(command);
        
        let processes;
        try {
            processes = JSON.parse(stdout);
            if (!Array.isArray(processes)) {
                processes = [processes];
            }
        } catch (e) {
            processes = [];
        }
        
        let text = `📋 **Running Processes:**\n\n`;
        
        if (processes.length === 0) {
            text += 'No processes found.';
        } else {
            processes.forEach(proc => {
                const memory = proc.WorkingSet ? Math.round(proc.WorkingSet / 1024 / 1024) : 0;
                const cpu = proc.CPU ? proc.CPU.toFixed(2) : '0.00';
                text += `• **${proc.ProcessName}** (PID: ${proc.Id}) - CPU: ${cpu}s, Memory: ${memory}MB\n`;
            });
        }
        
        return {
            content: [{
                type: 'text',
                text: text
            }]
        };
    } catch (error) {
        throw new Error(`Process management error: ${error.message}`);
    }
}

async function manageService(args) {
    const { action, service } = args;
    
    try {
        let command;
        let actionText;
        
        switch (action) {
            case 'start':
                command = `Start-Service -Name "${service}"`;
                actionText = 'started';
                break;
            case 'stop':
                command = `Stop-Service -Name "${service}"`;
                actionText = 'stopped';
                break;
            case 'restart':
                command = `Restart-Service -Name "${service}"`;
                actionText = 'restarted';
                break;
            case 'status':
                command = `Get-Service -Name "${service}" | ConvertTo-Json`;
                actionText = 'status retrieved';
                break;
            default:
                throw new Error(`Unknown action: ${action}`);
        }
        
        const { stdout, stderr } = await execAsync(`powershell -Command "${command}"`);
        
        if (action === 'status') {
            try {
                const serviceInfo = JSON.parse(stdout);
                return {
                    content: [{
                        type: 'text',
                        text: `🔧 **Service Status:**\n\n` +
                              `• **Name:** ${serviceInfo.Name}\n` +
                              `• **Status:** ${serviceInfo.Status}\n` +
                              `• **Start Type:** ${serviceInfo.StartType}`
                    }]
                };
            } catch (e) {
                return {
                    content: [{
                        type: 'text',
                        text: `🔧 **Service Status:**\n\`\`\`\n${stdout}\n\`\`\``
                    }]
                };
            }
        }
        
        return {
            content: [{
                type: 'text',
                text: `✅ Service **${service}** ${actionText} successfully.`
            }]
        };
    } catch (error) {
        throw new Error(`Service management error: ${error.message}`);
    }
}

// Uruchomienie serwera
async function main() {
    const transport = new StdioServerTransport();
    await server.connect(transport);
    console.error('Desktop Commander MCP Server running...');
}

// Error handling
process.on('uncaughtException', (error) => {
    console.error('Uncaught Exception:', error);
    process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
    console.error('Unhandled Rejection at:', promise, 'reason:', reason);
    process.exit(1);
});

if (require.main === module) {
    main().catch(console.error);
}
