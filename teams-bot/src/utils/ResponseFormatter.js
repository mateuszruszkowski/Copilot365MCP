/**
 * Response Formatter - Formatowanie odpowiedzi z serwerów MCP
 */

class ResponseFormatter {
    constructor() {
        this.maxTextLength = 4000; // Limit dla Teams messages
    }

    /**
     * Formatuj odpowiedź z serwera MCP do wyświetlenia w Teams
     */
    formatMCPResponse(mcpResult, context = {}) {
        if (!mcpResult || !mcpResult.content) {
            return 'Brak odpowiedzi z serwera MCP';
        }

        const content = mcpResult.content[0];
        if (!content || content.type !== 'text') {
            return 'Nieobsługiwany format odpowiedzi';
        }

        let text = content.text;
        
        // Skróć tekst jeśli jest za długi
        if (text.length > this.maxTextLength) {
            text = text.substring(0, this.maxTextLength - 3) + '...';
        }

        // Formatuj dla Teams (Markdown)
        text = this.convertToTeamsMarkdown(text);
        
        return text;
    }

    /**
     * Konwertuj tekst do formatu Markdown obsługiwanego przez Teams
     */
    convertToTeamsMarkdown(text) {
        // Teams obsługuje ograniczony podzbiór Markdown
        
        // Konwertuj emoji shortcuts
        text = text.replace(/:\)/g, '😊');
        text = text.replace(/:\(/g, '😞');
        text = text.replace(/:check:/g, '✅');
        text = text.replace(/:x:/g, '❌');
        text = text.replace(/:warning:/g, '⚠️');
        text = text.replace(/:rocket:/g, '🚀');
        
        // Zachowaj podstawowy Markdown (bold, italic, code)
        // Teams automatycznie renderuje **bold**, *italic*, `code`
        
        return text;
    }

    /**
     * Formatuj dane deploymentu
     */
    formatDeploymentData(deploymentResult) {
        const content = deploymentResult.content?.[0]?.text || '';
        
        // Wyciągnij kluczowe informacje z tekstu MCP
        const deploymentId = this.extractValue(content, /ID[:\s]+([^\s\n]+)/i);
        const status = this.extractValue(content, /Status[:\s]+([^\s\n]+)/i);
        const environment = this.extractValue(content, /Environment[:\s]+([^\s\n]+)/i);
        const version = this.extractValue(content, /Version[:\s]+([^\s\n]+)/i);
        
        return {
            id: deploymentId,
            status: status || 'Starting',
            environment: environment,
            version: version,
            rawContent: content
        };
    }

    /**
     * Formatuj dane pipeline
     */
    formatPipelineData(pipelineResult) {
        const content = pipelineResult.content?.[0]?.text || '';
        
        const pipelineId = this.extractValue(content, /Pipeline[:\s]+([^\s\n]+)/i);
        const status = this.extractValue(content, /Status[:\s]+([^\s\n,]+)/i);
        const lastRun = this.extractValue(content, /run[:\s]+([^\n]+)/i);
        
        return {
            id: pipelineId,
            status: status || 'Unknown',
            lastRun: lastRun,
            rawContent: content
        };
    }

    /**
     * Formatuj dane work item
     */
    formatWorkItemData(workItemResult) {
        const content = workItemResult.content?.[0]?.text || '';
        
        const workItemId = this.extractValue(content, /#(\d+)/);
        const title = this.extractValue(content, /Tytuł[:\s]+([^\n]+)/i);
        const type = this.extractValue(content, /Typ[:\s]+([^\s\n]+)/i);
        const assignee = this.extractValue(content, /Przypisane[:\s]+([^\n]+)/i);
        
        return {
            id: workItemId,
            title: title,
            type: type,
            assignee: assignee,
            rawContent: content
        };
    }

    /**
     * Formatuj dane zasobów
     */
    formatResourceData(resourceResult) {
        const content = resourceResult.content?.[0]?.text || '';
        
        // Wyciągnij metryki z tekstu
        const cpuUsage = this.extractValue(content, /CPU[:\s]+(\d+%)/i);
        const memoryUsage = this.extractValue(content, /Memory[:\s]+(\d+%)/i);
        const storageUsage = this.extractValue(content, /Storage[:\s]+(\d+%)/i);
        
        return {
            cpu: cpuUsage,
            memory: memoryUsage,
            storage: storageUsage,
            rawContent: content
        };
    }

    /**
     * Wyciągnij wartość z tekstu używając regex
     */
    extractValue(text, pattern) {
        const match = text.match(pattern);
        return match ? match[1].trim() : null;
    }

    /**
     * Utwórz podsumowanie dla złożonych operacji
     */
    createSummary(title, items, maxItems = 5) {
        let summary = `**${title}**\n\n`;
        
        const displayItems = items.slice(0, maxItems);
        
        for (const item of displayItems) {
            summary += `• ${item}\n`;
        }
        
        if (items.length > maxItems) {
            summary += `\n... i ${items.length - maxItems} więcej`;
        }
        
        return summary;
    }

    /**
     * Formatuj błędy w sposób przyjazny dla użytkownika
     */
    formatError(error, context = {}) {
        let message = '❌ Wystąpił błąd podczas wykonywania operacji.';
        
        // Spersonalizuj wiadomość błędu na podstawie kontekstu
        if (context.operation) {
            message = `❌ Błąd podczas wykonywania: ${context.operation}`;
        }
        
        // Dodaj szczegóły błędu jeśli są dostępne i bezpieczne
        if (error.message && !this.isSensitiveError(error.message)) {
            message += `\n\n**Szczegóły:** ${error.message}`;
        }
        
        // Dodaj sugestie naprawy
        const suggestions = this.getErrorSuggestions(error, context);
        if (suggestions.length > 0) {
            message += '\n\n**Sugestie:**\n';
            suggestions.forEach(suggestion => {
                message += `• ${suggestion}\n`;
            });
        }
        
        return message;
    }

    /**
     * Sprawdź czy błąd zawiera wrażliwe informacje
     */
    isSensitiveError(errorMessage) {
        const sensitivePatterns = [
            /password/i,
            /token/i,
            /key/i,
            /secret/i,
            /credential/i
        ];
        
        return sensitivePatterns.some(pattern => pattern.test(errorMessage));
    }

    /**
     * Pobierz sugestie naprawy błędu
     */
    getErrorSuggestions(error, context) {
        const suggestions = [];
        
        if (error.message?.includes('timeout')) {
            suggestions.push('Spróbuj ponownie za chwilę');
            suggestions.push('Sprawdź połączenie sieciowe');
        }
        
        if (error.message?.includes('unauthorized') || error.message?.includes('403')) {
            suggestions.push('Sprawdź uprawnienia dostępu');
            suggestions.push('Skontaktuj się z administratorem');
        }
        
        if (error.message?.includes('not found') || error.message?.includes('404')) {
            suggestions.push('Sprawdź czy zasób istnieje');
            suggestions.push('Zweryfikuj nazwę/ID zasobu');
        }
        
        if (context.operation === 'deploy') {
            suggestions.push('Sprawdź czy wersja jest poprawna');
            suggestions.push('Upewnij się że środowisko jest dostępne');
        }
        
        if (context.operation === 'pipeline') {
            suggestions.push('Sprawdź czy pipeline ID jest poprawny');
            suggestions.push('Zweryfikuj status pipeline w Azure DevOps');
        }
        
        return suggestions;
    }

    /**
     * Formatuj dane do wyświetlenia w tabeli
     */
    formatAsTable(data, headers) {
        if (!data || data.length === 0) {
            return 'Brak danych do wyświetlenia';
        }

        let table = '| ' + headers.join(' | ') + ' |\n';
        table += '| ' + headers.map(() => '---').join(' | ') + ' |\n';
        
        for (const row of data.slice(0, 10)) { // Maksymalnie 10 wierszy
            table += '| ' + headers.map(header => row[header] || '-').join(' | ') + ' |\n';
        }
        
        if (data.length > 10) {
            table += `\n*...i ${data.length - 10} więcej wierszy*`;
        }
        
        return table;
    }

    /**
     * Formatuj czas wykonania
     */
    formatDuration(milliseconds) {
        const seconds = Math.floor(milliseconds / 1000);
        const minutes = Math.floor(seconds / 60);
        const hours = Math.floor(minutes / 60);
        
        if (hours > 0) {
            return `${hours}h ${minutes % 60}m ${seconds % 60}s`;
        } else if (minutes > 0) {
            return `${minutes}m ${seconds % 60}s`;
        } else {
            return `${seconds}s`;
        }
    }

    /**
     * Formatuj rozmiar danych
     */
    formatBytes(bytes) {
        if (bytes === 0) return '0 B';
        
        const k = 1024;
        const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    }

    /**
     * Formatuj procenty z kolorem (emoji)
     */
    formatPercentage(value, thresholds = { good: 70, warning: 85 }) {
        const numValue = parseFloat(value);
        let emoji = '📊';
        
        if (numValue >= thresholds.warning) {
            emoji = '🔴'; // Wysoki
        } else if (numValue >= thresholds.good) {
            emoji = '🟡'; // Średni
        } else {
            emoji = '🟢'; // Niski
        }
        
        return `${emoji} ${value}%`;
    }
}

module.exports = { ResponseFormatter };
