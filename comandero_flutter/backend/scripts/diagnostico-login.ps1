# Script de diagnóstico para problemas de login
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Diagnóstico de Login" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Verificar que el backend esté corriendo
Write-Host "1. Verificando backend..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000/api/health" -Method GET -TimeoutSec 5 -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "   ✅ Backend está corriendo" -ForegroundColor Green
        Write-Host "   Respuesta: $($response.Content)" -ForegroundColor Gray
    }
} catch {
    Write-Host "   ❌ Backend NO está corriendo" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "   💡 Solución: Inicia el backend con:" -ForegroundColor Yellow
    Write-Host "      cd comandero_flutter\backend" -ForegroundColor Gray
    Write-Host "      npm run dev" -ForegroundColor Gray
    exit 1
}
Write-Host ""

# 2. Verificar que el usuario admin exista
Write-Host "2. Verificando usuario admin..." -ForegroundColor Yellow
try {
    $loginResponse = Invoke-WebRequest -Uri "http://localhost:3000/api/auth/login" -Method POST -ContentType "application/json" -Body '{"username":"admin","password":"Demo1234"}' -TimeoutSec 5 -ErrorAction Stop
    if ($loginResponse.StatusCode -eq 200) {
        Write-Host "   ✅ Login funciona correctamente" -ForegroundColor Green
        $data = $loginResponse.Content | ConvertFrom-Json
        Write-Host "   Usuario: $($data.user.username)" -ForegroundColor Gray
        Write-Host "   Roles: $($data.user.roles -join ', ')" -ForegroundColor Gray
    }
} catch {
    if ($_.Exception.Response) {
        $statusCode = [int]$_.Exception.Response.StatusCode.value__
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        
        if ($statusCode -eq 401) {
            Write-Host "   ❌ Credenciales incorrectas" -ForegroundColor Red
            Write-Host "   💡 Solución: Ejecuta:" -ForegroundColor Yellow
            Write-Host "      cd comandero_flutter\backend" -ForegroundColor Gray
            Write-Host "      node scripts/crear-usuario-admin.cjs" -ForegroundColor Gray
        } else {
            Write-Host "   ❌ Error en login: $statusCode" -ForegroundColor Red
            Write-Host "   Respuesta: $responseBody" -ForegroundColor Gray
        }
    } else {
        Write-Host "   ❌ Error de conexión: $($_.Exception.Message)" -ForegroundColor Red
    }
}
Write-Host ""

# 3. Verificar CORS
Write-Host "3. Verificando CORS..." -ForegroundColor Yellow
try {
    $headers = @{
        "Origin" = "http://localhost"
        "Access-Control-Request-Method" = "POST"
        "Access-Control-Request-Headers" = "Content-Type"
    }
    $corsResponse = Invoke-WebRequest -Uri "http://localhost:3000/api/auth/login" -Method OPTIONS -Headers $headers -TimeoutSec 5 -ErrorAction Stop
    Write-Host "   ✅ CORS configurado correctamente" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️  No se pudo verificar CORS (puede ser normal)" -ForegroundColor Yellow
}
Write-Host ""

# 4. Verificar MySQL
Write-Host "4. Verificando MySQL..." -ForegroundColor Yellow
try {
    $mysql = Get-Service -Name MySQL81 -ErrorAction Stop
    if ($mysql.Status -eq 'Running') {
        Write-Host "   ✅ MySQL está corriendo" -ForegroundColor Green
    } else {
        Write-Host "   ❌ MySQL NO está corriendo" -ForegroundColor Red
        Write-Host "   💡 Solución: Inicia MySQL con:" -ForegroundColor Yellow
        Write-Host "      Start-Service MySQL81" -ForegroundColor Gray
    }
} catch {
    Write-Host "   ⚠️  No se pudo verificar MySQL" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Diagnóstico completado" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

