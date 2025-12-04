module.exports = {
  apps: [{
    name: 'comandero-backend',
    script: './dist/server.js',
    instances: 2, // Número de instancias (recomendado: número de CPUs)
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: './logs/pm2-error.log',
    out_file: './logs/pm2-out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,
    autorestart: true,
    max_memory_restart: '1G',
    watch: false,
    // Configuración de reinicio automático
    min_uptime: '10s',
    max_restarts: 10,
    restart_delay: 4000,
    // Variables de entorno adicionales (se cargan desde .env)
    env_file: '.env'
  }]
};

