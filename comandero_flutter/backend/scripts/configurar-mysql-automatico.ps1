# Script para configurar MySQL81 para inicio automático
# IMPORTANTE: Ejecutar este script como Administrador

Write-Host "Configurando MySQL81 para inicio automático..." -ForegroundColor Yellow

# Verificar si se ejecuta como administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: Este script requiere permisos de Administrador" -ForegroundColor Red
    Write-Host "Por favor, ejecuta PowerShell como Administrador y vuelve a ejecutar este script" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Para ejecutar como Administrador:" -ForegroundColor Cyan
    Write-Host "1. Cierra esta ventana" -ForegroundColor Cyan
    Write-Host "2. Busca 'PowerShell' en el menú de inicio" -ForegroundColor Cyan
    Write-Host "3. Haz clic derecho en 'Windows PowerShell'" -ForegroundColor Cyan
    Write-Host "4. Selecciona 'Ejecutar como administrador'" -ForegroundColor Cyan
    Write-Host "5. Navega a esta carpeta y ejecuta: .\configurar-mysql-automatico.ps1" -ForegroundColor Cyan
    pause
    exit 1
}

# Configurar el servicio para inicio automático
try {
    Write-Host "Configurando tipo de inicio como 'Automático'..." -ForegroundColor Cyan
    Set-Service -Name MySQL81 -StartupType Automatic
    
    Write-Host "✓ MySQL81 configurado para inicio automático" -ForegroundColor Green
    
    # Verificar el estado actual
    $service = Get-Service -Name MySQL81
    Write-Host ""
    Write-Host "Estado del servicio:" -ForegroundColor Yellow
    Write-Host "  Nombre: $($service.Name)" -ForegroundColor White
    Write-Host "  Estado: $($service.Status)" -ForegroundColor White
    Write-Host "  Tipo de inicio: $($service.StartType)" -ForegroundColor White
    
    # Intentar iniciar el servicio si no está corriendo
    if ($service.Status -ne 'Running') {
        Write-Host ""
        Write-Host "Iniciando el servicio MySQL81..." -ForegroundColor Cyan
        Start-Service -Name MySQL81
        Start-Sleep -Seconds 2
        
        $service = Get-Service -Name MySQL81
        if ($service.Status -eq 'Running') {
            Write-Host "✓ MySQL81 iniciado correctamente" -ForegroundColor Green
        } else {
            Write-Host "⚠ MySQL81 no pudo iniciarse. Revisa los logs de MySQL." -ForegroundColor Yellow
        }
    } else {
        Write-Host ""
        Write-Host "✓ MySQL81 ya está corriendo" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Configuración completada exitosamente" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "MySQL81 ahora se iniciará automáticamente cuando Windows inicie." -ForegroundColor Cyan
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "ERROR al configurar el servicio:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    pause
    exit 1
}

pause

