@echo off
setlocal enabledelayedexpansion

REM AIClient-2-API PM2 Manager Script (Windows)
REM Usage: pm2-manager.bat [start|stop|restart|reload|logs|status|install]

title AIClient-2-API PM2 Manager

REM Project configuration
set "APP_NAME=aiclient-2-api"
set "PROJECT_ROOT=%~dp0"
set "ECOSYSTEM_FILE=%PROJECT_ROOT%ecosystem.config.js"

cd /d "%PROJECT_ROOT%"

echo =========================================
echo AIClient-2-API PM2 Manager (Windows)
echo =========================================
echo.

REM Check Node.js
where node >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: Node.js not installed
    echo Please download and install Node.js 18+ from https://nodejs.org/
    pause
    exit /b 1
)

REM Check PM2 installation
where pm2 >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo WARNING: PM2 not installed
    echo Install PM2 now? (y/n)
    set /p "choice="
    if /i "!choice!"=="y" (
        echo Installing PM2...
        call npm install -g pm2
        if %ERRORLEVEL% neq 0 (
            echo PM2 installation failed
            pause
            exit /b 1
        )
        echo PM2 installed successfully!
    ) else (
        echo PM2 is required to continue
        echo Install command: npm install -g pm2
        pause
        exit /b 1
    )
)

REM Check configuration file
if not exist "%ECOSYSTEM_FILE%" (
    echo ERROR: PM2 config file not found: %ECOSYSTEM_FILE%
    pause
    exit /b 1
)

REM Check .env file
if not exist ".env" (
    echo WARNING: .env file does not exist
    if exist ".env.template" (
        echo Creating .env file from template...
        copy ".env.template" ".env" >nul
        echo Please edit .env file and configure OAUTH_HOST!
        echo.
        echo Edit now? (y/n)
        set /p "choice="
        if /i "!choice!"=="y" notepad .env
        pause
        exit /b 1
    )
)

REM Create logs directory
set "LOGS_DIR=%PROJECT_ROOT%logs"
if not exist "%LOGS_DIR%" (
    echo Creating logs directory: %LOGS_DIR%
    mkdir "%LOGS_DIR%"
)

REM Get action type
set "ACTION=%1"
if "%ACTION%"=="" set "ACTION=status"

echo Action: %ACTION%
echo.

REM Execute based on action type
if /i "%ACTION%"=="start" (
    echo Starting application...
    call pm2 start "%ECOSYSTEM_FILE%" --env production
    if %ERRORLEVEL% equ 0 (
        call pm2 save
        echo Application started and saved to PM2 startup list
        echo.
        call pm2 show "%APP_NAME%"
    ) else (
        echo Start failed
    )
) else if /i "%ACTION%"=="stop" (
    echo Stopping application...
    call pm2 stop "%APP_NAME%" 2>nul
    if %ERRORLEVEL% equ 0 (
        echo Application stopped
    ) else (
        echo Application not running
    )
) else if /i "%ACTION%"=="restart" (
    echo Restarting application...
    call pm2 restart "%APP_NAME%" 2>nul
    if %ERRORLEVEL% neq 0 (
        echo Application not running, starting...
        call pm2 start "%ECOSYSTEM_FILE%" --env production
    )
    if %ERRORLEVEL% equ 0 (
        echo Application restarted
        echo.
        call pm2 show "%APP_NAME%"
    )
) else if /i "%ACTION%"=="reload" (
    echo Hot reloading application...
    call pm2 reload "%APP_NAME%" 2>nul
    if %ERRORLEVEL% neq 0 (
        echo Application not running, starting...
        call pm2 start "%ECOSYSTEM_FILE%" --env production
    )
    if %ERRORLEVEL% equ 0 (
        echo Application hot reloaded
    )
) else if /i "%ACTION%"=="delete" (
    echo Deleting application...
    call pm2 delete "%APP_NAME%" 2>nul
    if %ERRORLEVEL% equ 0 (
        call pm2 save
        echo Application removed from PM2
    ) else (
        echo Application does not exist
    )
) else if /i "%ACTION%"=="logs" (
    echo Viewing logs ^(Ctrl+C to exit^)...
    call pm2 logs "%APP_NAME%" --lines 50
) else if /i "%ACTION%"=="status" (
    echo Application status:
    call pm2 list
    echo.
    call pm2 show "%APP_NAME%" 2>nul
    if %ERRORLEVEL% neq 0 (
        echo Application not running
    )
) else if /i "%ACTION%"=="info" (
    echo Application detailed information:
    call pm2 show "%APP_NAME%"
) else if /i "%ACTION%"=="monit" (
    echo Opening monitoring interface...
    call pm2 monit
) else if /i "%ACTION%"=="install" (
    echo Installing PM2...
    call npm install -g pm2
    if %ERRORLEVEL% equ 0 (
        echo PM2 installed successfully!
        call pm2 --version
    ) else (
        echo PM2 installation failed
    )
) else if /i "%ACTION%"=="save" (
    echo Saving current process list...
    call pm2 save
    echo Process list saved
) else if /i "%ACTION%"=="startup" (
    echo System startup configuration...
    echo Windows system recommends using Task Scheduler or service for startup
    echo.
    echo Options:
    echo 1. Add this script to Windows startup folder
    echo 2. Use pm2-windows-service package to create Windows service
    echo 3. Use Task Scheduler
    echo.
    echo Startup folder path: 
    echo %%USERPROFILE%%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup
) else if /i "%ACTION%"=="help" (
    goto :show_help
) else (
    echo ERROR: Unknown action '%ACTION%'
    goto :show_help
)

goto :end

:show_help
echo.
echo Usage: %0 [action]
echo.
echo Available actions:
echo   start    - Start application
echo   stop     - Stop application  
echo   restart  - Restart application
echo   reload   - Hot reload application
echo   delete   - Delete application
echo   logs     - View logs
echo   status   - View status ^(default^)
echo   info     - View detailed information
echo   monit    - Open monitoring interface
echo   install  - Install PM2
echo   save     - Save process list
echo   startup  - System startup configuration info
echo   help     - Show this help information
echo.

:end
echo.
pause
endlocal