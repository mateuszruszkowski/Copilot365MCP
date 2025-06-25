#!/bin/bash
# Start workshop script for Linux

# Kolory
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║         Copilot 365 MCP Workshop - Starting...                ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Sprawdź konfigurację Azure DevOps
if [ ! -f "mcp-servers/azure-devops/.env" ]; then
    echo -e "${YELLOW}Najpierw skonfiguruj Azure DevOps:${NC}"
    echo "bash setup-azure-devops.sh"
    exit 1
fi

# Uruchom serwer Azure DevOps MCP
echo -e "${GREEN}Uruchamiam Azure DevOps MCP Server...${NC}"
cd mcp-servers/azure-devops
source venv/bin/activate
python src/server.py &
MCP_PID=$!
cd ../..

echo -e "${GREEN}✓ Serwer MCP uruchomiony (PID: $MCP_PID)${NC}"
echo
echo -e "${CYAN}Następne kroki:${NC}"
echo "1. Wdróż na Azure Functions: cd mcp-servers/azure-function && func azure functionapp publish <your-app-name>"
echo "2. Skonfiguruj Copilot Studio według instrukcji w AZURE-DEVOPS-MCP-SETUP.md"
echo
echo -e "${YELLOW}Aby zatrzymać serwer, naciśnij Ctrl+C${NC}"

# Czekaj na sygnał zatrzymania
trap "kill $MCP_PID 2>/dev/null; exit" INT TERM
wait $MCP_PID
