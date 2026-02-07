@echo off
chcp 65001 > nul

echo ======================================
echo 📋 VibeVoice API Logs (CPU Version)
echo ======================================
echo.
echo Drücke Ctrl+C zum Beenden
echo.

docker-compose -f docker-compose.cpu.yml logs -f
