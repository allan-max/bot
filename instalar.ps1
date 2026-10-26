$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "Node.js nao encontrado. Instale em https://nodejs.org" -ForegroundColor Red
    exit 1
}

Write-Host "Instalando dependencias (package.json)..." -ForegroundColor Cyan
npm install
if ($LASTEXITCODE -ne 0) { Write-Host "Falha no npm install" -ForegroundColor Red; exit 1 }

Write-Host "`n=== SEU IP ===" -ForegroundColor Green
Write-Host "IP local:"
[System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() |
    Where-Object { $_.OperationalStatus -eq 'Up' } |
    ForEach-Object {
        $n = $_.Name
        $_.GetIPProperties().UnicastAddresses |
            Where-Object { $_.Address.AddressFamily -eq 'InterNetwork' -and $_.Address.ToString() -notmatch '^(127\.|169\.254)' } |
            ForEach-Object { "  $($_.Address)  ($n)" }
    }
try {
    $pub = (Invoke-RestMethod -Uri "https://api.ipify.org" -TimeoutSec 10)
    Write-Host "IP publico: $pub"
} catch {
    Write-Host "Nao foi possivel obter o IP publico."
}
