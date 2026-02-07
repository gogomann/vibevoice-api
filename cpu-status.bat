@echo off
chcp 65001 > nul

echo ======================================
echo 📊 VibeVoice API Status
echo ======================================
echo.

echo Container Status:
docker-compose -f docker-compose.cpu.yml ps

echo.
echo Ressourcen (Ctrl+C zum Beenden):
docker stats vibevoice-api-cpu --no-stream

echo.
echo Health Check:
curl -s http://localhost:8000/health

echo.
echo.
pause
