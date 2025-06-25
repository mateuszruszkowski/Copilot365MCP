import azure.functions as func
import json
import logging
import os
from typing import Dict, Any, List, Optional
from azure.devops.connection import Connection
from msrest.authentication import BasicAuthentication
from azure.devops.v7_0.work_item_tracking.models import Wiql

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class AzureDevOpsMCPServer:
    """Azure DevOps MCP Server for Azure Function"""
    
    def __init__(self):
        self.org_url = os.environ.get('AZURE_DEVOPS_ORG_URL')
        self.pat = os.environ.get('AZURE_DEVOPS_PAT')
        self.project = os.environ.get('AZURE_DEVOPS_PROJECT')
        
        if not all([self.org_url, self.pat]):
            raise ValueError("Missing Azure DevOps configuration")
        
        # Initialize connection
        credentials = BasicAuthentication('', self.pat)
        self.connection = Connection(base_url=self.org_url, creds=credentials)
    
    def list_tools(self) -> Dict[str, Any]:
        """List available MCP tools"""
        return {
            "tools": [
                {
                    "name": "list_work_items",
                    "description": "List work items from Azure DevOps project",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "project": {"type": "string", "description": "Project name"},
                            "query": {"type": "string", "description": "WIQL query (optional)"},
                            "limit": {"type": "integer", "description": "Max items to return", "default": 10}
                        },
                        "required": ["project"]
                    }
                },
                {
                    "name": "get_work_item",
                    "description": "Get specific work item by ID",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "id": {"type": "integer", "description": "Work item ID"}
                        },
                        "required": ["id"]
                    }
                },
                {
                    "name": "create_work_item",
                    "description": "Create a new work item",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "project": {"type": "string", "description": "Project name"},
                            "type": {"type": "string", "description": "Work item type (Task, Bug, User Story)"},
                            "title": {"type": "string", "description": "Work item title"},
                            "description": {"type": "string", "description": "Work item description"},
                            "assigned_to": {"type": "string", "description": "Assigned to (email)"},
                            "priority": {"type": "integer", "description": "Priority (1-4)"}
                        },
                        "required": ["project", "type", "title"]
                    }
                },
                {
                    "name": "update_work_item",
                    "description": "Update an existing work item",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "id": {"type": "integer", "description": "Work item ID"},
                            "title": {"type": "string", "description": "New title"},
                            "state": {"type": "string", "description": "New state"},
                            "assigned_to": {"type": "string", "description": "New assignee"},
                            "priority": {"type": "integer", "description": "New priority"}
                        },
                        "required": ["id"]
                    }
                },
                {
                    "name": "run_pipeline",
                    "description": "Run a build pipeline",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "project": {"type": "string", "description": "Project name"},
                            "pipeline_id": {"type": "integer", "description": "Pipeline ID"},
                            "branch": {"type": "string", "description": "Branch name", "default": "main"}
                        },
                        "required": ["project", "pipeline_id"]
                    }
                },
                {
                    "name": "get_pipeline_status",
                    "description": "Get status of recent pipeline runs",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "project": {"type": "string", "description": "Project name"},
                            "pipeline_id": {"type": "integer", "description": "Pipeline ID"},
                            "limit": {"type": "integer", "description": "Number of runs to return", "default": 5}
                        },
                        "required": ["project", "pipeline_id"]
                    }
                }
            ]
        }
    
    async def call_tool(self, tool_name: str, arguments: Dict[str, Any]) -> Dict[str, Any]:
        """Execute a tool and return results"""
        try:
            if tool_name == "list_work_items":
                return await self._list_work_items(arguments)
            elif tool_name == "get_work_item":
                return await self._get_work_item(arguments)
            elif tool_name == "create_work_item":
                return await self._create_work_item(arguments)
            elif tool_name == "update_work_item":
                return await self._update_work_item(arguments)
            elif tool_name == "run_pipeline":
                return await self._run_pipeline(arguments)
            elif tool_name == "get_pipeline_status":
                return await self._get_pipeline_status(arguments)
            else:
                raise ValueError(f"Unknown tool: {tool_name}")
        except Exception as e:
            logger.error(f"Error executing tool {tool_name}: {str(e)}")
            return {
                "content": [{
                    "type": "text",
                    "text": f"Error: {str(e)}"
                }]
            }
    
    async def _list_work_items(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """List work items from project"""
        wit_client = self.connection.clients.get_work_item_tracking_client()
        project = args.get('project', self.project)
        query = args.get('query')
        limit = args.get('limit', 10)
        
        if not query:
            query = f"SELECT [System.Id], [System.Title], [System.State], [System.AssignedTo] FROM WorkItems WHERE [System.TeamProject] = '{project}' ORDER BY [System.ChangedDate] DESC"
        
        wiql = Wiql(query=query)
        query_result = wit_client.query_by_wiql(wiql, project=project, top=limit)
        
        work_items = []
        if query_result.work_items:
            ids = [wi.id for wi in query_result.work_items[:limit]]
            items = wit_client.get_work_items(ids=ids)
            
            for item in items:
                work_items.append({
                    'id': item.id,
                    'title': item.fields.get('System.Title', ''),
                    'state': item.fields.get('System.State', ''),
                    'assigned_to': item.fields.get('System.AssignedTo', {}).get('displayName', 'Unassigned'),
                    'type': item.fields.get('System.WorkItemType', ''),
                    'url': item.url
                })
        
        return {
            "content": [{
                "type": "text",
                "text": json.dumps(work_items, indent=2)
            }]
        }
    
    async def _get_work_item(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Get specific work item details"""
        wit_client = self.connection.clients.get_work_item_tracking_client()
        work_item_id = args['id']
        
        item = wit_client.get_work_item(work_item_id)
        
        result = {
            'id': item.id,
            'title': item.fields.get('System.Title', ''),
            'description': item.fields.get('System.Description', ''),
            'state': item.fields.get('System.State', ''),
            'assigned_to': item.fields.get('System.AssignedTo', {}).get('displayName', 'Unassigned'),
            'type': item.fields.get('System.WorkItemType', ''),
            'priority': item.fields.get('Microsoft.VSTS.Common.Priority', ''),
            'created_date': item.fields.get('System.CreatedDate', ''),
            'changed_date': item.fields.get('System.ChangedDate', ''),
            'url': item.url
        }
        
        return {
            "content": [{
                "type": "text",
                "text": json.dumps(result, indent=2)
            }]
        }
    
    async def _create_work_item(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new work item"""
        wit_client = self.connection.clients.get_work_item_tracking_client()
        project = args.get('project', self.project)
        
        document = []
        
        # Add title
        document.append({
            "op": "add",
            "path": "/fields/System.Title",
            "value": args['title']
        })
        
        # Add optional fields
        if 'description' in args:
            document.append({
                "op": "add",
                "path": "/fields/System.Description",
                "value": args['description']
            })
        
        if 'assigned_to' in args:
            document.append({
                "op": "add",
                "path": "/fields/System.AssignedTo",
                "value": args['assigned_to']
            })
        
        if 'priority' in args:
            document.append({
                "op": "add",
                "path": "/fields/Microsoft.VSTS.Common.Priority",
                "value": args['priority']
            })
        
        work_item = wit_client.create_work_item(
            document=document,
            project=project,
            type=args['type']
        )
        
        return {
            "content": [{
                "type": "text",
                "text": f"Created work item #{work_item.id}: {work_item.fields['System.Title']}"
            }]
        }
    
    async def _update_work_item(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Update an existing work item"""
        wit_client = self.connection.clients.get_work_item_tracking_client()
        work_item_id = args['id']
        
        document = []
        
        # Update fields if provided
        field_mapping = {
            'title': '/fields/System.Title',
            'state': '/fields/System.State',
            'assigned_to': '/fields/System.AssignedTo',
            'priority': '/fields/Microsoft.VSTS.Common.Priority'
        }
        
        for field, path in field_mapping.items():
            if field in args:
                document.append({
                    "op": "replace",
                    "path": path,
                    "value": args[field]
                })
        
        if document:
            work_item = wit_client.update_work_item(
                document=document,
                id=work_item_id
            )
            
            return {
                "content": [{
                    "type": "text",
                    "text": f"Updated work item #{work_item.id}"
                }]
            }
        else:
            return {
                "content": [{
                    "type": "text",
                    "text": "No fields to update"
                }]
            }
    
    async def _run_pipeline(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Run a build pipeline"""
        build_client = self.connection.clients.get_build_client()
        project = args.get('project', self.project)
        pipeline_id = args['pipeline_id']
        branch = args.get('branch', 'main')
        
        build = {
            'definition': {'id': pipeline_id},
            'sourceBranch': f'refs/heads/{branch}'
        }
        
        queued_build = build_client.queue_build(
            build=build,
            project=project
        )
        
        return {
            "content": [{
                "type": "text",
                "text": f"Pipeline run started: Build #{queued_build.id} on branch {branch}"
            }]
        }
    
    async def _get_pipeline_status(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Get status of recent pipeline runs"""
        build_client = self.connection.clients.get_build_client()
        project = args.get('project', self.project)
        pipeline_id = args['pipeline_id']
        limit = args.get('limit', 5)
        
        builds = build_client.get_builds(
            project=project,
            definitions=[pipeline_id],
            top=limit
        )
        
        results = []
        for build in builds:
            results.append({
                'id': build.id,
                'status': build.status,
                'result': build.result,
                'branch': build.source_branch,
                'started': str(build.start_time) if build.start_time else None,
                'finished': str(build.finish_time) if build.finish_time else None
            })
        
        return {
            "content": [{
                "type": "text",
                "text": json.dumps(results, indent=2)
            }]
        }


# Azure Function entry point
async def main(req: func.HttpRequest) -> func.HttpResponse:
    logger.info('Azure DevOps MCP Server function triggered')
    
    try:
        # Parse request
        req_body = req.get_json()
        method = req_body.get('method')
        params = req_body.get('params', {})
        
        # Initialize server
        server = AzureDevOpsMCPServer()
        
        # Handle different MCP methods
        if method == 'tools/list':
            result = server.list_tools()
        elif method == 'tools/call':
            tool_name = params.get('name')
            arguments = params.get('arguments', {})
            result = await server.call_tool(tool_name, arguments)
        else:
            return func.HttpResponse(
                json.dumps({"error": f"Unknown method: {method}"}),
                status_code=400,
                headers={"Content-Type": "application/json"}
            )
        
        # Return successful response
        return func.HttpResponse(
            json.dumps({"result": result}),
            status_code=200,
            headers={
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "POST, OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type"
            }
        )
        
    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": str(e)}),
            status_code=500,
            headers={"Content-Type": "application/json"}
        )