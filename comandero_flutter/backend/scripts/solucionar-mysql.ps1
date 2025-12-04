# Script completo para solucionar problemas de MySQL
# Ejecutar como Administrador para iniciar servicios

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SOLUCIÓN DE PROBLEMAS MYSQL" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar servicios de MySQL disponibles
Write-Host "Servicios de MySQL encontrados:" -ForegroundColor Yellow
$mysqlServices = Get-Service -Name MySQL* -ErrorAction SilentlyContinue

if ($null -eq $mysqlServices -or $mysqlServices.Count -eq 0) {
    Write-Host "ERROR: No se encontraron servicios de MySQL instalados" -ForegroundColor Red
    Write-Host "Verifica que MySQL esté instalado correctamente" -ForegroundColor Yellow
    exit 1
}

$mysqlServices | ForEach-Object {
    $statusColor = if ($_.Status -eq 'Running') { 'Green' } else { 'Red' }
    Write-Host "  - $($_.Name): $($_.Status)" -ForegroundColor $statusColor
}

Write-Host ""

# Intentar iniciar MySQL81 primero (más común)
$targetService = $mysqlServices | Where-Object { $_.Name -eq 'MySQL81' } | Select-Object -First 1

if ($null -eq $targetService) {
    # Si no existe MySQL81, intentar con el primero disponible
    $targetService = $mysqlServices | Select-Object -First 1
    Write-Host "MySQL81 no encontrado, usando: $($targetService.Name)" -ForegroundColor Yellow
}

if ($targetService.Status -eq 'Running') {
    Write-Host "✓ $($targetService.Name) ya está corriendo" -ForegroundColor Green
    Write-Host ""
    Write-Host "Verificando conexión..." -ForegroundColor Cyan
    
    # Verificar puerto
    $port = Get-NetTCPConnection -LocalPort 3306,3307 -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($port) {
        Write-Host "✓ MySQL está escuchando en el puerto $($port.LocalPort)" -ForegroundColor Green
        Write-Host ""
        Write-Host "IMPORTANTE: Actualiza DATABASE_PORT en .env a $($port.LocalPort)" -ForegroundColor Yellow
    }
    exit 0
}

Write-Host "Intentando iniciar $($targetService.Name)..." -ForegroundColor Yellow
Write-Host ""

# Verificar si tenemos permisos de administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "⚠ ADVERTENCIA: No se detectaron permisos de Administrador" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Para iniciar MySQL, necesitas:" -ForegroundColor Cyan
    Write-Host "  1. Cerrar esta ventana de PowerShell" -ForegroundColor White
    Write-Host "  2. Clic derecho en PowerShell > 'Ejecutar como administrador'" -ForegroundColor White
    Write-Host "  3. Ejecutar este script nuevamente" -ForegroundColor White
    Write-Host ""
    Write-Host "O inicia MySQL manualmente:" -ForegroundColor Cyan
    Write-Host "  1. Presiona Win + R" -ForegroundColor White
    Write-Host "  2. Escribe: services.msc" -ForegroundColor White
    Write-Host "  3. Busca '$($targetService.Name)'" -ForegroundColor White
    Write-Host "  4. Clic derecho > Iniciar" -ForegroundColor White
    Write-Host ""
    exit 1
}

try {
    Write-Host "Iniciando servicio $($targetService.Name)..." -ForegroundColor Cyan
    Start-Service -Name $targetService.Name -ErrorAction Stop
    Start-Sleep -Seconds 5
    
    $service = Get-Service -Name $targetService.Name
    if ($service.Status -eq 'Running') {
        Write-Host "✓ $($targetService.Name) iniciado correctamente" -ForegroundColor Green
        Write-Host ""
        
        # Esperar un poco más para que MySQL termine de inicializar
        Write-Host "Esperando a que MySQL termine de inicializar..." -ForegroundColor Cyan
        Start-Sleep -Seconds 5
        
        # Verificar puerto
        $port = Get-NetTCPConnection -LocalPort 3306,3307 -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($port) {
            Write-Host "✓ MySQL está escuchando en el puerto $($port.LocalPort)" -ForegroundColor Green
            Write-Host ""
            Write-Host "Verifica que DATABASE_PORT en .env sea: $($port.LocalPort)" -ForegroundColor Yellow
        } else {
            Write-Host "⚠ No se detectó MySQL escuchando en puertos 3306 o 3307" -ForegroundColor Yellow
            Write-Host "  Puede que MySQL esté usando otro puerto" -ForegroundColor Yellow
        }
        
        Write-Host ""
        Write-Host "✓ MySQL está listo para usar" -ForegroundColor Green
        Write-Host ""
        Write-Host "Ahora puedes reiniciar el backend:" -ForegroundColor Cyan
        Write-Host "  npm run dev" -ForegroundColor White
    } else {
        Write-Host "⚠ $($targetService.Name) no se pudo iniciar. Estado: $($service.Status)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Intenta iniciarlo manualmente desde 'Servicios' (services.msc)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "ERROR: No se pudo iniciar $($targetService.Name)" -ForegroundColor Red
    Write-Host "Mensaje: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Solución alternativa:" -ForegroundColor Yellow
    Write-Host "  1. Abre 'Servicios' (Win+R > services.msc)" -ForegroundColor White
    Write-Host "  2. Busca '$($targetService.Name)'" -ForegroundColor White
    Write-Host "  3. Clic derecho > Iniciar" -ForegroundColor White
    Write-Host "  4. Si falla, revisa los logs de MySQL" -ForegroundColor White
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan

