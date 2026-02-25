@echo off
setlocal enabledelayedexpansion

REM AIClient-2-API Windows Start Script
REM Usage: start.bat [dev|prod|test|standalone]

title AIClient-2-API Start Script

REM Project root directory
set "PROJECT_ROOT=%~dp0"
cd /d "%PROJECT_ROOT%"

REM Logs directory
set "LOGS_DIR=%PROJECT_ROOT%logs"

echo ====================================
echo AIClient-2-API Windows Start Script
echo ====================================
echo.

REM Check Node.js installation
where node >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: Node.js not installed or not in PATH
    echo Please download and install Node.js 18+ from https://nodejs.org/
    pause
    exit /b 1
)

REM Check Node.js version
for /f "tokens=1 delims=." %%a in ('node -v 2^>nul') do (
    set "NODE_MAJOR=%%a"
    set "NODE_MAJOR=!NODE_MAJOR:v=!"
)

if !NODE_MAJOR! lss 18 (
    echo ERROR: Requires Node.js 18+ ^(Current version: !NODE_MAJOR!^)
    pause
    exit /b 1
)

REM Create logs directory
if not exist "%LOGS_DIR%" (
    echo Creating logs directory: %LOGS_DIR%
    mkdir "%LOGS_DIR%"
)

REM Check .env file
if not exist ".env" (
    echo WARNING: .env file does not exist
    if exist ".env.template" (
        echo Creating .env file from template...
        copy ".env.template" ".env" >nul
        echo Please edit .env file and configure OAUTH_HOST!
        echo Press any key to continue editing .env file...
        pause >nul
        notepad .env
        echo Please run this script again
        pause
        exit /b 1
    ) else (
        echo ERROR: .env.template template file not found
        pause
        exit /b 1
    )
)

REM Check OAUTH_HOST configuration
findstr /c:"OAUTH_HOST=your-public-ip-or-domain" .env >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo ERROR: Please configure correct OAUTH_HOST in .env file
    echo Example: OAUTH_HOST=127.0.0.1 ^(Windows test^)
    echo Or: OAUTH_HOST=123.456.789.123 ^(Linux deployment^)
    echo.
    echo Edit .env file now? (y/n)
    set /p "choice="
    if /i "!choice!"=="y" (
        notepad .env
        echo Please run this script again
        pause
        exit /b 1
    )
    pause
    exit /b 1
)

REM Get startup mode
set "MODE=%1"
if "%MODE%"=="" set "MODE=prod"

echo Startup mode: %MODE%
echo Project path: %PROJECT_ROOT%
echo.

REM Check dependencies installation
if not exist "node_modules" (
    echo Dependencies not installed, installing...
    call npm install
    if %ERRORLEVEL% neq 0 (
        echo Dependencies installation failed
        pause
        exit /b 1
    )
)

REM Start based on mode
if /i "%MODE%"=="dev" (
    echo Starting development mode...
    set "NODE_ENV=development"
    set "LOG_LEVEL=debug"
    call npm run start:dev
) else if /i "%MODE%"=="prod" (
    echo Starting production mode...
    set "NODE_ENV=production" 
    set "LOG_LEVEL=info"
    call npm start
) else if /i "%MODE%"=="test" (
    echo Starting test mode...
    set "NODE_ENV=test"
    set "LOG_LEVEL=debug"
    call npm test
) else if /i "%MODE%"=="standalone" (
    echo Starting standalone server mode...
    set "NODE_ENV=production"
    set "LOG_LEVEL=info"
    call npm run start:standalone
) else (
    echo ERROR: Unknown startup mode '%MODE%'
    echo.
    echo Usage: %0 [dev^|prod^|test^|standalone]
    echo.
    echo Available modes:
    echo   dev        - Development mode
    echo   prod       - Production mode ^(default^)
    echo   test       - Test mode
    echo   standalone - Standalone server mode
    pause
    exit /b 1
)

if %ERRORLEVEL% neq 0 (
    echo.
    echo Startup failed, error code: %ERRORLEVEL%
    echo Please check the error messages above
    pause
    exit /b 1
)

endlocal