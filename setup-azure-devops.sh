#!/bin/bash
# Setup Azure DevOps configuration for Linux

# Kolory
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║           Azure DevOps MCP Server - Konfiguracja              ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Zbierz dane
echo -e "${GREEN}📋 Potrzebuję kilku informacji do konfiguracji Azure DevOps:${NC}"

# URL organizacji
echo -e "\n${YELLOW}1️⃣  URL Twojej organizacji Azure DevOps${NC}"
echo "   Przykład: https://dev.azure.com/mycompany"
read -p "   Podaj URL: " ORG_URL

# Nazwa projektu
echo -e "\n${YELLOW}2️⃣  Nazwa projektu w Azure DevOps${NC}"
read -p "   Podaj nazwę projektu: " PROJECT

# PAT token
echo -e "\n${YELLOW}3️⃣  Personal Access Token (PAT)${NC}"
echo "   Jak uzyskać: $ORG_URL/_usersSettings/tokens"
read -s -p "   Wklej PAT token: " PAT
echo

# Tworzenie .env
ENV_PATH="mcp-servers/azure-devops/.env"
mkdir -p $(dirname $ENV_PATH)

cat > $ENV_PATH << EOL
AZURE_DEVOPS_ORG_URL=$ORG_URL
AZURE_DEVOPS_PAT=$PAT
AZURE_DEVOPS_PROJECT=$PROJECT
EOL

# Aktualizacja .ai-config.env
AI_CONFIG=".ai-config.env"
if [ -f "$AI_CONFIG" ]; then
    grep -v "AZURE_DEVOPS_" $AI_CONFIG > ${AI_CONFIG}.tmp || true
    mv ${AI_CONFIG}.tmp $AI_CONFIG
fi

cat >> $AI_CONFIG << EOL

# Azure DevOps Configuration
AZURE_DEVOPS_ORG_URL=$ORG_URL
AZURE_DEVOPS_PAT=$PAT
AZURE_DEVOPS_PROJECT=$PROJECT
EOL

echo -e "\n${GREEN}✅ Konfiguracja zapisana!${NC}"
echo -e "\n${CYAN}🚀 Następne kroki:${NC}"
echo "   1. Uruchom warsztat: ./start-workshop.sh"
echo "   2. Lub testuj lokalnie: cd mcp-servers/azure-devops && python src/server.py"
