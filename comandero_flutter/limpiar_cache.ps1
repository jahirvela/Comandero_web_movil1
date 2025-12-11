# Script para limpiar el cache del navegador
# Ejecuta este script como administrador para limpiar completamente el cache

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host ""
Write-Host "Limpiando cache del navegador..." -ForegroundColor Cyan

# Funcion para limpiar cache de Chrome
function LimpiarChromeCache {
    Write-Host ""
    Write-Host "Limpiando cache de Google Chrome..." -ForegroundColor Yellow
    
    $chromeCachePaths = @(
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache",
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\GPUCache",
        "$env:LOCALAPPDATA\Google\Chrome\User Data\ShaderCache"
    )
    
    foreach ($path in $chromeCachePaths) {
        if (Test-Path $path) {
            try {
                Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "   [OK] Limpiado: $path" -ForegroundColor Green
            } catch {
                Write-Host "   [ADVERTENCIA] No se pudo limpiar: $path (puede estar en uso)" -ForegroundColor Yellow
            }
        }
    }
}

# Funcion para limpiar cache de Edge
function LimpiarEdgeCache {
    Write-Host ""
    Write-Host "Limpiando cache de Microsoft Edge..." -ForegroundColor Yellow
    
    $edgeCachePaths = @(
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\GPUCache",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\ShaderCache"
    )
    
    foreach ($path in $edgeCachePaths) {
        if (Test-Path $path) {
            try {
                Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "   [OK] Limpiado: $path" -ForegroundColor Green
            } catch {
                Write-Host "   [ADVERTENCIA] No se pudo limpiar: $path (puede estar en uso)" -ForegroundColor Yellow
            }
        }
    }
}

# Funcion para limpiar Local Storage y Session Storage (si es posible)
function LimpiarLocalStorage {
    Write-Host ""
    Write-Host "Limpiando datos de almacenamiento local..." -ForegroundColor Yellow
    
    # Chrome
    $chromeLocalStorage = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Local Storage"
    if (Test-Path $chromeLocalStorage) {
        try {
            Get-ChildItem -Path $chromeLocalStorage -Filter "*localhost*" -Recurse | Remove-Item -Force -ErrorAction SilentlyContinue
            Write-Host "   [OK] Limpiado Local Storage de Chrome (localhost)" -ForegroundColor Green
        } catch {
            Write-Host "   [ADVERTENCIA] No se pudo limpiar Local Storage de Chrome" -ForegroundColor Yellow
        }
    }
    
    # Edge
    $edgeLocalStorage = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Local Storage"
    if (Test-Path $edgeLocalStorage) {
        try {
            Get-ChildItem -Path $edgeLocalStorage -Filter "*localhost*" -Recurse | Remove-Item -Force -ErrorAction SilentlyContinue
            Write-Host "   [OK] Limpiado Local Storage de Edge (localhost)" -ForegroundColor Green
        } catch {
            Write-Host "   [ADVERTENCIA] No se pudo limpiar Local Storage de Edge" -ForegroundColor Yellow
        }
    }
}

# Cerrar navegadores si estan abiertos
Write-Host ""
Write-Host "Cerrando navegadores..." -ForegroundColor Yellow
try {
    Get-Process chrome -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
    Write-Host "   [OK] Chrome cerrado" -ForegroundColor Green
} catch {
    Write-Host "   [INFO] Chrome no estaba abierto" -ForegroundColor Gray
}

try {
    Get-Process msedge -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
    Write-Host "   [OK] Edge cerrado" -ForegroundColor Green
} catch {
    Write-Host "   [INFO] Edge no estaba abierto" -ForegroundColor Gray
}

# Esperar un momento
Start-Sleep -Seconds 2

# Limpiar caches
LimpiarChromeCache
LimpiarEdgeCache
LimpiarLocalStorage

Write-Host ""
Write-Host "[EXITO] Cache limpiado exitosamente!" -ForegroundColor Green
Write-Host ""
Write-Host "Consejo: Abre el navegador en modo incognito para evitar problemas de cache durante desarrollo" -ForegroundColor Cyan
Write-Host "   Chrome: Ctrl + Shift + N" -ForegroundColor Gray
Write-Host "   Edge: Ctrl + Shift + N" -ForegroundColor Gray

Write-Host ""
Write-Host "Presiona cualquier tecla para continuar..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
