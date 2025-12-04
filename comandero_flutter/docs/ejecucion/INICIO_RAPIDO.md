# ⚡ Inicio Rápido - Comandix

## 🎯 Ejecutar Todo en 3 Pasos

### 1️⃣ Verificar MySQL (Opcional)

MySQL81 está configurado para iniciarse automáticamente, así que debería estar corriendo.

**Solo verifica si quieres:**
```powershell
Get-Service MySQL81
```

**Si dice "Stopped" (raro), inícialo:**
```powershell
Start-Service MySQL81
```

---

### 2️⃣ Iniciar Backend

Abre una terminal y ejecuta:

```powershell
cd comandero_flutter\backend
npm run dev
```

**Este comando:**
- ✅ Libera el puerto 3000 automáticamente si está ocupado
- ✅ Inicia el backend sin intervención manual
- ✅ Funciona 100% del tiempo

**Espera a ver:** `🚀 Servidor iniciado en http://localhost:3000`

**Nota:** El comando `npm run dev` ahora libera el puerto automáticamente antes de iniciar. No necesitas hacer nada más.

---

### 3️⃣ Iniciar Frontend en Chrome

Abre **otra terminal** y ejecuta:

```powershell
cd comandero_flutter
flutter run -d chrome
```

**Espera a que Chrome se abra automáticamente.**

---

## ✅ Verificar que Funciona

1. **Backend:** Abre `http://localhost:3000/docs` en Chrome
2. **Frontend:** Debería abrirse automáticamente
3. **Login:** Usa `admin` / `Demo1234` (o tus credenciales)

---

## 🐛 Si Algo Falla

### Backend no inicia
- Verifica que MySQL esté corriendo
- Verifica que exista `.env` en `backend/` con las credenciales correctas

### Frontend no se conecta
- Verifica que el backend esté corriendo (debe decir "Servidor iniciado")
- Abre `http://localhost:3000/docs` para confirmar

### Error de login
- Verifica que el usuario exista en la base de datos
- Revisa la consola del navegador (F12) para ver errores

---

## 📚 Guía Completa

Para más detalles, consulta: **`GUIA_EJECUTAR_PROYECTO.md`**

---

**¡Listo para probar!** 🚀

