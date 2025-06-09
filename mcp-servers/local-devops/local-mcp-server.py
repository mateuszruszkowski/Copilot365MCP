#!/usr/bin/env python3
"""
Lokalny serwer MCP dla DevOps - warsztat Copilot 365 MCP
Serwer obsługuje lokalne narzędzia DevOps jak Docker, kubectl, helm itp.
"""

import asyncio
import os
import subprocess
import json
import logging
from datetime import datetime
from typing import Any, Dict, List, Optional
import sys

# Dodaj ścieżkę do MCP SDK (może wymagać instalacji: pip install mcp)
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
logger = logging.getLogger('LocalDevOpsMCP')

class LocalDevOpsMCPServer:
    """Lokalny serwer MCP dla narzędzi DevOps"""
    
    def __init__(self):
        self.server = Server("local-devops-mcp")
        self.setup_handlers()
        
        # Sprawdź dostępność narzędzi
        self.available_tools = self._check_available_tools()
        logger.info(f"Dostępne narzędzia: {list(self.available_tools.keys())}")
    
    def _check_available_tools(self) -> Dict[str, bool]:
        """Sprawdź które narzędzia są dostępne w systemie"""
        tools_to_check = {
            'docker': 'docker --version',
            'kubectl': 'kubectl version --client',
            'helm': 'helm version',
            'git': 'git --version',
            'azure-cli': 'az --version',
            'terraform': 'terraform version',
            'powershell': 'powershell -Command "Get-Host"'
        }
        
        available = {}
        for tool, command in tools_to_check.items():
            try:
                result = subprocess.run(
                    command.split(), 
                    capture_output=True, 
                    text=True, 
                    timeout=5
                )
                available[tool] = result.returncode == 0
            except (subprocess.TimeoutExpired, FileNotFoundError):
                available[tool] = False
        
        return available
    
    def setup_handlers(self):
        """Konfiguracja handlerów MCP"""
        
        @self.server.list_tools()
        async def handle_list_tools() -> List[types.Tool]:
            tools = []
            
            # Docker tools
            if self.available_tools.get('docker', False):
                tools.extend([
                    types.Tool(
                        name="docker_build",
                        description="Zbuduj obraz Docker z Dockerfile",
                        inputSchema={
                            "type": "object",
                            "properties": {
                                "dockerfile": {
                                    "type": "string",
                                    "description": "Ścieżka do Dockerfile"
                                },
                                "tag": {
                                    "type": "string",
                                    "description": "Tag obrazu (np. myapp:latest)"
                                },
                                "context": {
                                    "type": "string",
                                    "description": "Ścieżka kontekstu budowania",
                                    "default": "."
                                }
                            },
                            "required": ["tag"]
                        }
                    ),
                    types.Tool(
                        name="docker_run",
                        description="Uruchom kontener Docker",
                        inputSchema={
                            "type": "object",
                            "properties": {
                                "image": {
                                    "type": "string",
                                    "description": "Nazwa obrazu do uruchomienia"
                                },
                                "ports": {
                                    "type": "string",
                                    "description": "Mapowanie portów (np. 8080:80)"
                                },
                                "name": {
                                    "type": "string",
                                    "description": "Nazwa kontenera"
                                },
                                "detached": {
                                    "type": "boolean",
                                    "description": "Uruchom w tle",
                                    "default": True
                                }
                            },
                            "required": ["image"]
                        }
                    ),
                    types.Tool(
                        name="docker_ps",
                        description="Lista uruchomionych kontenerów",
                        inputSchema={
                            "type": "object",
                            "properties": {
                                "all": {
                                    "type": "boolean",
                                    "description": "Pokaż wszystkie kontenery (również zatrzymane)",
                                    "default": False
                                }
                            }
                        }
                    )
                ])
            
            # Kubernetes tools
            if self.available_tools.get('kubectl', False):
                tools.extend([
                    types.Tool(
                        name="kubectl_apply",
                        description="Zastosuj konfigurację Kubernetes",
                        inputSchema={
                            "type": "object",
                            "properties": {
                                "manifest": {
                                    "type": "string",
                                    "description": "Ścieżka do pliku YAML lub zawartość manifestu"
                                },
                                "namespace": {
                                    "type": "string",
                                    "description": "Namespace Kubernetes"
                                }
                            },
                            "required": ["manifest"]
                        }
                    ),
                    types.Tool(
                        name="kubectl_get",
                        description="Pobierz zasoby Kubernetes",
                        inputSchema={
                            "type": "object",
                            "properties": {
                                "resource": {
                                    "type": "string",
                                    "description": "Typ zasobu (pods, services, deployments, itp.)"
                                },
                                "namespace": {
                                    "type": "string",
                                    "description": "Namespace Kubernetes"
                                },
                                "name": {
                                    "type": "string",
                                    "description": "Nazwa konkretnego zasobu"
                                }
                            },
                            "required": ["resource"]
                        }
                    )
                ])
            
            # Git tools
            if self.available_tools.get('git', False):
                tools.extend([
                    types.Tool(
                        name="git_status",
                        description="Status repozytorium Git",
                        inputSchema={
                            "type": "object",
                            "properties": {
                                "path": {
                                    "type": "string",
                                    "description": "Ścieżka do repozytorium",
                                    "default": "."
                                }
                            }
                        }
                    ),
                    types.Tool(
                        name="git_commit",
                        description="Commit zmian do Git",
                        inputSchema={
                            "type": "object",
                            "properties": {
                                "message": {
                                    "type": "string",
                                    "description": "Wiadomość commit"
                                },
                                "add_all": {
                                    "type": "boolean",
                                    "description": "Dodaj wszystkie pliki przed commit",
                                    "default": False
                                },
                                "path": {
                                    "type": "string",
                                    "description": "Ścieżka do repozytorium",
                                    "default": "."
                                }
                            },
                            "required": ["message"]
                        }
                    )
                ])
            
            # System tools
            tools.extend([
                types.Tool(
                    name="run_command",
                    description="Wykonaj dowolną komendę systemową",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "command": {
                                "type": "string",
                                "description": "Komenda do wykonania"
                            },
                            "working_dir": {
                                "type": "string",
                                "description": "Katalog roboczy",
                                "default": "."
                            },
                            "timeout": {
                                "type": "integer",
                                "description": "Timeout w sekundach",
                                "default": 30
                            }
                        },
                        "required": ["command"]
                    }
                ),
                types.Tool(
                    name="check_process",
                    description="Sprawdź uruchomione procesy",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "name": {
                                "type": "string",
                                "description": "Nazwa procesu do wyszukania"
                            }
                        }
                    }
                }
            ])
            
            return tools
        
        @self.server.call_tool()
        async def handle_call_tool(name: str, arguments: dict) -> List[types.TextContent]:
            logger.info(f"Wywołanie narzędzia: {name} z argumentami: {arguments}")
            
            try:
                if name == "docker_build":
                    return await self._docker_build(arguments)
                elif name == "docker_run":
                    return await self._docker_run(arguments)
                elif name == "docker_ps":
                    return await self._docker_ps(arguments)
                elif name == "kubectl_apply":
                    return await self._kubectl_apply(arguments)
                elif name == "kubectl_get":
                    return await self._kubectl_get(arguments)
                elif name == "git_status":
                    return await self._git_status(arguments)
                elif name == "git_commit":
                    return await self._git_commit(arguments)
                elif name == "run_command":
                    return await self._run_command(arguments)
                elif name == "check_process":
                    return await self._check_process(arguments)
                else:
                    raise ValueError(f"Nieznane narzędzie: {name}")
            except Exception as e:
                logger.error(f"Błąd wykonania narzędzia {name}: {e}")
                return [types.TextContent(
                    type="text",
                    text=f"❌ Błąd wykonania narzędzia {name}: {str(e)}"
                )]
    
    async def _run_subprocess(self, command: List[str], cwd: str = ".", timeout: int = 30) -> subprocess.CompletedProcess:
        """Pomocnicza metoda do uruchamiania poleceń"""
        try:
            result = subprocess.run(
                command,
                cwd=cwd,
                capture_output=True,
                text=True,
                timeout=timeout,
                check=False
            )
            return result
        except subprocess.TimeoutExpired:
            raise Exception(f"Komenda przekroczyła timeout {timeout}s")
        except FileNotFoundError:
            raise Exception(f"Komenda nie została znaleziona: {command[0]}")
    
    # Docker tools implementation
    async def _docker_build(self, args: dict) -> List[types.TextContent]:
        tag = args["tag"]
        dockerfile = args.get("dockerfile", "Dockerfile")
        context = args.get("context", ".")
        
        command = ["docker", "build", "-t", tag, "-f", dockerfile, context]
        result = await self._run_subprocess(command, timeout=300)  # 5 minut
        
        if result.returncode == 0:
            text = f"✅ **Docker build zakończony pomyślnie!**\n\n"
            text += f"🏷️ **Tag:** {tag}\n"
            text += f"📁 **Dockerfile:** {dockerfile}\n"
            text += f"📂 **Kontekst:** {context}\n\n"
            text += f"📋 **Output:**\n```\n{result.stdout}\n```"
        else:
            text = f"❌ **Docker build nie powiódł się!**\n\n"
            text += f"📋 **Błąd:**\n```\n{result.stderr}\n```"
        
        return [types.TextContent(type="text", text=text)]
    
    async def _docker_run(self, args: dict) -> List[types.TextContent]:
        image = args["image"]
        ports = args.get("ports")
        name = args.get("name")
        detached = args.get("detached", True)
        
        command = ["docker", "run"]
        if detached:
            command.append("-d")
        if ports:
            command.extend(["-p", ports])
        if name:
            command.extend(["--name", name])
        command.append(image)
        
        result = await self._run_subprocess(command)
        
        if result.returncode == 0:
            container_id = result.stdout.strip()
            text = f"✅ **Kontener uruchomiony pomyślnie!**\n\n"
            text += f"🐳 **Obraz:** {image}\n"
            text += f"🆔 **Container ID:** {container_id[:12]}...\n"
            if ports:
                text += f"🔌 **Porty:** {ports}\n"
            if name:
                text += f"📛 **Nazwa:** {name}\n"
        else:
            text = f"❌ **Nie udało się uruchomić kontenera!**\n\n"
            text += f"📋 **Błąd:**\n```\n{result.stderr}\n```"
        
        return [types.TextContent(type="text", text=text)]
    
    async def _docker_ps(self, args: dict) -> List[types.TextContent]:
        all_containers = args.get("all", False)
        
        command = ["docker", "ps"]
        if all_containers:
            command.append("-a")
        command.extend(["--format", "table {{.ID}}\\t{{.Image}}\\t{{.Status}}\\t{{.Names}}"])
        
        result = await self._run_subprocess(command)
        
        if result.returncode == 0:
            text = f"📋 **Lista kontenerów Docker:**\n\n"
            text += f"```\n{result.stdout}\n```"
        else:
            text = f"❌ **Błąd pobierania listy kontenerów:**\n\n"
            text += f"```\n{result.stderr}\n```"
        
        return [types.TextContent(type="text", text=text)]
    
    # Kubernetes tools implementation
    async def _kubectl_apply(self, args: dict) -> List[types.TextContent]:
        manifest = args["manifest"]
        namespace = args.get("namespace")
        
        command = ["kubectl", "apply"]
        if namespace:
            command.extend(["-n", namespace])
        
        # Sprawdź czy manifest to plik czy zawartość
        if os.path.exists(manifest):
            command.extend(["-f", manifest])
            source = f"plik: {manifest}"
        else:
            # Zapisz zawartość do tymczasowego pliku
            import tempfile
            with tempfile.NamedTemporaryFile(mode='w', suffix='.yaml', delete=False) as f:
                f.write(manifest)
                temp_file = f.name
            command.extend(["-f", temp_file])
            source = "zawartość YAML"
        
        result = await self._run_subprocess(command)
        
        # Usuń tymczasowy plik jeśli został utworzony
        if not os.path.exists(manifest):
            os.unlink(temp_file)
        
        if result.returncode == 0:
            text = f"✅ **Konfiguracja Kubernetes zastosowana!**\n\n"
            text += f"📁 **Źródło:** {source}\n"
            if namespace:
                text += f"🏷️ **Namespace:** {namespace}\n"
            text += f"\n📋 **Wynik:**\n```\n{result.stdout}\n```"
        else:
            text = f"❌ **Błąd zastosowania konfiguracji Kubernetes:**\n\n"
            text += f"```\n{result.stderr}\n```"
        
        return [types.TextContent(type="text", text=text)]
    
    async def _kubectl_get(self, args: dict) -> List[types.TextContent]:
        resource = args["resource"]
        namespace = args.get("namespace")
        name = args.get("name")
        
        command = ["kubectl", "get", resource]
        if namespace:
            command.extend(["-n", namespace])
        if name:
            command.append(name)
        command.extend(["-o", "wide"])
        
        result = await self._run_subprocess(command)
        
        if result.returncode == 0:
            text = f"📋 **Zasoby Kubernetes ({resource}):**\n\n"
            if namespace:
                text += f"🏷️ **Namespace:** {namespace}\n\n"
            text += f"```\n{result.stdout}\n```"
        else:
            text = f"❌ **Błąd pobierania zasobów Kubernetes:**\n\n"
            text += f"```\n{result.stderr}\n```"
        
        return [types.TextContent(type="text", text=text)]
    
    # Git tools implementation
    async def _git_status(self, args: dict) -> List[types.TextContent]:
        path = args.get("path", ".")
        
        result = await self._run_subprocess(["git", "status", "--porcelain"], cwd=path)
        
        if result.returncode == 0:
            if result.stdout.strip():
                text = f"📝 **Status repozytorium Git:**\n\n"
                text += f"📂 **Ścieżka:** {path}\n\n"
                text += f"```\n{result.stdout}\n```"
            else:
                text = f"✅ **Repozytorium Git jest czyste**\n\n"
                text += f"📂 **Ścieżka:** {path}\n"
                text += f"📋 Brak zmian do zacommitowania"
        else:
            text = f"❌ **Błąd sprawdzania statusu Git:**\n\n"
            text += f"```\n{result.stderr}\n```"
        
        return [types.TextContent(type="text", text=text)]
    
    async def _git_commit(self, args: dict) -> List[types.TextContent]:
        message = args["message"]
        add_all = args.get("add_all", False)
        path = args.get("path", ".")
        
        if add_all:
            add_result = await self._run_subprocess(["git", "add", "."], cwd=path)
            if add_result.returncode != 0:
                return [types.TextContent(
                    type="text",
                    text=f"❌ **Błąd dodawania plików:**\n```\n{add_result.stderr}\n```"
                )]
        
        result = await self._run_subprocess(["git", "commit", "-m", message], cwd=path)
        
        if result.returncode == 0:
            text = f"✅ **Commit wykonany pomyślnie!**\n\n"
            text += f"📂 **Ścieżka:** {path}\n"
            text += f"💬 **Wiadomość:** {message}\n"
            if add_all:
                text += f"📁 **Dodano wszystkie pliki**\n"
            text += f"\n📋 **Wynik:**\n```\n{result.stdout}\n```"
        else:
            text = f"❌ **Błąd wykonania commit:**\n\n"
            text += f"```\n{result.stderr}\n```"
        
        return [types.TextContent(type="text", text=text)]
    
    # System tools implementation
    async def _run_command(self, args: dict) -> List[types.TextContent]:
        command = args["command"]
        working_dir = args.get("working_dir", ".")
        timeout = args.get("timeout", 30)
        
        # Bezpieczeństwo - lista dozwolonych komend
        dangerous_commands = ['rm -rf', 'del /f', 'format', 'shutdown', 'reboot']
        if any(dangerous in command.lower() for dangerous in dangerous_commands):
            return [types.TextContent(
                type="text",
                text="❌ **Komenda odrzucona ze względów bezpieczeństwa!**"
            )]
        
        result = await self._run_subprocess(command.split(), cwd=working_dir, timeout=timeout)
        
        text = f"🖥️ **Wykonanie komendy:**\n\n"
        text += f"💻 **Komenda:** `{command}`\n"
        text += f"📂 **Katalog:** {working_dir}\n"
        text += f"⏱️ **Timeout:** {timeout}s\n"
        text += f"🔄 **Kod powrotu:** {result.returncode}\n\n"
        
        if result.stdout:
            text += f"📋 **Output:**\n```\n{result.stdout}\n```\n"
        
        if result.stderr:
            text += f"⚠️ **Stderr:**\n```\n{result.stderr}\n```"
        
        return [types.TextContent(type="text", text=text)]
    
    async def _check_process(self, args: dict) -> List[types.TextContent]:
        name = args.get("name", "")
        
        if os.name == 'nt':  # Windows
            command = ["tasklist", "/FI", f"IMAGENAME eq {name}*"]
        else:  # Unix/Linux
            command = ["ps", "aux"]
        
        result = await self._run_subprocess(command)
        
        if result.returncode == 0:
            if name:
                # Filtruj wyniki dla Unix/Linux
                if os.name != 'nt':
                    lines = result.stdout.split('\n')
                    filtered_lines = [line for line in lines if name.lower() in line.lower()]
                    output = '\n'.join(filtered_lines) if filtered_lines else "Brak procesów"
                else:
                    output = result.stdout
                
                text = f"🔍 **Procesy zawierające '{name}':**\n\n"
            else:
                output = result.stdout
                text = f"📋 **Lista procesów:**\n\n"
            
            text += f"```\n{output}\n```"
        else:
            text = f"❌ **Błąd sprawdzania procesów:**\n\n"
            text += f"```\n{result.stderr}\n```"
        
        return [types.TextContent(type="text", text=text)]
    
    async def run(self):
        """Uruchom serwer MCP"""
        logger.info("Uruchamianie lokalnego serwera MCP DevOps...")
        async with stdio_server() as (read_stream, write_stream):
            await self.server.run(
                read_stream,
                write_stream,
                self.server.create_initialization_options()
            )

def main():
    """Główna funkcja"""
    if len(sys.argv) > 1 and sys.argv[1] == "--help":
        print("Lokalny serwer MCP dla narzędzi DevOps")
        print("Użycie: python local-mcp-server.py")
        print("\nObsługiwane narzędzia:")
        print("  • Docker (build, run, ps)")
        print("  • Kubernetes (kubectl apply, get)")
        print("  • Git (status, commit)")
        print("  • Systemowe (run_command, check_process)")
        return
    
    server = LocalDevOpsMCPServer()
    try:
        asyncio.run(server.run())
    except KeyboardInterrupt:
        logger.info("Serwer zatrzymany przez użytkownika")
    except Exception as e:
        logger.error(f"Błąd serwera: {e}")

if __name__ == "__main__":
    main()
