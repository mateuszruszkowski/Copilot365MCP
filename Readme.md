# 🚀 Copilot 365 MCP Workshop

## 📚 O warsztacie

Warsztat pokazujący integrację **Microsoft Copilot Studio** z **Model Context Protocol (MCP)** dla automatyzacji zadań DevOps. Uczestnicy nauczą się budować asystenta AI, który może wykonywać operacje w Azure DevOps poprzez protokół MCP.

### 🎯 Czego się nauczysz

- ✅ Konfiguracja serwera MCP dla Azure DevOps
- ✅ Wdrażanie serwera jako Azure Function
- ✅ Integracja z Microsoft Copilot Studio
- ✅ Tworzenie własnych narzędzi MCP
- ✅ Automatyzacja zadań DevOps przez AI

---

## 🚀 Szybki start

### 1️⃣ Instalacja i konfiguracja

#### Windows
```powershell
# Sklonuj repozytorium
git clone https://github.com/[your-repo]/Copilot365MCP.git
cd Copilot365MCP

# Skonfiguruj Azure DevOps
.\setup-azure-devops.ps1

# Uruchom warsztat
.\start-workshop.ps1
```

#### Ubuntu/Linux
```bash
# Zainstaluj wymagania
./setup-ubuntu.sh

# Skonfiguruj Azure DevOps
./setup-azure-devops.sh

# Uruchom warsztat
./start-workshop.sh
```

### 2️⃣ Wymagania

- **Windows 10/11** lub **Ubuntu 20.04+**
- **Node.js 18+** i **Python 3.8+**
- **Azure CLI** zainstalowany i skonfigurowany
- Konto **Azure** z aktywną subskrypcją
- Organizacja **Azure DevOps** z projektem
- Dostęp do **Microsoft Copilot Studio**

📖 Szczegółowa instrukcja: [AZURE-DEVOPS-MCP-SETUP.md](./AZURE-DEVOPS-MCP-SETUP.md)

---

## 🤖 Integracja z Copilot Studio

### Wymagania
- Konto Microsoft 365 z dostępem do Copilot Studio
- Serwer MCP wdrożony na Azure Functions
- Personal Access Token z Azure DevOps

### Kroki integracji
1. **Wdróż serwer MCP** na Azure Functions
2. **Utwórz Custom Connector** w Copilot Studio
3. **Skonfiguruj agenta** z narzędziami MCP
4. **Testuj** w oknie czatu

📖 Pełna instrukcja: [COPILOT-STUDIO-INSTRUKCJA.md](./COPILOT-STUDIO-INSTRUKCJA.md)

---

## 🛠️ Dostępne narzędzia MCP

### Azure DevOps Tools

| Narzędzie | Opis | Parametry |
|-----------|------|------------|
| `list_work_items` | Lista zadań z projektu | project, wiql (opcjonalny) |
| `get_work_item` | Szczegóły zadania | id |
| `create_work_item` | Tworzenie zadania | project, type, title, description |
| `update_work_item` | Aktualizacja zadania | id, fields |
| `check_pipeline_status` | Status pipeline | pipelineId, project |
| `trigger_pipeline` | Uruchomienie pipeline | pipelineId, branch, parameters |

---

## 📁 Struktura projektu

```
Copilot365MCP/
├── 📄 README.md                    # Ten plik
├── 📄 CLAUDE.md                    # Dokumentacja projektu
├── 📄 AZURE-DEVOPS-MCP-SETUP.md   # Instrukcja instalacji
├── 📄 WORKSHOP-TASKS.md            # Zadania i postępy
├── 📄 setup-azure-devops.ps1       # Konfiguracja Azure DevOps
├── 📄 setup-ubuntu.sh              # Instalator dla Linux
├── 📄 start-workshop.ps1           # Uruchamianie warsztatu
├── 🗂️ azure-setup/                # Skrypty konfiguracji Azure
├── 🗂️ mcp-servers/                # Implementacje serwerów MCP
│   ├── 🗂️ azure-devops/           # Serwer Python dla Azure DevOps
│   ├── 🗂️ azure-function/         # Serwer dla Azure Functions
│   ├── 🗂️ desktop-commander/      # Kontrola aplikacji desktop
│   └── 🗂️ local-devops/           # Lokalne narzędzia DevOps
├── 🗂️ teams-bot/                  # Bot Teams z integracją MCP
└── 🗂️ docs/                       # Dodatkowa dokumentacja
```

---

## 💡 Przykłady użycia

### Zarządzanie zadaniami
```
User: "Pokaż wszystkie aktywne zadania w projekcie MyProject"
Copilot: [Wywołuje list_work_items z project="MyProject"]

User: "Utwórz nowe zadanie typu Bug o problemach z logowaniem"
Copilot: [Wywołuje create_work_item z type="Bug", title="Login issues"]
```

### Pipeline automation
```
User: "Sprawdź status ostatniego builda"
Copilot: [Wywołuje check_pipeline_status]

User: "Uruchom pipeline deploy-to-staging"
Copilot: [Wywołuje trigger_pipeline z branch="main"]
```

---

## 🧪 Testowanie

### Test lokalny serwera MCP
```bash
# Python server
cd mcp-servers/azure-devops
python src/server.py --debug

# W drugim terminalu
echo '{"jsonrpc": "2.0", "method": "tools/list", "id": 1}' | python src/server.py
```

### Test Azure Function
```powershell
# Lokalnie
cd mcp-servers/azure-function
func start

# Test endpoint
Invoke-RestMethod -Uri "http://localhost:7071/api/mcp" `
  -Method POST `
  -Body (@{jsonrpc="2.0"; method="tools/list"; id=1} | ConvertTo-Json)
```

---

## 🐛 Rozwiązywanie problemów

### "PAT token is invalid"
- Sprawdź czy token nie wygasł
- Zweryfikuj uprawnienia (Work Items R/W, Build R/E)
- Upewnij się że URL organizacji jest poprawny

### "Python module not found"
```bash
cd mcp-servers/azure-devops
python -m venv venv
# Windows: .\venv\Scripts\activate
# Linux: source venv/bin/activate
pip install -r requirements.txt
```

### "Function returns 401"
- Pobierz klucz funkcji z Azure Portal
- Zaktualizuj Custom Connector w Copilot Studio

📖 Więcej: [AZURE-DEVOPS-MCP-SETUP.md#rozwiązywanie-problemów](./AZURE-DEVOPS-MCP-SETUP.md#rozwiązywanie-problemów)

---

## 📚 Dokumentacja

- **[CLAUDE.md](./CLAUDE.md)** - Przegląd projektu i architektury
- **[AZURE-DEVOPS-MCP-SETUP.md](./AZURE-DEVOPS-MCP-SETUP.md)** - Kompletna instrukcja instalacji
- **[azure-setup/CLAUDE.md](./azure-setup/CLAUDE.md)** - Dokumentacja skryptów Azure
- **[mcp-servers/CLAUDE.md](./mcp-servers/CLAUDE.md)** - Opis serwerów MCP
- **[teams-bot/CLAUDE.md](./teams-bot/CLAUDE.md)** - Integracja z Teams

---

## 🤝 Wsparcie

- **Issues:** Zgłoś problem w [GitHub Issues](https://github.com/[your-repo]/Copilot365MCP/issues)
- **Pytania:** Skorzystaj z kanału Teams warsztatu
- **Dokumentacja MCP:** [modelcontextprotocol.io](https://modelcontextprotocol.io)
- **Azure DevOps API:** [docs.microsoft.com](https://docs.microsoft.com/azure/devops/rest/)

## 📄 Licencja

MIT License - zobacz plik [LICENSE](./LICENSE)

---

*Ostatnia aktualizacja: 2025-01-25 | Wersja: 1.0.0*
