# AIClient-2-API Linux部署指南

## 环境变量配置说明

### 核心环境变量

| 变量名 | 描述 | 示例值 | 必需 |
|--------|------|--------|------|
| `OAUTH_HOST` | OAuth回调的公网IP或域名 | `123.456.789.123` | ✅ |
| `NODE_ENV` | 运行环境 | `production` | ❌ |
| `PORT` | 主服务端口 | `3000` | ❌ |
| `LOG_LEVEL` | 日志级别 | `info` | ❌ |

## 部署方式

### 方式1: 使用npm直接启动

#### 1.1 配置环境变量

```bash
# 复制环境变量模板
cp .env.template .env

# 编辑配置文件
nano .env
```

在`.env`文件中设置：
```bash
OAUTH_HOST=123.456.789.123  # 你的公网IP
NODE_ENV=production
PORT=3000
LOG_LEVEL=info
```

#### 1.2 启动应用

```bash
# 安装依赖
npm install

# 直接启动
npm start

# 或使用启动脚本
chmod +x start.sh
./start.sh prod
```

#### 1.3 临时环境变量启动

```bash
# 单次启动时设置环境变量
OAUTH_HOST=123.456.789.123 NODE_ENV=production npm start

# 或者导出环境变量后启动
export OAUTH_HOST=123.456.789.123
export NODE_ENV=production
npm start
```

### 方式2: 使用PM2进程管理

#### 2.1 安装PM2

```bash
# 全局安装PM2
npm install -g pm2

# 验证安装
pm2 --version
```

#### 2.2 配置文件启动

```bash
# 复制和编辑环境变量
cp .env.template .env
nano .env

# 使用PM2启动
pm2 start ecosystem.config.js --env production

# 或使用管理脚本
chmod +x pm2-manager.sh
./pm2-manager.sh start
```

#### 2.3 PM2常用命令

```bash
# 启动应用
pm2 start ecosystem.config.js --env production

# 查看状态
pm2 status
pm2 show aiclient-2-api

# 查看日志
pm2 logs aiclient-2-api

# 重启应用
pm2 restart aiclient-2-api

# 停止应用
pm2 stop aiclient-2-api

# 删除应用
pm2 delete aiclient-2-api

# 保存进程列表（开机自启）
pm2 save
pm2 startup
```

#### 2.4 PM2配置系统自启

```bash
# 生成系统启动脚本
pm2 startup

# 执行生成的sudo命令（PM2会提示）
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u your-username --hp /home/your-username

# 保存当前进程列表
pm2 save
```

### 方式3: 使用systemd服务

#### 3.1 创建系统用户

```bash
# 创建专用用户
sudo useradd -r -s /bin/false aiclient
sudo mkdir -p /opt/aiclient-2-api
sudo chown -R aiclient:aiclient /opt/aiclient-2-api
```

#### 3.2 部署应用

```bash
# 复制应用到系统目录
sudo cp -r /path/to/your/aiclient-2-api/* /opt/aiclient-2-api/
sudo chown -R aiclient:aiclient /opt/aiclient-2-api

# 安装依赖
cd /opt/aiclient-2-api
sudo -u aiclient npm install --production
```

#### 3.3 配置systemd服务

```bash
# 复制服务文件
sudo cp aiclient-2-api.service /etc/systemd/system/

# 编辑服务文件，修改OAUTH_HOST
sudo nano /etc/systemd/system/aiclient-2-api.service

# 重载systemd配置
sudo systemctl daemon-reload

# 启动服务
sudo systemctl start aiclient-2-api

# 设置开机自启
sudo systemctl enable aiclient-2-api

# 查看状态
sudo systemctl status aiclient-2-api

# 查看日志
sudo journalctl -u aiclient-2-api -f
```

## 防火墙配置

### Ubuntu/Debian (ufw)

```bash
# 开放必要端口
sudo ufw allow 3000          # Web UI
sudo ufw allow 8085:8087/tcp # OAuth回调
sudo ufw allow 1455          # Codex OAuth
sudo ufw allow 19876:19880/tcp # Kiro OAuth

# 启用防火墙
sudo ufw enable

# 查看状态
sudo ufw status
```

### CentOS/RHEL/Rocky Linux (firewalld)

```bash
# 开放端口
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --permanent --add-port=8085-8087/tcp
sudo firewall-cmd --permanent --add-port=1455/tcp
sudo firewall-cmd --permanent --add-port=19876-19880/tcp

# 重载配置
sudo firewall-cmd --reload

# 查看状态
sudo firewall-cmd --list-all
```

## OAuth应用配置更新

### Google Cloud Console
1. 访问 [Google Cloud Console](https://console.cloud.google.com/)
2. 进入"API和服务" > "凭据"
3. 编辑OAuth 2.0客户端ID
4. 在"已获授权的重定向URI"中添加：
   - `http://你的公网IP:8085`
   - `http://你的公网IP:8086`

### OpenAI Platform
1. 访问 [OpenAI Platform](https://platform.openai.com/)
2. 在OAuth应用设置中添加：
   - `http://你的公网IP:1455/auth/callback`

### iFlow
添加回调URL：`http://你的公网IP:8087/oauth2callback`

### Kiro (Claude)
添加回调URL：
- `http://你的公网IP:19876/oauth/callback`
- `http://你的公网IP:19877/oauth/callback`
- `http://你的公网IP:19878/oauth/callback`
- `http://你的公网IP:19879/oauth/callback`
- `http://你的公网IP:19880/oauth/callback`

## 故障排查

### 1. 检查环境变量

```bash
# 查看当前环境变量
printenv | grep OAUTH
echo $OAUTH_HOST

# PM2环境变量检查
pm2 show aiclient-2-api | grep -A 20 "env:"
```

### 2. 检查端口占用

```bash
# 查看端口占用
sudo netstat -tlnp | grep :3000
sudo netstat -tlnp | grep :8085

# 或使用ss命令
sudo ss -tlnp | grep :3000
```

### 3. 查看日志

```bash
# npm启动的日志
tail -f logs/combined.log

# PM2日志
pm2 logs aiclient-2-api --lines 100

# systemd日志
sudo journalctl -u aiclient-2-api --lines 100 -f
```

### 4. 测试OAuth回调

```bash
# 测试端口连通性
curl http://your-public-ip:8085
curl http://your-public-ip:3000

# 从外网测试
curl http://123.456.789.123:3000/health
```

### 5. 常见问题

**问题1**: OAuth回调失败
- 检查`OAUTH_HOST`是否设置正确
- 确认防火墙端口已开放
- 验证OAuth应用配置中的回调URL

**问题2**: 应用无法启动
- 检查Node.js版本（需要18+）
- 确认所有依赖已安装
- 查看详细错误日志

**问题3**: 端口冲突
- 使用`netstat`或`ss`检查端口占用
- 修改配置使用其他端口
- 停止冲突的服务

## 安全建议

1. **使用HTTPS**: 生产环境配置SSL证书
2. **限制访问**: 配置防火墙规则限制IP访问
3. **定期更新**: 及时更新依赖和系统补丁
4. **监控日志**: 设置日志监控和告警
5. **备份配置**: 定期备份配置文件和数据

## 性能优化

1. **PM2集群模式**: 对于高并发场景
2. **反向代理**: 使用Nginx进行负载均衡
3. **资源监控**: 设置内存和CPU限制
4. **日志轮转**: 配置日志文件轮转避免磁盘占满