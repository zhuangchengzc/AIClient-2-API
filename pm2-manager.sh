#!/bin/bash

# AIClient-2-API PM2 管理脚本
# 使用方法: ./pm2-manager.sh [start|stop|restart|reload|logs|status]

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目配置
APP_NAME="aiclient-2-api"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ECOSYSTEM_FILE="$PROJECT_ROOT/ecosystem.config.cjs"

cd "$PROJECT_ROOT"

# 检查 PM2 是否安装
if ! command -v pm2 &> /dev/null; then
    echo -e "${RED}错误: PM2 未安装${NC}"
    echo -e "${YELLOW}安装命令: npm install -g pm2${NC}"
    exit 1
fi

# 检查配置文件
if [ ! -f "$ECOSYSTEM_FILE" ]; then
    echo -e "${RED}错误: 找不到 PM2 配置文件: $ECOSYSTEM_FILE${NC}"
    exit 1
fi

# 检查 .env 文件
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}警告: .env 文件不存在${NC}"
    if [ -f ".env.template" ]; then
        echo -e "${GREEN}从模板创建 .env 文件...${NC}"
        cp .env.template .env
        echo -e "${RED}请编辑 .env 文件，配置 OAUTH_HOST 等参数！${NC}"
        exit 1
    fi
fi

# 创建日志目录
LOGS_DIR="$PROJECT_ROOT/logs"
if [ ! -d "$LOGS_DIR" ]; then
    echo -e "${GREEN}创建日志目录: $LOGS_DIR${NC}"
    mkdir -p "$LOGS_DIR"
fi

# 获取操作类型
ACTION=${1:-status}

echo -e "${BLUE}AIClient-2-API PM2 管理器${NC}"
echo -e "${BLUE}操作: $ACTION${NC}"

case "$ACTION" in
    "start")
        echo -e "${GREEN}启动应用...${NC}"
        pm2 start "$ECOSYSTEM_FILE" --env production
        pm2 save
        echo -e "${GREEN}应用已启动并保存到 PM2 启动列表${NC}"
        pm2 show "$APP_NAME"
        ;;
    "stop")
        echo -e "${YELLOW}停止应用...${NC}"
        pm2 stop "$APP_NAME" 2>/dev/null || echo -e "${YELLOW}应用未运行${NC}"
        echo -e "${GREEN}应用已停止${NC}"
        ;;
    "restart")
        echo -e "${YELLOW}重启应用...${NC}"
        pm2 restart "$APP_NAME" 2>/dev/null || pm2 start "$ECOSYSTEM_FILE" --env production
        echo -e "${GREEN}应用已重启${NC}"
        pm2 show "$APP_NAME"
        ;;
    "reload")
        echo -e "${YELLOW}热重载应用...${NC}"
        pm2 reload "$APP_NAME" 2>/dev/null || pm2 start "$ECOSYSTEM_FILE" --env production
        echo -e "${GREEN}应用已热重载${NC}"
        ;;
    "delete"|"remove")
        echo -e "${RED}删除应用...${NC}"
        pm2 delete "$APP_NAME" 2>/dev/null || echo -e "${YELLOW}应用不存在${NC}"
        pm2 save
        echo -e "${GREEN}应用已从 PM2 中删除${NC}"
        ;;
    "logs")
        echo -e "${BLUE}查看日志 (Ctrl+C 退出)...${NC}"
        pm2 logs "$APP_NAME" --lines 50
        ;;
    "status"|"info")
        echo -e "${BLUE}应用状态:${NC}"
        pm2 list
        echo ""
        pm2 show "$APP_NAME" 2>/dev/null || echo -e "${YELLOW}应用未运行${NC}"
        ;;
    "monit")
        echo -e "${BLUE}打开监控界面...${NC}"
        pm2 monit
        ;;
    "startup")
        echo -e "${GREEN}配置系统启动...${NC}"
        pm2 startup
        echo -e "${YELLOW}请按照上面的提示执行 sudo 命令${NC}"
        ;;
    "save")
        echo -e "${GREEN}保存当前进程列表...${NC}"
        pm2 save
        echo -e "${GREEN}进程列表已保存${NC}"
        ;;
    *)
        echo -e "${RED}错误: 未知操作 '$ACTION'${NC}"
        echo ""
        echo "使用方法: $0 [操作]"
        echo ""
        echo "可用操作:"
        echo "  start    - 启动应用"
        echo "  stop     - 停止应用"
        echo "  restart  - 重启应用"
        echo "  reload   - 热重载应用"
        echo "  delete   - 删除应用"
        echo "  logs     - 查看日志"
        echo "  status   - 查看状态"
        echo "  monit    - 打开监控"
        echo "  startup  - 配置系统启动"
        echo "  save     - 保存进程列表"
        exit 1
        ;;
esac