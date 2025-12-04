# Script para iniciar MySQL81
# DEBE ejecutarse como Administrador

# Verificar permisos de administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ ERROR: Este script requiere permisos de Administrador" -ForegroundColor Red
    Write-Host ""
    Write-Host "Para ejecutar como Administrador:" -ForegroundColor Yellow
    Write-Host "  1. Cierra esta ventana" -ForegroundColor White
    Write-Host "  2. Clic derecho en PowerShell" -ForegroundColor White
    Write-Host "  3. Selecciona 'Ejecutar como administrador'" -ForegroundColor White
    Write-Host "  4. Ejecuta este script nuevamente" -ForegroundColor White
    Write-Host ""
    Write-Host "O ejecuta directamente:" -ForegroundColor Cyan
    Write-Host "  net start MySQL81" -ForegroundColor Green
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Iniciando MySQL81" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$service = Get-Service -Name MySQL81 -ErrorAction SilentlyContinue

if ($null -eq $service) {
    Write-Host "❌ ERROR: El servicio MySQL81 no existe" -ForegroundColor Red
    Write-Host ""
    Write-Host "Servicios de MySQL disponibles:" -ForegroundColor Yellow
    Get-Service -Name MySQL* | ForEach-Object {
        Write-Host "  - $($_.Name)" -ForegroundColor White
    }
    exit 1
}

if ($service.Status -eq 'Running') {
    Write-Host "✅ MySQL81 ya está corriendo" -ForegroundColor Green
    exit 0
}

Write-Host "Iniciando MySQL81..." -ForegroundColor Yellow

try {
    Start-Service -Name MySQL81 -ErrorAction Stop
    Write-Host "Esperando a que MySQL se inicialice..." -ForegroundColor Cyan
    Start-Sleep -Seconds 5
    
    $service = Get-Service -Name MySQL81
    if ($service.Status -eq 'Running') {
        Write-Host ""
        Write-Host "✅ MySQL81 iniciado correctamente" -ForegroundColor Green
        Write-Host ""
        
        # Verificar puerto
        Start-Sleep -Seconds 2
        $port = Get-NetTCPConnection -LocalPort 3306,3307 -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($port) {
            Write-Host "✓ MySQL está escuchando en el puerto $($port.LocalPort)" -ForegroundColor Green
        }
        
        Write-Host ""
        Write-Host "✅ MySQL está listo para usar" -ForegroundColor Green
        Write-Host ""
        Write-Host "Ahora puedes reiniciar el backend:" -ForegroundColor Cyan
        Write-Host "  npm run dev" -ForegroundColor White
    } else {
        Write-Host "⚠ MySQL81 no se pudo iniciar. Estado: $($service.Status)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ ERROR: No se pudo iniciar MySQL81" -ForegroundColor Red
    Write-Host "Mensaje: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Intenta iniciarlo manualmente desde 'Servicios' (services.msc)" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan

