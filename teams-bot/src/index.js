/**
 * Teams MCP Bot - Main Entry Point
 * Bot z integracją Model Context Protocol dla Microsoft Teams
 * Warsztat: Copilot 365 MCP Integration
 */

require('dotenv').config();
const restify = require('restify');
const { CloudAdapter, ConfigurationBotFrameworkAuthentication } = require('botbuilder');
const { TeamsBot } = require('./bot/TeamsBot');
const { MCPClient } = require('./services/MCPClient');
const appInsights = require('applicationinsights');

// Initialize Application Insights
if (process.env.APPINSIGHTS_INSTRUMENTATIONKEY) {
    appInsights.setup(process.env.APPINSIGHTS_INSTRUMENTATIONKEY);
    appInsights.start();
    console.log('✅ Application Insights initialized');
}

// Konfiguracja serwera
const server = restify.createServer({
    name: 'Teams MCP Bot',
    version: '1.0.0'
});

server.use(restify.plugins.bodyParser());
server.use(restify.plugins.queryParser());

// CORS support
server.pre(restify.plugins.pre.cors());
server.use(restify.plugins.cors({
    origins: ['*'],
    allowHeaders: ['authorization', 'content-type'],
    exposeHeaders: ['authorization', 'content-type']
}));

// Konfiguracja Bot Framework
const botFrameworkAuthentication = new ConfigurationBotFrameworkAuthentication({
    MicrosoftAppId: process.env.MICROSOFT_APP_ID,
    MicrosoftAppPassword: process.env.MICROSOFT_APP_PASSWORD,
    MicrosoftAppType: process.env.MICROSOFT_APP_TYPE || 'MultiTenant',
    MicrosoftAppTenantId: process.env.MICROSOFT_APP_TENANT_ID
});

// Inicjalizacja adaptera
const adapter = new CloudAdapter(botFrameworkAuthentication);

// Error handler
adapter.onTurnError = async (context, error) => {
    console.error('❌ Bot Error:', error);
    
    // Track error in Application Insights
    if (appInsights.defaultClient) {
        appInsights.defaultClient.trackException({ exception: error });
    }
    
    // Send error message to user
    await context.sendActivity('😔 Przepraszam, wystąpił błąd. Spróbuj ponownie za chwilę.');
};

// Inicjalizacja MCP Client
const mcpClient = new MCPClient({
    azureFunctionEndpoint: process.env.MCP_AZURE_FUNCTION_ENDPOINT,
    localDevOpsEndpoint: process.env.MCP_LOCAL_DEVOPS_ENDPOINT,
    desktopCommanderEndpoint: process.env.MCP_DESKTOP_COMMANDER_ENDPOINT,
    azureDevOpsEndpoint: process.env.MCP_AZURE_DEVOPS_ENDPOINT
});

// Inicjalizacja bota
const bot = new TeamsBot(mcpClient);

// Health check endpoint
server.get('/health', (req, res, next) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        version: '1.0.0',
        name: 'Teams MCP Bot'
    });
    return next();
});

// Bot endpoint
server.post('/api/messages', async (req, res, next) => {
    try {
        await adapter.process(req, res, async (context) => {
            await bot.run(context);
        });
    } catch (error) {
        console.error('❌ Message processing error:', error);
        if (appInsights.defaultClient) {
            appInsights.defaultClient.trackException({ exception: error });
        }
    }
    return next();
});

// MCP Test endpoint (for debugging)
server.get('/api/mcp/test', async (req, res, next) => {
    try {
        const testResults = await mcpClient.testConnections();
        res.json({
            status: 'success',
            results: testResults,
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        console.error('❌ MCP Test Error:', error);
        res.json({
            status: 'error',
            error: error.message,
            timestamp: new Date().toISOString()
        });
    }
    return next();
});

// Configuration endpoint
server.get('/api/config', (req, res, next) => {
    res.json({
        botId: process.env.MICROSOFT_APP_ID || 'Not configured',
        mcpEndpoints: {
            azureFunction: process.env.MCP_AZURE_FUNCTION_ENDPOINT ? '✅ Configured' : '❌ Not configured',
            localDevOps: process.env.MCP_LOCAL_DEVOPS_ENDPOINT ? '✅ Configured' : '❌ Not configured',
            desktopCommander: process.env.MCP_DESKTOP_COMMANDER_ENDPOINT ? '✅ Configured' : '❌ Not configured',
            azureDevOps: process.env.MCP_AZURE_DEVOPS_ENDPOINT ? '✅ Configured' : '❌ Not configured'
        },
        applicationInsights: process.env.APPINSIGHTS_INSTRUMENTATIONKEY ? '✅ Enabled' : '❌ Disabled',
        timestamp: new Date().toISOString()
    });
    return next();
});

// Start server
const port = process.env.PORT || 3978;
server.listen(port, () => {
    console.log('🚀 Teams MCP Bot Started');
    console.log('==========================');
    console.log(`📡 Server listening on port ${port}`);
    console.log(`🤖 Bot ID: ${process.env.MICROSOFT_APP_ID || 'Not configured'}`);
    console.log(`🔗 Health Check: http://localhost:${port}/health`);
    console.log(`⚙️  Config: http://localhost:${port}/api/config`);
    console.log(`🧪 MCP Test: http://localhost:${port}/api/mcp/test`);
    console.log('');
    
    // Log MCP endpoints
    console.log('🔌 MCP Endpoints:');
    console.log(`   • Azure Function: ${process.env.MCP_AZURE_FUNCTION_ENDPOINT || '❌ Not configured'}`);
    console.log(`   • Local DevOps: ${process.env.MCP_LOCAL_DEVOPS_ENDPOINT || '❌ Not configured'}`);
    console.log(`   • Desktop Commander: ${process.env.MCP_DESKTOP_COMMANDER_ENDPOINT || '❌ Not configured'}`);
    console.log(`   • Azure DevOps: ${process.env.MCP_AZURE_DEVOPS_ENDPOINT || '❌ Not configured'}`);
    console.log('');
    console.log('✨ Ready to receive messages!');
});

// Graceful shutdown
process.on('SIGINT', () => {
    console.log('\n🛑 Shutting down Teams MCP Bot...');
    server.close(() => {
        console.log('✅ Server closed');
        process.exit(0);
    });
});

process.on('SIGTERM', () => {
    console.log('\n🛑 Teams MCP Bot terminated');
    server.close(() => {
        console.log('✅ Server closed');
        process.exit(0);
    });
});
