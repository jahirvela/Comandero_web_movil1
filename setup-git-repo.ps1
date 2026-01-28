# Script para configurar el repositorio Git y hacer commit inicial
# Ejecutar desde PowerShell: .\setup-git-repo.ps1

Write-Host "=== Configuración del Repositorio Git ===" -ForegroundColor Cyan

# Verificar si git está instalado
try {
    $gitVersion = git --version
    Write-Host "Git encontrado: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Git no está instalado. Por favor instala Git primero." -ForegroundColor Red
    exit 1
}

# Cambiar al directorio del proyecto
Set-Location "c:\Users\Jahir VS\comandero_web_movil"

# Inicializar repositorio si no existe
if (-not (Test-Path .git)) {
    Write-Host "Inicializando repositorio Git..." -ForegroundColor Yellow
    git init
} else {
    Write-Host "Repositorio Git ya existe" -ForegroundColor Green
}

# Configurar usuario de Git (si no está configurado)
$gitUser = git config user.name
if (-not $gitUser) {
    Write-Host "Configurando usuario de Git..." -ForegroundColor Yellow
    git config user.name "Jahir VS"
    git config user.email "tu-email@ejemplo.com"
    Write-Host "Por favor actualiza el email con: git config user.email 'tu-email@ejemplo.com'" -ForegroundColor Yellow
}

# Agregar archivos (solo comandero_flutter)
Write-Host "Agregando archivos al staging..." -ForegroundColor Yellow
git add .gitignore
git add README.md
git add comandero_flutter/

# Verificar estado
Write-Host "`nEstado del repositorio:" -ForegroundColor Cyan
git status --short

# Crear commit inicial
Write-Host "`nCreando commit inicial..." -ForegroundColor Yellow
$commitMessage = @"
Configuración inicial del repositorio

- Configurado .gitignore para incluir solo comandero_flutter
- Agregado script SQL completo de la base de datos
- Actualizado .gitignore para excluir archivos temporales y binarios
- Creado README.md con instrucciones de instalación
"@

git commit -m $commitMessage

Write-Host "`n✅ Commit creado exitosamente" -ForegroundColor Green

# Verificar si hay un remoto configurado
$remote = git remote -v
if ($remote) {
    Write-Host "`nRemoto configurado:" -ForegroundColor Cyan
    Write-Host $remote
    
    Write-Host "`n¿Deseas hacer push al repositorio remoto? (S/N)" -ForegroundColor Yellow
    $response = Read-Host
    if ($response -eq "S" -or $response -eq "s") {
        Write-Host "Haciendo push..." -ForegroundColor Yellow
        git push -u origin main
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Push completado exitosamente" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Error al hacer push. Verifica la configuración del remoto." -ForegroundColor Yellow
            Write-Host "Para configurar el remoto manualmente:" -ForegroundColor Yellow
            Write-Host "  git remote add origin <URL_DEL_REPOSITORIO>" -ForegroundColor Yellow
            Write-Host "  git branch -M main" -ForegroundColor Yellow
            Write-Host "  git push -u origin main" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "`n⚠️ No hay remoto configurado" -ForegroundColor Yellow
    Write-Host "Para agregar un remoto y hacer push:" -ForegroundColor Yellow
    Write-Host "  git remote add origin <URL_DEL_REPOSITORIO>" -ForegroundColor Yellow
    Write-Host "  git branch -M main" -ForegroundColor Yellow
    Write-Host "  git push -u origin main" -ForegroundColor Yellow
}

Write-Host "`n=== Configuración completada ===" -ForegroundColor Cyan
