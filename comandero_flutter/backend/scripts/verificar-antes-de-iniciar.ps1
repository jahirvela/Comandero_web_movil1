# Script de verificación previa antes de iniciar el backend
# Verifica MySQL, puerto 3000, archivo .env, etc.

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Verificación Previa - Backend Comandix" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$errores = @()
$advertencias = @()

# 1. Verificar MySQL
Write-Host "1. Verificando MySQL81..." -ForegroundColor Yellow
try {
    $mysql = Get-Service -Name MySQL81 -ErrorAction Stop
    if ($mysql.Status -eq 'Running') {
        Write-Host "   ✅ MySQL81 está corriendo" -ForegroundColor Green
    } else {
        Write-Host "   ❌ MySQL81 NO está corriendo (Estado: $($mysql.Status))" -ForegroundColor Red
        $errores += "MySQL81 no está corriendo"
    }
    
    if ($mysql.StartType -ne 'Automatic') {
        Write-Host "   ⚠️  MySQL81 no está configurado como automático" -ForegroundColor Yellow
        $advertencias += "MySQL81 no está configurado como automático"
    }
} catch {
    Write-Host "   ❌ No se encontró el servicio MySQL81" -ForegroundColor Red
    $errores += "MySQL81 no está instalado o no se encontró"
}
Write-Host ""

# 2. Verificar puerto 3000
Write-Host "2. Verificando puerto 3000..." -ForegroundColor Yellow
$port3000 = Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue
if ($null -ne $port3000 -and $port3000.Count -gt 0) {
    $pids = $port3000 | Select-Object -ExpandProperty OwningProcess -Unique
    Write-Host "   ⚠️  El puerto 3000 está en uso por:" -ForegroundColor Yellow
    foreach ($pid in $pids) {
        try {
            $proc = Get-Process -Id $pid -ErrorAction Stop
            Write-Host "      PID $pid - $($proc.ProcessName)" -ForegroundColor Yellow
        } catch {
            Write-Host "      PID $pid (proceso no encontrado)" -ForegroundColor Yellow
        }
    }
    Write-Host "   💡 Para liberar el puerto, ejecuta: .\liberar-puerto-3000.ps1" -ForegroundColor Cyan
    $advertencias += "Puerto 3000 en uso"
} else {
    Write-Host "   ✅ Puerto 3000 está libre" -ForegroundColor Green
}
Write-Host ""

# 3. Verificar archivo .env
Write-Host "3. Verificando archivo .env..." -ForegroundColor Yellow
$envPath = Join-Path $PSScriptRoot "..\\.env"
if (Test-Path $envPath) {
    Write-Host "   ✅ Archivo .env existe" -ForegroundColor Green
    
    # Verificar variables críticas
    $envContent = Get-Content $envPath -Raw
    $requiredVars = @(
        'DATABASE_HOST',
        'DATABASE_USER',
        'DATABASE_PASSWORD',
        'DATABASE_NAME',
        'JWT_ACCESS_SECRET',
        'JWT_REFRESH_SECRET'
    )
    
    $missingVars = @()
    foreach ($var in $requiredVars) {
        if ($envContent -notmatch "$var\s*=") {
            $missingVars += $var
        }
    }
    
    if ($missingVars.Count -gt 0) {
        Write-Host "   ⚠️  Faltan variables en .env:" -ForegroundColor Yellow
        foreach ($var in $missingVars) {
            Write-Host "      - $var" -ForegroundColor Yellow
        }
        $advertencias += "Variables faltantes en .env"
    } else {
        Write-Host "   ✅ Variables críticas presentes en .env" -ForegroundColor Green
    }
} else {
    Write-Host "   ❌ Archivo .env NO existe" -ForegroundColor Red
    Write-Host "   💡 Crea el archivo .env basándote en .env.example" -ForegroundColor Cyan
    $errores += "Archivo .env no existe"
}
Write-Host ""

# 4. Verificar Node.js
Write-Host "4. Verificando Node.js..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version
    Write-Host "   ✅ Node.js instalado: $nodeVersion" -ForegroundColor Green
    
    # Verificar versión mínima (20.0.0)
    $versionNumber = [int]($nodeVersion -replace 'v(\d+)\..*', '$1')
    if ($versionNumber -lt 20) {
        Write-Host "   ⚠️  Se recomienda Node.js 20 o superior" -ForegroundColor Yellow
        $advertencias += "Node.js versión antigua"
    }
} catch {
    Write-Host "   ❌ Node.js no está instalado o no está en PATH" -ForegroundColor Red
    $errores += "Node.js no encontrado"
}
Write-Host ""

# 5. Verificar dependencias npm
Write-Host "5. Verificando dependencias npm..." -ForegroundColor Yellow
$packageJsonPath = Join-Path $PSScriptRoot "..\package.json"
$nodeModulesPath = Join-Path $PSScriptRoot "..\node_modules"
if (Test-Path $packageJsonPath) {
    if (Test-Path $nodeModulesPath) {
        Write-Host "   ✅ node_modules existe" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  node_modules no existe. Ejecuta: npm install" -ForegroundColor Yellow
        $advertencias += "Dependencias npm no instaladas"
    }
} else {
    Write-Host "   ⚠️  package.json no encontrado" -ForegroundColor Yellow
    $advertencias += "package.json no encontrado"
}
Write-Host ""

# Resumen
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Resumen" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($errores.Count -eq 0 -and $advertencias.Count -eq 0) {
    Write-Host "✅ Todo está listo para iniciar el backend" -ForegroundColor Green
    Write-Host ""
    Write-Host "Para iniciar, ejecuta:" -ForegroundColor Cyan
    Write-Host "   npm run dev" -ForegroundColor White
    exit 0
} elseif ($errores.Count -eq 0) {
    Write-Host "⚠️  Hay $($advertencias.Count) advertencia(s), pero puedes intentar iniciar" -ForegroundColor Yellow
    Write-Host ""
    foreach ($adv in $advertencias) {
        Write-Host "   - $adv" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "Para iniciar, ejecuta:" -ForegroundColor Cyan
    Write-Host "   npm run dev" -ForegroundColor White
    exit 0
} else {
    Write-Host "❌ Hay $($errores.Count) error(es) que debes corregir antes de iniciar:" -ForegroundColor Red
    Write-Host ""
    foreach ($err in $errores) {
        Write-Host "   - $err" -ForegroundColor Red
    }
    Write-Host ""
    if ($advertencias.Count -gt 0) {
        Write-Host "Advertencias adicionales:" -ForegroundColor Yellow
        foreach ($adv in $advertencias) {
            Write-Host "   - $adv" -ForegroundColor Yellow
        }
        Write-Host ""
    }
    exit 1
}

