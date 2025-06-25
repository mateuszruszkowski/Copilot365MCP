#!/bin/bash
# setup-ubuntu.sh - Skrypt instalacyjny dla Ubuntu/Linux
# Instaluje wszystkie wymagania dla warsztatu Copilot 365 MCP

set -e  # Zakończ przy błędzie

# Kolory dla lepszej czytelności
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Banner
echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║        Copilot 365 MCP Workshop - Ubuntu Setup                ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Funkcja do sprawdzania czy komenda istnieje
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Funkcja do wyświetlania statusu
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Sprawdzenie czy uruchomiono jako root
if [[ $EUID -eq 0 ]]; then
   print_error "Ten skrypt nie powinien być uruchamiany jako root!"
   exit 1
fi

# Aktualizacja systemu
print_status "Aktualizuję system..."
sudo apt update && sudo apt upgrade -y
print_success "System zaktualizowany"

# Instalacja podstawowych narzędzi
print_status "Instaluję podstawowe narzędzia..."
sudo apt install -y curl wget git build-essential software-properties-common apt-transport-https ca-certificates gnupg lsb-release
print_success "Podstawowe narzędzia zainstalowane"

# Node.js 18.x
print_status "Instaluję Node.js 18.x..."
if ! command_exists node || [[ $(node -v | cut -d'.' -f1 | sed 's/v//') -lt 18 ]]; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
    print_success "Node.js zainstalowany: $(node -v)"
else
    print_warning "Node.js już zainstalowany: $(node -v)"
fi

# Python 3 i pip
print_status "Instaluję Python 3 i pip..."
if ! command_exists python3; then
    sudo apt install -y python3 python3-pip python3-venv
    print_success "Python zainstalowany: $(python3 --version)"
else
    print_warning "Python już zainstalowany: $(python3 --version)"
fi

# Azure CLI
print_status "Instaluję Azure CLI..."
if ! command_exists az; then
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    print_success "Azure CLI zainstalowany: $(az --version | head -n1)"
else
    print_warning "Azure CLI już zainstalowany: $(az --version | head -n1)"
fi

# Azure Functions Core Tools
print_status "Instaluję Azure Functions Core Tools..."
if ! command_exists func; then
    # Dodaj klucz Microsoft GPG
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
    sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
    
    # Dodaj repozytorium
    sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-$(lsb_release -cs)-prod $(lsb_release -cs) main" > /etc/apt/sources.list.d/dotnetdev.list'
    
    # Instalacja
    sudo apt update
    sudo apt install -y azure-functions-core-tools-4
    print_success "Azure Functions Core Tools zainstalowany: $(func --version)"
else
    print_warning "Azure Functions Core Tools już zainstalowany: $(func --version)"
fi

# PowerShell Core (opcjonalne, ale przydatne)
print_status "Instaluję PowerShell Core (opcjonalne)..."
if ! command_exists pwsh; then
    # Dodaj repozytorium Microsoft
    wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb
    sudo dpkg -i packages-microsoft-prod.deb
    rm packages-microsoft-prod.deb
    
    # Instalacja
    sudo apt update
    sudo apt install -y powershell
    print_success "PowerShell Core zainstalowany: $(pwsh --version)"
else
    print_warning "PowerShell Core już zainstalowany"
fi

# Docker (opcjonalne)
read -p "Czy chcesz zainstalować Docker? (zalecane dla przyszłych warsztatów) [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Instaluję Docker..."
    if ! command_exists docker; then
        # Usuń stare wersje
        sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
        
        # Dodaj klucz GPG Docker
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        
        # Dodaj repozytorium
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        # Instalacja
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        
        # Dodaj użytkownika do grupy docker
        sudo usermod -aG docker $USER
        print_success "Docker zainstalowany"
        print_warning "Wyloguj się i zaloguj ponownie aby używać Docker bez sudo"
    else
        print_warning "Docker już zainstalowany"
    fi
fi

# Sprawdzenie czy jesteśmy w katalogu projektu
if [ ! -f "CLAUDE.md" ] || [ ! -d "mcp-servers" ]; then
    print_error "Ten skrypt musi być uruchomiony z głównego katalogu projektu Copilot365MCP!"
    print_status "Upewnij się, że jesteś w katalogu z plikiem CLAUDE.md"
    exit 1
fi

print_success "Instaluję w katalogu: $(pwd)"

# Instalacja zależności Python dla Azure DevOps MCP
print_status "Konfiguruję środowisko Python dla Azure DevOps MCP..."
cd "$(pwd)/mcp-servers/azure-devops"

# Tworzenie wirtualnego środowiska
python3 -m venv venv
source venv/bin/activate

# Instalacja requirements
if [ -f "requirements.txt" ]; then
    pip install --upgrade pip
    pip install -r requirements.txt
    print_success "Zależności Python zainstalowane"
else
    print_warning "Brak pliku requirements.txt"
fi

deactivate
cd "$(dirname "$(dirname "$(pwd)")")"

# Instalacja zależności Node.js dla Azure Function
print_status "Instaluję zależności Node.js dla Azure Function..."
cd "$(pwd)/mcp-servers/azure-function"
if [ -f "package.json" ]; then
    npm install
    print_success "Zależności Node.js zainstalowane"
else
    print_warning "Brak pliku package.json"
fi
cd "$(dirname "$(dirname "$(pwd)")")"

# Tworzenie skryptu uruchomieniowego dla Linux
print_status "Tworzę skrypt uruchomieniowy dla Linux..."
cat > start-workshop.sh << 'EOF'
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
EOF

chmod +x start-workshop.sh
print_success "Skrypt start-workshop.sh utworzony"

# Tworzenie skryptu setup-azure-devops.sh dla Linux
print_status "Tworzę skrypt konfiguracyjny Azure DevOps dla Linux..."
cat > setup-azure-devops.sh << 'EOF'
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
EOF

chmod +x setup-azure-devops.sh
print_success "Skrypt setup-azure-devops.sh utworzony"

# Podsumowanie
echo
echo -e "${GREEN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║              ✅ Instalacja zakończona!                        ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${CYAN}📋 Zainstalowane komponenty:${NC}"
echo "   ✓ Node.js $(node -v)"
echo "   ✓ Python $(python3 --version)"
echo "   ✓ Azure CLI $(az --version | head -n1)"
echo "   ✓ Azure Functions Core Tools $(func --version)"
if command_exists pwsh; then
    echo "   ✓ PowerShell Core $(pwsh --version | head -n1)"
fi
if command_exists docker; then
    echo "   ✓ Docker $(docker --version)"
fi

echo -e "\n${YELLOW}🚀 Następne kroki:${NC}"
echo "   1. Skonfiguruj Azure DevOps:"
echo "      ${GREEN}./setup-azure-devops.sh${NC}"
echo
echo "   2. Zaloguj się do Azure:"
echo "      ${GREEN}az login${NC}"
echo
echo "   3. Uruchom warsztat:"
echo "      ${GREEN}./start-workshop.sh${NC}"

echo -e "\n${BLUE}💡 Wskazówka:${NC}"
echo "   Dokumentacja znajduje się w pliku AZURE-DEVOPS-MCP-SETUP.md"

# Sprawdź czy trzeba się przelogować (dla Docker)
if groups $USER | grep -q docker; then
    :
else
    if command_exists docker; then
        echo -e "\n${YELLOW}⚠️  Uwaga:${NC}"
        echo "   Aby używać Docker bez sudo, wyloguj się i zaloguj ponownie."
    fi
fi