/**
 * Script para habilitar el usuario mesero
 * Ejecutar con: npx tsx scripts/enable-mesero-user.ts
 */

import { actualizarUsuario } from '../src/modules/usuarios/usuarios.repository.js';
import { findUserByUsername } from '../src/auth/auth.repository.js';
import { pool } from '../src/db/pool.js';

async function enableMeseroUser() {
  try {
    console.log('🔍 Buscando usuario "mesero"...');
    
    const user = await findUserByUsername('mesero');
    
    if (!user) {
      console.log('❌ No se encontró el usuario "mesero"');
      return;
    }
    
    console.log(`📋 Usuario encontrado: ID=${user.id}, Nombre=${user.nombre}, Activo=${user.activo}`);
    
    if (user.activo) {
      console.log('✅ El usuario "mesero" ya está habilitado');
      return;
    }
    
    // Habilitar el usuario usando el repositorio
    await actualizarUsuario(user.id, {
      activo: true,
    });
    
    console.log('✅ Usuario "mesero" habilitado correctamente');
    
    // Verificar el cambio
    const updatedUser = await findUserByUsername('mesero');
    if (updatedUser) {
      console.log(`✅ Verificación: Usuario ahora está activo=${updatedUser.activo}`);
    }
    
  } catch (error) {
    console.error('❌ Error al habilitar usuario mesero:', error);
    throw error;
  }
}

enableMeseroUser()
  .then(() => {
    console.log('✅ Script completado');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Error:', error);
    process.exit(1);
  });
