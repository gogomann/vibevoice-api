# Intel NUC CPU-Only Setup Guide

## 🖥️ Für deinen Intel NUC optimiert

### Schnellstart

```bash
# CPU-optimierte Version starten
docker-compose -f docker-compose.cpu.yml up -d

# Logs ansehen
docker-compose -f docker-compose.cpu.yml logs -f
```

## ⚙️ Konfiguration

### Aktuelle Einstellungen (optimiert für deinen NUC):

- **RAM Limit**: 20 GB
- **CPU Kerne**: Bis zu 8 Kerne
- **Device**: CPU (forciert)
- **Shared Memory**: 4 GB
- **Startzeit**: 3 Minuten (Health Check)

### Anpassung der Einstellungen

**docker-compose.cpu.yml bearbeiten:**

```yaml
deploy:
  resources:
    limits:
      cpus: '8.0'        # Ändere auf Anzahl deiner CPU Kerne
      memory: 20G        # Ändere RAM Limit hier
```

## 🐛 Problemlösung

### Problem 1: Container startet nicht

**Prüfe Docker Memory:**
```bash
docker info | grep Memory
```

**Erhöhe Docker Memory Limit:**
- Docker Desktop: Settings → Resources → Memory → 20GB
- Linux: Bearbeite `/etc/docker/daemon.json`

```json
{
  "default-runtime": "runc",
  "default-ulimits": {
    "memlock": {
      "Hard": -1,
      "Name": "memlock",
      "Soft": -1
    }
  }
}
```

### Problem 2: "Out of Memory" beim Modell-Laden

**Lösung 1: Kleineres Modell**
```yaml
environment:
  - MODEL_PATH=vibevoice/VibeVoice-1.5B  # Statt 7B
```

**Lösung 2: Swap erhöhen (Linux)**
```bash
# Prüfe aktuellen Swap
free -h

# Erstelle 8GB Swap File
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### Problem 3: Container läuft, aber API antwortet nicht

**Prüfe Container Status:**
```bash
docker-compose -f docker-compose.cpu.yml ps
docker-compose -f docker-compose.cpu.yml logs --tail=100
```

**Häufige Ursachen:**
1. **Modell lädt noch** - Warte 3-5 Minuten beim ersten Start
2. **Port belegt** - Ändere Port auf 8001:
   ```yaml
   ports:
     - "8001:8000"
   ```
3. **Firewall** - Öffne Port 8000

### Problem 4: Sehr langsame Generierung

**Das ist normal auf CPU!** Erwartungen:

- **Erster Start**: 2-5 Minuten (Modell wird geladen)
- **Kurzer Text (10 Sek.)**: ~30-60 Sekunden
- **Mittlerer Text (1 Min.)**: ~3-5 Minuten
- **Langer Text (5 Min.)**: ~15-25 Minuten

**Optimierungen:**

```yaml
environment:
  - OMP_NUM_THREADS=16  # Erhöhe auf Anzahl deiner Threads
```

### Problem 5: Container stoppt nach Start

**Prüfe Logs:**
```bash
docker-compose -f docker-compose.cpu.yml logs
```

**Häufige Fehler:**

**"CUDA out of memory"**
→ Setze `FORCE_CPU=true` (sollte schon gesetzt sein)

**"Cannot allocate memory"**
→ Erhöhe Docker Memory Limit oder nutze Swap

**"ModuleNotFoundError"**
→ Rebuilde das Image:
```bash
docker-compose -f docker-compose.cpu.yml build --no-cache
```

## 📊 Performance Monitoring

### Container Ressourcen überwachen:

```bash
# Live Stats
docker stats vibevoice-api-cpu

# CPU und Memory Nutzung
watch -n 1 'docker stats vibevoice-api-cpu --no-stream'
```

### Erwartete Werte beim Generieren:

- **CPU**: 400-800% (4-8 Kerne aktiv)
- **Memory**: 6-12 GB
- **Network**: Minimal

## 🔧 Manuelle Installation (ohne Docker)

Falls Docker Probleme macht:

```bash
# Python Environment
python3 -m venv venv
source venv/bin/activate

# Dependencies
pip install -r requirements.txt
pip install git+https://github.com/vibevoice-community/VibeVoice.git

# Environment setzen
export FORCE_CPU=true
export OMP_NUM_THREADS=8
export MODEL_PATH=vibevoice/VibeVoice-1.5B

# API starten
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

## ✅ Schritt-für-Schritt Erste Installation

```bash
# 1. Projekt entpacken
tar -xzf vibevoice-api.tar.gz
cd vibevoice-api

# 2. Prüfe System
docker info
free -h  # Mindestens 8GB frei

# 3. Starte optimierte Version
docker-compose -f docker-compose.cpu.yml up -d

# 4. Warte 3-5 Minuten, dann prüfe
curl http://localhost:8000/health

# 5. Wenn OK, teste:
python3 examples/client.py
```

## 🚀 Nach erstem erfolgreichen Start

```bash
# Normale Nutzung
docker-compose -f docker-compose.cpu.yml up -d

# Stoppen
docker-compose -f docker-compose.cpu.yml down

# Neustart
docker-compose -f docker-compose.cpu.yml restart

# Logs
docker-compose -f docker-compose.cpu.yml logs -f
```

## 📝 Nützliche Befehle

```bash
# Status prüfen
docker-compose -f docker-compose.cpu.yml ps

# In Container einloggen
docker exec -it vibevoice-api-cpu bash

# Container komplett neu bauen
docker-compose -f docker-compose.cpu.yml down -v
docker-compose -f docker-compose.cpu.yml build --no-cache
docker-compose -f docker-compose.cpu.yml up -d

# Cache löschen (spart Platz)
docker system prune -a
```

## 🎯 Optimale Einstellungen für verschiedene NUC Modelle

### NUC mit 8GB RAM:
```yaml
memory: 8G
cpus: '4.0'
MODEL_PATH: vibevoice/VibeVoice-1.5B
```

### NUC mit 16GB RAM:
```yaml
memory: 14G
cpus: '6.0'
MODEL_PATH: vibevoice/VibeVoice-1.5B
```

### NUC mit 32GB RAM:
```yaml
memory: 20G
cpus: '8.0'
MODEL_PATH: vibevoice/VibeVoice-7B  # Bessere Qualität möglich
```

## ⚠️ Wichtig für CPU-Only Betrieb

1. **Erste Generierung dauert lange** (2-5 Minuten) - das ist normal
2. **Jede weitere Generierung**: ~30-60 Sek. pro Minute Audio
3. **Modell bleibt im RAM** - kein Neustart zwischen Anfragen nötig
4. **Nutze kurze Texte** für schnellere Tests
5. **Swap aktivieren** hilft bei wenig RAM

## 🆘 Immer noch Probleme?

Schicke mir diese Informationen:

```bash
# System Info
uname -a
free -h
docker --version
docker info | grep -A5 Memory

# Container Info
docker-compose -f docker-compose.cpu.yml ps
docker-compose -f docker-compose.cpu.yml logs --tail=50

# Test
curl -v http://localhost:8000/health
```

Dann kann ich dir gezielt helfen!
