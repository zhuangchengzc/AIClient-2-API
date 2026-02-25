@echo off

REM Quick Start Script for Windows
REM Simple script to avoid encoding issues

echo =====================================
echo AIClient-2-API Quick Start
echo =====================================
echo.

REM Check if .env exists
if not exist ".env" (
    echo Creating .env file...
    (
    echo # OAuth Host Configuration
    echo OAUTH_HOST=127.0.0.1
    echo.
    echo # Server Configuration  
    echo NODE_ENV=development
    echo PORT=3000
    echo LOG_LEVEL=debug
    ) > .env
    echo .env file created with default settings.
    echo Please edit .env file if needed.
    echo.
)

REM Install dependencies if needed
if not exist "node_modules" (
    echo Installing dependencies...
    npm install
    echo.
)

REM Start the application
echo Starting AIClient-2-API...
set NODE_ENV=development
set LOG_LEVEL=debug
npm start

pause