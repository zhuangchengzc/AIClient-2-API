@echo off
setlocal enabledelayedexpansion

REM Windows Environment Variable Configuration Script
REM For AIClient-2-API quick setup

title AIClient-2-API Environment Setup

echo ====================================
echo AIClient-2-API Environment Setup
echo ====================================
echo.

REM Project root directory
set "PROJECT_ROOT=%~dp0"
cd /d "%PROJECT_ROOT%"

REM Check template file
if not exist ".env.template" (
    echo ERROR: .env.template file not found
    pause
    exit /b 1
)

REM Check existing .env file
if exist ".env" (
    echo WARNING: Found existing .env file
    echo.
    type .env
    echo.
    echo Do you want to reconfigure? (y/n)
    set /p "choice="
    if /i not "!choice!"=="y" (
        echo Configuration cancelled
        pause
        exit /b 0
    )
    echo.
)

REM Configuration wizard
echo === Environment Configuration Wizard ===
echo.

REM 1. OAUTH_HOST Configuration
echo 1. OAuth Callback Host Configuration
echo This is the most important setting for OAuth callback URLs
echo.
echo Choose deployment environment:
echo [1] Windows Local Test (localhost)
echo [2] Windows Local Test (127.0.0.1) 
echo [3] LAN Test (enter LAN IP)
echo [4] Public Network (enter public IP)
echo [5] Domain Deployment (enter domain)
echo [6] Manual Input

set /p "host_choice=Please choose [1-6]: "

if "%host_choice%"=="1" (
    set "OAUTH_HOST=localhost"
    echo Set: OAUTH_HOST=localhost
) else if "%host_choice%"=="2" (
    set "OAUTH_HOST=127.0.0.1"  
    echo Set: OAUTH_HOST=127.0.0.1
) else if "%host_choice%"=="3" (
    echo Enter LAN IP address (e.g. 192.168.1.100):
    set /p "OAUTH_HOST="
    echo Set: OAUTH_HOST=!OAUTH_HOST!
) else if "%host_choice%"=="4" (
    echo Enter public IP address (e.g. 123.456.789.123):
    set /p "OAUTH_HOST="
    echo Set: OAUTH_HOST=!OAUTH_HOST!
) else if "%host_choice%"=="5" (
    echo Enter domain name (e.g. yourdomain.com):
    set /p "OAUTH_HOST="
    echo Set: OAUTH_HOST=!OAUTH_HOST!
) else if "%host_choice%"=="6" (
    echo Enter OAuth host address:
    set /p "OAUTH_HOST="
    echo Set: OAUTH_HOST=!OAUTH_HOST!
) else (
    echo Invalid choice, using default: localhost
    set "OAUTH_HOST=localhost"
)

echo.

REM 2. Runtime Environment Configuration
echo 2. Runtime Environment Configuration
echo [1] Development Environment (development)
echo [2] Production Environment (production) - Recommended
echo [3] Test Environment (test)

set /p "env_choice=Please choose [1-3]: "

if "%env_choice%"=="1" (
    set "NODE_ENV=development"
    set "LOG_LEVEL=debug"
) else if "%env_choice%"=="3" (
    set "NODE_ENV=test" 
    set "LOG_LEVEL=debug"
) else (
    set "NODE_ENV=production"
    set "LOG_LEVEL=info"
)

echo Set: NODE_ENV=!NODE_ENV!, LOG_LEVEL=!LOG_LEVEL!
echo.

REM 3. Port Configuration
echo 3. Service Port Configuration
echo Default port: 3000
echo Use default port? (y/n)
set /p "port_choice="

if /i "!port_choice!"=="n" (
    echo Enter port number (recommended range: 3000-9999):
    set /p "PORT="
) else (
    set "PORT=3000"
)

echo Set: PORT=!PORT!
echo.

REM 4. Optional Configuration
echo 4. Optional Configuration
echo Configure proxy settings? (y/n)
set /p "proxy_choice="

if /i "!proxy_choice!"=="y" (
    echo Enter proxy address (e.g. http://127.0.0.1:1089):
    set /p "PROXY_URL="
    echo Set: PROXY_URL=!PROXY_URL!
) else (
    set "PROXY_URL="
)

echo.

REM 5. Generate .env file
echo Generating .env file...

(
echo # AIClient-2-API Environment Configuration
echo # Generated at: %date% %time%
echo.
echo # OAuth Callback Configuration ^(Required^)
echo OAUTH_HOST=!OAUTH_HOST!
echo.
echo # Server Configuration
echo NODE_ENV=!NODE_ENV!
echo PORT=!PORT!
echo LOG_LEVEL=!LOG_LEVEL!
echo.
if defined PROXY_URL (
    echo # Proxy Configuration
    echo PROXY_URL=!PROXY_URL!
    echo.
)
echo # Optional Configuration ^(uncomment as needed^)
echo # REQUIRED_API_KEY=your-secure-api-key
echo # LOGIN_EXPIRY=3600
echo # MASTER_PORT=3100
echo # PROXY_ENABLED_PROVIDERS=gemini-cli-oauth,gemini-antigravity
echo # OPENAI_REASONING_MAX_TOKENS=50000
echo # CODEX_INSTRUCTIONS_ENABLED=true
) > .env

echo .env file generated successfully!
echo.

REM 6. Show configuration summary
echo === Configuration Summary ===
type .env
echo.

REM 7. Next steps
echo === Next Steps ===
echo.
echo 1. Check configuration: Edit .env file for fine-tuning
echo    Command: notepad .env
echo.
echo 2. Install dependencies: 
echo    Command: npm install
echo.
echo 3. Start application:
echo    Command: start.bat prod
echo    Or: pm2-manager.bat start
echo.
echo 4. OAuth Configuration:
echo    Configure callback URLs in OAuth providers:
echo    - Google: http://!OAUTH_HOST!:8085, http://!OAUTH_HOST!:8086
echo    - OpenAI: http://!OAUTH_HOST!:1455/auth/callback  
echo    - iFlow:  http://!OAUTH_HOST!:8087/oauth2callback
echo    - Kiro:   http://!OAUTH_HOST!:19876-19880/oauth/callback
echo.

echo Edit .env file now for fine-tuning? (y/n)
set /p "edit_choice="
if /i "!edit_choice!"=="y" (
    notepad .env
)

echo.
echo Configuration completed!
pause

endlocal