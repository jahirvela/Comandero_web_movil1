// Script para liberar el puerto 3000 antes de iniciar el servidor
const { execSync } = require('child_process');

try {
  // Buscar procesos usando el puerto 3000
  const result = execSync('netstat -ano | findstr :3000', { encoding: 'utf8', stdio: 'pipe' });
  const lines = result.trim().split('\n').filter(line => line.includes('LISTENING'));
  
  if (lines.length > 0) {
    // Extraer PID de la primera línea
    const parts = lines[0].trim().split(/\s+/);
    const pid = parts[parts.length - 1];
    
    if (pid && !isNaN(pid)) {
      try {
        execSync(`taskkill /F /PID ${pid}`, { stdio: 'ignore' });
        console.log(`✅ Puerto 3000 liberado (PID ${pid})`);
      } catch (err) {
        // Ignorar errores si el proceso ya no existe
      }
    }
  }
} catch (err) {
  // Si no hay procesos usando el puerto, no hacer nada
}

