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
            return [
                types.Tool(
                    name="docker_ps",
                    description="Lista uruchomionych kontenerów Docker",
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
                ),
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
                    name="run_command",
                    description="Wykonaj komendę systemową",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "command": {
                                "type": "string",
                                "description": "Komenda do wykonania"
                            }
                        },
                        "required": ["command"]
                    }
                )
            ]
        
        @self.server.call_tool()
        async def handle_call_tool(name: str, arguments: dict) -> List[types.TextContent]:
            try:
                if name == "docker_ps":
                    return await self._docker_ps(arguments)
                elif name == "git_status":
                    return await self._git_status(arguments)
                elif name == "run_command":
                    return await self._run_command(arguments)
                else:
                    raise ValueError(f"Nieznane narzędzie: {name}")
            except Exception as e:
                return [types.TextContent(
                    type="text",
                    text=f"❌ Błąd: {str(e)}"
                )]
    
    async def _docker_ps(self, args: dict) -> List[types.TextContent]:
        try:
            cmd = ["docker", "ps"]
            if args.get("all", False):
                cmd.append("-a")
            
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                return [types.TextContent(
                    type="text",
                    text=f"Docker kontenery:\n```\n{result.stdout}\n```"
                )]
            else:
                return [types.TextContent(
                    type="text", 
                    text=f"Błąd Docker: {result.stderr}"
                )]
        except Exception as e:
            return [types.TextContent(
                type="text",
                text=f"Błąd wykonania: {str(e)}"
            )]
    
    async def _git_status(self, args: dict) -> List[types.TextContent]:
        try:
            path = args.get("path", ".")
            result = subprocess.run(
                ["git", "status", "--short"], 
                cwd=path, 
                capture_output=True, 
                text=True
            )
            
            if result.returncode == 0:
                if result.stdout.strip():
                    return [types.TextContent(
                        type="text",
                        text=f"Status Git:\n```\n{result.stdout}\n```"
                    )]
                else:
                    return [types.TextContent(
                        type="text",
                        text="✅ Repozytorium Git jest czyste"
                    )]
            else:
                return [types.TextContent(
                    type="text",
                    text=f"Błąd Git: {result.stderr}"
                )]
        except Exception as e:
            return [types.TextContent(
                type="text",
                text=f"Błąd wykonania: {str(e)}"
            )]
    
    async def _run_command(self, args: dict) -> List[types.TextContent]:
        try:
            command = args["command"]
            
            # Bezpieczeństwo
            dangerous = ['rm -rf', 'del /f', 'format', 'shutdown']
            if any(d in command.lower() for d in dangerous):
                return [types.TextContent(
                    type="text",
                    text="❌ Komenda odrzucona ze względów bezpieczeństwa"
                )]
            
            result = subprocess.run(
                command.split(), 
                capture_output=True, 
                text=True,
                timeout=30
            )
            
            output = f"Komenda: {command}\nKod powrotu: {result.returncode}\n"
            if result.stdout:
                output += f"\nOutput:\n{result.stdout}"
            if result.stderr:
                output += f"\nStderr:\n{result.stderr}"
            
            return [types.TextContent(type="text", text=output)]
            
        except Exception as e:
            return [types.TextContent(
                type="text",
                text=f"Błąd wykonania: {str(e)}"
            )]
    
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
    server = LocalDevOpsMCPServer()
    try:
        asyncio.run(server.run())
    except KeyboardInterrupt:
        logger.info("Serwer zatrzymany")
    except Exception as e:
        logger.error(f"Błąd serwera: {e}")

if __name__ == "__main__":
    main()
# Uruchomienie serwera
# Jeśli ten plik jest uruchamiany bezpośrednio, uruchom serwer
# Możesz użyć: python local-mcp-server.py
# lub: python3 local-mcp-server.py
# Upewnij się, że masz zainstalowane wymagane biblioteki i narzędzia