# Script para cerrar automáticamente procesos en el puerto 3000
# Útil cuando necesitas liberar el puerto rápidamente

Write-Host "Liberando puerto 3000..." -ForegroundColor Yellow

$processes = Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue | 
    Select-Object -ExpandProperty OwningProcess -Unique

if ($null -eq $processes -or $processes.Count -eq 0) {
    Write-Host "✅ El puerto 3000 ya está libre" -ForegroundColor Green
    exit 0
}

foreach ($pid in $processes) {
    try {
        $process = Get-Process -Id $pid -ErrorAction Stop
        Write-Host "Cerrando PID $pid ($($process.ProcessName))..." -ForegroundColor Yellow
        Stop-Process -Id $pid -Force -ErrorAction Stop
        Write-Host "✅ Proceso $pid cerrado" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  No se pudo cerrar el proceso $pid" -ForegroundColor Yellow
    }
}

Start-Sleep -Seconds 2

# Verificar
$remaining = Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue
if ($null -eq $remaining -or $remaining.Count -eq 0) {
    Write-Host "✅ Puerto 3000 liberado exitosamente" -ForegroundColor Green
} else {
    Write-Host "⚠️  El puerto 3000 aún está en uso" -ForegroundColor Yellow
}

