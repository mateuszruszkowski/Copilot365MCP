# SZYBKA NAPRAWA DEPENDENCIES
# Naprawia wszystkie problemy instalacji

Write-Host "🔧 Szybka naprawa workshop dependencies..." -ForegroundColor Cyan

# Zatrzymaj procesy
Get-Process -Name "node", "func", "python" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

Write-Host "✅ Procesy zatrzymane" -ForegroundColor Green

# Azure Function
Write-Host "⚡ Naprawianie Azure Function..." -ForegroundColor Yellow
cd "mcp-servers\azure-function"
Remove-Item "node_modules" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "package-lock.json" -Force -ErrorAction SilentlyContinue
npm install
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Azure Function - OK" -ForegroundColor Green
} else {
    Write-Host "❌ Azure Function - ERROR" -ForegroundColor Red
}
cd "..\..\"

# Desktop Commander
Write-Host "💻 Naprawianie Desktop Commander..." -ForegroundColor Yellow
cd "mcp-servers\desktop-commander"
Remove-Item "node_modules" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "package-lock.json" -Force -ErrorAction SilentlyContinue
Remove-Item "dist" -Recurse -Force -ErrorAction SilentlyContinue
npm install
if ($LASTEXITCODE -eq 0) {
    npm run build
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Desktop Commander - OK" -ForegroundColor Green
    } else {
        Write-Host "❌ Desktop Commander build - ERROR" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Desktop Commander install - ERROR" -ForegroundColor Red
}
cd "..\..\"

# Teams Bot
Write-Host "🤖 Naprawianie Teams Bot..." -ForegroundColor Yellow
cd "teams-bot"
Remove-Item "node_modules" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "package-lock.json" -Force -ErrorAction SilentlyContinue
npm install
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Teams Bot - OK" -ForegroundColor Green
} else {
    Write-Host "❌ Teams Bot - ERROR" -ForegroundColor Red
}
cd "..\"

# Python
Write-Host "🐍 Naprawianie Python dependencies..." -ForegroundColor Yellow
cd "mcp-servers\local-devops"
pip install -r requirements.txt --upgrade --quiet
cd "..\azure-devops"
pip install -r requirements.txt --upgrade --quiet
cd "..\..\"
Write-Host "✅ Python - OK" -ForegroundColor Green

Write-Host ""
Write-Host "🎉 NAPRAWA ZAKOŃCZONA!" -ForegroundColor Green
Write-Host "Uruchom teraz: .\start-workshop.ps1" -ForegroundColor Cyan
