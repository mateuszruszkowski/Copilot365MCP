#!/usr/bin/env node
/**
 * Desktop Commander MCP Server Starter
 * Uruchamia serwer MCP dla Windows system management
 */

const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

const projectRoot = __dirname;
const srcFile = path.join(projectRoot, 'src', 'index.ts');
const distFile = path.join(projectRoot, 'dist', 'index.js');

console.log('🚀 Desktop Commander MCP Server');
console.log('================================');

// Sprawdź czy dist istnieje
if (fs.existsSync(distFile)) {
    console.log('✅ Using compiled version');
    
    // Uruchom skompilowaną wersję
    const child = spawn('node', [distFile], {
        stdio: 'inherit',
        shell: true
    });

    child.on('error', (error) => {
        console.error('❌ Error starting server:', error);
        process.exit(1);
    });

    child.on('close', (code) => {
        console.log(`📤 Server exited with code ${code}`);
        process.exit(code);
    });

} else if (fs.existsSync(srcFile)) {
    console.log('⚠️  Using development version (ts-node)');
    console.log('💡 Run "npm run build" to create production version');
    
    // Uruchom przez ts-node
    const child = spawn('npx', ['ts-node', srcFile], {
        stdio: 'inherit',
        shell: true
    });

    child.on('error', (error) => {
        console.error('❌ Error starting server:', error);
        console.error('💡 Make sure ts-node is installed: npm install -g ts-node');
        process.exit(1);
    });

    child.on('close', (code) => {
        console.log(`📤 Server exited with code ${code}`);
        process.exit(code);
    });

} else {
    console.error('❌ Neither compiled nor source files found!');
    console.error('📁 Expected files:');
    console.error(`   • ${distFile} (compiled)`);
    console.error(`   • ${srcFile} (source)`);
    process.exit(1);
}

// Graceful shutdown
process.on('SIGINT', () => {
    console.log('\n🛑 Shutting down Desktop Commander...');
    process.exit(0);
});
