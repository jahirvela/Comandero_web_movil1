# Script para liberar el puerto 3000

Write-Host "Liberando puerto 3000..." -ForegroundColor Yellow

try {
    $connections = Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue
    if ($connections) {
        $pids = $connections | Select-Object -ExpandProperty OwningProcess -Unique
        $count = 0
        foreach ($pid in $pids) {
            try {
                $process = Get-Process -Id $pid -ErrorAction SilentlyContinue
                if ($process) {
                    Write-Host "Cerrando proceso PID $pid ($($process.ProcessName))..." -ForegroundColor Gray
                    Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
                    $count++
                }
            } catch {
                # Ignorar errores
            }
        }
        if ($count -gt 0) {
            Write-Host "✅ Se cerraron $count proceso(s)" -ForegroundColor Green
        } else {
            Write-Host "✅ Puerto 3000 ya está libre" -ForegroundColor Green
        }
    } else {
        Write-Host "✅ Puerto 3000 ya está libre" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️  No se pudo verificar el puerto: $($_.Exception.Message)" -ForegroundColor Yellow
}
