# AIClient-2-API PowerShell PM2 管理脚本
# 使用方法: .\pm2-manager.ps1 [start|stop|restart|reload|logs|status|install]

param(
    [Parameter(Position=0)]
    [ValidateSet("start", "stop", "restart", "reload", "delete", "logs", "status", "info", "monit", "install", "save", "startup", "help")]
    [string]$Action = "status"
)

# 设置控制台标题
$Host.UI.RawUI.WindowTitle = "AIClient-2-API PM2 管理器 (PowerShell)"

# 颜色定义
$Colors = @{
    Red = "Red"
    Green = "Green"
    Yellow = "Yellow" 
    Blue = "Blue"
    Cyan = "Cyan"
    Magenta = "Magenta"
    White = "White"
}

function Write-ColorText {
    param(
        [string]$Text,
        [string]$Color = "White"
    )
    Write-Host $Text -ForegroundColor $Colors[$Color]
}

function Write-Status {
    param(
        [string]$Message,
        [string]$Type = "Info"
    )
    $timestamp = Get-Date -Format "HH:mm:ss"
    switch ($Type) {
        "Success" { Write-Host "[$timestamp] " -NoNewline; Write-ColorText "✓ $Message" "Green" }
        "Error"   { Write-Host "[$timestamp] " -NoNewline; Write-ColorText "✗ $Message" "Red" }
        "Warning" { Write-Host "[$timestamp] " -NoNewline; Write-ColorText "⚠ $Message" "Yellow" }
        default   { Write-Host "[$timestamp] " -NoNewline; Write-ColorText "ℹ $Message" "Blue" }
    }
}

# 项目配置
$AppName = "aiclient-2-api"
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$EcosystemFile = Join-Path $ProjectRoot "ecosystem.config.js"

Set-Location $ProjectRoot

Write-ColorText "AIClient-2-API PM2 管理器 (PowerShell)" "Cyan"
Write-Host ""

# 检查 Node.js
Write-Status "检查 Node.js 环境..."
try {
    $nodeVersion = node --version 2>$null
    if ($LASTEXITCODE -ne 0) { throw "Node.js not found" }
    Write-Status "Node.js 版本: $nodeVersion" "Success"
} catch {
    Write-Status "Node.js 未安装" "Error"
    Write-Status "请从 https://nodejs.org/ 下载并安装 Node.js 18+" "Warning"
    Read-Host "按回车键退出"
    exit 1
}

# 检查 PM2
Write-Status "检查 PM2 环境..."
try {
    $pm2Version = pm2 --version 2>$null
    if ($LASTEXITCODE -ne 0) { throw "PM2 not found" }
    Write-Status "PM2 版本: $pm2Version" "Success"
} catch {
    Write-Status "PM2 未安装" "Warning"
    $choice = Read-Host "是否现在安装 PM2? (y/n)"
    if ($choice -eq "y" -or $choice -eq "Y") {
        Write-Status "正在安装 PM2..." "Info"
        npm install -g pm2
        if ($LASTEXITCODE -eq 0) {
            Write-Status "PM2 安装成功！" "Success"
        } else {
            Write-Status "PM2 安装失败" "Error"
            Read-Host "按回车键退出"
            exit 1
        }
    } else {
        Write-Status "需要 PM2 才能继续" "Error"
        Write-Status "安装命令: npm install -g pm2" "Info"
        Read-Host "按回车键退出"
        exit 1
    }
}

# 检查配置文件
if (-not (Test-Path $EcosystemFile)) {
    Write-Status "找不到 PM2 配置文件: $EcosystemFile" "Error"
    Read-Host "按回车键退出"
    exit 1
}

# 检查 .env 文件
if (-not (Test-Path ".env")) {
    Write-Status ".env 文件不存在" "Warning"
    if (Test-Path ".env.template") {
        Write-Status "从模板创建 .env 文件..." "Info"
        Copy-Item ".env.template" ".env"
        Write-Status "请编辑 .env 文件，配置 OAUTH_HOST 等参数！" "Warning"
        
        $choice = Read-Host "是否现在编辑? (y/n)"
        if ($choice -eq "y" -or $choice -eq "Y") {
            Start-Process notepad ".env" -Wait
        }
        Read-Host "按回车键退出"
        exit 1
    }
}

# 创建日志目录
$LogsDir = Join-Path $ProjectRoot "logs"
if (-not (Test-Path $LogsDir)) {
    Write-Status "创建日志目录: $LogsDir" "Info"
    New-Item -Path $LogsDir -ItemType Directory -Force | Out-Null
}

Write-Status "操作: $Action" "Info"
Write-Host ""

# 执行操作
try {
    switch ($Action) {
        "start" {
            Write-Status "启动应用..." "Info"
            pm2 start $EcosystemFile --env production
            if ($LASTEXITCODE -eq 0) {
                pm2 save | Out-Null
                Write-Status "应用已启动并保存到 PM2 启动列表" "Success"
                Write-Host ""
                pm2 show $AppName
            } else {
                Write-Status "启动失败" "Error"
            }
        }
        
        "stop" {
            Write-Status "停止应用..." "Warning"
            pm2 stop $AppName 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Status "应用已停止" "Success"
            } else {
                Write-Status "应用未运行" "Warning"
            }
        }
        
        "restart" {
            Write-Status "重启应用..." "Info"
            pm2 restart $AppName 2>$null
            if ($LASTEXITCODE -ne 0) {
                Write-Status "应用未运行，正在启动..." "Info"
                pm2 start $EcosystemFile --env production
            }
            if ($LASTEXITCODE -eq 0) {
                Write-Status "应用已重启" "Success"
                Write-Host ""
                pm2 show $AppName
            }
        }
        
        "reload" {
            Write-Status "热重载应用..." "Info"
            pm2 reload $AppName 2>$null
            if ($LASTEXITCODE -ne 0) {
                Write-Status "应用未运行，正在启动..." "Info"
                pm2 start $EcosystemFile --env production
            }
            if ($LASTEXITCODE -eq 0) {
                Write-Status "应用已热重载" "Success"
            }
        }
        
        "delete" {
            Write-Status "删除应用..." "Warning"
            pm2 delete $AppName 2>$null
            if ($LASTEXITCODE -eq 0) {
                pm2 save | Out-Null
                Write-Status "应用已从 PM2 中删除" "Success"
            } else {
                Write-Status "应用不存在" "Warning"
            }
        }
        
        "logs" {
            Write-Status "查看日志 (Ctrl+C 退出)..." "Info"
            pm2 logs $AppName --lines 50
        }
        
        "status" {
            Write-Status "应用状态:" "Info"
            pm2 list
            Write-Host ""
            pm2 show $AppName 2>$null
            if ($LASTEXITCODE -ne 0) {
                Write-Status "应用未运行" "Warning"
            }
        }
        
        "info" {
            Write-Status "应用详细信息:" "Info"
            pm2 show $AppName
        }
        
        "monit" {
            Write-Status "打开监控界面..." "Info"
            pm2 monit
        }
        
        "install" {
            Write-Status "安装 PM2..." "Info"
            npm install -g pm2
            if ($LASTEXITCODE -eq 0) {
                Write-Status "PM2 安装成功！" "Success"
                pm2 --version
            } else {
                Write-Status "PM2 安装失败" "Error"
            }
        }
        
        "save" {
            Write-Status "保存当前进程列表..." "Info"
            pm2 save
            Write-Status "进程列表已保存" "Success"
        }
        
        "startup" {
            Write-Status "配置系统启动..." "Info"
            Write-Status "Windows 系统建议使用任务计划程序或服务来实现开机自启" "Warning"
            Write-Host ""
            Write-ColorText "可选方案:" "Cyan"
            Write-Host "1. 将此脚本添加到 Windows 启动文件夹"
            Write-Host "2. 使用 pm2-windows-service 包创建 Windows 服务"
            Write-Host "3. 使用任务计划程序"
            Write-Host ""
            Write-ColorText "启动文件夹路径:" "Yellow" 
            Write-Host "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
            Write-Host ""
            Write-ColorText "pm2-windows-service 安装:" "Yellow"
            Write-Host "npm install -g pm2-windows-service"
            Write-Host "pm2-service-install"
        }
        
        "help" {
            Show-Help
        }
        
        default {
            Write-Status "未知操作: $Action" "Error"
            Show-Help
        }
    }
} catch {
    Write-Status "执行操作时发生错误: $($_.Exception.Message)" "Error"
    Read-Host "按回车键退出"
    exit 1
}

function Show-Help {
    Write-Host ""
    Write-ColorText "使用方法: .\pm2-manager.ps1 [操作]" "Cyan"
    Write-Host ""
    Write-ColorText "可用操作:" "Yellow"
    Write-Host "  start    - 启动应用"
    Write-Host "  stop     - 停止应用"
    Write-Host "  restart  - 重启应用"
    Write-Host "  reload   - 热重载应用"
    Write-Host "  delete   - 删除应用"
    Write-Host "  logs     - 查看日志"
    Write-Host "  status   - 查看状态 (默认)"
    Write-Host "  info     - 查看详细信息"
    Write-Host "  monit    - 打开监控界面"
    Write-Host "  install  - 安装 PM2"
    Write-Host "  save     - 保存进程列表"
    Write-Host "  startup  - 开机启动配置说明"
    Write-Host "  help     - 显示此帮助信息"
}

if ($Action -eq "help") {
    Show-Help
}

Write-Host ""
Read-Host "按回车键退出"