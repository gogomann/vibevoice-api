@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

echo ======================================
echo 🖥️  VibeVoice API - Intel NUC Setup
echo ======================================
echo.
echo CPU-Only Modus mit 20GB RAM
echo.

:check_system
echo 📊 System-Check...

:: Prüfe Docker
where docker >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Docker ist nicht installiert!
    echo    Installiere Docker Desktop: https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)
echo ✅ Docker installiert

:: Prüfe Docker Compose
where docker-compose >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Docker Compose ist nicht installiert!
    pause
    exit /b 1
)
echo ✅ Docker Compose installiert

:: Prüfe ob Docker läuft
docker ps >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Docker läuft nicht!
    echo    Starte Docker Desktop und versuche es erneut.
    pause
    exit /b 1
)
echo ✅ Docker läuft

echo.

:ask_continue
set /p continue="Fortfahren? (j/n): "
if /i not "%continue%"=="j" (
    echo Abgebrochen.
    pause
    exit /b 0
)

echo.
echo 🔨 Baue Docker Image...
docker-compose -f docker-compose.cpu.yml build

if %errorlevel% neq 0 (
    echo ❌ Build fehlgeschlagen!
    pause
    exit /b 1
)

echo.
echo 🚀 Starte CPU-optimierte Version...
echo    - 20GB RAM Limit
echo    - 8 CPU Kerne
echo    - CPU-only (kein GPU)
echo.

docker-compose -f docker-compose.cpu.yml up -d

if %errorlevel% neq 0 (
    echo ❌ Start fehlgeschlagen!
    echo.
    echo Mögliche Lösungen:
    echo 1. Erhöhe Docker Memory Limit auf mindestens 20GB
    echo 2. Prüfe Logs: docker-compose -f docker-compose.cpu.yml logs
    echo 3. Siehe TROUBLESHOOTING.md
    pause
    exit /b 1
)

echo.
echo ⏳ Warte auf API (dies kann 3-5 Minuten dauern beim ersten Start)...
echo    Das Modell wird heruntergeladen und geladen...
echo.

:: Warte max 10 Minuten (120 x 5 Sekunden)
set /a attempts=0
set /a max_attempts=120

:wait_loop
if !attempts! geq !max_attempts! goto timeout

:: Prüfe Health Check
curl -s http://localhost:8000/health >nul 2>nul
if %errorlevel% equ 0 (
    echo.
    echo ✅ API ist bereit!
    goto show_info
)

set /a attempts+=1
set /a progress=!attempts!*100/!max_attempts!

:: Zeige Fortschritt alle 6 Versuche (30 Sekunden)
set /a mod=!attempts! %% 6
if !mod! equ 0 (
    echo    Warte... !progress!%% ^(!attempts!/!max_attempts!^)
) else (
    echo|set /p="."
)

timeout /t 5 /nobreak >nul
goto wait_loop

:timeout
echo.
echo ⚠️  API antwortet nicht nach 10 Minuten
echo.
echo Das Modell lädt möglicherweise noch. Prüfe:
echo   docker-compose -f docker-compose.cpu.yml logs -f
echo.
echo Oder warte weitere 5 Minuten und prüfe dann:
echo   curl http://localhost:8000/health
goto show_troubleshooting

:show_info
echo.
echo ======================================
echo ✅ VibeVoice API läuft auf CPU!
echo ======================================
echo.
echo 🌐 API:           http://localhost:8000
echo 📚 Dokumentation: http://localhost:8000/docs
echo ❤️  Health Check:  http://localhost:8000/health
echo.
echo ⚙️  Konfiguration:
echo    - Device: CPU-only
echo    - RAM: 20GB Limit
echo    - CPU: Bis zu 8 Kerne
echo.
echo ⏱️  Performance (CPU-only):
echo    - Erster Request: 2-5 Minuten
echo    - Weitere Requests: ~30-60 Sek. pro Minute Audio
echo.
echo Nützliche Batch-Dateien:
echo   cpu-logs.bat     - Logs anzeigen
echo   cpu-down.bat     - API stoppen
echo   cpu-restart.bat  - API neu starten
echo   test.bat         - Test Client ausführen
echo.
echo Oder mit Docker Compose direkt:
echo   docker-compose -f docker-compose.cpu.yml logs -f
echo.
pause
exit /b 0

:show_troubleshooting
echo.
echo 📝 Troubleshooting Schritte:
echo.
echo 1. Prüfe ob Container läuft:
echo    docker-compose -f docker-compose.cpu.yml ps
echo.
echo 2. Prüfe Logs:
echo    cpu-logs.bat
echo.
echo 3. Warte weitere 5 Minuten, dann teste:
echo    curl http://localhost:8000/health
echo.
echo 4. Wenn weiterhin Probleme:
echo    Lies TROUBLESHOOTING.md
echo.
pause
exit /b 0
