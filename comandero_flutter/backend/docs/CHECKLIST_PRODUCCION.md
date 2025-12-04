# ✅ Checklist de Producción - Comandero

Este checklist debe completarse antes de desplegar el sistema en producción.

## 📋 Pre-Deployment

### Configuración del Entorno

- [ ] Archivo `.env` creado y configurado
- [ ] `NODE_ENV=production` configurado
- [ ] `JWT_ACCESS_SECRET` generado con al menos 32 caracteres
- [ ] `JWT_REFRESH_SECRET` generado con al menos 32 caracteres
- [ ] `CORS_ORIGIN` configurado solo con dominios de producción
- [ ] `LOG_LEVEL` configurado como `info` o `warn`
- [ ] `LOG_PRETTY=false` para producción
- [ ] Variables de base de datos configuradas correctamente

### Base de Datos

- [ ] Base de datos creada
- [ ] Usuario de base de datos creado (no usar root)
- [ ] Permisos del usuario configurados correctamente
- [ ] Migraciones ejecutadas: `npm run migrate:full`
- [ ] Usuario administrador creado: `npm run create-admin`
- [ ] Backup inicial creado: `npm run backup:database`

### Backend

- [ ] Dependencias instaladas: `npm install`
- [ ] Proyecto compilado: `npm run build`
- [ ] Verificación ejecutada: `npm run verify:production`
- [ ] PM2 configurado (si se usa): `ecosystem.config.js` revisado
- [ ] Logs configurados: directorio `logs/` creado
- [ ] Rate limiting configurado correctamente
- [ ] Helmet configurado (ya incluido)
- [ ] Error handling verificado

### Frontend

- [ ] `ApiConfig` actualizado con URL de producción
- [ ] `API_ENV=production` configurado al compilar
- [ ] `API_URL` configurado con dominio de producción
- [ ] Proyecto compilado: `flutter build web --release`
- [ ] Variables de entorno configuradas (si aplica)

### Seguridad

- [ ] HTTPS configurado en el servidor web (Nginx/Apache)
- [ ] Certificado SSL válido instalado
- [ ] Firewall configurado (solo puertos necesarios)
- [ ] Rate limiting activado y configurado
- [ ] CORS restringido a dominios permitidos
- [ ] Secretos JWT no expuestos en código
- [ ] Variables de entorno no en el repositorio
- [ ] `.env` en `.gitignore`

### Backups

- [ ] Sistema de backups automáticos configurado
- [ ] Backups programados (diarios recomendado)
- [ ] Ruta de backups configurada
- [ ] Retención de backups configurada (mínimo 7 días)
- [ ] Proceso de restauración documentado y probado

### Monitoreo

- [ ] PM2 configurado con auto-restart
- [ ] Logs configurados y rotación activada
- [ ] Monitoreo de recursos configurado (opcional)
- [ ] Alertas configuradas (opcional)

### Red y Servidor

- [ ] Puerto 3000 (o el configurado) abierto en firewall
- [ ] Puerto de base de datos (3306) solo accesible localmente
- [ ] Proxy reverso configurado (Nginx/Apache) si aplica
- [ ] Dominio DNS configurado apuntando al servidor
- [ ] Certificado SSL instalado y renovación automática configurada

## 🚀 Deployment

### Proceso de Deployment

1. [ ] Código actualizado: `git pull`
2. [ ] Dependencias actualizadas: `npm install`
3. [ ] Backup de base de datos creado
4. [ ] Migraciones aplicadas (si hay nuevas)
5. [ ] Proyecto compilado: `npm run build`
6. [ ] Verificación ejecutada: `npm run verify:production`
7. [ ] Servicio reiniciado: `pm2 restart comandero-backend` o `npm start`
8. [ ] Verificación de funcionamiento: `curl http://localhost:3000`

### Post-Deployment

- [ ] Servidor responde correctamente
- [ ] API accesible desde el frontend
- [ ] Socket.IO conectando correctamente
- [ ] Login funcionando
- [ ] Funcionalidades críticas probadas:
  - [ ] Crear orden
  - [ ] Procesar pago
  - [ ] Enviar cuenta
  - [ ] Notificaciones en tiempo real
- [ ] Logs sin errores críticos
- [ ] Monitoreo activo

## 🔍 Verificación Continua

### Diaria

- [ ] Revisar logs de errores
- [ ] Verificar que backups se estén creando
- [ ] Monitorear uso de recursos

### Semanal

- [ ] Revisar logs de acceso
- [ ] Verificar espacio en disco
- [ ] Revisar métricas de rendimiento
- [ ] Actualizar dependencias si hay vulnerabilidades

### Mensual

- [ ] Revisar y limpiar logs antiguos
- [ ] Verificar backups y probar restauración
- [ ] Revisar configuración de seguridad
- [ ] Actualizar sistema operativo (si aplica)

## 📞 Contacto y Soporte

- Documentación: `docs/DEPLOYMENT.md`
- Guía de backups: `docs/GUIA_RESPALDOS.md`
- Configuración: `docs/CONFIGURACION_FINAL.md`

---

**Fecha de última revisión**: _______________
**Revisado por**: _______________
**Estado**: ⬜ Listo para producción | ⬜ Pendiente

