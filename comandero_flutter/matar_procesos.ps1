# Script para matar procesos bloqueantes
Write-Host "Matando procesos de Chrome, Flutter y Dart..." -ForegroundColor Yellow

# Matar Chrome
Get-Process | Where-Object {$_.ProcessName -like "*chrome*"} | ForEach-Object {
    Write-Host "Matando proceso: $($_.ProcessName) (PID: $($_.Id))" -ForegroundColor Red
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}

# Matar Flutter
Get-Process | Where-Object {$_.ProcessName -like "*flutter*"} | ForEach-Object {
    Write-Host "Matando proceso: $($_.ProcessName) (PID: $($_.Id))" -ForegroundColor Red
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}

# Matar Dart
Get-Process | Where-Object {$_.ProcessName -like "*dart*"} | ForEach-Object {
    Write-Host "Matando proceso: $($_.ProcessName) (PID: $($_.Id))" -ForegroundColor Red
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "Procesos eliminados. Espera 3 segundos..." -ForegroundColor Green
Start-Sleep -Seconds 3

