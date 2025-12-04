# Script simple para iniciar el backend (solo libera puerto e inicia)
# Útil cuando ya sabes que todo está configurado

# Obtener la ruta del script actual
$scriptPath = $PSScriptRoot
if (-not $scriptPath) {
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
}

# Obtener la ruta del backend (carpeta padre de scripts)
$backendPath = Join-Path $scriptPath ".."
$backendPath = Resolve-Path $backendPath -ErrorAction SilentlyContinue

if (-not $backendPath) {
    # Si no se puede resolver, usar ruta relativa
    $backendPath = Split-Path -Parent $scriptPath
}

# Cambiar a la carpeta del backend
Set-Location $backendPath

# Liberar puerto 3000 si está ocupado
Write-Host "Verificando puerto 3000..." -ForegroundColor Yellow
try {
    $port3000 = Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue
    if ($null -ne $port3000 -and $port3000.Count -gt 0) {
        $pids = $port3000 | Select-Object -ExpandProperty OwningProcess -Unique
        Write-Host "Liberando puerto 3000..." -ForegroundColor Yellow
        foreach ($pid in $pids) {
            try {
                Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
            } catch {
                # Ignorar errores
            }
        }
        Start-Sleep -Seconds 2
        Write-Host "Puerto 3000 liberado" -ForegroundColor Green
    } else {
        Write-Host "Puerto 3000 está libre" -ForegroundColor Green
    }
} catch {
    Write-Host "No se pudo verificar el puerto, continuando..." -ForegroundColor Yellow
}

# Iniciar backend
Write-Host "Iniciando backend..." -ForegroundColor Cyan
npm run dev
