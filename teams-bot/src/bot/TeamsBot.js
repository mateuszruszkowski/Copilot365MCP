/**
 * Teams Bot with MCP Integration
 * Główna klasa bota Teams z integracją Model Context Protocol
 */

const { 
    TeamsActivityHandler, 
    CardFactory, 
    MessageFactory,
    TeamsInfo 
} = require('botbuilder');
const { IntentRecognizer } = require('../services/IntentRecognizer');
const { CardBuilder } = require('../utils/CardBuilder');
const { ResponseFormatter } = require('../utils/ResponseFormatter');
const moment = require('moment');

class TeamsBot extends TeamsActivityHandler {
    constructor(mcpClient) {
        super();

        this.mcpClient = mcpClient;
        this.intentRecognizer = new IntentRecognizer();
        this.cardBuilder = new CardBuilder();
        this.responseFormatter = new ResponseFormatter();
        
        // Aktywne sesje deploymentów dla monitoringu
        this.activeDeployments = new Map();
        
        this.setupHandlers();
    }

    setupHandlers() {
        // Obsługa wiadomości
        this.onMessage(async (context, next) => {
            console.log(`📨 Message received: ${context.activity.text}`);
            
            try {
                const userMessage = context.activity.text?.trim();
                if (!userMessage) {
                    await context.sendActivity('👋 Cześć! Jestem DevOps Copilot. Jak mogę Ci pomóc?');
                    await next();
                    return;
                }

                // Rozpoznaj intencję
                const intent = await this.intentRecognizer.recognizeIntent(userMessage);
                console.log(`🧠 Intent recognized:`, intent);

                // Wykonaj odpowiednią akcję
                await this.handleIntent(context, intent);

            } catch (error) {
                console.error('❌ Error handling message:', error);
                await context.sendActivity('😔 Przepraszam, wystąpił błąd podczas przetwarzania Twojej wiadomości.');
            }

            await next();
        });

        // Obsługa nowych członków
        this.onMembersAdded(async (context, next) => {
            const welcomeText = 
                '🎉 **Witaj w DevOps Copilot!**\n\n' +
                'Jestem Twoim asystentem DevOps z integracją Model Context Protocol. Mogę pomóc Ci:\n\n' +
                '🚀 **Deploy aplikacji** - `deploy v1.2.3 do staging`\n' +
                '📊 **Sprawdzanie statusu** - `status pipeline 123`\n' +
                '📋 **Zarządzanie zadaniami** - `utwórz zadanie: Fix login bug`\n' +
                '🖥️ **Komendy systemowe** - `uruchom docker ps`\n' +
                '📈 **Monitoring zasobów** - `sprawdź zasoby Azure`\n\n' +
                '💡 **Wskazówka:** Napisz `help` aby zobaczyć wszystkie dostępne komendy!';

            const welcomeCard = this.cardBuilder.createWelcomeCard(welcomeText);
            await context.sendActivity(MessageFactory.attachment(welcomeCard));
            await next();
        });

        // Obsługa adaptiveCard submit actions
        this.onAdaptiveCardInvoke(async (context, invokeValue) => {
            console.log('🎯 AdaptiveCard invoke:', invokeValue);
            
            try {
                const action = invokeValue.action;
                
                switch (action.type) {
                    case 'deployment_action':
                        return await this.handleDeploymentAction(context, action.data);
                    case 'pipeline_action':
                        return await this.handlePipelineAction(context, action.data);
                    case 'work_item_action':
                        return await this.handleWorkItemAction(context, action.data);
                    default:
                        return this.createInvokeResponse(400, 'Unknown action type');
                }
            } catch (error) {
                console.error('❌ Error handling adaptive card invoke:', error);
                return this.createInvokeResponse(500, 'Internal error');
            }
        });
    }

    async handleIntent(context, intent) {
        const { type, parameters, confidence } = intent;

        // Log intent details
        console.log(`🎯 Handling intent: ${type} (confidence: ${confidence})`);

        // Sprawdź czy poziom pewności jest wystarczający
        if (confidence < 0.6) {
            await this.handleUnknownIntent(context, intent.originalText);
            return;
        }

        switch (type) {
            case 'deploy':
                await this.handleDeployment(context, parameters);
                break;
            
            case 'pipeline_status':
                await this.handlePipelineStatus(context, parameters);
                break;
            
            case 'create_work_item':
                await this.handleCreateWorkItem(context, parameters);
                break;
            
            case 'system_command':
                await this.handleSystemCommand(context, parameters);
                break;
            
            case 'resource_check':
                await this.handleResourceCheck(context, parameters);
                break;
            
            case 'help':
                await this.handleHelp(context);
                break;
            
            case 'git_operations':
                await this.handleGitOperations(context, parameters);
                break;
            
            default:
                await this.handleUnknownIntent(context, intent.originalText);
        }
    }

    // Deployment handling
    async handleDeployment(context, parameters) {
        const { version, environment, service } = parameters;
        
        if (!version || !environment) {
            const errorCard = this.cardBuilder.createErrorCard(
                'Niepełne parametry deploymentu',
                'Podaj wersję i środowisko, np: "deploy v1.2.3 do staging"'
            );
            await context.sendActivity(MessageFactory.attachment(errorCard));
            return;
        }

        // Wyślij wiadomość o rozpoczęciu
        const startCard = this.cardBuilder.createDeploymentStartCard(version, environment, service);
        const startResponse = await context.sendActivity(MessageFactory.attachment(startCard));

        try {
            // Wywołaj MCP do deploymentu
            const deployResult = await this.mcpClient.callTool('azure-function', 'deploy_to_azure', {
                version,
                environment,
                serviceName: service
            });

            // Przygotuj kartę z wynikiem
            const resultCard = this.cardBuilder.createDeploymentResultCard(deployResult, version, environment);
            
            // Aktualizuj poprzednią wiadomość
            await this.updateActivity(context, startResponse.id, MessageFactory.attachment(resultCard));

            // Rozpocznij monitoring deploymentu
            this.startDeploymentMonitoring(context, version, environment, startResponse.id);

        } catch (error) {
            console.error('❌ Deployment error:', error);
            const errorCard = this.cardBuilder.createErrorCard(
                'Błąd deploymentu',
                `Nie udało się rozpocząć deploymentu: ${error.message}`
            );
            await this.updateActivity(context, startResponse.id, MessageFactory.attachment(errorCard));
        }
    }

    // Pipeline status handling
    async handlePipelineStatus(context, parameters) {
        const { pipelineId, project } = parameters;
        
        if (!pipelineId) {
            const errorCard = this.cardBuilder.createErrorCard(
                'Brak ID pipeline',
                'Podaj ID pipeline, np: "status pipeline 123"'
            );
            await context.sendActivity(MessageFactory.attachment(errorCard));
            return;
        }

        try {
            // Wywołaj MCP do sprawdzenia statusu
            const statusResult = await this.mcpClient.callTool('azure-function', 'check_pipeline_status', {
                pipelineId,
                project
            });

            // Przygotuj kartę z statusem
            const statusCard = this.cardBuilder.createPipelineStatusCard(statusResult, pipelineId);
            await context.sendActivity(MessageFactory.attachment(statusCard));

        } catch (error) {
            console.error('❌ Pipeline status error:', error);
            const errorCard = this.cardBuilder.createErrorCard(
                'Błąd sprawdzania statusu',
                `Nie udało się sprawdzić statusu pipeline: ${error.message}`
            );
            await context.sendActivity(MessageFactory.attachment(errorCard));
        }
    }

    // Work item creation
    async handleCreateWorkItem(context, parameters) {
        const { title, type, description, assignee } = parameters;
        
        if (!title) {
            const errorCard = this.cardBuilder.createErrorCard(
                'Brak tytułu zadania',
                'Podaj tytuł zadania, np: "utwórz zadanie: Fix login bug"'
            );
            await context.sendActivity(MessageFactory.attachment(errorCard));
            return;
        }

        try {
            // Wywołaj Azure DevOps MCP
            const workItemResult = await this.mcpClient.callTool('azure-devops', 'create_work_item', {
                title,
                type: type || 'Task',
                description,
                assignee
            });

            // Przygotuj kartę z wynikiem
            const workItemCard = this.cardBuilder.createWorkItemResultCard(workItemResult);
            await context.sendActivity(MessageFactory.attachment(workItemCard));

        } catch (error) {
            console.error('❌ Work item creation error:', error);
            const errorCard = this.cardBuilder.createErrorCard(
                'Błąd tworzenia zadania',
                `Nie udało się utworzyć zadania: ${error.message}`
            );
            await context.sendActivity(MessageFactory.attachment(errorCard));
        }
    }

    // System command handling
    async handleSystemCommand(context, parameters) {
        const { command } = parameters;
        
        if (!command) {
            const errorCard = this.cardBuilder.createErrorCard(
                'Brak komendy',
                'Podaj komendę do wykonania, np: "uruchom docker ps"'
            );
            await context.sendActivity(MessageFactory.attachment(errorCard));
            return;
        }

        try {
            // Wybierz odpowiedni serwer MCP
            let mcpServer = 'local-devops';
            let toolName = 'run_command';
            
            // Sprawdź czy to komenda PowerShell/Windows
            if (command.toLowerCase().includes('powershell') || 
                command.toLowerCase().includes('get-') || 
                command.toLowerCase().includes('start-service')) {
                mcpServer = 'desktop-commander';
                toolName = 'run_powershell';
            }

            // Wywołaj odpowiedni MCP
            const commandResult = await this.mcpClient.callTool(mcpServer, toolName, {
                command: command
            });

            // Przygotuj kartę z wynikiem
            const commandCard = this.cardBuilder.createCommandResultCard(commandResult, command);
            await context.sendActivity(MessageFactory.attachment(commandCard));

        } catch (error) {
            console.error('❌ System command error:', error);
            const errorCard = this.cardBuilder.createErrorCard(
                'Błąd wykonania komendy',
                `Nie udało się wykonać komendy: ${error.message}`
            );
            await context.sendActivity(MessageFactory.attachment(errorCard));
        }
    }

    // Resource check handling
    async handleResourceCheck(context, parameters) {
        const { resourceType, resourceGroup } = parameters;
        
        try {
            // Wywołaj Azure Function MCP
            const resourceResult = await this.mcpClient.callTool('azure-function', 'get_resource_usage', {
                resourceGroup: resourceGroup || 'copilot-mcp-workshop-rg',
                timeRange: '24h'
            });

            // Przygotuj kartę z zasobami
            const resourceCard = this.cardBuilder.createResourceStatusCard(resourceResult);
            await context.sendActivity(MessageFactory.attachment(resourceCard));

        } catch (error) {
            console.error('❌ Resource check error:', error);
            const errorCard = this.cardBuilder.createErrorCard(
                'Błąd sprawdzania zasobów',
                `Nie udało się sprawdzić zasobów: ${error.message}`
            );
            await context.sendActivity(MessageFactory.attachment(errorCard));
        }
    }

    // Git operations
    async handleGitOperations(context, parameters) {
        const { operation, path, message } = parameters;
        
        try {
            let toolName = '';
            let toolParams = {};

            switch (operation) {
                case 'status':
                    toolName = 'git_status';
                    toolParams = { path: path || '.' };
                    break;
                case 'commit':
                    toolName = 'git_commit';
                    toolParams = { 
                        message: message || 'Auto commit from Teams Bot',
                        add_all: true,
                        path: path || '.'
                    };
                    break;
                default:
                    throw new Error(`Nieznana operacja Git: ${operation}`);
            }

            // Wywołaj Local DevOps MCP
            const gitResult = await this.mcpClient.callTool('local-devops', toolName, toolParams);

            // Przygotuj kartę z wynikiem
            const gitCard = this.cardBuilder.createGitResultCard(gitResult, operation);
            await context.sendActivity(MessageFactory.attachment(gitCard));

        } catch (error) {
            console.error('❌ Git operation error:', error);
            const errorCard = this.cardBuilder.createErrorCard(
                'Błąd operacji Git',
                `Nie udało się wykonać operacji Git: ${error.message}`
            );
            await context.sendActivity(MessageFactory.attachment(errorCard));
        }
    }

    // Help handling
    async handleHelp(context) {
        const helpCard = this.cardBuilder.createHelpCard();
        await context.sendActivity(MessageFactory.attachment(helpCard));
    }

    // Unknown intent handling
    async handleUnknownIntent(context, originalText) {
        const suggestions = this.intentRecognizer.getSuggestions(originalText);
        const unknownCard = this.cardBuilder.createUnknownIntentCard(originalText, suggestions);
        await context.sendActivity(MessageFactory.attachment(unknownCard));
    }

    // Deployment monitoring
    startDeploymentMonitoring(context, version, environment, messageId) {
        const deploymentId = `${version}-${environment}-${Date.now()}`;
        
        this.activeDeployments.set(deploymentId, {
            context,
            version,
            environment,
            messageId,
            startTime: new Date(),
            checkCount: 0
        });

        // Sprawdzaj status co 30 sekund przez maksymalnie 10 minut
        const interval = setInterval(async () => {
            const deployment = this.activeDeployments.get(deploymentId);
            if (!deployment) {
                clearInterval(interval);
                return;
            }

            deployment.checkCount++;
            
            try {
                // Symulacja sprawdzenia statusu deploymentu
                const isComplete = deployment.checkCount >= 3; // Po 3 sprawdzeniach uznaj za ukończony
                const isSuccess = Math.random() > 0.1; // 90% szans na sukces

                if (isComplete) {
                    const finalCard = this.cardBuilder.createDeploymentCompleteCard(
                        deployment.version,
                        deployment.environment,
                        isSuccess
                    );
                    
                    await this.updateActivity(
                        deployment.context,
                        deployment.messageId,
                        MessageFactory.attachment(finalCard)
                    );

                    this.activeDeployments.delete(deploymentId);
                    clearInterval(interval);
                } else {
                    // Aktualizuj kartę z progresem
                    const progressCard = this.cardBuilder.createDeploymentProgressCard(
                        deployment.version,
                        deployment.environment,
                        deployment.checkCount
                    );
                    
                    await this.updateActivity(
                        deployment.context,
                        deployment.messageId,
                        MessageFactory.attachment(progressCard)
                    );
                }
            } catch (error) {
                console.error('❌ Deployment monitoring error:', error);
                this.activeDeployments.delete(deploymentId);
                clearInterval(interval);
            }
        }, 30000); // 30 sekund

        // Timeout po 10 minutach
        setTimeout(() => {
            if (this.activeDeployments.has(deploymentId)) {
                this.activeDeployments.delete(deploymentId);
                clearInterval(interval);
            }
        }, 600000); // 10 minut
    }

    // Utility methods
    async updateActivity(context, activityId, newActivity) {
        try {
            newActivity.id = activityId;
            await context.updateActivity(newActivity);
        } catch (error) {
            console.error('❌ Error updating activity:', error);
            // Jeśli update się nie powiedzie, wyślij nową wiadomość
            await context.sendActivity(newActivity);
        }
    }

    createInvokeResponse(statusCode, body) {
        return {
            statusCode,
            body
        };
    }

    // Adaptive Card action handlers
    async handleDeploymentAction(context, data) {
        const { action, deploymentId } = data;
        
        switch (action) {
            case 'cancel':
                // Logika anulowania deploymentu
                await context.sendActivity('⏹️ Deployment został anulowany');
                break;
            case 'logs':
                // Pokaż logi deploymentu
                await context.sendActivity('📋 Wyświetlanie logów deploymentu...');
                break;
        }
        
        return this.createInvokeResponse(200, {});
    }

    async handlePipelineAction(context, data) {
        const { action, pipelineId } = data;
        
        switch (action) {
            case 'rerun':
                // Uruchom pipeline ponownie
                await this.handleDeployment(context, { pipelineId });
                break;
            case 'cancel':
                // Anuluj pipeline
                await context.sendActivity('⏹️ Pipeline został anulowany');
                break;
        }
        
        return this.createInvokeResponse(200, {});
    }

    async handleWorkItemAction(context, data) {
        const { action, workItemId } = data;
        
        switch (action) {
            case 'open':
                // Otwórz work item w przeglądarce
                await context.sendActivity(`🔗 Otwieranie zadania #${workItemId} w Azure DevOps`);
                break;
            case 'assign_to_me':
                // Przypisz do siebie
                await context.sendActivity(`👤 Zadanie #${workItemId} zostało przypisane do Ciebie`);
                break;
        }
        
        return this.createInvokeResponse(200, {});
    }
}

module.exports = { TeamsBot };
