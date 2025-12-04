# Script para iniciar el backend automáticamente
# Libera el puerto 3000 si está ocupado antes de iniciar

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Iniciando Backend Comandix" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar que estamos en la carpeta correcta
$backendPath = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $backendPath "package.json"))) {
    Write-Host "❌ Error: No se encontró package.json" -ForegroundColor Red
    Write-Host "   Ejecuta este script desde: comandero_flutter\backend\scripts" -ForegroundColor Yellow
    exit 1
}

# Cambiar a la carpeta del backend
Set-Location $backendPath

# 1. Verificar MySQL
Write-Host "1. Verificando MySQL81..." -ForegroundColor Yellow
try {
    $mysql = Get-Service -Name MySQL81 -ErrorAction Stop
    if ($mysql.Status -ne 'Running') {
        Write-Host "   ⚠️  MySQL81 no está corriendo. Intentando iniciar..." -ForegroundColor Yellow
        Start-Service -Name MySQL81 -ErrorAction Stop
        Start-Sleep -Seconds 2
        Write-Host "   ✅ MySQL81 iniciado" -ForegroundColor Green
    } else {
        Write-Host "   ✅ MySQL81 está corriendo" -ForegroundColor Green
    }
} catch {
    Write-Host "   ❌ Error con MySQL81: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   💡 Asegúrate de que MySQL esté instalado y configurado" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# 2. Liberar puerto 3000 si está ocupado
Write-Host "2. Verificando puerto 3000..." -ForegroundColor Yellow
$port3000 = Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue
if ($null -ne $port3000 -and $port3000.Count -gt 0) {
    $pids = $port3000 | Select-Object -ExpandProperty OwningProcess -Unique
    Write-Host "   ⚠️  Puerto 3000 está en uso. Liberando..." -ForegroundColor Yellow
    
    foreach ($pid in $pids) {
        try {
            $process = Get-Process -Id $pid -ErrorAction Stop
            Write-Host "      Cerrando PID $pid ($($process.ProcessName))..." -ForegroundColor Gray
            Stop-Process -Id $pid -Force -ErrorAction Stop
        } catch {
            # Ignorar errores si el proceso ya no existe
        }
    }
    
    Start-Sleep -Seconds 2
    
    # Verificar que se liberó
    $remaining = Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue
    if ($null -eq $remaining -or $remaining.Count -eq 0) {
        Write-Host "   ✅ Puerto 3000 liberado" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  El puerto 3000 aún está en uso" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ✅ Puerto 3000 está libre" -ForegroundColor Green
}
Write-Host ""

# 3. Verificar dependencias npm
Write-Host "3. Verificando dependencias..." -ForegroundColor Yellow
if (-not (Test-Path "node_modules")) {
    Write-Host "   ⚠️  node_modules no existe. Instalando dependencias..." -ForegroundColor Yellow
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   ❌ Error al instalar dependencias" -ForegroundColor Red
        exit 1
    }
    Write-Host "   ✅ Dependencias instaladas" -ForegroundColor Green
} else {
    Write-Host "   ✅ Dependencias instaladas" -ForegroundColor Green
}
Write-Host ""

# 4. Iniciar el backend
Write-Host "4. Iniciando el backend..." -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Backend iniciando..." -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "💡 Presiona Ctrl+C para detener el servidor" -ForegroundColor Cyan
Write-Host ""

# Iniciar el servidor
npm run dev

