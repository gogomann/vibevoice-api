# 🪟 Windows Setup Anleitung

## 📦 Voraussetzungen

### 1. Docker Desktop installieren

**Download:** https://www.docker.com/products/docker-desktop

Nach der Installation:
1. Docker Desktop starten
2. Settings → Resources → Memory → **20 GB** einstellen
3. Apply & Restart

### 2. Optional: Python installieren (für Test-Client)

**Download:** https://www.python.org/downloads/

✅ Bei Installation: "Add Python to PATH" anhaken!

## 🚀 Schnellstart

### Schritt 1: Archiv entpacken

Rechtsklick auf `vibevoice-api-cpu-optimized.tar.gz` → Extrahieren

Oder mit 7-Zip / WinRAR öffnen.

### Schritt 2: API starten

**Doppelklick auf:**
```
start-cpu.bat
```

Das war's! 🎉

### Schritt 3: Warten

⏳ **Beim ersten Start: 10-20 Minuten warten!**

Das Modell wird heruntergeladen (~6GB).

### Schritt 4: Testen

**Doppelklick auf:**
```
health-check.bat
```

Sollte anzeigen: ✅ API ist erreichbar!

## 📁 Nützliche BAT-Dateien

| Datei | Funktion |
|-------|----------|
| **start-cpu.bat** | API starten |
| **cpu-down.bat** | API stoppen |
| **cpu-restart.bat** | API neu starten |
| **cpu-logs.bat** | Logs live ansehen |
| **cpu-status.bat** | Status & Ressourcen prüfen |
| **health-check.bat** | Schneller Health Check |
| **test.bat** | Python Test-Client |

## 🐳 Docker Desktop Konfiguration

### Memory Limit erhöhen:

1. Docker Desktop öffnen
2. ⚙️ Settings (oben rechts)
3. Resources → Memory
4. Schieberegler auf **20 GB**
5. Apply & Restart

### Docker läuft nicht?

**Prüfe:**
- Docker Desktop ist gestartet
- WSL 2 ist aktiviert (für Windows 10/11)
- Virtualisierung ist im BIOS aktiviert

**WSL 2 Backend aktivieren:**
```powershell
# In PowerShell als Administrator:
wsl --install
wsl --set-default-version 2
```

## 🔧 Problemlösungen

### Problem 1: "Docker ist nicht installiert"

**Lösung:**
1. Docker Desktop installieren (siehe oben)
2. Docker Desktop starten
3. Warten bis Docker bereit ist (Icon wird grün)

### Problem 2: "Cannot allocate memory"

**Lösung:**
1. Docker Desktop Memory auf 20GB erhöhen (siehe oben)
2. Alle anderen Programme schließen
3. `cpu-restart.bat` ausführen

### Problem 3: "API antwortet nicht"

**Das ist normal beim ersten Start!**

Prüfe:
```
cpu-logs.bat
```

Wenn du siehst:
- `Downloading model...` → Warte noch 5-10 Min
- `Loading model...` → Warte noch 2-3 Min
- `Application startup complete` → API ist bereit!

### Problem 4: Port 8000 bereits belegt

**Lösung:**

Bearbeite `docker-compose.cpu.yml`:
```yaml
ports:
  - "8001:8000"  # Ändere zu Port 8001
```

### Problem 5: Container stoppt sofort

**Prüfe Logs:**
```
cpu-logs.bat
```

**Häufige Ursache:** Zu wenig RAM
→ Docker Memory auf 20GB erhöhen

## 💻 Befehle in PowerShell

Falls die BAT-Dateien nicht funktionieren:

```powershell
# Navigiere zum Projektverzeichnis
cd C:\Pfad\zu\vibevoice-api

# Starten
docker-compose -f docker-compose.cpu.yml up -d

# Logs
docker-compose -f docker-compose.cpu.yml logs -f

# Stoppen
docker-compose -f docker-compose.cpu.yml down

# Status
docker-compose -f docker-compose.cpu.yml ps

# Health Check
curl http://localhost:8000/health
```

## 🧪 API Testen

### Mit Browser:

**Öffne:** http://localhost:8000/docs

→ Interaktive API Dokumentation

### Mit Test-Client:

**Doppelklick auf:**
```
test.bat
```

### Mit PowerShell:

```powershell
# Health Check
Invoke-WebRequest -Uri http://localhost:8000/health

# Einfacher Test
$body = @{
    text = "[Alice] Hallo Welt!"
    speakers = @(
        @{name = "Alice"}
    )
    output_format = "base64"
} | ConvertTo-Json

Invoke-WebRequest -Uri http://localhost:8000/api/v1/synthesize `
    -Method POST `
    -ContentType "application/json" `
    -Body $body
```

## ⏱️ Performance Erwartungen

**Intel NUC (CPU-only):**

```
Erster Start:        10-20 Minuten (einmalig)
Folgende Starts:     2-3 Minuten
Audio (10 Sek):      ~30-60 Sekunden
Audio (1 Min):       ~3-5 Minuten
Audio (5 Min):       ~15-25 Minuten
```

Das ist **normal** für CPU-Betrieb!

## 📊 Ressourcen überwachen

### Task Manager:

1. Task Manager öffnen (Ctrl+Shift+Esc)
2. Reiter "Leistung"
3. Prüfe: CPU & RAM Auslastung

### Docker Stats:

**Doppelklick auf:**
```
cpu-status.bat
```

Erwartete Werte beim Generieren:
- **CPU:** 400-800% (4-8 Kerne)
- **Memory:** 8-16 GB

## 🔥 Firewall & Antivirus

Falls die API nicht erreichbar ist:

### Windows Firewall:

```powershell
# In PowerShell als Administrator:
netsh advfirewall firewall add rule name="VibeVoice API" dir=in action=allow protocol=TCP localport=8000
```

### Antivirus:

Falls dein Antivirus Docker blockiert:
- Füge Docker Desktop zur Ausnahmeliste hinzu
- Füge das Projektverzeichnis zur Ausnahmeliste hinzu

## 📝 Checkliste

- [ ] Docker Desktop installiert
- [ ] Docker Memory auf 20GB erhöht
- [ ] Docker Desktop läuft (grünes Icon)
- [ ] `start-cpu.bat` ausgeführt
- [ ] 10-15 Minuten gewartet
- [ ] `health-check.bat` → ✅ OK
- [ ] `test.bat` ausgeführt → Audio generiert

## 🆘 Weitere Hilfe

**Sammle Diagnose-Infos:**

```powershell
# In PowerShell:
systeminfo | findstr /C:"Total Physical Memory"
docker --version
docker info | findstr "Memory"
docker-compose -f docker-compose.cpu.yml ps
docker-compose -f docker-compose.cpu.yml logs --tail=50 > logs.txt
```

Schicke mir dann `logs.txt`!

## 🎯 Nächste Schritte

1. **API läuft?** → Öffne http://localhost:8000/docs
2. **Test erfolgreich?** → Lies README.md für API-Details
3. **Produktiv nutzen?** → Lies DEPLOYMENT.md

## 🎉 Viel Erfolg!

Bei weiteren Fragen einfach melden!
