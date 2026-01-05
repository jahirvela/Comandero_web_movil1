import mysql from 'mysql2/promise';
import { config } from 'dotenv';
import * as readline from 'readline';

config();

// Crear interfaz readline para entrada del usuario
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function pregunta(pregunta: string): Promise<string> {
  return new Promise((resolve) => {
    rl.question(pregunta, resolve);
  });
}

async function actualizarPasswordUsuariosExistentes() {
  let connection: mysql.Connection | null = null;

  try {
    // Obtener configuración de la base de datos desde variables de entorno
    const dbConfig = {
      host: process.env.DATABASE_HOST || 'localhost',
      port: Number(process.env.DATABASE_PORT) || 3306,
      user: process.env.DATABASE_USER || 'root',
      password: process.env.DATABASE_PASSWORD || '',
      database: process.env.DATABASE_NAME || 'comandero',
    };

    console.log('🔌 Conectando a la base de datos...');
    console.log(`   Host: ${dbConfig.host}`);
    console.log(`   Database: ${dbConfig.database}`);
    console.log(`   User: ${dbConfig.user}`);

    connection = await mysql.createConnection(dbConfig);

    // Obtener todos los usuarios
    console.log('\n🔍 Obteniendo lista de usuarios...');
    const [usuarios] = await connection.execute<any[]>(
      `SELECT id, username, password FROM usuario ORDER BY id`
    );

    if (usuarios.length === 0) {
      console.log('❌ No se encontraron usuarios');
      return;
    }

    console.log(`\n📋 Usuarios encontrados (${usuarios.length}):`);
    usuarios.forEach((u: any) => {
      const tienePassword = u.password && u.password !== '';
      console.log(`   ${tienePassword ? '✅' : '❌'} ID: ${u.id}, Username: ${u.username}${tienePassword ? `, Password actual: ${u.password}` : ', Sin contraseña guardada'}`);
    });

    console.log('\n⚠️  IMPORTANTE: No se pueden recuperar contraseñas hasheadas.');
    console.log('   Solo se pueden actualizar las contraseñas guardándolas en texto plano.');
    console.log('\nOpciones:');
    console.log('   1. Usar username como contraseña para todos');
    console.log('   2. Especificar contraseñas manualmente por usuario');
    console.log('   3. Cancelar');

    const opcion = await pregunta('\n¿Qué opción deseas? (1/2/3): ');

    if (opcion === '3') {
      console.log('\n❌ Operación cancelada');
      return;
    }

    if (opcion === '1') {
      // Usar username como contraseña
      console.log('\n📝 Actualizando contraseñas (usando username como contraseña)...');
      let actualizados = 0;

      for (const usuario of usuarios) {
        await connection.execute(
          `UPDATE usuario SET password = ? WHERE id = ?`,
          [usuario.username, usuario.id]
        );
        actualizados++;
        console.log(`   ✅ Usuario ${usuario.username} (ID: ${usuario.id}) → password: ${usuario.username}`);
      }

      console.log(`\n✅ ${actualizados} usuario(s) actualizado(s) exitosamente`);
    } else if (opcion === '2') {
      // Especificar contraseñas manualmente
      console.log('\n📝 Modo manual: Especifica la contraseña para cada usuario');
      console.log('   (Presiona Enter sin escribir nada para usar el username como contraseña)\n');

      let actualizados = 0;
      for (const usuario of usuarios) {
        const password = await pregunta(`   Contraseña para ${usuario.username} (ID: ${usuario.id}): `);
        const passwordFinal = password.trim() || usuario.username; // Si está vacío, usar username
        
        await connection.execute(
          `UPDATE usuario SET password = ? WHERE id = ?`,
          [passwordFinal, usuario.id]
        );
        actualizados++;
        console.log(`   ✅ ${usuario.username} → password: ${passwordFinal}\n`);
      }

      console.log(`\n✅ ${actualizados} usuario(s) actualizado(s) exitosamente`);
    } else {
      console.log('\n❌ Opción inválida');
      return;
    }

  } catch (error: any) {
    console.error('❌ Error al actualizar contraseñas:', error.message);
    process.exit(1);
  } finally {
    rl.close();
    if (connection) {
      await connection.end();
      console.log('\n🔌 Conexión cerrada');
    }
  }
}

actualizarPasswordUsuariosExistentes()
  .then(() => {
    console.log('\n✅ Script finalizado');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Error fatal:', error);
    process.exit(1);
  });

