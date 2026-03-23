/**
 * Expansión de roles para "gerente": mismas reglas que authorization.ts
 * y para Socket.IO (donde no pasa por requireRoles).
 */
export const normalizeRoleString = (role: string): string =>
  String(role)
    .toLowerCase()
    .trim()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '');

/**
 * Si el usuario es gerente, actúa como mesero, cajero y cocinero para permisos efectivos.
 */
export const expandGerenteRoles = (roles: string[]): string[] => {
  const lower = roles.map((r) => normalizeRoleString(r));
  if (lower.includes('gerente')) {
    return [...new Set([...lower, 'mesero', 'cajero', 'cocinero'])];
  }
  return lower;
};
