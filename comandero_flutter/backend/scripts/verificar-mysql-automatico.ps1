# Script para verificar que MySQL81 está configurado para inicio automático
# Este script NO requiere permisos de administrador

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Verificación de MySQL81" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

try {
    $service = Get-Service -Name MySQL81 -ErrorAction Stop
    
    Write-Host "Estado del servicio MySQL81:" -ForegroundColor Yellow
    Write-Host "  Nombre: $($service.Name)" -ForegroundColor White
    Write-Host "  Estado: $($service.Status)" -ForegroundColor $(if ($service.Status -eq 'Running') { 'Green' } else { 'Red' })
    Write-Host "  Tipo de inicio: $($service.StartType)" -ForegroundColor White
    Write-Host ""
    
    # Verificar configuración
    if ($service.StartType -eq 'Automatic') {
        Write-Host "✅ MySQL81 está configurado para INICIO AUTOMÁTICO" -ForegroundColor Green
        Write-Host "   El servicio se iniciará automáticamente cuando Windows inicie." -ForegroundColor Green
    } else {
        Write-Host "❌ MySQL81 NO está configurado para inicio automático" -ForegroundColor Red
        Write-Host "   Tipo de inicio actual: $($service.StartType)" -ForegroundColor Red
        Write-Host ""
        Write-Host "Para configurarlo como automático, ejecuta:" -ForegroundColor Yellow
        Write-Host "   .\configurar-mysql-automatico.ps1" -ForegroundColor Cyan
        Write-Host "   (Requiere permisos de Administrador)" -ForegroundColor Yellow
    }
    
    Write-Host ""
    
    # Verificar si está corriendo
    if ($service.Status -eq 'Running') {
        Write-Host "✅ MySQL81 está CORRIENDO" -ForegroundColor Green
    } else {
        Write-Host "⚠️  MySQL81 NO está corriendo" -ForegroundColor Yellow
        Write-Host "   Estado actual: $($service.Status)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Para iniciarlo ahora, ejecuta:" -ForegroundColor Yellow
        Write-Host "   Start-Service MySQL81" -ForegroundColor Cyan
        Write-Host "   (Puede requerir permisos de Administrador)" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ ERROR: No se pudo encontrar el servicio MySQL81" -ForegroundColor Red
    Write-Host "   Mensaje: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Posibles causas:" -ForegroundColor Yellow
    Write-Host "  1. MySQL no está instalado" -ForegroundColor White
    Write-Host "  2. El servicio tiene otro nombre" -ForegroundColor White
    Write-Host ""
    Write-Host "Para ver todos los servicios de MySQL, ejecuta:" -ForegroundColor Yellow
    Write-Host "   Get-Service | Where-Object {`$_.Name -like '*mysql*'}" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    exit 1
}

