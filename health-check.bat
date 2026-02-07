@echo off
chcp 65001 > nul

echo ======================================
echo ❤️  VibeVoice API Health Check
echo ======================================
echo.

:: Prüfe ob curl verfügbar ist
where curl >nul 2>nul
if %errorlevel% neq 0 (
    echo ⚠️  curl nicht gefunden, versuche mit PowerShell...
    powershell -Command "try { $response = Invoke-WebRequest -Uri 'http://localhost:8000/health' -UseBasicParsing; Write-Host '✅ API ist erreichbar!'; Write-Host ''; $response.Content } catch { Write-Host '❌ API ist nicht erreichbar!'; Write-Host 'Fehler:' $_.Exception.Message }"
) else (
    curl -s http://localhost:8000/health
    
    if %errorlevel% equ 0 (
        echo.
        echo ✅ API ist erreichbar!
    ) else (
        echo.
        echo ❌ API ist nicht erreichbar!
        echo    Starte die API mit: start-cpu.bat
    )
)

echo.
pause
