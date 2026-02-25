#!/bin/bash

# 设置中文环境
export LC_ALL=zh_CN.UTF-8
export LANG=zh_CN.UTF-8

echo "========================================"
echo "  AI Client 2 API PM2 快速安装启动脚本"
echo "========================================"
echo

# 处理参数
FORCE_PULL=0
APP_NAME="aiclient2api"

for arg in "$@"; do
    if [ "$arg" == "--pull" ]; then
        FORCE_PULL=1
    elif [[ "$arg" == --name=* ]]; then
        APP_NAME="${arg#*=}"
    fi
done

# 检查Git并尝试pull
if [ $FORCE_PULL -eq 1 ]; then
    echo "[更新] 正在从远程仓库拉取最新代码..."
    if command -v git > /dev/null 2>&1; then
        git pull
        if [ $? -ne 0 ]; then
            echo "[警告] Git pull 失败，请检查网络或手动处理冲突。"
        else
            echo "[成功] 代码已更新。"
        fi
    else
        echo "[警告] 未检测到 Git，跳过代码拉取。"
    fi
fi

# 检查Node.js是否已安装
echo "[检查] 正在检查Node.js是否已安装..."
node --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "[错误] 未检测到Node.js，请先安装Node.js"
    echo "下载地址：https://nodejs.org/"
    echo "提示：推荐安装LTS版本"
    exit 1
fi

# 获取Node.js版本
NODE_VERSION=$(node --version 2>/dev/null)
echo "[成功] Node.js已安装，版本: $NODE_VERSION"

# 检查npm是否可用
echo "[检查] 正在检查npm是否可用..."
npm --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "[错误] npm不可用，请重新安装Node.js"
    exit 1
fi

# 检查PM2是否已安装
echo "[检查] 正在检查PM2是否已安装..."
if ! command -v pm2 > /dev/null 2>&1; then
    echo "[警告] 未检测到PM2，正在安装PM2..."
    npm install -g pm2
    if [ $? -ne 0 ]; then
        echo "[错误] PM2安装失败"
        echo "请手动运行: npm install -g pm2"
        exit 1
    fi
    echo "[成功] PM2安装完成"
else
    PM2_VERSION=$(pm2 --version 2>/dev/null)
    echo "[成功] PM2已安装，版本: $PM2_VERSION"
fi

# 检查package.json是否存在
if [ ! -f "package.json" ]; then
    echo "[错误] 未找到package.json文件"
    echo "请确保在项目根目录下运行此脚本"
    exit 1
fi

echo "[成功] 找到package.json文件"

# 检查 pnpm 是否安装
if command -v pnpm > /dev/null 2>&1; then
    PKG_MANAGER=pnpm
else
    PKG_MANAGER=npm
fi

echo "[安装] 正在使用 $PKG_MANAGER 安装/更新依赖..."
echo "这可能需要几分钟时间，请耐心等待..."
echo "正在执行: $PKG_MANAGER install..."

$PKG_MANAGER install
if [ $? -ne 0 ]; then
    echo "[错误] 依赖安装失败"
    echo "请检查网络连接或手动运行 '$PKG_MANAGER install'"
    exit 1
fi
echo "[成功] 依赖安装/更新完成"

# 检查src目录和master.js是否存在
if [ ! -f "src/core/master.js" ]; then
    echo "[错误] 未找到src/core/master.js文件"
    exit 1
fi

echo "[成功] 项目文件检查完成"

# 检查PM2中是否已有同名应用在运行
echo
echo "========================================"
echo "  使用PM2启动AIClient2API服务器..."
echo "========================================"
echo

if pm2 list | grep -q "$APP_NAME"; then
    echo "[提示] 检测到PM2中已有名为 '$APP_NAME' 的应用"
    echo "[操作] 正在重启应用..."
    pm2 restart "$APP_NAME"
    if [ $? -ne 0 ]; then
        echo "[错误] 应用重启失败"
        exit 1
    fi
    echo "[成功] 应用已重启"
else
    echo "[操作] 正在启动新应用..."
    pm2 start src/core/master.js --name "$APP_NAME"
    if [ $? -ne 0 ]; then
        echo "[错误] 应用启动失败"
        exit 1
    fi
    echo "[成功] 应用已启动"
fi

# 保存PM2进程列表
pm2 save > /dev/null 2>&1

echo
echo "========================================"
echo "  服务器启动成功！"
echo "========================================"
echo
echo "应用名称: $APP_NAME"
echo "服务地址: http://localhost:3000"
echo "管理界面: http://localhost:3000"
echo
echo "常用PM2命令："
echo "  查看状态: pm2 status"
echo "  查看日志: pm2 logs $APP_NAME"
echo "  停止服务: pm2 stop $APP_NAME"
echo "  重启服务: pm2 restart $APP_NAME"
echo "  删除服务: pm2 delete $APP_NAME"
echo "  查看监控: pm2 monit"
echo
echo "设置开机自启："
echo "  pm2 startup"
echo "  pm2 save"
echo
