import type { Request, Response, NextFunction } from 'express';
import { forbidden, unauthorized } from '../utils/http-error.js';

export const requireRoles = (...roles: string[]) => {
  return (req: Request, _res: Response, next: NextFunction) => {
    // Log de la ruta que se está accediendo
    console.log(`🔒 Authorization: ${req.method} ${req.path}`);
    
    if (!req.user) {
      console.log('🔒 Authorization: No hay usuario en la request');
      return next(unauthorized('Token de acceso requerido'));
    }

    if (roles.length === 0) {
      console.log('🔒 Authorization: No se requieren roles específicos, acceso permitido');
      return next();
    }

    // Log detallado para depuración
    console.log(`🔒 Authorization: Usuario "${req.user.username}" (ID: ${req.user.id})`);
    console.log(`🔒 Authorization: Roles del usuario: [${JSON.stringify(req.user.roles)}]`);
    console.log(`🔒 Authorization: Roles requeridos: [${roles.join(', ')}]`);

    // Asegurar que roles sea un array
    const userRoles = Array.isArray(req.user.roles) ? req.user.roles : [];
    
    if (userRoles.length === 0) {
      console.log('❌ Authorization: El usuario no tiene roles asignados');
      return next(forbidden('No tienes permisos para esta operación'));
    }
    
    // Comparar en minúsculas para evitar problemas de case sensitivity
    const userRolesLower = userRoles.map(r => String(r).toLowerCase().trim());
    // "gerente" hereda permisos operativos de mesero/cajero/cocinero sin duplicar roles en BD.
    const effectiveRoles = userRolesLower.includes('gerente')
      ? [...new Set([...userRolesLower, 'mesero', 'cajero', 'cocinero'])]
      : userRolesLower;
    const requiredRolesLower = roles.map(r => String(r).toLowerCase().trim());
    
    const hasRole = effectiveRoles.some((role) => requiredRolesLower.includes(role));

    console.log(`🔒 Authorization: Roles normalizados del usuario: [${effectiveRoles.join(', ')}]`);
    console.log(`🔒 Authorization: ¿Tiene permiso? ${hasRole}`);

    if (!hasRole) {
      console.log(`❌ Authorization: Acceso denegado para ${req.user.username} - roles no coinciden`);
      return next(forbidden('No tienes permisos para esta operación'));
    }

    console.log(`✅ Authorization: Acceso permitido para ${req.user.username}`);
    return next();
  };
};

// Alias para compatibilidad - acepta array o argumentos separados
export const authorize = (...rolesOrArray: (string | string[])[]) => {
  // Aplanar si recibió un array como primer argumento
  const roles = rolesOrArray.flat();
  return requireRoles(...roles);
};

