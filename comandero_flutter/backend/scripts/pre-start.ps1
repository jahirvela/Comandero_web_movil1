# Script pre-inicio: Libera puerto automáticamente
# Se ejecuta automáticamente antes de npm run dev

# Obtener la ruta del script actual
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $scriptPath) {
    $scriptPath = $PSScriptRoot
}

# Obtener la ruta del backend (carpeta padre de scripts)
$backendPath = Join-Path $scriptPath ".."
$backendPath = (Resolve-Path $backendPath).Path

# Cambiar a la carpeta del backend
Set-Location $backendPath

# Liberar puerto 3000 si está ocupado
try {
    $connections = Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue
    if ($connections) {
        $pids = $connections | Select-Object -ExpandProperty OwningProcess -Unique
        foreach ($pid in $pids) {
            try {
                $process = Get-Process -Id $pid -ErrorAction SilentlyContinue
                if ($process) {
                    Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
                }
            } catch {
                # Ignorar errores
            }
        }
        Start-Sleep -Milliseconds 500
    }
} catch {
    # Ignorar errores
}
