# 🖥️ Intel NUC Schnellanleitung

## ✅ Jetzt für deinen Intel NUC optimiert!

### Was wurde geändert:

1. **CPU-only forciert** - Keine GPU-Erkennung mehr
2. **20GB RAM Limit** - Statt nur 8GB
3. **8 CPU Kerne** - Optimale Nutzung
4. **Längere Startzeit** - 3 Minuten Health Check (statt 1 Min)
5. **CPU Threading** - OMP/MKL Optimierungen

### 🚀 So startest du es RICHTIG:

```bash
# 1. Archiv entpacken
tar -xzf vibevoice-api-cpu-optimized.tar.gz
cd vibevoice-api

# 2. Einfach das CPU-Start-Script nutzen:
./start-cpu.sh

# Oder mit Make:
make cpu-up
```

**WICHTIG:** Nutze NICHT `docker-compose up -d` - das ist die alte Konfiguration!

### ⏱️ Was passiert beim Start:

```
1. System-Check (RAM, CPU, Docker)      - 5 Sekunden
2. Docker Image bauen                    - 2-5 Minuten
3. Container starten                     - 10 Sekunden
4. Modell herunterladen (nur 1x)        - 5-10 Minuten
5. Modell laden                          - 2-3 Minuten
6. API bereit! ✅                        - Total: 10-20 Min beim ersten Mal
```

**Ab dem zweiten Start:** Nur noch 2-3 Minuten (Modell ist schon da)!

### 📋 Befehle:

```bash
# Starten
make cpu-up
./start-cpu.sh

# Logs ansehen
make cpu-logs

# Stoppen
make cpu-down

# Neustart
make cpu-restart

# Ressourcen überwachen
make cpu-stats

# Test
make test
```

### 🔧 Wenn es nicht klappt:

**Problem 1: "Cannot allocate memory"**
```bash
# Lösung: Docker Memory erhöhen oder Swap erstellen
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

**Problem 2: Container stoppt sofort**
```bash
# Lösung: Logs prüfen
make cpu-logs

# Häufigste Ursache: Zu wenig RAM
# → Erstelle Swap (siehe oben)
```

**Problem 3: API antwortet nicht**
```bash
# Das ist NORMAL beim ersten Start!
# Warte 10-15 Minuten, dann:
curl http://localhost:8000/health

# Prüfe ob Modell lädt:
make cpu-logs
# Wenn du "Downloading" oder "Loading" siehst → Warte weiter!
```

### ✅ Teste ob es funktioniert:

```bash
# Nach dem Start (warte 10-15 Min beim ersten Mal)
curl http://localhost:8000/health

# Sollte zurückgeben:
{
  "status": "healthy",
  "model_loaded": true,
  "device": "cpu"
}

# Dann teste die API:
python3 examples/client.py
```

### 📖 Vollständige Dokumentation:

- **INTEL_NUC_SETUP.md** - Detaillierte Anleitung für Intel NUC
- **TROUBLESHOOTING.md** - Schnelle Problemlösungen
- **README.md** - Vollständige API Dokumentation

### ⚠️ Wichtig zu wissen:

1. **Erster Start dauert 10-20 Minuten** (Modell Download + Laden)
2. **CPU-only ist langsam**: 30-60 Sekunden pro Minute Audio
3. **Das ist NORMAL** für CPU-Betrieb
4. **Modell bleibt im RAM** - zweiter Request ist sofort schnell
5. **20GB RAM ist optimal** - Weniger kann zu Problemen führen

### 🎯 Erwartete Performance:

```
Intel NUC (CPU-only):
├─ Erster Start:           10-20 Minuten (nur einmal!)
├─ Zweiter Start:          2-3 Minuten
├─ Audio (10 Sekunden):    ~30-60 Sekunden
├─ Audio (1 Minute):       ~3-5 Minuten
└─ Audio (5 Minuten):      ~15-25 Minuten
```

### 🆘 Brauchst du Hilfe?

**Schicke mir diese Infos:**

```bash
# System Info
free -h
nproc

# Container Status
docker-compose -f docker-compose.cpu.yml ps

# Logs (letzte 50 Zeilen)
docker-compose -f docker-compose.cpu.yml logs --tail=50
```

Dann kann ich dir genau sagen was los ist!

### ✨ Das sollte jetzt funktionieren!

Viel Erfolg! 🎉
