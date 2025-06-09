#!/usr/bin/env python3
"""
Azure DevOps MCP Server
Model Context Protocol server for Azure DevOps integration
Warsztat: Copilot 365 MCP Integration
"""

import asyncio
import aiohttp
import base64
import json
import logging
import os
import sys
from datetime import datetime
from typing import Any, Dict, List, Optional
from urllib.parse import quote

# Import MCP SDK
try:
    from mcp.server import Server
    from mcp.server.stdio import stdio_server
    import mcp.types as types
except ImportError:
    print("❌ MCP SDK nie jest zainstalowane!")
    print("Zainstaluj: pip install mcp")
    sys.exit(1)

# Konfiguracja logowania
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('AzureDevOpsMCP')

class AzureDevOpsMCPServer:
    """Serwer MCP dla integracji z Azure DevOps"""
    
    def __init__(self):
        self.server = Server("azure-devops-mcp")
        
        # Konfiguracja Azure DevOps
        self.org_url = os.getenv("AZURE_DEVOPS_ORG", "https://dev.azure.com/yourorg")
        self.pat = os.getenv("AZURE_DEVOPS_PAT", "")
        self.project = os.getenv("AZURE_DEVOPS_PROJECT", "")
        
        if not self.pat:
            logger.warning("AZURE_DEVOPS_PAT nie jest ustawiony - niektóre funkcje mogą nie działać")
        
        # Przygotuj nagłówki autoryzacji
        self.headers = self._prepare_headers()
        
        # Konfiguruj handlery
        self.setup_handlers()
        
        logger.info(f"Azure DevOps MCP Server zainicjalizowany dla: {self.org_url}")
    
    def _prepare_headers(self) -> Dict[str, str]:
        """Przygotuj nagłówki HTTP z autoryzacją"""
        headers = {
            "Content-Type": "application/json",
            "Accept": "application/json"
        }
        
        if self.pat:
            # Azure DevOps używa Basic Auth z pustym username i PAT jako password
            auth_string = f":{self.pat}"
            auth_bytes = base64.b64encode(auth_string.encode()).decode()
            headers["Authorization"] = f"Basic {auth_bytes}"
        
        return headers
    
    def setup_handlers(self):
        """Konfiguracja handlerów MCP"""
        
        @self.server.list_tools()
        async def handle_list_tools() -> List[types.Tool]:
            return [
                types.Tool(
                    name="create_work_item",
                    description="Utwórz nowe zadanie w Azure DevOps",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "title": {
                                "type": "string",
                                "description": "Tytuł zadania"
                            },
                            "description": {
                                "type": "string",
                                "description": "Opis zadania (opcjonalny)"
                            },
                            "type": {
                                "type": "string",
                                "enum": ["Bug", "Task", "Feature", "User Story", "Epic"],
                                "description": "Typ zadania",
                                "default": "Task"
                            },
                            "assignee": {
                                "type": "string",
                                "description": "Email osoby przypisanej (opcjonalny)"
                            },
                            "priority": {
                                "type": "integer",
                                "minimum": 1,
                                "maximum": 4,
                                "description": "Priorytet (1=Najwyższy, 4=Najniższy)",
                                "default": 2
                            },
                            "area_path": {
                                "type": "string",
                                "description": "Ścieżka obszaru (opcjonalna)"
                            },
                            "iteration_path": {
                                "type": "string",
                                "description": "Ścieżka iteracji (opcjonalna)"
                            },
                            "tags": {
                                "type": "string",
                                "description": "Tagi oddzielone średnikami (opcjonalne)"
                            }
                        },
                        "required": ["title", "type"]
                    }
                ),
                types.Tool(
                    name="query_work_items",
                    description="Wyszukaj zadania w Azure DevOps",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "query": {
                                "type": "string",
                                "description": "Zapytanie WIQL lub tekst do wyszukania"
                            },
                            "project": {
                                "type": "string",
                                "description": "Nazwa projektu (opcjonalna, użyje domyślnego)"
                            },
                            "top": {
                                "type": "integer",
                                "description": "Maksymalna liczba wyników",
                                "default": 20,
                                "maximum": 100
                            }
                        },
                        "required": ["query"]
                    }
                ),
                types.Tool(
                    name="get_work_item",
                    description="Pobierz szczegóły zadania po ID",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "id": {
                                "type": "integer",
                                "description": "ID zadania"
                            },
                            "expand": {
                                "type": "string",
                                "enum": ["none", "relations", "fields", "links", "all"],
                                "description": "Dodatkowe informacje do pobrania",
                                "default": "fields"
                            }
                        },
                        "required": ["id"]
                    }
                ),
                types.Tool(
                    name="update_work_item",
                    description="Aktualizuj istniejące zadanie",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "id": {
                                "type": "integer",
                                "description": "ID zadania do aktualizacji"
                            },
                            "title": {
                                "type": "string",
                                "description": "Nowy tytuł (opcjonalny)"
                            },
                            "description": {
                                "type": "string",
                                "description": "Nowy opis (opcjonalny)"
                            },
                            "state": {
                                "type": "string",
                                "enum": ["New", "Active", "Resolved", "Closed", "Removed"],
                                "description": "Nowy status (opcjonalny)"
                            },
                            "assignee": {
                                "type": "string",
                                "description": "Nowa osoba przypisana (opcjonalna)"
                            },
                            "comment": {
                                "type": "string",
                                "description": "Komentarz do zmiany (opcjonalny)"
                            }
                        },
                        "required": ["id"]
                    }
                ),
                types.Tool(
                    name="run_pipeline",
                    description="Uruchom pipeline CI/CD",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "pipeline_id": {
                                "type": "integer",
                                "description": "ID pipeline do uruchomienia"
                            },
                            "branch": {
                                "type": "string",
                                "description": "Nazwa branch (domyślnie main)",
                                "default": "main"
                            },
                            "project": {
                                "type": "string",
                                "description": "Nazwa projektu (opcjonalna)"
                            },
                            "parameters": {
                                "type": "object",
                                "description": "Parametry pipeline (opcjonalne)"
                            }
                        },
                        "required": ["pipeline_id"]
                    }
                ),
                types.Tool(
                    name="get_pipeline_runs",
                    description="Pobierz uruchomienia pipeline",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "pipeline_id": {
                                "type": "integer",
                                "description": "ID pipeline (opcjonalne, wszystkie jeśli brak)"
                            },
                            "project": {
                                "type": "string",
                                "description": "Nazwa projektu (opcjonalna)"
                            },
                            "status": {
                                "type": "string",
                                "enum": ["inProgress", "completed", "cancelling", "postponed"],
                                "description": "Filtr statusu (opcjonalny)"
                            },
                            "top": {
                                "type": "integer",
                                "description": "Maksymalna liczba wyników",
                                "default": 10,
                                "maximum": 50
                            }
                        }
                    }
                ),
                types.Tool(
                    name="get_repositories",
                    description="Pobierz listę repozytoriów",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "project": {
                                "type": "string",
                                "description": "Nazwa projektu (opcjonalna)"
                            }
                        }
                    }
                ),
                types.Tool(
                    name="create_pull_request",
                    description="Utwórz pull request",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "repository_id": {
                                "type": "string",
                                "description": "ID repozytorium"
                            },
                            "title": {
                                "type": "string",
                                "description": "Tytuł pull requesta"
                            },
                            "description": {
                                "type": "string",
                                "description": "Opis pull requesta"
                            },
                            "source_branch": {
                                "type": "string",
                                "description": "Branch źródłowy"
                            },
                            "target_branch": {
                                "type": "string",
                                "description": "Branch docelowy",
                                "default": "main"
                            },
                            "reviewers": {
                                "type": "array",
                                "items": {"type": "string"},
                                "description": "Lista reviewerów (email)"
                            },
                            "work_items": {
                                "type": "array",
                                "items": {"type": "integer"},
                                "description": "Lista ID zadań do połączenia"
                            }
                        },
                        "required": ["repository_id", "title", "source_branch"]
                    }
                ),
                types.Tool(
                    name="get_build_artifacts",
                    description="Pobierz artefakty z buildu",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "build_id": {
                                "type": "integer",
                                "description": "ID buildu"
                            },
                            "project": {
                                "type": "string",
                                "description": "Nazwa projektu (opcjonalna)"
                            }
                        },
                        "required": ["build_id"]
                    }
                )
            ]
        
        @self.server.call_tool()
        async def handle_call_tool(name: str, arguments: dict) -> List[types.TextContent]:
            logger.info(f"Wywołanie narzędzia: {name} z argumentami: {arguments}")
            
            try:
                async with aiohttp.ClientSession() as session:
                    if name == "create_work_item":
                        return await self.create_work_item(session, arguments)
                    elif name == "query_work_items":
                        return await self.query_work_items(session, arguments)
                    elif name == "get_work_item":
                        return await self.get_work_item(session, arguments)
                    elif name == "update_work_item":
                        return await self.update_work_item(session, arguments)
                    elif name == "run_pipeline":
                        return await self.run_pipeline(session, arguments)
                    elif name == "get_pipeline_runs":
                        return await self.get_pipeline_runs(session, arguments)
                    elif name == "get_repositories":
                        return await self.get_repositories(session, arguments)
                    elif name == "create_pull_request":
                        return await self.create_pull_request(session, arguments)
                    elif name == "get_build_artifacts":
                        return await self.get_build_artifacts(session, arguments)
                    else:
                        raise ValueError(f"Nieznane narzędzie: {name}")
            except Exception as e:
                logger.error(f"Błąd wykonania narzędzia {name}: {e}")
                return [types.TextContent(
                    type="text",
                    text=f"❌ Błąd wykonania narzędzia {name}: {str(e)}"
                )]
        
        @self.server.list_resources()
        async def handle_list_resources() -> List[types.Resource]:
            return [
                types.Resource(
                    uri="azuredevops://projects",
                    name="Azure DevOps Projects",
                    description="Lista projektów w organizacji"
                ),
                types.Resource(
                    uri="azuredevops://pipelines",
                    name="CI/CD Pipelines",
                    description="Lista dostępnych pipeline"
                ),
                types.Resource(
                    uri="azuredevops://work-items/active",
                    name="Active Work Items",
                    description="Aktywne zadania w projekcie"
                ),
                types.Resource(
                    uri="azuredevops://repositories",
                    name="Git Repositories",
                    description="Lista repozytoriów Git"
                )
            ]
        
        @self.server.read_resource()
        async def handle_read_resource(uri: str) -> str:
            async with aiohttp.ClientSession() as session:
                if uri == "azuredevops://projects":
                    return await self.get_projects_resource(session)
                elif uri == "azuredevops://pipelines":
                    return await self.get_pipelines_resource(session)
                elif uri == "azuredevops://work-items/active":
                    return await self.get_active_work_items_resource(session)
                elif uri == "azuredevops://repositories":
                    return await self.get_repositories_resource(session)
                else:
                    raise ValueError(f"Nieznany zasób: {uri}")
    
    # Work Items implementation
    async def create_work_item(self, session: aiohttp.ClientSession, args: dict) -> List[types.TextContent]:
        project = args.get("project", self.project)
        if not project:
            raise ValueError("Projekt nie jest skonfigurowany")
        
        work_item_type = args["type"]
        title = args["title"]
        description = args.get("description", "")
        assignee = args.get("assignee")
        priority = args.get("priority", 2)
        area_path = args.get("area_path")
        iteration_path = args.get("iteration_path")
        tags = args.get("tags")
        
        url = f"{self.org_url}/{project}/_apis/wit/workitems/${work_item_type}?api-version=7.1"
        
        # Przygotuj operacje PATCH
        operations = [
            {
                "op": "add",
                "path": "/fields/System.Title",
                "value": title
            }
        ]
        
        if description:
            operations.append({
                "op": "add",
                "path": "/fields/System.Description",
                "value": description
            })
        
        if assignee:
            operations.append({
                "op": "add",
                "path": "/fields/System.AssignedTo",
                "value": assignee
            })
        
        # Mapa priorytetów
        priority_map = {1: 1, 2: 2, 3: 3, 4: 4}
        operations.append({
            "op": "add",
            "path": "/fields/Microsoft.VSTS.Common.Priority",
            "value": priority_map.get(priority, 2)
        })
        
        if area_path:
            operations.append({
                "op": "add",
                "path": "/fields/System.AreaPath",
                "value": area_path
            })
        
        if iteration_path:
            operations.append({
                "op": "add",
                "path": "/fields/System.IterationPath",
                "value": iteration_path
            })
        
        if tags:
            operations.append({
                "op": "add",
                "path": "/fields/System.Tags",
                "value": tags
            })
        
        headers = {**self.headers, "Content-Type": "application/json-patch+json"}
        
        async with session.post(url, json=operations, headers=headers) as response:
            if response.status in [200, 201]:
                data = await response.json()
                work_item_id = data['id']
                work_item_title = data['fields']['System.Title']
                work_item_url = data['_links']['html']['href']
                
                result = f"✅ **Zadanie utworzone pomyślnie!**\n\n"
                result += f"🆔 **ID:** #{work_item_id}\n"
                result += f"📋 **Typ:** {work_item_type}\n"
                result += f"📝 **Tytuł:** {work_item_title}\n"
                result += f"👤 **Projekt:** {project}\n"
                if assignee:
                    result += f"👨‍💼 **Przypisane do:** {assignee}\n"
                result += f"🔗 **Link:** [Otwórz w Azure DevOps]({work_item_url})\n"
                
                return [types.TextContent(type="text", text=result)]
            else:
                error_text = await response.text()
                raise Exception(f"API Error {response.status}: {error_text}")
    
    async def query_work_items(self, session: aiohttp.ClientSession, args: dict) -> List[types.TextContent]:
        query = args["query"]
        project = args.get("project", self.project)
        top = args.get("top", 20)
        
        # Sprawdź czy to WIQL query czy zwykły tekst
        if not query.upper().startswith("SELECT"):
            # Stwórz prosty WIQL query dla wyszukiwania tekstu
            wiql_query = f"""
            SELECT [System.Id], [System.Title], [System.State], [System.WorkItemType], [System.AssignedTo]
            FROM WorkItems
            WHERE [System.Title] CONTAINS '{query}'
            {f"AND [System.TeamProject] = '{project}'" if project else ""}
            ORDER BY [System.ChangedDate] DESC
            """
        else:
            wiql_query = query
        
        url = f"{self.org_url}/_apis/wit/wiql?api-version=7.1"
        
        wiql_body = {"query": wiql_query}
        
        async with session.post(url, json=wiql_body, headers=self.headers) as response:
            if response.status == 200:
                data = await response.json()
                work_items = data.get('workItems', [])
                
                if not work_items:
                    return [types.TextContent(
                        type="text",
                        text=f"🔍 **Brak wyników dla zapytania:** '{query}'"
                    )]
                
                # Pobierz szczegóły zadań (maksymalnie 'top' elementów)
                ids = [str(wi['id']) for wi in work_items[:top]]
                details_url = f"{self.org_url}/_apis/wit/workitems?ids={','.join(ids)}&$expand=fields&api-version=7.1"
                
                async with session.get(details_url, headers=self.headers) as details_response:
                    if details_response.status == 200:
                        details_data = await details_response.json()
                        
                        result = f"🔍 **Wyniki wyszukiwania:** '{query}'\n"
                        result += f"📊 **Znaleziono:** {len(details_data['value'])} zadań\n\n"
                        
                        for item in details_data['value']:
                            fields = item['fields']
                            item_id = item['id']
                            title = fields.get('System.Title', 'Brak tytułu')
                            state = fields.get('System.State', 'Unknown')
                            work_item_type = fields.get('System.WorkItemType', 'Unknown')
                            assignee = fields.get('System.AssignedTo', {}).get('displayName', 'Nieprzypisane')
                            
                            state_icon = {
                                'New': '🆕', 'Active': '🔄', 'Resolved': '✅', 
                                'Closed': '✅', 'Removed': '🗑️'
                            }.get(state, '📋')
                            
                            result += f"{state_icon} **#{item_id}** - {title}\n"
                            result += f"   📂 **Typ:** {work_item_type} | 📊 **Status:** {state} | 👤 **Przypisane:** {assignee}\n\n"
                        
                        return [types.TextContent(type="text", text=result)]
                    else:
                        raise Exception(f"Error getting work item details: {details_response.status}")
            else:
                error_text = await response.text()
                raise Exception(f"WIQL Query Error {response.status}: {error_text}")
    
    async def get_work_item(self, session: aiohttp.ClientSession, args: dict) -> List[types.TextContent]:
        work_item_id = args["id"]
        expand = args.get("expand", "fields")
        
        url = f"{self.org_url}/_apis/wit/workitems/{work_item_id}?$expand={expand}&api-version=7.1"
        
        async with session.get(url, headers=self.headers) as response:
            if response.status == 200:
                data = await response.json()
                fields = data['fields']
                
                title = fields.get('System.Title', 'Brak tytułu')
                state = fields.get('System.State', 'Unknown')
                work_item_type = fields.get('System.WorkItemType', 'Unknown')
                created_date = fields.get('System.CreatedDate', '')
                changed_date = fields.get('System.ChangedDate', '')
                created_by = fields.get('System.CreatedBy', {}).get('displayName', 'Unknown')
                assignee = fields.get('System.AssignedTo', {}).get('displayName', 'Nieprzypisane')
                description = fields.get('System.Description', 'Brak opisu')
                tags = fields.get('System.Tags', '')
                
                result = f"📋 **Szczegóły zadania #{work_item_id}**\n\n"
                result += f"📝 **Tytuł:** {title}\n"
                result += f"📂 **Typ:** {work_item_type}\n"
                result += f"📊 **Status:** {state}\n"
                result += f"👤 **Przypisane do:** {assignee}\n"
                result += f"👨‍💻 **Utworzone przez:** {created_by}\n"
                result += f"📅 **Data utworzenia:** {created_date[:10] if created_date else 'Unknown'}\n"
                result += f"🔄 **Ostatnia zmiana:** {changed_date[:10] if changed_date else 'Unknown'}\n"
                
                if tags:
                    result += f"🏷️ **Tagi:** {tags}\n"
                
                result += f"\n📄 **Opis:**\n{description}\n"
                
                if '_links' in data:
                    html_link = data['_links'].get('html', {}).get('href', '')
                    if html_link:
                        result += f"\n🔗 **Link:** [Otwórz w Azure DevOps]({html_link})"
                
                return [types.TextContent(type="text", text=result)]
            else:
                error_text = await response.text()
                raise Exception(f"Work Item Get Error {response.status}: {error_text}")
    
    async def update_work_item(self, session: aiohttp.ClientSession, args: dict) -> List[types.TextContent]:
        work_item_id = args["id"]
        
        url = f"{self.org_url}/_apis/wit/workitems/{work_item_id}?api-version=7.1"
        
        operations = []
        
        # Przygotuj operacje aktualizacji
        if "title" in args:
            operations.append({
                "op": "replace",
                "path": "/fields/System.Title",
                "value": args["title"]
            })
        
        if "description" in args:
            operations.append({
                "op": "replace",
                "path": "/fields/System.Description",
                "value": args["description"]
            })
        
        if "state" in args:
            operations.append({
                "op": "replace",
                "path": "/fields/System.State",
                "value": args["state"]
            })
        
        if "assignee" in args:
            operations.append({
                "op": "replace",
                "path": "/fields/System.AssignedTo",
                "value": args["assignee"]
            })
        
        if "comment" in args:
            operations.append({
                "op": "add",
                "path": "/fields/System.History",
                "value": args["comment"]
            })
        
        if not operations:
            raise ValueError("Brak zmian do zastosowania")
        
        headers = {**self.headers, "Content-Type": "application/json-patch+json"}
        
        async with session.patch(url, json=operations, headers=headers) as response:
            if response.status == 200:
                data = await response.json()
                
                result = f"✅ **Zadanie #{work_item_id} zaktualizowane!**\n\n"
                result += f"📝 **Tytuł:** {data['fields']['System.Title']}\n"
                result += f"📊 **Status:** {data['fields']['System.State']}\n"
                
                if '_links' in data:
                    html_link = data['_links'].get('html', {}).get('href', '')
                    if html_link:
                        result += f"🔗 **Link:** [Otwórz w Azure DevOps]({html_link})"
                
                return [types.TextContent(type="text", text=result)]
            else:
                error_text = await response.text()
                raise Exception(f"Work Item Update Error {response.status}: {error_text}")
    
    # Pipelines implementation
    async def run_pipeline(self, session: aiohttp.ClientSession, args: dict) -> List[types.TextContent]:
        pipeline_id = args["pipeline_id"]
        branch = args.get("branch", "main")
        project = args.get("project", self.project)
        parameters = args.get("parameters", {})
        
        if not project:
            raise ValueError("Projekt nie jest skonfigurowany")
        
        url = f"{self.org_url}/{project}/_apis/pipelines/{pipeline_id}/runs?api-version=7.1"
        
        body = {
            "resources": {
                "repositories": {
                    "self": {
                        "refName": f"refs/heads/{branch}"
                    }
                }
            }
        }
        
        if parameters:
            body["templateParameters"] = parameters
        
        async with session.post(url, json=body, headers=self.headers) as response:
            if response.status in [200, 201]:
                data = await response.json()
                run_id = data['id']
                pipeline_name = data['pipeline']['name']
                run_url = data['_links']['web']['href']
                
                result = f"🚀 **Pipeline uruchomiony!**\n\n"
                result += f"🆔 **Run ID:** {run_id}\n"
                result += f"📋 **Pipeline:** {pipeline_name}\n"
                result += f"🌿 **Branch:** {branch}\n"
                result += f"👤 **Projekt:** {project}\n"
                result += f"📊 **Status:** {data.get('state', 'Unknown')}\n"
                result += f"🔗 **Link:** [Zobacz w Azure DevOps]({run_url})"
                
                return [types.TextContent(type="text", text=result)]
            else:
                error_text = await response.text()
                raise Exception(f"Pipeline Run Error {response.status}: {error_text}")
    
    async def get_pipeline_runs(self, session: aiohttp.ClientSession, args: dict) -> List[types.TextContent]:
        pipeline_id = args.get("pipeline_id")
        project = args.get("project", self.project)
        status = args.get("status")
        top = args.get("top", 10)
        
        if not project:
            raise ValueError("Projekt nie jest skonfigurowany")
        
        # Buduj URL
        if pipeline_id:
            url = f"{self.org_url}/{project}/_apis/pipelines/{pipeline_id}/runs?"
        else:
            url = f"{self.org_url}/{project}/_apis/build/builds?"
        
        params = [f"api-version=7.1", f"$top={top}"]
        
        if status:
            params.append(f"statusFilter={status}")
        
        url += "&".join(params)
        
        async with session.get(url, headers=self.headers) as response:
            if response.status == 200:
                data = await response.json()
                runs = data.get('value', [])
                
                if not runs:
                    return [types.TextContent(
                        type="text",
                        text="📊 **Brak uruchomień pipeline do wyświetlenia**"
                    )]
                
                result = f"📊 **Pipeline Runs** ({'wszystkie' if not pipeline_id else f'pipeline {pipeline_id}'})\n\n"
                
                for run in runs:
                    run_id = run.get('id', 'Unknown')
                    pipeline_name = run.get('definition', {}).get('name', 'Unknown')
                    status = run.get('status', run.get('state', 'Unknown'))
                    result_status = run.get('result', 'Unknown')
                    start_time = run.get('startTime', run.get('queueTime', ''))
                    
                    status_icon = {
                        'inProgress': '🔄', 'completed': '✅', 'cancelling': '⏹️',
                        'succeeded': '✅', 'failed': '❌', 'canceled': '⏹️'
                    }.get(status.lower(), '📋')
                    
                    result += f"{status_icon} **#{run_id}** - {pipeline_name}\n"
                    result += f"   📊 **Status:** {status}"
                    if result_status != 'Unknown':
                        result += f" | 🎯 **Result:** {result_status}"
                    if start_time:
                        result += f" | 🕐 **Start:** {start_time[:16]}"
                    result += "\n\n"
                
                return [types.TextContent(type="text", text=result)]
            else:
                error_text = await response.text()
                raise Exception(f"Pipeline Runs Error {response.status}: {error_text}")
    
    # Repositories implementation
    async def get_repositories(self, session: aiohttp.ClientSession, args: dict) -> List[types.TextContent]:
        project = args.get("project", self.project)
        
        if project:
            url = f"{self.org_url}/{project}/_apis/git/repositories?api-version=7.1"
        else:
            url = f"{self.org_url}/_apis/git/repositories?api-version=7.1"
        
        async with session.get(url, headers=self.headers) as response:
            if response.status == 200:
                data = await response.json()
                repos = data.get('value', [])
                
                if not repos:
                    return [types.TextContent(
                        type="text",
                        text="📂 **Brak repozytoriów do wyświetlenia**"
                    )]
                
                result = f"📂 **Repozytoria Git** {f'(projekt: {project})' if project else '(wszystkie)'}\n\n"
                
                for repo in repos:
                    name = repo.get('name', 'Unknown')
                    repo_id = repo.get('id', 'Unknown')
                    default_branch = repo.get('defaultBranch', 'refs/heads/main').replace('refs/heads/', '')
                    web_url = repo.get('webUrl', '')
                    size = repo.get('size', 0)
                    
                    result += f"📦 **{name}** (ID: {repo_id[:8]}...)\n"
                    result += f"   🌿 **Default Branch:** {default_branch}\n"
                    if size > 0:
                        result += f"   📏 **Size:** {size} bytes\n"
                    if web_url:
                        result += f"   🔗 **URL:** [Otwórz repo]({web_url})\n"
                    result += "\n"
                
                return [types.TextContent(type="text", text=result)]
            else:
                error_text = await response.text()
                raise Exception(f"Repositories Error {response.status}: {error_text}")
    
    async def create_pull_request(self, session: aiohttp.ClientSession, args: dict) -> List[types.TextContent]:
        repository_id = args["repository_id"]
        title = args["title"]
        description = args.get("description", "")
        source_branch = args["source_branch"]
        target_branch = args.get("target_branch", "main")
        reviewers = args.get("reviewers", [])
        work_items = args.get("work_items", [])
        
        url = f"{self.org_url}/_apis/git/repositories/{repository_id}/pullrequests?api-version=7.1"
        
        body = {
            "sourceRefName": f"refs/heads/{source_branch}",
            "targetRefName": f"refs/heads/{target_branch}",
            "title": title,
            "description": description
        }
        
        # Dodaj reviewerów
        if reviewers:
            body["reviewers"] = [{"id": email} for email in reviewers]
        
        async with session.post(url, json=body, headers=self.headers) as response:
            if response.status in [200, 201]:
                data = await response.json()
                pr_id = data['pullRequestId']
                pr_url = data['_links']['web']['href']
                
                # Połącz z work items jeśli podano
                if work_items:
                    for wi_id in work_items:
                        await self._link_work_item_to_pr(session, repository_id, pr_id, wi_id)
                
                result = f"🔄 **Pull Request utworzony!**\n\n"
                result += f"🆔 **PR ID:** #{pr_id}\n"
                result += f"📝 **Tytuł:** {title}\n"
                result += f"🌿 **Branch:** {source_branch} → {target_branch}\n"
                if reviewers:
                    result += f"👥 **Reviewers:** {', '.join(reviewers)}\n"
                if work_items:
                    result += f"📋 **Połączone zadania:** {', '.join(map(str, work_items))}\n"
                result += f"🔗 **Link:** [Otwórz PR]({pr_url})"
                
                return [types.TextContent(type="text", text=result)]
            else:
                error_text = await response.text()
                raise Exception(f"Pull Request Error {response.status}: {error_text}")
    
    async def _link_work_item_to_pr(self, session: aiohttp.ClientSession, repo_id: str, pr_id: int, work_item_id: int):
        """Pomocnicza metoda do łączenia work item z PR"""
        url = f"{self.org_url}/_apis/git/repositories/{repo_id}/pullRequests/{pr_id}/workitems/{work_item_id}?api-version=7.1"
        
        async with session.patch(url, headers=self.headers) as response:
            if response.status not in [200, 201]:
                logger.warning(f"Nie udało się połączyć work item {work_item_id} z PR {pr_id}")
    
    async def get_build_artifacts(self, session: aiohttp.ClientSession, args: dict) -> List[types.TextContent]:
        build_id = args["build_id"]
        project = args.get("project", self.project)
        
        if not project:
            raise ValueError("Projekt nie jest skonfigurowany")
        
        url = f"{self.org_url}/{project}/_apis/build/builds/{build_id}/artifacts?api-version=7.1"
        
        async with session.get(url, headers=self.headers) as response:
            if response.status == 200:
                data = await response.json()
                artifacts = data.get('value', [])
                
                if not artifacts:
                    return [types.TextContent(
                        type="text",
                        text=f"📦 **Brak artefaktów dla buildu #{build_id}**"
                    )]
                
                result = f"📦 **Artefakty buildu #{build_id}**\n\n"
                
                for artifact in artifacts:
                    name = artifact.get('name', 'Unknown')
                    resource = artifact.get('resource', {})
                    download_url = resource.get('downloadUrl', '')
                    
                    result += f"📄 **{name}**\n"
                    if download_url:
                        result += f"   📥 **Download:** [Pobierz artefakt]({download_url})\n"
                    result += "\n"
                
                return [types.TextContent(type="text", text=result)]
            else:
                error_text = await response.text()
                raise Exception(f"Build Artifacts Error {response.status}: {error_text}")
    
    # Resource handlers
    async def get_projects_resource(self, session: aiohttp.ClientSession) -> str:
        url = f"{self.org_url}/_apis/projects?api-version=7.1"
        
        try:
            async with session.get(url, headers=self.headers) as response:
                if response.status == 200:
                    data = await response.json()
                    projects = [p["name"] for p in data.get("value", [])]
                    return f"📂 **Projekty Azure DevOps:**\n" + "\n".join([f"• {p}" for p in projects])
                else:
                    return f"❌ Błąd pobierania projektów: {response.status}"
        except Exception as e:
            return f"❌ Błąd połączenia: {str(e)}"
    
    async def get_pipelines_resource(self, session: aiohttp.ClientSession) -> str:
        if not self.project:
            return "⚠️ Projekt nie jest skonfigurowany"
        
        url = f"{self.org_url}/{self.project}/_apis/pipelines?api-version=7.1"
        
        try:
            async with session.get(url, headers=self.headers) as response:
                if response.status == 200:
                    data = await response.json()
                    pipelines = [f"#{p['id']} - {p['name']}" for p in data.get("value", [])]
                    return f"🚀 **Pipelines ({self.project}):**\n" + "\n".join([f"• {p}" for p in pipelines])
                else:
                    return f"❌ Błąd pobierania pipeline: {response.status}"
        except Exception as e:
            return f"❌ Błąd połączenia: {str(e)}"
    
    async def get_active_work_items_resource(self, session: aiohttp.ClientSession) -> str:
        if not self.project:
            return "⚠️ Projekt nie jest skonfigurowany"
        
        wiql_query = f"""
        SELECT [System.Id], [System.Title], [System.State], [System.WorkItemType]
        FROM WorkItems
        WHERE [System.TeamProject] = '{self.project}'
        AND [System.State] IN ('New', 'Active')
        ORDER BY [System.ChangedDate] DESC
        """
        
        url = f"{self.org_url}/_apis/wit/wiql?api-version=7.1"
        
        try:
            async with session.post(url, json={"query": wiql_query}, headers=self.headers) as response:
                if response.status == 200:
                    data = await response.json()
                    work_items = data.get('workItems', [])
                    
                    if work_items:
                        items_list = [f"#{wi['id']}" for wi in work_items[:10]]  # Pierwszych 10
                        return f"📋 **Aktywne zadania ({self.project}):**\n" + "\n".join([f"• {item}" for item in items_list])
                    else:
                        return f"📋 **Brak aktywnych zadań w projekcie {self.project}**"
                else:
                    return f"❌ Błąd pobierania zadań: {response.status}"
        except Exception as e:
            return f"❌ Błąd połączenia: {str(e)}"
    
    async def get_repositories_resource(self, session: aiohttp.ClientSession) -> str:
        if not self.project:
            url = f"{self.org_url}/_apis/git/repositories?api-version=7.1"
        else:
            url = f"{self.org_url}/{self.project}/_apis/git/repositories?api-version=7.1"
        
        try:
            async with session.get(url, headers=self.headers) as response:
                if response.status == 200:
                    data = await response.json()
                    repos = [r["name"] for r in data.get("value", [])]
                    return f"📂 **Repozytoria Git:**\n" + "\n".join([f"• {r}" for r in repos])
                else:
                    return f"❌ Błąd pobierania repozytoriów: {response.status}"
        except Exception as e:
            return f"❌ Błąd połączenia: {str(e)}"
    
    async def run(self):
        """Uruchom serwer MCP"""
        logger.info("Uruchamianie Azure DevOps MCP Server...")
        async with stdio_server() as (read_stream, write_stream):
            await self.server.run(
                read_stream,
                write_stream,
                self.server.create_initialization_options()
            )

def main():
    """Główna funkcja"""
    if len(sys.argv) > 1 and sys.argv[1] == "--help":
        print("Azure DevOps MCP Server")
        print("Serwer MCP dla integracji z Azure DevOps")
        print("\nZmienne środowiskowe:")
        print("  AZURE_DEVOPS_ORG - URL organizacji (np. https://dev.azure.com/yourorg)")
        print("  AZURE_DEVOPS_PAT - Personal Access Token")
        print("  AZURE_DEVOPS_PROJECT - Domyślny projekt (opcjonalnie)")
        print("\nObsługiwane funkcje:")
        print("  • Zarządzanie Work Items (tworzenie, aktualizacja, wyszukiwanie)")
        print("  • Uruchamianie Pipeline CI/CD")
        print("  • Zarządzanie Pull Requests")
        print("  • Pobieranie artefaktów")
        return
    
    server = AzureDevOpsMCPServer()
    try:
        asyncio.run(server.run())
    except KeyboardInterrupt:
        logger.info("Serwer zatrzymany przez użytkownika")
    except Exception as e:
        logger.error(f"Błąd serwera: {e}")

if __name__ == "__main__":
    main()
