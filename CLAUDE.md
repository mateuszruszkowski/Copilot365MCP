# CLAUDE.md - Copilot 365 MCP Workshop

## 📚 O projekcie

To repozytorium zawiera kompletny warsztat integracji **Microsoft Copilot Studio** z **Model Context Protocol (MCP)** dla automatyzacji zadań DevOps. Projekt umożliwia stworzenie asystenta AI, który może wykonywać operacje w Azure DevOps poprzez protokół MCP.

## 🎯 Cel projektu

Nauczyć uczestników jak:
- Zbudować serwer MCP dla Azure DevOps
- Wdrożyć go jako Azure Function
- Zintegrować z Microsoft Copilot Studio
- Stworzyć działającego asystenta AI do zarządzania projektami

## 🏗️ Struktura projektu

```
Copilot365MCP/
├── azure-setup/          # Skrypty konfiguracyjne Azure
├── mcp-servers/          # Implementacje serwerów MCP
│   ├── azure-devops/     # Serwer MCP dla Azure DevOps (Python)
│   ├── azure-function/   # Serwer MCP jako Azure Function
│   ├── desktop-commander/# Lokalny serwer do operacji desktop
│   └── local-devops/     # Lokalny serwer DevOps
├── teams-bot/           # Bot Teams z integracją MCP
├── docs/                # Dokumentacja i instrukcje
└── scripts/             # Skrypty pomocnicze
```

## 🚀 Szybki start

### Dla Windows (uczestnicy warsztatu)

```powershell
# 1. Sklonuj repozytorium
git clone https://github.com/[your-repo]/Copilot365MCP.git
cd Copilot365MCP

# 2. Uruchom warsztat
.\start-workshop.ps1

# 3. Postępuj zgodnie z wyświetlonymi instrukcjami
```

### Dla Ubuntu/Linux (środowisko deweloperskie)

```bash
# 1. Zainstaluj wymagania
./setup-ubuntu.sh

# 2. Skonfiguruj Azure DevOps
./setup-azure-devops.sh

# 3. Uruchom serwery
./start-workshop.sh
```

## 🛠️ Komponenty warsztatu

### 1. **Azure DevOps MCP Server**
- Serwer Python implementujący protokół MCP
- Narzędzia do zarządzania work items, pipelines, repos
- Możliwość lokalnego uruchomienia i debugowania

### 2. **Azure Function MCP**
- Wersja serwera przygotowana do wdrożenia w chmurze
- HTTP endpoint dla Copilot Studio
- Automatyczne skalowanie i zarządzanie

### 3. **Teams Bot** (opcjonalny)
- Integracja MCP z Microsoft Teams
- Możliwość interakcji przez czat

### 4. **Desktop Commander** (przyszłe warsztaty)
- Lokalny serwer do automatyzacji desktop
- Integracja z systemem operacyjnym

## 📋 Wymagania

### Minimalne (dla warsztatu Azure DevOps MCP)
- Windows 10/11 lub Ubuntu 20.04+
- Node.js 18+ 
- Python 3.8+
- Azure CLI
- PowerShell 7+ (Windows) lub Bash (Linux)
- Konto Azure z aktywną subskrypcją
- Organizacja Azure DevOps z projektem
- Dostęp do Microsoft Copilot Studio

### Opcjonalne (dla pełnego warsztatu)
- Docker Desktop
- Visual Studio Code
- Git

## 🔧 Konfiguracja

### Zmienne środowiskowe

Projekt automatycznie generuje plik `.ai-config.env` z konfiguracją:

```env
# Azure DevOps
AZURE_DEVOPS_ORG_URL=https://dev.azure.com/your-org
AZURE_DEVOPS_PAT=your-personal-access-token
AZURE_DEVOPS_PROJECT=your-project-name

# Azure Resources
AZURE_FUNCTION_URL=https://your-function.azurewebsites.net
AZURE_SUBSCRIPTION_ID=your-subscription-id
RESOURCE_GROUP=mcp-workshop-rg
```

### Personal Access Token (PAT)

1. Przejdź do Azure DevOps > User Settings > Personal Access Tokens
2. Utwórz nowy token z uprawnieniami:
   - Work Items (Read, Write, Manage)
   - Build (Read, Execute)
   - Code (Read)
3. Skopiuj token - będzie potrzebny podczas konfiguracji

## 🎓 Scenariusze użycia

### 1. Zarządzanie zadaniami
```
"Pokaż wszystkie aktywne zadania w projekcie"
"Utwórz nowe zadanie typu Bug z opisem..."
"Zaktualizuj status zadania #123 na Done"
```

### 2. Monitorowanie pipeline'ów
```
"Jaki jest status ostatniego builda?"
"Uruchom pipeline deploy-to-staging"
"Pokaż błędy z ostatniego niepowodzenia"
```

### 3. Analiza projektu
```
"Ile zadań jest przypisanych do mnie?"
"Pokaż zadania z wysokim priorytetem"
"Jakie są blokery w obecnym sprincie?"
```

## 🐛 Rozwiązywanie problemów

### Częste problemy

1. **"Azure CLI not logged in"**
   ```powershell
   az login
   az account set --subscription "your-subscription-id"
   ```

2. **"PAT token invalid"**
   - Sprawdź czy token nie wygasł
   - Zweryfikuj uprawnienia tokena
   - Upewnij się że URL organizacji jest poprawny

3. **"Python module not found"**
   ```bash
   cd mcp-servers/azure-devops
   pip install -r requirements.txt
   ```

### Diagnostyka

Uruchom skrypt diagnostyczny:
```powershell
.\test-azure-config.ps1
```

## 📝 Rozwój projektu

### Dodawanie nowych narzędzi MCP

1. Edytuj `mcp-servers/azure-devops/src/tools.py`
2. Dodaj nową metodę z dekoratorem `@tool`
3. Zaktualizuj dokumentację narzędzia
4. Przetestuj lokalnie przed wdrożeniem

### Rozszerzanie warsztatu

- `teams-bot/` - integracja z Teams
- `desktop-commander/` - automatyzacja desktop
- `local-devops/` - lokalne narzędzia DevOps

## 🤝 Wsparcie

- Problemy: Utwórz issue w repozytorium
- Pytania: Skorzystaj z kanału Teams warsztatu
- Dokumentacja: Zobacz folder `docs/`

## 📄 Licencja

MIT License - zobacz plik LICENSE

## 🙏 Podziękowania

- Microsoft za Copilot Studio i Azure
- Anthropic za Model Context Protocol
- Społeczność za feedback i kontrybucje

---
*Ostatnia aktualizacja: 2025-01-25*