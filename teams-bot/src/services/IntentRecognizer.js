/**
 * Intent Recognizer - Rozpoznawanie intencji użytkownika
 * Prosta implementacja bez zewnętrznych serwisów AI
 */

class IntentRecognizer {
    constructor() {
        this.patterns = this.initializePatterns();
    }

    initializePatterns() {
        return {
            deploy: {
                patterns: [
                    /deploy\s+(?:version\s+)?(?:v)?(\d+\.\d+\.\d+|\w+)\s+(?:to|do)\s+(\w+)/i,
                    /wdróż\s+(?:wersję\s+)?(?:v)?(\d+\.\d+\.\d+|\w+)\s+(?:na|do)\s+(\w+)/i,
                    /deployment\s+(?:of\s+)?(?:v)?(\d+\.\d+\.\d+|\w+)\s+(?:to|do)\s+(\w+)/i,
                    /(?:uruchom|start)\s+deploy(?:ment)?\s+(?:v)?(\d+\.\d+\.\d+|\w+)\s+(\w+)/i
                ],
                extract: (match) => ({
                    version: match[1],
                    environment: match[2],
                    service: this.extractService(match.input)
                })
            },

            pipeline_status: {
                patterns: [
                    /(?:status|sprawdź)\s+pipeline\s+(?:#)?(\d+)/i,
                    /pipeline\s+(?:#)?(\d+)\s+status/i,
                    /(?:jak|what)\s+(?:is\s+)?(?:status|stan)\s+pipeline\s+(?:#)?(\d+)/i,
                    /build\s+(?:#)?(\d+)\s+(?:status|stan)/i
                ],
                extract: (match) => ({
                    pipelineId: match[1],
                    project: this.extractProject(match.input)
                })
            },

            create_work_item: {
                patterns: [
                    /(?:utwórz|create|add)\s+(?:zadanie|task|work[\s-]?item)[\s:]+(.+)/i,
                    /(?:nowe|new)\s+(?:zadanie|task)[\s:]+(.+)/i,
                    /(?:dodaj|add)\s+(?:bug|feature|story)[\s:]+(.+)/i,
                    /(?:zgłoś|report)\s+(?:bug|błąd)[\s:]+(.+)/i
                ],
                extract: (match) => {
                    const fullText = match[1];
                    const type = this.extractWorkItemType(match.input);
                    const assignee = this.extractAssignee(fullText);
                    
                    return {
                        title: fullText.replace(/@\w+/g, '').trim(),
                        type: type,
                        assignee: assignee,
                        description: this.extractDescription(fullText)
                    };
                }
            },

            system_command: {
                patterns: [
                    /(?:uruchom|run|execute)\s+(.+)/i,
                    /(?:wykonaj|exec)\s+(?:komendę?\s+)?(.+)/i,
                    /command[\s:]+(.+)/i,
                    /cmd[\s:]+(.+)/i,
                    /powershell[\s:]+(.+)/i
                ],
                extract: (match) => ({
                    command: match[1].trim()
                })
            },

            resource_check: {
                patterns: [
                    /(?:sprawdź|check)\s+(?:zasoby|resources?)(?:\s+(\w+))?/i,
                    /(?:status|stan)\s+(?:zasobów|resources?)(?:\s+(\w+))?/i,
                    /(?:wykorzystanie|usage)\s+(?:zasobów|resources?)(?:\s+(\w+))?/i,
                    /(?:jak|how)\s+(?:wygląda|looks?)\s+(?:infrastruktura|infrastructure)/i
                ],
                extract: (match) => ({
                    resourceType: 'all',
                    resourceGroup: match[1] || this.extractResourceGroup(match.input)
                })
            },

            git_operations: {
                patterns: [
                    /git\s+(status|commit|push|pull|log)(?:\s+(.+))?/i,
                    /(?:sprawdź|check)\s+git\s+(?:status|stan)/i,
                    /(?:commit|zapisz)\s+(?:zmiany|changes?)(?:\s+[\"\'](.+)[\"\'])?/i,
                    /(?:push|wyślij)\s+(?:na|to)\s+(\w+)/i
                ],
                extract: (match) => ({
                    operation: match[1]?.toLowerCase() || 'status',
                    path: this.extractPath(match.input),
                    message: match[2] || this.extractCommitMessage(match.input)
                })
            },

            help: {
                patterns: [
                    /^(?:help|pomoc|\?)$/i,
                    /(?:jak|how)\s+(?:mogę|can\s+i)\s+(?:użyć|use)/i,
                    /(?:co|what)\s+(?:potrafisz|can\s+you\s+do)/i,
                    /(?:komendy|commands?|funkcje|functions?)/i
                ],
                extract: () => ({})
            }
        };
    }

    /**
     * Rozpoznaj intencję w tekście użytkownika
     */
    async recognizeIntent(text) {
        const normalizedText = text.trim();
        
        for (const [intentType, config] of Object.entries(this.patterns)) {
            for (const pattern of config.patterns) {
                const match = normalizedText.match(pattern);
                if (match) {
                    const parameters = config.extract(match);
                    const confidence = this.calculateConfidence(match, pattern, normalizedText);
                    
                    return {
                        type: intentType,
                        parameters: parameters,
                        confidence: confidence,
                        originalText: normalizedText,
                        matchedPattern: pattern.source
                    };
                }
            }
        }

        // Jeśli nie znaleziono dokładnego dopasowania, spróbuj dopasowania częściowego
        const partialMatch = this.tryPartialMatching(normalizedText);
        if (partialMatch) {
            return partialMatch;
        }

        // Zwróć unknown intent
        return {
            type: 'unknown',
            parameters: {},
            confidence: 0.0,
            originalText: normalizedText,
            matchedPattern: null
        };
    }

    /**
     * Oblicz poziom pewności dopasowania
     */
    calculateConfidence(match, pattern, text) {
        let confidence = 0.7; // Base confidence
        
        // Zwiększ confidence jeśli dopasowanie jest dokładne
        if (match[0].length / text.length > 0.7) {
            confidence += 0.2;
        }
        
        // Zwiększ confidence jeśli znaleziono konkretne parametry
        if (match.length > 1 && match[1]) {
            confidence += 0.1;
        }
        
        return Math.min(confidence, 1.0);
    }

    /**
     * Spróbuj dopasowania częściowego dla niepełnych komend
     */
    tryPartialMatching(text) {
        const lowerText = text.toLowerCase();
        
        // Deploy keywords
        if (lowerText.includes('deploy') || lowerText.includes('wdróż')) {
            return {
                type: 'deploy',
                parameters: this.extractPartialDeployParams(text),
                confidence: 0.5,
                originalText: text,
                matchedPattern: 'partial_deploy'
            };
        }
        
        // Pipeline keywords
        if (lowerText.includes('pipeline') || lowerText.includes('build')) {
            return {
                type: 'pipeline_status',
                parameters: this.extractPartialPipelineParams(text),
                confidence: 0.5,
                originalText: text,
                matchedPattern: 'partial_pipeline'
            };
        }
        
        // Work item keywords
        if (lowerText.includes('zadanie') || lowerText.includes('task') || 
            lowerText.includes('bug') || lowerText.includes('feature')) {
            return {
                type: 'create_work_item',
                parameters: { title: text },
                confidence: 0.4,
                originalText: text,
                matchedPattern: 'partial_workitem'
            };
        }
        
        return null;
    }

    /**
     * Wyodrębnij częściowe parametry deploymentu
     */
    extractPartialDeployParams(text) {
        const versionMatch = text.match(/(?:v)?(\d+\.\d+\.\d+)/);
        const envMatch = text.match(/(?:staging|prod|production|dev|development|test)/i);
        
        return {
            version: versionMatch ? versionMatch[1] : null,
            environment: envMatch ? envMatch[0].toLowerCase() : null
        };
    }

    /**
     * Wyodrębnij częściowe parametry pipeline
     */
    extractPartialPipelineParams(text) {
        const idMatch = text.match(/(?:#)?(\d+)/);
        
        return {
            pipelineId: idMatch ? idMatch[1] : null
        };
    }

    /**
     * Wyodrębnij nazwę serwisu
     */
    extractService(text) {
        const serviceMatch = text.match(/(?:service|serwis)[\s:]+(\w+)/i);
        return serviceMatch ? serviceMatch[1] : null;
    }

    /**
     * Wyodrębnij nazwę projektu
     */
    extractProject(text) {
        const projectMatch = text.match(/(?:project|projekt)[\s:]+(\w+)/i);
        return projectMatch ? projectMatch[1] : null;
    }

    /**
     * Wyodrębnij typ work item
     */
    extractWorkItemType(text) {
        const lowerText = text.toLowerCase();
        
        if (lowerText.includes('bug') || lowerText.includes('błąd')) return 'Bug';
        if (lowerText.includes('feature') || lowerText.includes('funkcja')) return 'Feature';
        if (lowerText.includes('story') || lowerText.includes('historia')) return 'User Story';
        if (lowerText.includes('epic')) return 'Epic';
        
        return 'Task'; // default
    }

    /**
     * Wyodrębnij osobę przypisaną
     */
    extractAssignee(text) {
        const assigneeMatch = text.match(/@(\w+)/);
        if (assigneeMatch) {
            return assigneeMatch[1] + '@company.com'; // Dodaj domenę
        }
        
        const assignToMatch = text.match(/(?:assign|przypisz)\s+(?:to|do)\s+(\w+)/i);
        return assignToMatch ? assignToMatch[1] + '@company.com' : null;
    }

    /**
     * Wyodrębnij opis
     */
    extractDescription(text) {
        const descMatch = text.match(/(?:description|opis)[\s:]+(.+)/i);
        return descMatch ? descMatch[1] : null;
    }

    /**
     * Wyodrębnij ścieżkę
     */
    extractPath(text) {
        const pathMatch = text.match(/(?:in|w)\s+([\w\/\\.-]+)/);
        return pathMatch ? pathMatch[1] : null;
    }

    /**
     * Wyodrębnij wiadomość commit
     */
    extractCommitMessage(text) {
        const messageMatch = text.match(/[\"\'](.+)[\"\']/);
        return messageMatch ? messageMatch[1] : null;
    }

    /**
     * Wyodrębnij grupę zasobów
     */
    extractResourceGroup(text) {
        const rgMatch = text.match(/(?:resource[-\s]?group|grupa[-\s]?zasobów)[\s:]+(\w+)/i);
        return rgMatch ? rgMatch[1] : null;
    }

    /**
     * Pobierz sugestie dla nierozpoznanego tekstu
     */
    getSuggestions(text) {
        const suggestions = [];
        const lowerText = text.toLowerCase();
        
        // Sprawdź podobieństwo do znanych wzorców
        if (this.containsKeywords(lowerText, ['deploy', 'wdróż', 'version'])) {
            suggestions.push('deploy v1.2.3 do staging');
            suggestions.push('wdróż wersję v2.0.0 na prod');
        }
        
        if (this.containsKeywords(lowerText, ['pipeline', 'build', 'status'])) {
            suggestions.push('status pipeline 123');
            suggestions.push('sprawdź pipeline 456');
        }
        
        if (this.containsKeywords(lowerText, ['task', 'zadanie', 'bug'])) {
            suggestions.push('utwórz zadanie: Fix login issue');
            suggestions.push('dodaj bug: Button not working');
        }
        
        if (this.containsKeywords(lowerText, ['run', 'uruchom', 'command'])) {
            suggestions.push('uruchom docker ps');
            suggestions.push('wykonaj ls -la');
        }
        
        // Domyślne sugestie
        if (suggestions.length === 0) {
            suggestions.push('help - pokaż dostępne komendy');
            suggestions.push('deploy v1.0.0 do staging');
            suggestions.push('status pipeline 123');
            suggestions.push('utwórz zadanie: Task description');
        }
        
        return suggestions.slice(0, 3); // Maksymalnie 3 sugestie
    }

    /**
     * Sprawdź czy tekst zawiera słowa kluczowe
     */
    containsKeywords(text, keywords) {
        return keywords.some(keyword => text.includes(keyword));
    }

    /**
     * Pobierz wszystkie dostępne typy intencji
     */
    getAvailableIntents() {
        return Object.keys(this.patterns);
    }

    /**
     * Pobierz przykłady dla danego typu intencji
     */
    getExamplesForIntent(intentType) {
        const examples = {
            deploy: [
                'deploy v1.2.3 do staging',
                'wdróż wersję v2.0.0 na prod',
                'deployment of v1.5.0 to test'
            ],
            pipeline_status: [
                'status pipeline 123',
                'sprawdź pipeline 456',
                'pipeline 789 status'
            ],
            create_work_item: [
                'utwórz zadanie: Fix login bug',
                'nowe zadanie: Add user authentication',
                'dodaj bug: Button not responding'
            ],
            system_command: [
                'uruchom docker ps',
                'wykonaj ls -la',
                'run kubectl get pods'
            ],
            resource_check: [
                'sprawdź zasoby',
                'status zasobów Azure',
                'wykorzystanie infrastruktury'
            ],
            git_operations: [
                'git status',
                'commit zmiany "Update README"',
                'sprawdź git status'
            ],
            help: [
                'help',
                'pomoc',
                'co potrafisz?'
            ]
        };

        return examples[intentType] || [];
    }
}

module.exports = { IntentRecognizer };
