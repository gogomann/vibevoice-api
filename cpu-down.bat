@echo off
chcp 65001 > nul

echo ======================================
echo 🛑 VibeVoice API Stoppen
echo ======================================
echo.

docker-compose -f docker-compose.cpu.yml down

if %errorlevel% equ 0 (
    echo.
    echo ✅ API erfolgreich gestoppt!
) else (
    echo.
    echo ❌ Fehler beim Stoppen!
)

echo.
pause
