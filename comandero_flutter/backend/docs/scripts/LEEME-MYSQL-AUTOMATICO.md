# 🔧 Configurar MySQL81 para Inicio Automático

## 📋 ¿Qué hace esto?

Configura el servicio MySQL81 para que se inicie automáticamente cada vez que Windows inicia, sin necesidad de iniciarlo manualmente.

---

## 🚀 Opción 1: Ejecutar Script Automático (Recomendado)

### Paso 1: Abrir PowerShell como Administrador

1. **Presiona `Win + X`** (o clic derecho en el botón de Inicio)
2. **Selecciona "Windows PowerShell (Administrador)"** o **"Terminal (Administrador)"**
3. **Confirma** el aviso de Control de Cuentas de Usuario (UAC)

### Paso 2: Navegar a la Carpeta

```powershell
cd "C:\Users\Jahir VS\comandero_web_movil\comandero_flutter\backend\scripts"
```

### Paso 3: Ejecutar el Script

```powershell
.\configurar-mysql-automatico.ps1
```

**El script hará:**
- ✅ Configurará MySQL81 para inicio automático
- ✅ Iniciará el servicio ahora mismo
- ✅ Te mostrará el estado final

---

## 🚀 Opción 2: Comando Manual

Si prefieres hacerlo manualmente, ejecuta estos comandos en PowerShell como Administrador:

```powershell
# Configurar inicio automático
Set-Service -Name MySQL81 -StartupType Automatic

# Iniciar el servicio ahora
Start-Service -Name MySQL81

# Verificar estado
Get-Service -Name MySQL81
```

---

## ✅ Verificar que Funcionó

Después de ejecutar el script, verifica:

```powershell
Get-Service -Name MySQL81
```

**Debes ver:**
- **Status**: `Running`
- **StartType**: `Automatic`

---

## 🔄 Script Rápido para Iniciar MySQL

Si necesitas iniciar MySQL manualmente (sin reiniciar Windows), usa:

```powershell
cd "C:\Users\Jahir VS\comandero_web_movil\comandero_flutter\backend\scripts"
.\iniciar-mysql.ps1
```

Este script **NO requiere permisos de administrador** si el servicio ya está configurado.

---

## 🐛 Solución de Problemas

### Error: "Acceso denegado"
**Causa:** No tienes permisos de administrador.

**Solución:** Ejecuta PowerShell como Administrador (ver Opción 1, Paso 1).

### Error: "El servicio MySQL81 no existe"
**Causa:** MySQL no está instalado o el servicio tiene otro nombre.

**Solución:** 
1. Verifica el nombre del servicio:
   ```powershell
   Get-Service | Where-Object {$_.Name -like "*mysql*"}
   ```
2. Si el nombre es diferente (ej: `MySQL80`), reemplaza `MySQL81` por el nombre correcto en los comandos.

### Error: "No se puede iniciar el servicio"
**Causa:** El servicio está detenido o hay un problema con MySQL.

**Solución:**
1. Revisa los logs de MySQL en: `C:\ProgramData\MySQL\MySQL Server 8.0\Data\*.err`
2. Intenta reparar MySQL desde el MySQL Installer

---

## 📝 Notas Importantes

- ⚠️ **Después de configurar como automático**, MySQL se iniciará cada vez que Windows inicie.
- ⚠️ Esto consume recursos, pero es necesario para que el backend funcione.
- ✅ Si no quieres que se inicie automáticamente, puedes cambiarlo a "Manual":
  ```powershell
  Set-Service -Name MySQL81 -StartupType Manual
  ```

---

## 🎯 Resultado Esperado

Una vez configurado, **no necesitarás iniciar MySQL manualmente nunca más**. El servicio estará disponible automáticamente cuando:
- ✅ Windows inicia
- ✅ Reinicias tu computadora
- ✅ El servicio se detiene por alguna razón y Windows lo reinicia

**Tu backend podrá conectarse a MySQL sin problemas.** 🚀

