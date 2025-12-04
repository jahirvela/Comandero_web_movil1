// Script para crear/actualizar el usuario admin con la contraseña Demo1234
const bcrypt = require('bcrypt');
const mysql = require('mysql2/promise');
require('dotenv').config();

async function crearUsuarioAdmin() {
  let connection;
  
  try {
    // Conectar a la base de datos
    connection = await mysql.createConnection({
      host: process.env.DATABASE_HOST || 'localhost',
      port: parseInt(process.env.DATABASE_PORT || '3306'),
      user: process.env.DATABASE_USER,
      password: process.env.DATABASE_PASSWORD,
      database: process.env.DATABASE_NAME,
    });

    console.log('✅ Conectado a la base de datos');

    // Generar hash de la contraseña Demo1234
    const password = 'Demo1234';
    const saltRounds = 10;
    const passwordHash = await bcrypt.hash(password, saltRounds);
    
    console.log('✅ Hash generado para contraseña:', password);

    // Verificar si el usuario admin ya existe
    const [users] = await connection.execute(
      'SELECT id FROM usuario WHERE username = ?',
      ['admin']
    );

    if (users.length > 0) {
      // Actualizar el usuario existente
      const userId = users[0].id;
      await connection.execute(
        `UPDATE usuario 
         SET password_hash = ?, 
             password_actualizada_en = NOW(),
             actualizado_en = NOW()
         WHERE id = ?`,
        [passwordHash, userId]
      );
      console.log('✅ Usuario admin actualizado (ID:', userId, ')');
    } else {
      // Crear nuevo usuario admin
      const [result] = await connection.execute(
        `INSERT INTO usuario (
          nombre, username, password_hash, activo,
          password_actualizada_en, creado_en, actualizado_en
        ) VALUES (?, ?, ?, 1, NOW(), NOW(), NOW())`,
        ['Administrador', 'admin', passwordHash]
      );
      console.log('✅ Usuario admin creado (ID:', result.insertId, ')');
    }

    // Obtener el ID del usuario admin
    const [adminUsers] = await connection.execute(
      'SELECT id FROM usuario WHERE username = ?',
      ['admin']
    );
    const adminId = adminUsers[0].id;

    // Verificar si existe el rol Administrador
    const [roles] = await connection.execute(
      'SELECT id FROM rol WHERE nombre = ?',
      ['Administrador']
    );

    if (roles.length === 0) {
      console.log('⚠️  El rol "Administrador" no existe. Creándolo...');
      const [rolResult] = await connection.execute(
        `INSERT INTO rol (nombre, descripcion, creado_en, actualizado_en)
         VALUES (?, ?, NOW(), NOW())`,
        ['Administrador', 'Rol de administrador del sistema']
      );
      console.log('✅ Rol Administrador creado (ID:', rolResult.insertId, ')');
    }

    // Obtener el ID del rol Administrador
    const [adminRoles] = await connection.execute(
      'SELECT id FROM rol WHERE nombre = ?',
      ['Administrador']
    );
    const rolAdminId = adminRoles[0].id;

    // Asignar el rol al usuario admin si no lo tiene
    const [userRoles] = await connection.execute(
      'SELECT * FROM usuario_rol WHERE usuario_id = ? AND rol_id = ?',
      [adminId, rolAdminId]
    );

    if (userRoles.length === 0) {
      await connection.execute(
        'INSERT INTO usuario_rol (usuario_id, rol_id) VALUES (?, ?)',
        [adminId, rolAdminId]
      );
      console.log('✅ Rol Administrador asignado al usuario admin');
    } else {
      console.log('✅ El usuario admin ya tiene el rol Administrador');
    }

    console.log('\n✅ Proceso completado exitosamente');
    console.log('📝 Credenciales:');
    console.log('   Usuario: admin');
    console.log('   Contraseña: Demo1234');

  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.code) {
      console.error('   Código:', error.code);
    }
    process.exit(1);
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

crearUsuarioAdmin();

