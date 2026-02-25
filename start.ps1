# AIClient-2-API PowerShell 启动脚本
# 使用方法: .\start.ps1 [dev|prod|test|standalone]

param(
    [Parameter(Position=0)]
    [ValidateSet("dev", "prod", "test", "standalone")]
    [string]$Mode = "prod"
)

# 设置控制台标题
$Host.UI.RawUI.WindowTitle = "AIClient-2-API PowerShell 启动脚本"

# 颜色定义
$Colors = @{
    Red = "Red"
    Green = "Green" 
    Yellow = "Yellow"
    Blue = "Blue"
    Cyan = "Cyan"
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

# 项目根目录
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectRoot

$LogsDir = Join-Path $ProjectRoot "logs"

Write-ColorText "AIClient-2-API PowerShell 启动脚本" "Cyan"
Write-Host ""

# 检查 Node.js
Write-Status "检查 Node.js 环境..."
try {
    $nodeVersion = node --version 2>$null
    if ($LASTEXITCODE -ne 0) { throw "Node.js not found" }
    
    $majorVersion = [int]($nodeVersion -replace 'v(\d+)\..*', '$1')
    if ($majorVersion -lt 18) {
        Write-Status "需要 Node.js 18+ (当前版本: $nodeVersion)" "Error"
        Read-Host "按回车键退出"
        exit 1
    }
    Write-Status "Node.js 版本: $nodeVersion" "Success"
} catch {
    Write-Status "Node.js 未安装或不在 PATH 中" "Error"
    Write-Status "请从 https://nodejs.org/ 下载并安装 Node.js 18+" "Warning"
    Read-Host "按回车键退出"
    exit 1
}

# 创建日志目录
if (-not (Test-Path $LogsDir)) {
    Write-Status "创建日志目录: $LogsDir" "Info"
    New-Item -Path $LogsDir -ItemType Directory -Force | Out-Null
}

# 检查 .env 文件
if (-not (Test-Path ".env")) {
    Write-Status ".env 文件不存在" "Warning"
    if (Test-Path ".env.template") {
        Write-Status "从模板创建 .env 文件..." "Info"
        Copy-Item ".env.template" ".env"
        Write-Status "请编辑 .env 文件，配置 OAUTH_HOST 等参数！" "Warning"
        
        $choice = Read-Host "是否现在编辑 .env 文件? (y/n)"
        if ($choice -eq "y" -or $choice -eq "Y") {
            Start-Process notepad ".env" -Wait
        }
        Write-Status "请重新运行此脚本" "Info"
        Read-Host "按回车键退出"
        exit 1
    } else {
        Write-Status "找不到 .env.template 模板文件" "Error"
        Read-Host "按回车键退出"
        exit 1
    }
}

# 检查 OAUTH_HOST 配置
$envContent = Get-Content ".env" -ErrorAction SilentlyContinue
$oauthHostLine = $envContent | Where-Object { $_ -like "OAUTH_HOST=*" }
if ($oauthHostLine -like "*your-public-ip-or-domain*") {
    Write-Status "请在 .env 文件中配置正确的 OAUTH_HOST" "Error"
    Write-Status "示例: OAUTH_HOST=127.0.0.1 (Windows测试)" "Warning" 
    Write-Status "或者: OAUTH_HOST=123.456.789.123 (Linux部署)" "Warning"
    
    $choice = Read-Host "是否现在编辑 .env 文件? (y/n)"
    if ($choice -eq "y" -or $choice -eq "Y") {
        Start-Process notepad ".env" -Wait
        Write-Status "请重新运行此脚本" "Info"
    }
    Read-Host "按回车键退出"
    exit 1
}

Write-Status "启动模式: $Mode" "Info"
Write-Status "项目路径: $ProjectRoot" "Info"
Write-Host ""

# 检查依赖
if (-not (Test-Path "node_modules")) {
    Write-Status "依赖未安装，正在安装..." "Warning"
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Status "依赖安装失败" "Error"
        Read-Host "按回车键退出"
        exit 1
    }
    Write-Status "依赖安装完成" "Success"
}

# 设置环境变量并启动
Write-Status "准备启动应用..." "Info"

try {
    switch ($Mode) {
        "dev" {
            Write-Status "开发模式启动..." "Info"
            $env:NODE_ENV = "development"
            $env:LOG_LEVEL = "debug"
            npm run start:dev
        }
        "prod" {
            Write-Status "生产模式启动..." "Success"
            $env:NODE_ENV = "production"
            $env:LOG_LEVEL = "info" 
            npm start
        }
        "test" {
            Write-Status "测试模式启动..." "Info"
            $env:NODE_ENV = "test"
            $env:LOG_LEVEL = "debug"
            npm test
        }
        "standalone" {
            Write-Status "独立服务器模式启动..." "Info"
            $env:NODE_ENV = "production"
            $env:LOG_LEVEL = "info"
            npm run start:standalone
        }
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Status "应用启动成功" "Success"
    } else {
        Write-Status "应用启动失败，错误代码: $LASTEXITCODE" "Error"
    }
} catch {
    Write-Status "启动过程中发生错误: $($_.Exception.Message)" "Error"
    Read-Host "按回车键退出"
    exit 1
}

Write-Host ""
Read-Host "按回车键退出"