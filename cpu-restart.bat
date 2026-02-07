@echo off
chcp 65001 > nul

echo ======================================
echo 🔄 VibeVoice API Neu starten
echo ======================================
echo.

docker-compose -f docker-compose.cpu.yml restart

if %errorlevel% equ 0 (
    echo.
    echo ✅ API erfolgreich neu gestartet!
    echo.
    echo ⏳ Warte 1-2 Minuten, dann teste:
    echo    curl http://localhost:8000/health
) else (
    echo.
    echo ❌ Fehler beim Neustart!
)

echo.
pause
