# Copilot Studio Setup Guide for Azure DevOps MCP Server

This guide will help you set up the Azure DevOps MCP Server with Microsoft Copilot Studio.

## 📋 Prerequisites

- ✅ Azure Function deployed and running
- ✅ Function Key available
- ✅ Access to Microsoft Copilot Studio
- ✅ Azure DevOps project configured

## 🚀 Quick Setup

### Step 1: Verify Function is Working

Test your function with curl:
```bash
curl -X POST https://copilotmcpdevfunc.azurewebsites.net/api/mcp \
  -H "x-functions-key: YOUR_FUNCTION_KEY" \
  -H "Content-Type: application/json" \
  -d '{"method":"tools/list","params":{}}'
```

You should see a list of available tools.

### Step 2: Import Custom Connector

1. Go to **Microsoft Copilot Studio**
2. Navigate to **Settings** → **Custom Connectors**
3. Click **New custom connector** → **Import an OpenAPI file**
4. Use one of these YAML files:
   - `copilot-connector-fixed.yaml` - Full featured connector
   - `simple-list-connector.yaml` - Simple connector for testing

### Step 3: Configure Security

1. In the connector configuration, go to **Security** tab
2. Set authentication:
   - **Authentication type**: `API Key`
   - **Parameter label**: `Function Key`
   - **Parameter name**: `x-functions-key`
   - **Parameter location**: `Header`
3. Save the connector

### Step 4: Create Connection

1. Go to **Connections**
2. Find your custom connector
3. Click **Create connection**
4. Enter your Function Key: `<YOUR-FUNCTION-KEY>`
5. Save the connection

## 🛠️ Manual Configuration (Alternative)

If YAML import fails, create the connector manually:

### 1. Create Custom Connector from Blank

**General Tab:**
- **Host**: `copilotmcpdevfunc.azurewebsites.net`
- **Base URL**: `/api`
- **Scheme**: `HTTPS`

### 2. Security Tab

- **Authentication type**: `API Key`
- **Parameter label**: `Function Key`
- **Parameter name**: `x-functions-key`
- **Parameter location**: `Header`

### 3. Definition Tab

**Create New Action:**
- **Summary**: `List Work Items`
- **Description**: `Get work items from Azure DevOps project`
- **Operation ID**: `ListWorkItems`
- **Visibility**: `important`

**Request:**
- **Verb**: `POST`
- **URL**: `/mcp`
- **Headers**: `Content-Type: application/json` (add if not automatic)

**Body:**
Click **Import from sample** and paste:
```json
{
  "method": "tools/call",
  "params": {
    "name": "list_work_items",
    "arguments": {
      "project": "AI Space Team"
    }
  }
}
```

**Response:**
Click **Add default response** → **Import from sample** and paste:
```json
{
  "result": {
    "content": [
      {
        "type": "text",
        "text": "[{\"id\":1,\"title\":\"Sample Task\",\"state\":\"New\"}]"
      }
    ]
  }
}
```

### 4. Test Tab

1. Create a new connection with your Function Key
2. Test the operation
3. You should see work items from your project

## 📝 Common Issues and Solutions

### Issue: Validation Errors

**Problem**: Parameters with `x-ms-visibility: internal` require specific settings.

**Solution**: 
- For parameters with default values, use `x-ms-visibility: none`
- Leave "Required" unchecked for these parameters

### Issue: 500 Error

**Problem**: Connector returns HTTP 500 error.

**Possible Causes & Solutions**:

1. **Wrong project name**
   - Ensure project name matches exactly (including spaces)
   - Example: `"AI Space Team"` not `"AISpaceTeam"`

2. **Missing configuration**
   - Check Function App settings in Azure Portal
   - Ensure these are set:
     - `AZURE_DEVOPS_ORG_URL`
     - `AZURE_DEVOPS_PAT`
     - `AZURE_DEVOPS_PROJECT`

3. **Invalid Function Key**
   - Verify key in Azure Portal: Function App → Functions → McpServer → Function Keys

### Issue: Empty Response

**Problem**: Connector works but returns no data.

**Solution**:
- Check if the project has work items
- Verify PAT token has correct permissions
- Test with a different project name

## 🧪 Testing in Copilot Studio

### Basic Test Commands

1. **List all work items:**
   ```
   Show me work items from AI Space Team
   ```

2. **Get specific work item:**
   ```
   Get details of work item 7554
   ```

3. **Create new work item:**
   ```
   Create a new task called "Test MCP Integration" in AI Space Team
   ```

### Available Tools

The MCP server provides these tools:

| Tool | Description | Required Parameters |
|------|-------------|-------------------|
| `list_work_items` | List work items from project | `project` |
| `get_work_item` | Get specific work item details | `id` |
| `create_work_item` | Create new work item | `project`, `type`, `title` |
| `update_work_item` | Update existing work item | `id` |
| `run_pipeline` | Run a build pipeline | `project`, `pipeline_id` |
| `get_pipeline_status` | Get pipeline run status | `project`, `pipeline_id` |

## 🔐 Security Best Practices

1. **Never share Function Keys publicly**
2. **Use separate keys for different environments**
3. **Rotate keys regularly**
4. **Limit PAT token permissions to minimum required**

## 📊 Monitoring

Check function logs in Azure Portal:
1. Go to your Function App
2. Navigate to **Functions** → **McpServer** → **Monitor**
3. View invocation traces and logs

## 🆘 Need Help?

1. **Check Function Status**:
   ```bash
   curl https://copilotmcpdevfunc.azurewebsites.net/api/mcp \
     -H "x-functions-key: YOUR_KEY"
   ```

2. **View Function Logs**:
   ```bash
   az functionapp logs tail --name copilotmcpdevfunc \
     --resource-group copilot-mcp-workshop-rg
   ```

3. **Test with Postman**:
   - Import the YAML file into Postman
   - Add Function Key header
   - Test each operation

## 📚 Additional Resources

- [MCP Documentation](https://modelcontextprotocol.io)
- [Copilot Studio Custom Connectors](https://learn.microsoft.com/en-us/microsoft-copilot-studio/connectors-custom)
- [Azure Functions Documentation](https://docs.microsoft.com/azure/azure-functions/)
- [Azure DevOps REST API](https://docs.microsoft.com/azure/devops/rest/)

---
*Last updated: 2025-01-25*