@echo off
chcp 65001 > nul

echo ======================================
echo 🧪 VibeVoice API Test Client
echo ======================================
echo.

:: Prüfe ob Python installiert ist
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Python ist nicht installiert!
    echo    Installiere Python: https://www.python.org/downloads/
    pause
    exit /b 1
)

echo Python gefunden: 
python --version
echo.

:: Prüfe ob requests installiert ist
python -c "import requests" >nul 2>nul
if %errorlevel% neq 0 (
    echo 📦 Installiere 'requests' Bibliothek...
    python -m pip install requests
    echo.
)

echo 🚀 Führe Test Client aus...
echo.

python examples\client.py

echo.
pause
