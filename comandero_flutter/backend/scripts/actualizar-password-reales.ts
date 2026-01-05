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

async function actualizarPasswordReales() {
  let connection: mysql.Connection | null = null;

  try {
    const dbConfig = {
      host: process.env.DATABASE_HOST || 'localhost',
      port: Number(process.env.DATABASE_PORT) || 3306,
      user: process.env.DATABASE_USER || 'root',
      password: process.env.DATABASE_PASSWORD || '',
      database: process.env.DATABASE_NAME || 'comandero',
    };

    console.log('🔌 Conectando a la base de datos...');
    connection = await mysql.createConnection(dbConfig);

    // Obtener todos los usuarios
    console.log('\n🔍 Obteniendo lista de usuarios...\n');
    const [usuarios] = await connection.execute<any[]>(
      `SELECT id, username, password FROM usuario ORDER BY id`
    );

    if (usuarios.length === 0) {
      console.log('❌ No se encontraron usuarios');
      return;
    }

    console.log('📋 Usuarios encontrados:');
    usuarios.forEach((u: any, index: number) => {
      const tienePassword = u.password && u.password !== '';
      console.log(`   ${index + 1}. ${u.username} (ID: ${u.id})${tienePassword ? ` [Password actual: ${u.password}]` : ' [Sin contraseña guardada]'}`);
    });

    console.log('\n⚠️  IMPORTANTE:');
    console.log('   Este script actualizará las contraseñas en texto plano para visualización del administrador.');
    console.log('   Debes proporcionar las contraseñas REALES de cada usuario.');
    console.log('   Presiona Enter sin escribir nada si quieres mantener la contraseña actual (si existe).\n');

    const confirmar = await pregunta('¿Deseas continuar? (s/n): ');
    if (confirmar.toLowerCase() !== 's' && confirmar.toLowerCase() !== 'si' && confirmar.toLowerCase() !== 'y' && confirmar.toLowerCase() !== 'yes') {
      console.log('\n❌ Operación cancelada');
      return;
    }

    console.log('\n📝 Ingresa las contraseñas REALES para cada usuario:\n');
    
    let actualizados = 0;
    for (const usuario of usuarios) {
      const prompt = `   Contraseña para ${usuario.username}${usuario.password ? ` [actual: ${usuario.password}]` : ''}: `;
      const password = await pregunta(prompt);
      
      if (password.trim() === '') {
        // Si está vacío y ya tiene contraseña, mantenerla
        if (usuario.password && usuario.password !== '') {
          console.log(`   ⏭️  ${usuario.username}: Se mantiene la contraseña actual\n`);
          continue;
        } else {
          // Si está vacío y no tiene contraseña, usar username
          const passwordFinal = usuario.username;
          await connection.execute(
            `UPDATE usuario SET password = ? WHERE id = ?`,
            [passwordFinal, usuario.id]
          );
          actualizados++;
          console.log(`   ✅ ${usuario.username} → password: ${passwordFinal}\n`);
        }
      } else {
        // Actualizar con la nueva contraseña proporcionada
        const passwordFinal = password.trim();
        await connection.execute(
          `UPDATE usuario SET password = ? WHERE id = ?`,
          [passwordFinal, usuario.id]
        );
        actualizados++;
        console.log(`   ✅ ${usuario.username} → password: ${passwordFinal}\n`);
      }
    }

    console.log(`\n✅ ${actualizados} usuario(s) actualizado(s) exitosamente`);
    console.log('   Las contraseñas ahora están guardadas en texto plano y serán visibles en el panel de administración.');

  } catch (error: any) {
    console.error('\n❌ Error:', error.message);
    process.exit(1);
  } finally {
    rl.close();
    if (connection) {
      await connection.end();
      console.log('\n🔌 Conexión cerrada');
    }
  }
}

actualizarPasswordReales()
  .then(() => {
    console.log('\n✅ Script finalizado');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Error fatal:', error);
    process.exit(1);
  });

