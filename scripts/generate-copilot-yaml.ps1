# Generate Copilot Studio Custom Connection YAML
param(
    [Parameter(Mandatory=$true)]
    [string]$FunctionAppName,
    
    [Parameter(Mandatory=$true)]
    [string]$FunctionKey,
    
    [string]$OutputPath = ".\copilot-custom-connection.yaml"
)

$yamlContent = @"
swagger: '2.0'
info:
  title: Azure DevOps MCP Server
  description: MCP Server for Azure DevOps task management through Copilot Studio
  version: 1.0.0
host: $FunctionAppName.azurewebsites.net
basePath: /api
schemes:
  - https
securityDefinitions:
  apiKeyHeader:
    type: apiKey
    name: x-functions-key
    in: header
security:
  - apiKeyHeader: []
paths:
  /mcp:
    post:
      summary: Azure DevOps MCP API Endpoint
      description: Handles MCP protocol requests for Azure DevOps operations
      operationId: InvokeMCP
      x-ms-agentic-protocol: mcp-streamable-1.0
      consumes:
        - application/json
      produces:
        - application/json
      parameters:
        - in: body
          name: body
          required: true
          schema:
            type: object
            properties:
              method:
                type: string
                description: MCP method to invoke
              params:
                type: object
                description: Parameters for the method
      responses:
        '200':
          description: Successful operation
          schema:
            type: object
            properties:
              result:
                type: object
                description: Result from MCP operation
        '400':
          description: Bad request
          schema:
            type: object
            properties:
              error:
                type: string
        '500':
          description: Internal server error
          schema:
            type: object
            properties:
              error:
                type: string
x-ms-connector-metadata:
  - propertyName: Website
    propertyValue: https://github.com/yourorg/copilot365mcp
  - propertyName: Privacy Policy
    propertyValue: https://github.com/yourorg/copilot365mcp/privacy
  - propertyName: Categories
    propertyValue: AI;Productivity
"@

# Save YAML file
$yamlContent | Out-File -FilePath $OutputPath -Encoding UTF8

Write-Host "`n✅ Custom Connection YAML generated successfully!" -ForegroundColor Green
Write-Host "`n📋 Next steps:" -ForegroundColor Yellow
Write-Host "1. Copy the content of $OutputPath" -ForegroundColor White
Write-Host "2. Go to Microsoft Copilot Studio" -ForegroundColor White
Write-Host "3. Navigate to Settings > Custom Connectors" -ForegroundColor White
Write-Host "4. Click 'New custom connector' > 'Import an OpenAPI file'" -ForegroundColor White
Write-Host "5. Upload the generated YAML file" -ForegroundColor White
Write-Host "6. Configure the connection with your Function Key: $FunctionKey" -ForegroundColor White
Write-Host "`n🔗 Function URL: https://$FunctionAppName.azurewebsites.net/api/mcp" -ForegroundColor Cyan
Write-Host "`n📝 Function Key location:" -ForegroundColor Yellow
Write-Host "   Azure Portal > Function App > Functions > McpServer > Function Keys" -ForegroundColor White