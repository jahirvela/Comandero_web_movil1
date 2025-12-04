# 🛠️ Scripts Útiles - Backend Comandix

Esta carpeta contiene scripts útiles para gestionar el backend.

---

## 📋 Scripts Disponibles

### 1. `verificar-antes-de-iniciar.ps1`

**¿Qué hace?**
Verifica que todo esté listo antes de iniciar el backend:
- MySQL está corriendo
- Puerto 3000 está libre
- Archivo `.env` existe y tiene las variables necesarias
- Node.js está instalado
- Dependencias npm están instaladas

**Cómo usarlo:**
```powershell
.\verificar-antes-de-iniciar.ps1
```

**Cuándo usarlo:**
- Antes de iniciar el backend por primera vez
- Cuando tengas errores al iniciar
- Para verificar la configuración

---

### 2. `cerrar-proceso-puerto-3000.ps1`

**¿Qué hace?**
Cierra automáticamente cualquier proceso que esté usando el puerto 3000.

**Cómo usarlo:**
```powershell
.\cerrar-proceso-puerto-3000.ps1
```

**Cuándo usarlo:**
- Cuando veas el error: `EADDRINUSE: address already in use :::3000`
- Cuando el backend no pueda iniciar porque el puerto está ocupado

---

### 3. `liberar-puerto-3000.ps1`

**¿Qué hace?**
Versión interactiva del script anterior. Te muestra qué procesos están usando el puerto y te pregunta si quieres cerrarlos.

**Cómo usarlo:**
```powershell
.\liberar-puerto-3000.ps1
```

**Cuándo usarlo:**
- Cuando quieras ver qué proceso está usando el puerto antes de cerrarlo
- Cuando prefieras tener control sobre qué procesos cerrar

---

### 4. `verificar-mysql-automatico.ps1`

**¿Qué hace?**
Verifica que MySQL81 esté configurado para inicio automático y corriendo.

**Cómo usarlo:**
```powershell
.\verificar-mysql-automatico.ps1
```

**Cuándo usarlo:**
- Para verificar el estado de MySQL
- Cuando tengas problemas de conexión a la base de datos

---

### 5. `configurar-mysql-automatico.ps1`

**¿Qué hace?**
Configura MySQL81 para que se inicie automáticamente cuando Windows inicia.

**Cómo usarlo:**
```powershell
# Como Administrador
.\configurar-mysql-automatico.ps1
```

**Cuándo usarlo:**
- La primera vez que configures el proyecto
- Si MySQL no se inicia automáticamente

**⚠️ Requiere permisos de Administrador**

---

### 6. `iniciar-mysql.ps1`

**¿Qué hace?**
Inicia el servicio MySQL81 manualmente.

**Cómo usarlo:**
```powershell
.\iniciar-mysql.ps1
```

**Cuándo usarlo:**
- Si MySQL se detuvo y necesitas iniciarlo manualmente
- Si MySQL no está configurado como automático

---

## 🚀 Flujo Recomendado

### Primera vez que ejecutas el proyecto:

1. **Verificar MySQL:**
   ```powershell
   .\verificar-mysql-automatico.ps1
   ```

2. **Configurar MySQL como automático (si no está):**
   ```powershell
   .\configurar-mysql-automatico.ps1
   ```

3. **Verificar todo antes de iniciar:**
   ```powershell
   .\verificar-antes-de-iniciar.ps1
   ```

4. **Si hay problemas con el puerto 3000:**
   ```powershell
   .\cerrar-proceso-puerto-3000.ps1
   ```

5. **Iniciar el backend:**
   ```powershell
   cd ..
   npm run dev
   ```

### Cuando tengas el error "Puerto 3000 en uso":

```powershell
.\cerrar-proceso-puerto-3000.ps1
```

Luego intenta iniciar el backend de nuevo.

---

## 💡 Tips

- **Todos los scripts** (excepto `configurar-mysql-automatico.ps1`) pueden ejecutarse sin permisos de administrador
- Si un script no funciona, verifica que estés en la carpeta `scripts`
- Los scripts te darán mensajes claros sobre qué hacer si hay problemas

---

## 🐛 Solución de Problemas

### "No se puede ejecutar scripts en este sistema"

**Solución:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "Acceso denegado" al cerrar procesos

**Solución:**
Algunos procesos pueden requerir permisos de administrador. Ejecuta PowerShell como Administrador.

---

**Última actualización:** 2024-01-15

