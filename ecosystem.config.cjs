module.exports = {
  apps: [
    {
      name: 'aiclient-2-api',
      script: 'src/core/master.js',
      cwd: './',
      instances: 1,
      exec_mode: 'fork',
      
      // 环境变量配置
      env: {
        NODE_ENV: 'development',
        PORT: 3000,
        OAUTH_HOST: 'localhost', // 开发环境
        LOG_LEVEL: 'debug'
      },
      
      // 生产环境配置
      env_production: {
        NODE_ENV: 'production',
        PORT: 3000,
        OAUTH_HOST: process.env.OAUTH_HOST || 'your-public-ip-or-domain',
        LOG_LEVEL: 'info',
        MASTER_PORT: 3100
      },
      
      // 从.env文件加载环境变量
      env_file: '.env',
      
      // 日志配置
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      out_file: './logs/out.log',
      error_file: './logs/error.log',
      log_file: './logs/combined.log',
      time: true,
      
      // 进程管理配置
      autorestart: true,
      watch: false, // 生产环境不建议开启watch
      max_memory_restart: '1G',
      restart_delay: 1000,
      max_restarts: 10,
      min_uptime: '10s',
      
      // 错误处理
      kill_timeout: 1600,
      listen_timeout: 3000,
      
      // 高级配置
      node_args: ['--max-old-space-size=1024'],
      
      // 合并日志
      merge_logs: true,
      
      // 实例ID
      instance_var: 'INSTANCE_ID'
    }
  ]
};