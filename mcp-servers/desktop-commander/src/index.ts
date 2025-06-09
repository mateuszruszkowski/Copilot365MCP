/**
 * Desktop Commander MCP Server
 * Model Context Protocol server for Windows system management
 * Warsztat: Copilot 365 MCP Integration
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { exec, spawn } from 'child_process';
import { promisify } from 'util';
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';

const execAsync = promisify(exec);

interface SystemInfo {
    hostname: string;
    platform: string;
    arch: string;
    release: string;
    uptime: number;
    memory: {
        total: number;
        free: number;
        used: number;
    };
    cpu: {
        model: string;
        cores: number;
    };
}

interface ServiceStatus {
    name: string;
    status: string;
    startType: string;
    description?: string;
}

interface ProcessInfo {
    pid: number;
    name: string;
    cpu: number;
    memory: number;
    status: string;
}

class DesktopCommanderMCPServer {
    private server: Server;
    private isWindows: boolean;

    constructor() {
        this.server = new Server(
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

        this.isWindows = os.platform() === 'win32';
        this.setupHandlers();
    }

    private setupHandlers(): void {
        // Lista dostępnych narzędzi
        this.server.setRequestHandler('tools/list', async () => {
            const tools = [
                {
                    name: 'run_powershell',
                    description: 'Wykonaj komendę PowerShell',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            command: { 
                                type: 'string',
                                description: 'Komenda PowerShell do wykonania'
                            },
                            timeout: {
                                type: 'number',
                                description: 'Timeout w sekundach (domyślnie 30)',
                                default: 30
                            }
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
                            action: { 
                                type: 'string', 
                                enum: ['start', 'stop', 'restart', 'status', 'list'],
                                description: 'Akcja do wykonania'
                            },
                            service: { 
                                type: 'string',
                                description: 'Nazwa usługi (wymagane dla start/stop/restart/status)'
                            }
                        },
                        required: ['action']
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
                                description: 'Pokaż szczegółowe informacje',
                                default: false
                            }
                        }
                    }
                },
                {
                    name: 'manage_processes',
                    description: 'Zarządzaj procesami systemowymi',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            action: {
                                type: 'string',
                                enum: ['list', 'kill', 'info'],
                                description: 'Akcja do wykonania'
                            },
                            processName: {
                                type: 'string',
                                description: 'Nazwa procesu (dla kill/info)'
                            },
                            pid: {
                                type: 'number',
                                description: 'PID procesu (alternatywnie dla kill/info)'
                            },
                            filter: {
                                type: 'string',
                                description: 'Filtr nazwy procesu (dla list)'
                            }
                        },
                        required: ['action']
                    }
                },
                {
                    name: 'file_operations',
                    description: 'Operacje na plikach i katalogach',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            operation: {
                                type: 'string',
                                enum: ['list', 'create_dir', 'delete', 'copy', 'move', 'info'],
                                description: 'Typ operacji'
                            },
                            path: {
                                type: 'string',
                                description: 'Ścieżka do pliku/katalogu'
                            },
                            destination: {
                                type: 'string',
                                description: 'Ścieżka docelowa (dla copy/move)'
                            },
                            recursive: {
                                type: 'boolean',
                                description: 'Operacja rekurencyjna',
                                default: false
                            }
                        },
                        required: ['operation', 'path']
                    }
                },
                {
                    name: 'registry_operations',
                    description: 'Operacje na rejestrze Windows (tylko odczyt)',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            action: {
                                type: 'string',
                                enum: ['read', 'list'],
                                description: 'Akcja rejestru'
                            },
                            keyPath: {
                                type: 'string',
                                description: 'Ścieżka klucza rejestru'
                            },
                            valueName: {
                                type: 'string',
                                description: 'Nazwa wartości (dla read)'
                            }
                        },
                        required: ['action', 'keyPath']
                    }
                },
                {
                    name: 'network_info',
                    description: 'Informacje o sieci i połączeniach',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            type: {
                                type: 'string',
                                enum: ['interfaces', 'connections', 'ping', 'trace'],
                                description: 'Typ informacji sieciowej'
                            },
                            target: {
                                type: 'string',
                                description: 'Adres docelowy (dla ping/trace)'
                            }
                        },
                        required: ['type']
                    }
                }
            ];

            // Dodaj narzędzia specyficzne dla Windows
            if (this.isWindows) {
                tools.push({
                    name: 'wmi_query',
                    description: 'Wykonaj zapytanie WMI (Windows Management Instrumentation)',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            query: {
                                type: 'string',
                                description: 'Zapytanie WQL (WMI Query Language)'
                            },
                            namespace: {
                                type: 'string',
                                description: 'Namespace WMI',
                                default: 'root\\cimv2'
                            }
                        },
                        required: ['query']
                    }
                });
            }

            return { tools };
        });

        // Obsługa wywołań narzędzi
        this.server.setRequestHandler('tools/call', async (request) => {
            const { name, arguments: args } = request.params;

            try {
                switch (name) {
                    case 'run_powershell':
                        return await this.runPowerShell(args);
                    case 'manage_services':
                        return await this.manageServices(args);
                    case 'get_system_info':
                        return await this.getSystemInfo(args);
                    case 'manage_processes':
                        return await this.manageProcesses(args);
                    case 'file_operations':
                        return await this.fileOperations(args);
                    case 'registry_operations':
                        return await this.registryOperations(args);
                    case 'network_info':
                        return await this.networkInfo(args);
                    case 'wmi_query':
                        return await this.wmiQuery(args);
                    default:
                        throw new Error(`Nieznane narzędzie: ${name}`);
                }
            } catch (error) {
                return {
                    content: [{
                        type: 'text',
                        text: `❌ Błąd wykonania narzędzia ${name}: ${error.message}`
                    }]
                };
            }
        });

        // Lista zasobów
        this.server.setRequestHandler('resources/list', async () => {
            return {
                resources: [
                    {
                        uri: 'system://info',
                        name: 'System Information',
                        description: 'Podstawowe informacje o systemie'
                    },
                    {
                        uri: 'system://services',
                        name: 'Windows Services',
                        description: 'Lista usług Windows'
                    },
                    {
                        uri: 'system://processes',
                        name: 'Running Processes',
                        description: 'Lista uruchomionych procesów'
                    },
                    {
                        uri: 'system://network',
                        name: 'Network Configuration',
                        description: 'Konfiguracja sieciowa'
                    }
                ]
            };
        });

        // Odczyt zasobów
        this.server.setRequestHandler('resources/read', async (request) => {
            const { uri } = request.params;

            switch (uri) {
                case 'system://info':
                    const info = await this.getSystemInfoDetailed();
                    return {
                        contents: [{
                            type: 'text',
                            text: this.formatSystemInfo(info)
                        }]
                    };
                case 'system://services':
                    const services = await this.getServicesList();
                    return {
                        contents: [{
                            type: 'text',
                            text: this.formatServicesList(services)
                        }]
                    };
                case 'system://processes':
                    const processes = await this.getProcessesList();
                    return {
                        contents: [{
                            type: 'text',
                            text: this.formatProcessesList(processes)
                        }]
                    };
                case 'system://network':
                    const network = await this.getNetworkInfo();
                    return {
                        contents: [{
                            type: 'text',
                            text: network
                        }]
                    };
                default:
                    throw new Error(`Nieznany zasób: ${uri}`);
            }
        });
    }

    // PowerShell execution
    private async runPowerShell(args: any) {
        if (!this.isWindows) {
            throw new Error('PowerShell jest dostępny tylko na Windows');
        }

        const { command, timeout = 30 } = args;
        
        // Sprawdź czy komenda nie jest niebezpieczna
        const dangerousCommands = [
            'format', 'del /f', 'rd /s', 'shutdown', 'restart-computer', 
            'remove-item -recurse', 'rm -rf', 'stop-computer'
        ];
        
        if (dangerousCommands.some(cmd => command.toLowerCase().includes(cmd))) {
            throw new Error('Komenda odrzucona ze względów bezpieczeństwa');
        }

        try {
            const { stdout, stderr } = await execAsync(
                `powershell -Command "${command.replace(/"/g, '`"')}"`,
                { timeout: timeout * 1000 }
            );

            let result = '🖥️ **PowerShell Command Executed**\n\n';
            result += `💻 **Command:** \`${command}\`\n\n`;
            
            if (stdout) {
                result += `📋 **Output:**\n\`\`\`\n${stdout}\n\`\`\`\n`;
            }
            
            if (stderr) {
                result += `⚠️ **Warnings/Errors:**\n\`\`\`\n${stderr}\n\`\`\``;
            }

            return {
                content: [{
                    type: 'text',
                    text: result
                }]
            };
        } catch (error) {
            throw new Error(`PowerShell error: ${error.message}`);
        }
    }

    // Service management
    private async manageServices(args: any) {
        if (!this.isWindows) {
            throw new Error('Zarządzanie usługami jest dostępne tylko na Windows');
        }

        const { action, service } = args;

        try {
            let command = '';
            let result = '';

            switch (action) {
                case 'start':
                    if (!service) throw new Error('Nazwa usługi jest wymagana');
                    command = `Start-Service -Name "${service}"`;
                    await execAsync(`powershell -Command "${command}"`);
                    result = `✅ Usługa **${service}** została uruchomiona`;
                    break;

                case 'stop':
                    if (!service) throw new Error('Nazwa usługi jest wymagana');
                    command = `Stop-Service -Name "${service}" -Force`;
                    await execAsync(`powershell -Command "${command}"`);
                    result = `⏹️ Usługa **${service}** została zatrzymana`;
                    break;

                case 'restart':
                    if (!service) throw new Error('Nazwa usługi jest wymagana');
                    command = `Restart-Service -Name "${service}" -Force`;
                    await execAsync(`powershell -Command "${command}"`);
                    result = `🔄 Usługa **${service}** została zrestartowana`;
                    break;

                case 'status':
                    if (!service) throw new Error('Nazwa usługi jest wymagana');
                    command = `Get-Service -Name "${service}" | Select-Object Name, Status, StartType, DisplayName | ConvertTo-Json`;
                    const { stdout } = await execAsync(`powershell -Command "${command}"`);
                    const serviceInfo = JSON.parse(stdout);
                    result = this.formatServiceStatus(serviceInfo);
                    break;

                case 'list':
                    const services = await this.getServicesList();
                    result = this.formatServicesList(services.slice(0, 20)); // Limit to 20 services
                    break;

                default:
                    throw new Error(`Nieznana akcja: ${action}`);
            }

            return {
                content: [{
                    type: 'text',
                    text: result
                }]
            };
        } catch (error) {
            throw new Error(`Service management error: ${error.message}`);
        }
    }

    // System information
    private async getSystemInfo(args: any) {
        const { detailed = false } = args;
        
        try {
            const info = await this.getSystemInfoDetailed();
            const result = this.formatSystemInfo(info, detailed);

            return {
                content: [{
                    type: 'text',
                    text: result
                }]
            };
        } catch (error) {
            throw new Error(`System info error: ${error.message}`);
        }
    }

    // Process management
    private async manageProcesses(args: any) {
        const { action, processName, pid, filter } = args;

        try {
            let result = '';

            switch (action) {
                case 'list':
                    const processes = await this.getProcessesList(filter);
                    result = this.formatProcessesList(processes.slice(0, 30)); // Limit to 30 processes
                    break;

                case 'kill':
                    if (!processName && !pid) {
                        throw new Error('Nazwa procesu lub PID jest wymagany');
                    }
                    
                    if (pid) {
                        if (this.isWindows) {
                            await execAsync(`taskkill /PID ${pid} /F`);
                        } else {
                            await execAsync(`kill -9 ${pid}`);
                        }
                        result = `❌ Proces PID **${pid}** został zakończony`;
                    } else {
                        if (this.isWindows) {
                            await execAsync(`taskkill /IM "${processName}" /F`);
                        } else {
                            await execAsync(`pkill "${processName}"`);
                        }
                        result = `❌ Proces **${processName}** został zakończony`;
                    }
                    break;

                case 'info':
                    if (!processName && !pid) {
                        throw new Error('Nazwa procesu lub PID jest wymagany');
                    }
                    
                    const processInfo = await this.getProcessInfo(processName, pid);
                    result = this.formatProcessInfo(processInfo);
                    break;

                default:
                    throw new Error(`Nieznana akcja: ${action}`);
            }

            return {
                content: [{
                    type: 'text',
                    text: result
                }]
            };
        } catch (error) {
            throw new Error(`Process management error: ${error.message}`);
        }
    }

    // File operations
    private async fileOperations(args: any) {
        const { operation, path: filePath, destination, recursive = false } = args;

        try {
            let result = '';

            switch (operation) {
                case 'list':
                    const items = await fs.promises.readdir(filePath, { withFileTypes: true });
                    result = `📁 **Zawartość katalogu:** ${filePath}\n\n`;
                    for (const item of items) {
                        const icon = item.isDirectory() ? '📁' : '📄';
                        result += `${icon} ${item.name}\n`;
                    }
                    break;

                case 'create_dir':
                    await fs.promises.mkdir(filePath, { recursive });
                    result = `✅ Katalog utworzony: **${filePath}**`;
                    break;

                case 'delete':
                    const stats = await fs.promises.stat(filePath);
                    if (stats.isDirectory()) {
                        await fs.promises.rmdir(filePath, { recursive });
                        result = `🗑️ Katalog usunięty: **${filePath}**`;
                    } else {
                        await fs.promises.unlink(filePath);
                        result = `🗑️ Plik usunięty: **${filePath}**`;
                    }
                    break;

                case 'copy':
                    if (!destination) throw new Error('Ścieżka docelowa jest wymagana');
                    await fs.promises.copyFile(filePath, destination);
                    result = `📋 Skopiowano: **${filePath}** → **${destination}**`;
                    break;

                case 'move':
                    if (!destination) throw new Error('Ścieżka docelowa jest wymagana');
                    await fs.promises.rename(filePath, destination);
                    result = `🔄 Przeniesiono: **${filePath}** → **${destination}**`;
                    break;

                case 'info':
                    const info = await fs.promises.stat(filePath);
                    result = this.formatFileInfo(filePath, info);
                    break;

                default:
                    throw new Error(`Nieznana operacja: ${operation}`);
            }

            return {
                content: [{
                    type: 'text',
                    text: result
                }]
            };
        } catch (error) {
            throw new Error(`File operation error: ${error.message}`);
        }
    }

    // Registry operations (Windows only, read-only)
    private async registryOperations(args: any) {
        if (!this.isWindows) {
            throw new Error('Operacje rejestru są dostępne tylko na Windows');
        }

        const { action, keyPath, valueName } = args;

        try {
            let result = '';

            switch (action) {
                case 'read':
                    if (!valueName) throw new Error('Nazwa wartości jest wymagana');
                    const command = `Get-ItemProperty -Path "Registry::${keyPath}" -Name "${valueName}" | Select-Object -ExpandProperty "${valueName}"`;
                    const { stdout } = await execAsync(`powershell -Command "${command}"`);
                    result = `🔑 **Registry Value:** ${keyPath}\\${valueName}\n\n`;
                    result += `📋 **Value:** ${stdout.trim()}`;
                    break;

                case 'list':
                    const listCommand = `Get-ChildItem -Path "Registry::${keyPath}" | Select-Object Name`;
                    const { stdout: listOutput } = await execAsync(`powershell -Command "${listCommand}"`);
                    result = `🔑 **Registry Keys:** ${keyPath}\n\n`;
                    result += `\`\`\`\n${listOutput}\n\`\`\``;
                    break;

                default:
                    throw new Error(`Nieznana akcja: ${action}`);
            }

            return {
                content: [{
                    type: 'text',
                    text: result
                }]
            };
        } catch (error) {
            throw new Error(`Registry operation error: ${error.message}`);
        }
    }

    // Network information
    private async networkInfo(args: any) {
        const { type, target } = args;

        try {
            let result = '';

            switch (type) {
                case 'interfaces':
                    const interfaces = os.networkInterfaces();
                    result = this.formatNetworkInterfaces(interfaces);
                    break;

                case 'connections':
                    if (this.isWindows) {
                        const { stdout } = await execAsync('netstat -an');
                        result = `🌐 **Network Connections**\n\n\`\`\`\n${stdout}\n\`\`\``;
                    } else {
                        const { stdout } = await execAsync('ss -tuln');
                        result = `🌐 **Network Connections**\n\n\`\`\`\n${stdout}\n\`\`\``;
                    }
                    break;

                case 'ping':
                    if (!target) throw new Error('Adres docelowy jest wymagany');
                    const pingCmd = this.isWindows ? `ping -n 4 ${target}` : `ping -c 4 ${target}`;
                    const { stdout: pingOutput } = await execAsync(pingCmd);
                    result = `🏓 **Ping:** ${target}\n\n\`\`\`\n${pingOutput}\n\`\`\``;
                    break;

                case 'trace':
                    if (!target) throw new Error('Adres docelowy jest wymagany');
                    const traceCmd = this.isWindows ? `tracert ${target}` : `traceroute ${target}`;
                    const { stdout: traceOutput } = await execAsync(traceCmd, { timeout: 30000 });
                    result = `🗺️ **Traceroute:** ${target}\n\n\`\`\`\n${traceOutput}\n\`\`\``;
                    break;

                default:
                    throw new Error(`Nieznany typ: ${type}`);
            }

            return {
                content: [{
                    type: 'text',
                    text: result
                }]
            };
        } catch (error) {
            throw new Error(`Network info error: ${error.message}`);
        }
    }

    // WMI Query (Windows only)
    private async wmiQuery(args: any) {
        if (!this.isWindows) {
            throw new Error('WMI jest dostępne tylko na Windows');
        }

        const { query, namespace = 'root\\cimv2' } = args;

        try {
            const command = `Get-WmiObject -Namespace "${namespace}" -Query "${query}" | ConvertTo-Json`;
            const { stdout } = await execAsync(`powershell -Command "${command}"`);
            
            let result = `🔍 **WMI Query Results**\n\n`;
            result += `📋 **Query:** ${query}\n`;
            result += `🗂️ **Namespace:** ${namespace}\n\n`;
            result += `📊 **Results:**\n\`\`\`json\n${stdout}\n\`\`\``;

            return {
                content: [{
                    type: 'text',
                    text: result
                }]
            };
        } catch (error) {
            throw new Error(`WMI query error: ${error.message}`);
        }
    }

    // Helper methods
    private async getSystemInfoDetailed(): Promise<SystemInfo> {
        const cpus = os.cpus();
        const totalMem = os.totalmem();
        const freeMem = os.freemem();

        return {
            hostname: os.hostname(),
            platform: os.platform(),
            arch: os.arch(),
            release: os.release(),
            uptime: os.uptime(),
            memory: {
                total: totalMem,
                free: freeMem,
                used: totalMem - freeMem
            },
            cpu: {
                model: cpus[0]?.model || 'Unknown',
                cores: cpus.length
            }
        };
    }

    private formatSystemInfo(info: SystemInfo, detailed: boolean = false): string {
        const formatBytes = (bytes: number) => {
            const gb = bytes / (1024 ** 3);
            return `${gb.toFixed(2)} GB`;
        };

        const formatUptime = (seconds: number) => {
            const days = Math.floor(seconds / 86400);
            const hours = Math.floor((seconds % 86400) / 3600);
            const minutes = Math.floor((seconds % 3600) / 60);
            return `${days}d ${hours}h ${minutes}m`;
        };

        let result = `💻 **System Information**\n\n`;
        result += `🖥️ **Hostname:** ${info.hostname}\n`;
        result += `🏷️ **Platform:** ${info.platform} (${info.arch})\n`;
        result += `📋 **Release:** ${info.release}\n`;
        result += `⏱️ **Uptime:** ${formatUptime(info.uptime)}\n\n`;
        
        result += `🧠 **Memory:**\n`;
        result += `   • Total: ${formatBytes(info.memory.total)}\n`;
        result += `   • Used: ${formatBytes(info.memory.used)} (${((info.memory.used / info.memory.total) * 100).toFixed(1)}%)\n`;
        result += `   • Free: ${formatBytes(info.memory.free)}\n\n`;
        
        result += `⚙️ **CPU:**\n`;
        result += `   • Model: ${info.cpu.model}\n`;
        result += `   • Cores: ${info.cpu.cores}\n`;

        if (detailed && this.isWindows) {
            result += `\n📊 **Additional Windows Info:** (Use WMI queries for detailed hardware info)`;
        }

        return result;
    }

    private async getServicesList(): Promise<ServiceStatus[]> {
        if (!this.isWindows) return [];

        try {
            const { stdout } = await execAsync(
                'powershell -Command "Get-Service | Select-Object Name, Status, StartType, DisplayName | ConvertTo-Json"'
            );
            return JSON.parse(stdout);
        } catch (error) {
            console.error('Error getting services list:', error);
            return [];
        }
    }

    private formatServicesList(services: ServiceStatus[]): string {
        let result = `🔧 **Windows Services** (showing ${services.length} services)\n\n`;
        
        for (const service of services) {
            const statusIcon = service.status === 'Running' ? '✅' : '⏹️';
            result += `${statusIcon} **${service.name}** - ${service.status}\n`;
            if (service.displayName && service.displayName !== service.name) {
                result += `   📋 ${service.displayName}\n`;
            }
        }

        return result;
    }

    private formatServiceStatus(service: any): string {
        const statusIcon = service.Status === 'Running' ? '✅' : '⏹️';
        
        let result = `🔧 **Service Status**\n\n`;
        result += `${statusIcon} **Name:** ${service.Name}\n`;
        result += `📋 **Display Name:** ${service.DisplayName}\n`;
        result += `🔄 **Status:** ${service.Status}\n`;
        result += `⚙️ **Start Type:** ${service.StartType}\n`;

        return result;
    }

    private async getProcessesList(filter?: string): Promise<ProcessInfo[]> {
        try {
            let command = '';
            
            if (this.isWindows) {
                command = 'powershell -Command "Get-Process | Select-Object Id, ProcessName, CPU, WorkingSet, Responding | ConvertTo-Json"';
            } else {
                command = 'ps aux --no-headers';
            }

            const { stdout } = await execAsync(command);
            
            if (this.isWindows) {
                const processes = JSON.parse(stdout);
                return processes.map((p: any) => ({
                    pid: p.Id,
                    name: p.ProcessName,
                    cpu: p.CPU || 0,
                    memory: p.WorkingSet || 0,
                    status: p.Responding ? 'Running' : 'Not Responding'
                })).filter((p: ProcessInfo) => !filter || p.name.toLowerCase().includes(filter.toLowerCase()));
            } else {
                // Parse ps output for Unix/Linux
                const lines = stdout.split('\n').filter(line => line.trim());
                return lines.map(line => {
                    const parts = line.trim().split(/\s+/);
                    return {
                        pid: parseInt(parts[1]),
                        name: parts[10] || 'Unknown',
                        cpu: parseFloat(parts[2]) || 0,
                        memory: parseFloat(parts[3]) || 0,
                        status: 'Running'
                    };
                }).filter((p: ProcessInfo) => !filter || p.name.toLowerCase().includes(filter.toLowerCase()));
            }
        } catch (error) {
            console.error('Error getting processes list:', error);
            return [];
        }
    }

    private formatProcessesList(processes: ProcessInfo[]): string {
        let result = `⚙️ **Running Processes** (showing ${processes.length} processes)\n\n`;
        
        for (const process of processes) {
            const memoryMB = this.isWindows ? 
                (process.memory / (1024 * 1024)).toFixed(1) : 
                process.memory.toFixed(1);
            
            result += `🔄 **${process.name}** (PID: ${process.pid})\n`;
            result += `   💻 CPU: ${process.cpu}% | 🧠 Memory: ${memoryMB}MB | 📊 Status: ${process.status}\n\n`;
        }

        return result;
    }

    private async getProcessInfo(processName?: string, pid?: number): Promise<string> {
        try {
            let command = '';
            
            if (pid) {
                if (this.isWindows) {
                    command = `powershell -Command "Get-Process -Id ${pid} | Select-Object * | ConvertTo-Json"`;
                } else {
                    command = `ps -p ${pid} -o pid,ppid,cmd,pcpu,pmem,etime`;
                }
            } else if (processName) {
                if (this.isWindows) {
                    command = `powershell -Command "Get-Process -Name '${processName}' | Select-Object * | ConvertTo-Json"`;
                } else {
                    command = `ps aux | grep ${processName}`;
                }
            }

            const { stdout } = await execAsync(command);
            return stdout;
        } catch (error) {
            throw new Error(`Process not found or error getting process info: ${error.message}`);
        }
    }

    private formatProcessInfo(processOutput: string): string {
        let result = `🔍 **Process Information**\n\n`;
        result += `\`\`\`\n${processOutput}\n\`\`\``;
        return result;
    }

    private formatFileInfo(filePath: string, stats: fs.Stats): string {
        const formatBytes = (bytes: number) => {
            if (bytes === 0) return '0 B';
            const k = 1024;
            const sizes = ['B', 'KB', 'MB', 'GB'];
            const i = Math.floor(Math.log(bytes) / Math.log(k));
            return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
        };

        let result = `📄 **File Information:** ${path.basename(filePath)}\n\n`;
        result += `📁 **Path:** ${filePath}\n`;
        result += `📏 **Size:** ${formatBytes(stats.size)}\n`;
        result += `📅 **Created:** ${stats.birthtime.toLocaleString()}\n`;
        result += `✏️ **Modified:** ${stats.mtime.toLocaleString()}\n`;
        result += `👁️ **Accessed:** ${stats.atime.toLocaleString()}\n`;
        result += `🔐 **Mode:** ${stats.mode.toString(8)}\n`;
        result += `📂 **Type:** ${stats.isDirectory() ? 'Directory' : stats.isFile() ? 'File' : 'Other'}\n`;

        return result;
    }

    private formatNetworkInterfaces(interfaces: NodeJS.Dict<os.NetworkInterfaceInfo[]>): string {
        let result = `🌐 **Network Interfaces**\n\n`;
        
        for (const [name, addrs] of Object.entries(interfaces)) {
            if (addrs) {
                result += `🔌 **${name}:**\n`;
                for (const addr of addrs) {
                    result += `   • ${addr.family}: ${addr.address}`;
                    if (addr.netmask) result += ` (${addr.netmask})`;
                    if (addr.mac && addr.mac !== '00:00:00:00:00:00') result += ` - MAC: ${addr.mac}`;
                    result += `\n`;
                }
                result += `\n`;
            }
        }

        return result;
    }

    private async getNetworkInfo(): Promise<string> {
        const interfaces = os.networkInterfaces();
        return this.formatNetworkInterfaces(interfaces);
    }

    // Main run method
    async run(): Promise<void> {
        console.error('🖥️ Desktop Commander MCP Server starting...');
        console.error(`📋 Platform: ${os.platform()}`);
        console.error(`🏷️ Node version: ${process.version}`);
        
        const transport = new StdioServerTransport();
        await this.server.connect(transport);
        
        console.error('✅ Desktop Commander MCP Server running');
    }
}

// Main execution
async function main() {
    try {
        const server = new DesktopCommanderMCPServer();
        await server.run();
    } catch (error) {
        console.error('❌ Server error:', error);
        process.exit(1);
    }
}

// Handle graceful shutdown
process.on('SIGINT', () => {
    console.error('\n🛑 Desktop Commander MCP Server shutting down...');
    process.exit(0);
});

process.on('SIGTERM', () => {
    console.error('\n🛑 Desktop Commander MCP Server terminated');
    process.exit(0);
});

if (require.main === module) {
    main().catch(console.error);
}

export { DesktopCommanderMCPServer };
