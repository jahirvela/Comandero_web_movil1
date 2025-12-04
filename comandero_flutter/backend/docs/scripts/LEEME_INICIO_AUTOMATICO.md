# 🚀 Inicio Automático del Backend

## 📋 ¿Qué hace esto?

Los scripts de inicio automático se encargan de:
- ✅ Verificar que MySQL esté corriendo
- ✅ Liberar el puerto 3000 automáticamente si está ocupado
- ✅ Verificar/instalar dependencias npm
- ✅ Iniciar el backend sin intervención manual

---

## 🎯 Opciones de Inicio

### Opción 1: Comando npm (Más Rápido) ⭐ Recomendado

```powershell
cd comandero_flutter\backend
npm run dev:auto
```

**Ventajas:**
- ✅ Más rápido
- ✅ Libera el puerto automáticamente
- ✅ No requiere navegar a la carpeta scripts

**Qué hace:**
- Libera el puerto 3000 si está ocupado
- Inicia el backend

---

### Opción 2: Script Completo (Con Verificaciones)

```powershell
cd comandero_flutter\backend\scripts
.\iniciar-backend.ps1
```

**Ventajas:**
- ✅ Verifica MySQL antes de iniciar
- ✅ Verifica dependencias npm
- ✅ Instala dependencias si faltan
- ✅ Libera el puerto automáticamente
- ✅ Muestra mensajes informativos

**Cuándo usarlo:**
- Primera vez que ejecutas el proyecto
- Cuando quieres verificar que todo esté listo
- Cuando tienes dudas sobre la configuración

---

### Opción 3: Script Simple (Solo Libera Puerto)

```powershell
cd comandero_flutter\backend\scripts
.\iniciar-backend-simple.ps1
```

**Ventajas:**
- ✅ Rápido
- ✅ Solo libera el puerto e inicia

**Cuándo usarlo:**
- Cuando ya sabes que todo está configurado
- Cuando solo necesitas liberar el puerto e iniciar

---

### Opción 4: Manual (Control Total)

```powershell
cd comandero_flutter\backend
npm run dev
```

**Cuándo usarlo:**
- Cuando el puerto 3000 ya está libre
- Cuando prefieres control manual

**Si el puerto está ocupado:**
```powershell
cd scripts
.\cerrar-proceso-puerto-3000.ps1
cd ..
npm run dev
```

---

## 🔄 Flujo Recomendado

### Para Desarrollo Diario:

```powershell
cd comandero_flutter\backend
npm run dev:auto
```

**Esto es todo.** El script se encarga de todo automáticamente.

---

### Para Primera Vez o Verificación:

```powershell
cd comandero_flutter\backend\scripts
.\iniciar-backend.ps1
```

Esto verifica todo antes de iniciar.

---

## ✅ Ventajas del Inicio Automático

1. **No necesitas verificar el puerto manualmente**
   - El script lo hace automáticamente

2. **No necesitas cerrar procesos manualmente**
   - El script cierra procesos en el puerto 3000 automáticamente

3. **Verificaciones automáticas**
   - MySQL, dependencias, puerto, todo verificado

4. **Mensajes claros**
   - Sabes exactamente qué está pasando

---

## 🐛 Solución de Problemas

### "No se puede ejecutar scripts en este sistema"

**Solución:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "El puerto sigue ocupado después de liberarlo"

**Solución:**
1. Espera 2-3 segundos y vuelve a intentar
2. O reinicia tu computadora
3. O cambia el puerto en `.env` a otro (ej: 3001)

### "MySQL no inicia"

**Solución:**
```powershell
cd comandero_flutter\backend\scripts
.\configurar-mysql-automatico.ps1
```

*(Requiere permisos de Administrador)*

---

## 📝 Notas

- **Todos los scripts** pueden ejecutarse sin permisos de administrador (excepto `configurar-mysql-automatico.ps1`)
- Los scripts **no afectan** otros procesos que no estén usando el puerto 3000
- El script **solo cierra procesos** en el puerto 3000, no otros puertos

---

## 🎯 Resumen

**Para uso diario:**
```powershell
cd comandero_flutter\backend
npm run dev:auto
```

**¡Eso es todo!** El backend se iniciará automáticamente sin problemas. 🚀

---

**Última actualización:** 2024-01-15

