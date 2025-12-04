# Script para programar backups automáticos en Windows usando Task Scheduler
# Ejecuta backups diarios de la base de datos

$scriptPath = Join-Path $PSScriptRoot "backup-periodico.ts"
$nodePath = (Get-Command node).Source
$projectRoot = Split-Path -Parent $PSScriptRoot

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "PROGRAMAR BACKUPS AUTOMÁTICOS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar que Node.js está instalado
if (-not $nodePath) {
    Write-Host "❌ Node.js no está instalado o no está en el PATH" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Node.js encontrado: $nodePath" -ForegroundColor Green
Write-Host ""

# Nombre de la tarea programada
$taskName = "Comandero_Backup_Diario"

# Verificar si la tarea ya existe
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($existingTask) {
    Write-Host "⚠️  La tarea '$taskName' ya existe" -ForegroundColor Yellow
    $response = Read-Host "¿Deseas eliminarla y crear una nueva? (s/n)"
    if ($response -eq "s" -or $response -eq "S") {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Write-Host "✅ Tarea anterior eliminada" -ForegroundColor Green
    } else {
        Write-Host "❌ Operación cancelada" -ForegroundColor Red
        exit 0
    }
}

# Crear acción (ejecutar el script de backup)
$action = New-ScheduledTaskAction -Execute $nodePath `
    -Argument "npx tsx `"$scriptPath`"" `
    -WorkingDirectory $projectRoot

# Crear trigger (diario a las 2:00 AM)
$trigger = New-ScheduledTaskTrigger -Daily -At "2:00AM"

# Configuración de la tarea
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable:$false

# Crear la tarea
try {
    Register-ScheduledTask `
        -TaskName $taskName `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Description "Backup diario automático de la base de datos Comandero" `
        -User "SYSTEM" `
        -RunLevel Highest

    Write-Host "✅ Tarea programada creada exitosamente" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Detalles de la tarea:" -ForegroundColor Cyan
    Write-Host "   Nombre: $taskName"
    Write-Host "   Frecuencia: Diario"
    Write-Host "   Hora: 2:00 AM"
    Write-Host "   Script: $scriptPath"
    Write-Host ""
    Write-Host "💡 Para verificar la tarea, ejecuta:" -ForegroundColor Yellow
    Write-Host "   Get-ScheduledTask -TaskName '$taskName'"
    Write-Host ""
    Write-Host "💡 Para eliminar la tarea, ejecuta:" -ForegroundColor Yellow
    Write-Host "   Unregister-ScheduledTask -TaskName '$taskName' -Confirm:`$false"
    
} catch {
    Write-Host "❌ Error al crear la tarea programada: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "⚠️  Nota: Puede que necesites ejecutar PowerShell como Administrador" -ForegroundColor Yellow
    exit 1
}

