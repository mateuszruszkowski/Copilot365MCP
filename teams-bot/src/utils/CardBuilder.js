/**
 * Card Builder - Tworzenie Adaptive Cards dla Teams
 */

const { CardFactory } = require('botbuilder');

class CardBuilder {
    constructor() {
        this.cardVersion = '1.5';
    }

    /**
     * Tworzy kartę powitalną
     */
    createWelcomeCard(welcomeText) {
        const card = {
            type: 'AdaptiveCard',
            version: this.cardVersion,
            body: [
                {
                    type: 'Container',
                    style: 'emphasis',
                    items: [
                        {
                            type: 'ColumnSet',
                            columns: [
                                {
                                    type: 'Column',
                                    width: 'auto',
                                    items: [
                                        {
                                            type: 'Image',
                                            url: 'https://raw.githubusercontent.com/microsoft/botframework-sdk/main/icon.png',
                                            size: 'Medium',
                                            style: 'Person'
                                        }
                                    ]
                                },
                                {
                                    type: 'Column',
                                    width: 'stretch',
                                    items: [
                                        {
                                            type: 'TextBlock',
                                            text: '🤖 DevOps Copilot z MCP',
                                            weight: 'Bolder',
                                            size: 'Large',
                                            color: 'Accent'
                                        },
                                        {
                                            type: 'TextBlock',
                                            text: 'Model Context Protocol Integration',
                                            weight: 'Lighter',
                                            size: 'Small'
                                        }
                                    ]
                                }
                            ]
                        }
                    ]
                },
                {
                    type: 'TextBlock',
                    text: welcomeText,
                    wrap: true,
                    spacing: 'Medium'
                }
            ],
            actions: [
                {
                    type: 'Action.Submit',
                    title: '📋 Pokaż dostępne komendy',
                    data: {
                        action: 'help'
                    }
                },
                {
                    type: 'Action.Submit',
                    title: '🚀 Przykład: Deploy',
                    data: {
                        action: 'example',
                        command: 'deploy v1.0.0 do staging'
                    }
                }
            ]
        };

        return CardFactory.adaptiveCard(card);
    }

    /**
     * Tworzy kartę z wynikiem deploymentu
     */
    createDeploymentResultCard(mcpResult, version, environment) {
        const resultText = mcpResult.content?.[0]?.text || 'Brak szczegółów';
        
        const card = {
            type: 'AdaptiveCard',
            version: this.cardVersion,
            body: [
                {
                    type: 'Container',
                    style: 'good',
                    items: [
                        {
                            type: 'TextBlock',
                            text: '🚀 Deployment Started',
                            weight: 'Bolder',
                            size: 'Medium',
                            color: 'Light'
                        }
                    ]
                },
                {
                    type: 'FactSet',
                    facts: [
                        {
                            title: 'Version',
                            value: version
                        },
                        {
                            title: 'Environment',
                            value: environment
                        },
                        {
                            title: 'Status',
                            value: '🔄 In Progress'
                        },
                        {
                            title: 'Started',
                            value: new Date().toLocaleString()
                        }
                    ]
                },
                {
                    type: 'TextBlock',
                    text: resultText,
                    wrap: true,
                    separator: true
                }
            ],
            actions: [
                {
                    type: 'Action.Submit',
                    title: '⏹️ Cancel Deployment',
                    data: {
                        action: 'deployment_action',
                        type: 'cancel',
                        version: version,
                        environment: environment
                    },
                    style: 'destructive'
                },
                {
                    type: 'Action.Submit',
                    title: '📋 Show Logs',
                    data: {
                        action: 'deployment_action',
                        type: 'logs',
                        version: version,
                        environment: environment
                    }
                }
            ]
        };

        return CardFactory.adaptiveCard(card);
    }

    /**
     * Tworzy kartę startu deploymentu
     */
    createDeploymentStartCard(version, environment, service) {
        const card = {
            type: 'AdaptiveCard',
            version: this.cardVersion,
            body: [
                {
                    type: 'Container',
                    style: 'attention',
                    items: [
                        {
                            type: 'TextBlock',
                            text: '⏳ Initializing Deployment...',
                            weight: 'Bolder',
                            size: 'Medium',
                            color: 'Light'
                        }
                    ]
                },
                {
                    type: 'FactSet',
                    facts: [
                        {
                            title: 'Version',
                            value: version
                        },
                        {
                            title: 'Environment',
                            value: environment
                        },
                        {
                            title: 'Service',
                            value: service || 'default'
                        }
                    ]
                },
                {
                    type: 'TextBlock',
                    text: 'Connecting to deployment service...',
                    wrap: true,
                    isSubtle: true
                }
            ]
        };

        return CardFactory.adaptiveCard(card);
    }

    /**
     * Tworzy kartę postępu deploymentu
     */
    createDeploymentProgressCard(version, environment, step) {
        const steps = [
            '📋 Initializing',
            '🔍 Validating configuration',
            '📦 Building artifacts', 
            '🧪 Running tests',
            '🚀 Deploying to environment',
            '🔍 Smoke tests',
            '✅ Finalizing'
        ];

        const progress = Math.min(Math.floor((step / 7) * 100), 100);
        const currentStep = Math.min(step, steps.length - 1);

        const card = {
            type: 'AdaptiveCard',
            version: this.cardVersion,
            body: [
                {
                    type: 'Container',
                    style: 'accent',
                    items: [
                        {
                            type: 'TextBlock',
                            text: '🔄 Deployment In Progress',
                            weight: 'Bolder',
                            size: 'Medium',
                            color: 'Light'
                        }
                    ]
                },
                {
                    type: 'ColumnSet',
                    columns: [
                        {
                            type: 'Column',
                            width: 'stretch',
                            items: [
                                {
                                    type: 'TextBlock',
                                    text: `Progress: ${progress}%`,
                                    weight: 'Bolder'
                                }
                            ]
                        },
                        {
                            type: 'Column',
                            width: 'auto',
                            items: [
                                {
                                    type: 'TextBlock',
                                    text: `Step ${step}/7`,
                                    isSubtle: true
                                }
                            ]
                        }
                    ]
                },
                {
                    type: 'TextBlock',
                    text: `Current: ${steps[currentStep]}`,
                    wrap: true,
                    spacing: 'Small'
                },
                {
                    type: 'FactSet',
                    facts: [
                        {
                            title: 'Version',
                            value: version
                        },
                        {
                            title: 'Environment', 
                            value: environment
                        },
                        {
                            title: 'Elapsed',
                            value: `${step * 30} seconds`
                        }
                    ]
                }
            ]
        };

        return CardFactory.adaptiveCard(card);
    }

    /**
     * Tworzy kartę ukończonego deploymentu
     */
    createDeploymentCompleteCard(version, environment, success) {
        const card = {
            type: 'AdaptiveCard',
            version: this.cardVersion,
            body: [
                {
                    type: 'Container',
                    style: success ? 'good' : 'attention',
                    items: [
                        {
                            type: 'TextBlock',
                            text: success ? '✅ Deployment Successful!' : '❌ Deployment Failed!',
                            weight: 'Bolder',
                            size: 'Medium',
                            color: 'Light'
                        }
                    ]
                },
                {
                    type: 'FactSet',
                    facts: [
                        {
                            title: 'Version',
                            value: version
                        },
                        {
                            title: 'Environment',
                            value: environment
                        },
                        {
                            title: 'Status',
                            value: success ? '✅ Success' : '❌ Failed'
                        },
                        {
                            title: 'Completed',
                            value: new Date().toLocaleString()
                        }
                    ]
                }
            ],
            actions: success ? [
                {
                    type: 'Action.OpenUrl',
                    title: '🌐 Open Application',
                    url: `https://app-${environment}.company.com`
                },
                {
                    type: 'Action.Submit',
                    title: '📊 View Metrics',
                    data: {
                        action: 'deployment_action',
                        type: 'metrics',
                        version: version,
                        environment: environment
                    }
                }
            ] : [
                {
                    type: 'Action.Submit',
                    title: '🔄 Retry Deployment',
                    data: {
                        action: 'deployment_action',
                        type: 'retry',
                        version: version,
                        environment: environment
                    }
                },
                {
                    type: 'Action.Submit',
                    title: '📋 View Logs',
                    data: {
                        action: 'deployment_action',
                        type: 'logs',
                        version: version,
                        environment: environment
                    }
                }
            ]
        };

        return CardFactory.adaptiveCard(card);
    }

    /**
     * Tworzy kartę statusu pipeline
     */
    createPipelineStatusCard(mcpResult, pipelineId) {
        const resultText = mcpResult.content?.[0]?.text || 'Brak szczegółów';
        
        // Wyciągnij status z tekstu (uproszczona logika)
        const isRunning = resultText.toLowerCase().includes('running') || resultText.includes('🔄');
        const isSuccess = resultText.toLowerCase().includes('success') || resultText.includes('✅');
        const isFailed = resultText.toLowerCase().includes('failed') || resultText.includes('❌');

        let style = 'default';
        let statusIcon = '📋';
        
        if (isRunning) {
            style = 'accent';
            statusIcon = '🔄';
        } else if (isSuccess) {
            style = 'good';
            statusIcon = '✅';
        } else if (isFailed) {
            style = 'attention';
            statusIcon = '❌';
        }

        const card = {
            type: 'AdaptiveCard',
            version: this.cardVersion,
            body: [
                {
                    type: 'Container',
                    style: style,
                    items: [
                        {
                            type: 'TextBlock',
                            text: `${statusIcon} Pipeline #${pipelineId}`,
                            weight: 'Bolder',
                            size: 'Medium',
                            color: style === 'default' ? 'Default' : 'Light'
                        }
                    ]
                },
                {
                    type: 'TextBlock',
                    text: resultText,
                    wrap: true,
                    spacing: 'Medium'
                }
            ],
            actions: [
                {
                    type: 'Action.Submit',
                    title: '🔄 Rerun Pipeline',
                    data: {
                        action: 'pipeline_action',
                        type: 'rerun',
                        pipelineId: pipelineId
                    }
                },
                {
                    type: 'Action.OpenUrl',
                    title: '🔗 Open in Azure DevOps',
                    url: `https://dev.azure.com/_build/results?buildId=${pipelineId}`
                }
            ]
        };

        return CardFactory.adaptiveCard(card);
    }

    /**
     * Tworzy kartę wyniku work item
     */
    createWorkItemResultCard(mcpResult) {
        const resultText = mcpResult.content?.[0]?.text || 'Brak szczegółów';
        
        // Wyciągnij ID z tekstu (uproszczona logika)
        const idMatch = resultText.match(/#(\d+)/);
        const workItemId = idMatch ? idMatch[1] : 'Unknown';

        const card = {
            type: 'AdaptiveCard',
            version: this.cardVersion,
            body: [
                {
                    type: 'Container',
                    style: 'good',
                    items: [
                        {
                            type: 'TextBlock',
                            text: '📋 Work Item Created',
                            weight: 'Bolder',
                            size: 'Medium',
                            color: 'Light'
                        }
                    ]
                },
                {
                    type: 'TextBlock',
                    text: resultText,
                    wrap: true,
                    spacing: 'Medium'
                }
            ],
            actions: [
                {
                    type: 'Action.Submit',
                    title: '👤 Assign to Me',
                    data: {
                        action: 'work_item_action',
                        type: 'assign_to_me',
                        workItemId: workItemId
                    }
                },
                {
                    type: 'Action.OpenUrl',
                    title: '🔗 Open Work Item',
                    url: `https://dev.azure.com/_workitems/edit/${workItemId}`
                }
            ]
        };

        return CardFactory.adaptiveCard(card);
    }

    /**
     * Tworzy kartę wyniku komendy systemowej
     */
    createCommandResultCard(mcpResult, command) {
        const resultText = mcpResult.content?.[0]?.text || 'Brak wyników';
        
        const card = {
            type: 'AdaptiveCard',
            version: this.cardVersion,
            body: [
                {
                    type: 'Container',
                    style: 'emphasis',
                    items: [
                        {
                            type: 'TextBlock',
                            text: '🖥️ Command Executed',
                            weight: 'Bolder',
                            size: 'Medium'
                        }
                    ]
                },
                {
                    type: 'TextBlock',
                    text: `**Command:** \`${command}\``,
                    wrap: true,
                    spacing: 'Medium'
                },
                {
                    type: 'TextBlock',
                    text: resultText,
                    wrap: true,
                    fontType: 'Monospace',
                    spacing: 'Small'
                }
            ]
        };

        return CardFactory.adaptiveCard(card);
    }

    /**
     * Tworzy kartę statusu zasobów
     */
    createResourceStatusCard(mcpResult) {
        const resultText = mcpResult.content?.[0]?.text || 'Brak danych o zasobach';
        
        const card = {
            type: 'AdaptiveCard',
            version: this.cardVersion,
            body: [
                {
                    type: 'Container',
                    style: 'accent',
                    items: [
                        {
                            type: 'TextBlock',
                            text: '📊 Resource Status',
                            weight: 'Bolder',
                            size: 'Medium',
                            color: 'Light'
                        }
                    ]
                },
                {
                    type: 'TextBlock',
                    text: resultText,
                    wrap: true,
                    spacing: 'Medium'
                }
            ],
            actions: [
                {
                    type: 'Action.OpenUrl',
                    title: '📈 Azure Portal',
                    url: 'https://portal.azure.com'
                },
                {
                    type: 'Action.Submit',
                    title: '🔄 Refresh',
                    data: {
                        action: 'resource_action',
                        type: 'refresh'
                    }
                }
            ]
        };

        return CardFactory.adaptiveCard(card);
    }

    /**
     * Tworzy kartę wyniku operacji Git
     */
    createGitResultCard(mcpResult, operation) {
        const resultText = mcpResult.content?.[0]?.text || 'Brak wyników';
        
        const operationIcons = {
            'status': '📋',
            'commit': '💾',
            'push': '⬆️',
            'pull': '⬇️',
            'log': '📜'
        };

        const icon = operationIcons[operation] || '🔧';

        const card = {
            type: 'AdaptiveCard',
            version: this.cardVersion,
            body: [
                {
                    type: 'Container',
                    style: 'emphasis',
                    items: [
                        {
                            type: 'TextBlock',
                            text: `${icon} Git ${operation.charAt(0).toUpperCase() + operation.slice(1)}`,
                            weight: 'Bolder',
                            size: 'Medium'
                        }
                    ]
                },
                {
                    type: 'TextBlock',
                    text: resultText,
                    wrap: true,
                    fontType: 'Monospace',
                    spacing: 'Medium'
                }
            ]
        };

        return CardFactory.adaptiveCard(card);
    }

    /**
     * Tworzy kartę pomocy
     */
    createHelpCard() {
        const card = {
            type: 'AdaptiveCard',
            version: this.cardVersion,
            body: [
                {
                    type: 'Container',
                    style: 'accent',
                    items: [
                        {
                            type: 'TextBlock',
                            text: '📚 DevOps Copilot - Help',
                            weight: 'Bolder',
                            size: 'Large',
                            color: 'Light'
                        }
                    ]
                },
                {
                    type: 'TextBlock',
                    text: 'Dostępne komendy i przykłady użycia:',
                    weight: 'Bolder',
                    spacing: 'Medium'
                },
                {
                    type: 'Container',
                    items: [
                        {
                            type: 'TextBlock',
                            text: '🚀 **Deployment**',
                            weight: 'Bolder',
                            color: 'Accent'
                        },
                        {
                            type: 'TextBlock',
                            text: '• `deploy v1.2.3 do staging`\n• `wdróż wersję v2.0.0 na prod`',
                            wrap: true,
                            fontType: 'Monospace'
                        }
                    ]
                },
                {
                    type: 'Container',
                    items: [
                        {
                            type: 'TextBlock',
                            text: '📊 **Pipeline Status**',
                            weight: 'Bolder',
                            color: 'Accent'
                        },
                        {
                            type: 'TextBlock',
                            text: '• `status pipeline 123`\n• `sprawdź pipeline 456`',
                            wrap: true,
                            fontType: 'Monospace'
                        }
                    ]
                },
                {
                    type: 'Container',
                    items: [
                        {
                            type: 'TextBlock',
                            text: '📋 **Work Items**',
                            weight: 'Bolder',
                            color: 'Accent'
                        },
                        {
                            type: 'TextBlock',
                            text: '• `utwórz zadanie: Fix login bug`\n• `dodaj feature: Add user settings`',
                            wrap: true,
                            fontType: 'Monospace'
                        }
                    ]
                },
                {
                    type: 'Container',
                    items: [
                        {
                            type: 'TextBlock',
                            text: '🖥️ **System Commands**',
                            weight: 'Bolder',
                            color: 'Accent'
                        },
                        {
                            type: 'TextBlock',
                            text: '• `uruchom docker ps`\n• `wykonaj kubectl get pods`',
                            wrap: true,
                            fontType: 'Monospace'
                        }
                    ]
                },
                {
                    type: 'Container',
                    items: [
                        {
                            type: 'TextBlock',
                            text: '📈 **Resources**',
                            weight: 'Bolder',
                            color: 'Accent'
                        },
                        {
                            type: 'TextBlock',
                            text: '• `sprawdź zasoby`\n• `status infrastruktury`',
                            wrap: true,
                            fontType: 'Monospace'
                        }
                    ]
                }
            ],
            actions: [
                {
                    type: 'Action.Submit',
                    title: '🚀 Try: Deploy Example',
                    data: {
                        action: 'example',
                        command: 'deploy v1.0.0 do staging'
                    }
                },
                {
                    type: 'Action.Submit',
                    title: '📊 Try: Pipeline Status',
                    data: {
                        action: 'example',
                        command: 'status pipeline 123'
                    }
                }
            ]
        };

        return CardFactory.adaptiveCard(card);
    }

    /**
     * Tworzy kartę dla nierozpoznanej intencji
     */
    createUnknownIntentCard(originalText, suggestions) {
        const card = {
            type: 'AdaptiveCard',
            version: this.cardVersion,
            body: [
                {
                    type: 'Container',
                    style: 'warning',
                    items: [
                        {
                            type: 'TextBlock',
                            text: '🤔 Nie rozumiem tego polecenia',
                            weight: 'Bolder',
                            size: 'Medium',
                            color: 'Light'
                        }
                    ]
                },
                {
                    type: 'TextBlock',
                    text: `**Twoje polecenie:** "${originalText}"`,
                    wrap: true,
                    spacing: 'Medium'
                },
                {
                    type: 'TextBlock',
                    text: 'Może miałeś na myśli:',
                    weight: 'Bolder',
                    spacing: 'Medium'
                },
                ...suggestions.map(suggestion => ({
                    type: 'TextBlock',
                    text: `• \`${suggestion}\``,
                    wrap: true,
                    fontType: 'Monospace'
                }))
            ],
            actions: [
                {
                    type: 'Action.Submit',
                    title: '📚 Show Help',
                    data: {
                        action: 'help'
                    }
                },
                ...suggestions.slice(0, 2).map((suggestion, index) => ({
                    type: 'Action.Submit',
                    title: `Try: ${suggestion.substring(0, 20)}...`,
                    data: {
                        action: 'example',
                        command: suggestion
                    }
                }))
            ]
        };

        return CardFactory.adaptiveCard(card);
    }

    /**
     * Tworzy kartę błędu
     */
    createErrorCard(title, message, details = null) {
        const card = {
            type: 'AdaptiveCard',
            version: this.cardVersion,
            body: [
                {
                    type: 'Container',
                    style: 'attention',
                    items: [
                        {
                            type: 'TextBlock',
                            text: `❌ ${title}`,
                            weight: 'Bolder',
                            size: 'Medium',
                            color: 'Light'
                        }
                    ]
                },
                {
                    type: 'TextBlock',
                    text: message,
                    wrap: true,
                    spacing: 'Medium'
                }
            ]
        };

        if (details) {
            card.body.push({
                type: 'TextBlock',
                text: `**Details:** ${details}`,
                wrap: true,
                isSubtle: true,
                spacing: 'Small'
            });
        }

        card.actions = [
            {
                type: 'Action.Submit',
                title: '📚 Show Help',
                data: {
                    action: 'help'
                }
            }
        ];

        return CardFactory.adaptiveCard(card);
    }
}

module.exports = { CardBuilder };
