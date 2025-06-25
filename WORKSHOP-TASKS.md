# Workshop Tasks - Copilot 365 MCP Azure DevOps

## 📋 Status zadań

Data ostatniej aktualizacji: 2025-01-25

### ✅ Zadania ukończone

- [x] Analiza struktury projektu
- [x] Identyfikacja komponentów do warsztatu Azure DevOps MCP
- [x] Plan uproszczenia konfiguracji

### 🔄 Zadania w trakcie

- [ ] **Dokumentacja CLAUDE.md** - Tworzenie opisów dla każdego modułu
  - [ ] Główny katalog
  - [ ] azure-setup
  - [ ] mcp-servers
  - [ ] teams-bot

### 📝 Zadania do wykonania

#### Wysokiego priorytetu
- [ ] Utworzenie AZURE-DEVOPS-MCP-SETUP.md z instrukcjami instalacyjnymi
- [ ] Dokumentacja wymagań dla Windows i Ubuntu

#### Średniego priorytetu
- [ ] Aktualizacja start-workshop.ps1 dla Azure DevOps MCP
- [ ] Utworzenie setup-azure-devops.ps1 do konfiguracji środowiska
- [ ] Przygotowanie .env.example dla Azure DevOps
- [ ] Skrypt instalacyjny setup-ubuntu.sh

#### Niskiego priorytetu
- [ ] Aktualizacja głównego README.md
- [ ] Zmiana nazw plików z "-fixed" na finalne wersje
- [ ] Optymalizacja struktury katalogów

## 🎯 Cel warsztatu

Warsztat skupia się na integracji **Azure DevOps** z **Microsoft Copilot Studio** poprzez **Model Context Protocol (MCP)**. Uczestnicy nauczą się:

1. Konfigurować serwer MCP dla Azure DevOps
2. Wdrażać go jako Azure Function
3. Integrować z Copilot Studio
4. Tworzyć asystenta AI do zarządzania zadaniami DevOps

## 🔧 Komponenty warsztatu

### 1. Azure DevOps MCP Server
- Lokalizacja: `/mcp-servers/azure-devops/`
- Narzędzia:
  - `list_work_items` - listowanie zadań
  - `get_work_item` - pobieranie szczegółów zadania
  - `create_work_item` - tworzenie nowych zadań
  - `update_work_item` - aktualizacja zadań
  - `check_pipeline_status` - status pipeline
  - `trigger_pipeline` - uruchomienie pipeline

### 2. Azure Setup
- Skrypty PowerShell do konfiguracji:
  - Resource Group
  - Storage Account
  - Azure Function App
  - Konfiguracja zmiennych środowiskowych

### 3. Integracja z Copilot Studio
- Custom Connector (OpenAPI)
- Konfiguracja agenta
- Testowanie połączenia

## 📊 Postęp implementacji

### Faza 1: Dokumentacja (W TRAKCIE)
- [ ] CLAUDE.md dla każdego modułu - 0%
- [ ] Instrukcje instalacyjne - 0%
- [ ] Wymagania systemowe - 0%

### Faza 2: Skrypty konfiguracyjne
- [ ] setup-azure-devops.ps1 - 0%
- [ ] setup-ubuntu.sh - 0%
- [ ] Aktualizacja start-workshop.ps1 - 0%

### Faza 3: Przykłady i testy
- [ ] .env.example - 0%
- [ ] Skrypty testowe - 0%
- [ ] Przykładowe zapytania do Copilot - 0%

## 🚀 Następne kroki

1. Dokończyć dokumentację CLAUDE.md
2. Stworzyć kompletne instrukcje instalacyjne
3. Przygotować skrypty automatyzujące konfigurację
4. Przetestować całość na Windows i Ubuntu

## 📝 Notatki

- Warsztat wymaga Node.js 18+ i Python 3.8+
- Azure CLI musi być zainstalowany i skonfigurowany
- Wymagany jest Personal Access Token (PAT) z Azure DevOps
- Copilot Studio wymaga subskrypcji Microsoft 365

---
*Ten plik jest aktualizowany podczas prac nad warsztatem*