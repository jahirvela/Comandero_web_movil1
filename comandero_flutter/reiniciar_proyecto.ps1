# Script para reiniciar el proyecto Flutter
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Reiniciando Proyecto Flutter" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Matar procesos relacionados
Write-Host "[1/5] Cerrando procesos de Chrome y Flutter..." -ForegroundColor Yellow
Get-Process | Where-Object {$_.ProcessName -like "*chrome*"} | Stop-Process -Force -ErrorAction SilentlyContinue
Get-Process | Where-Object {$_.ProcessName -like "*flutter*"} | Stop-Process -Force -ErrorAction SilentlyContinue
Get-Process | Where-Object {$_.ProcessName -like "*dart*"} | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Write-Host "   Procesos cerrados" -ForegroundColor Green
Write-Host ""

# 2. Limpiar cache de Flutter
Write-Host "[2/5] Limpiando cache de Flutter..." -ForegroundColor Yellow
flutter clean
Write-Host "   Cache limpiado" -ForegroundColor Green
Write-Host ""

# 3. Obtener dependencias
Write-Host "[3/5] Obteniendo dependencias..." -ForegroundColor Yellow
flutter pub get
Write-Host "   Dependencias obtenidas" -ForegroundColor Green
Write-Host ""

# 4. Verificar puertos
Write-Host "[4/5] Verificando puertos..." -ForegroundColor Yellow
$port49705 = Get-NetTCPConnection -LocalPort 49705 -ErrorAction SilentlyContinue
$port3000 = Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue

if ($port49705) {
    Write-Host "   Puerto 49705 esta en uso" -ForegroundColor Red
    $port49705 | ForEach-Object {
        $pid = $_.OwningProcess
        $proc = Get-Process -Id $pid -ErrorAction SilentlyContinue
        if ($proc) {
            Write-Host "   Matando proceso $($proc.ProcessName) (PID: $pid)..." -ForegroundColor Yellow
            Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
        }
    }
}

if ($port3000) {
    Write-Host "   Puerto 3000 esta en uso" -ForegroundColor Red
    $port3000 | ForEach-Object {
        $pid = $_.OwningProcess
        $proc = Get-Process -Id $pid -ErrorAction SilentlyContinue
        if ($proc) {
            Write-Host "   Matando proceso $($proc.ProcessName) (PID: $pid)..." -ForegroundColor Yellow
            Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
        }
    }
}
Write-Host "   Puertos verificados" -ForegroundColor Green
Write-Host ""

# 5. Iniciar Flutter
Write-Host "[5/5] Iniciando Flutter..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Ejecutando: flutter run -d chrome --web-port=49705" -ForegroundColor Cyan
Write-Host ""

flutter run -d chrome --web-port=49705

