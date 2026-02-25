#!/bin/bash

# AIClient-2-API 启动脚本
# 使用方法: ./start.sh [dev|prod|test]

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

# 日志目录
LOGS_DIR="$PROJECT_ROOT/logs"

# 创建日志目录
if [ ! -d "$LOGS_DIR" ]; then
    echo -e "${GREEN}创建日志目录: $LOGS_DIR${NC}"
    mkdir -p "$LOGS_DIR"
fi

# 检查 .env 文件
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}警告: .env 文件不存在${NC}"
    if [ -f ".env.template" ]; then
        echo -e "${GREEN}从模板创建 .env 文件...${NC}"
        cp .env.template .env
        echo -e "${RED}请编辑 .env 文件，配置 OAUTH_HOST 等参数！${NC}"
        exit 1
    else
        echo -e "${RED}错误: 找不到 .env.template 模板文件${NC}"
        exit 1
    fi
fi

# 检查 OAUTH_HOST 配置
if ! grep -q "^OAUTH_HOST=" .env || grep -q "^OAUTH_HOST=your-public-ip-or-domain" .env; then
    echo -e "${RED}错误: 请在 .env 文件中配置正确的 OAUTH_HOST${NC}"
    echo -e "${YELLOW}示例: OAUTH_HOST=123.456.789.123${NC}"
    exit 1
fi

# 获取启动模式
MODE=${1:-prod}

echo -e "${GREEN}AIClient-2-API 启动脚本${NC}"
echo -e "${GREEN}启动模式: $MODE${NC}"
echo -e "${GREEN}项目路径: $PROJECT_ROOT${NC}"

# 检查 Node.js 版本
NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo -e "${RED}错误: 需要 Node.js 18+ (当前版本: $(node --version))${NC}"
    exit 1
fi

case "$MODE" in
    "dev")
        echo -e "${YELLOW}开发模式启动...${NC}"
        export NODE_ENV=development
        export LOG_LEVEL=debug
        npm run start:dev
        ;;
    "prod")
        echo -e "${GREEN}生产模式启动...${NC}"
        export NODE_ENV=production
        export LOG_LEVEL=info
        npm start
        ;;
    "test")
        echo -e "${YELLOW}测试模式启动...${NC}"
        export NODE_ENV=test
        export LOG_LEVEL=debug
        npm test
        ;;
    "standalone")
        echo -e "${YELLOW}独立服务器模式启动...${NC}"
        export NODE_ENV=production
        export LOG_LEVEL=info
        npm run start:standalone
        ;;
    *)
        echo -e "${RED}错误: 未知的启动模式 '$MODE'${NC}"
        echo "使用方法: $0 [dev|prod|test|standalone]"
        exit 1
        ;;
esac