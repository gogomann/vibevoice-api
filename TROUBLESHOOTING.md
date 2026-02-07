# 🚨 Schnelle Problemlösungen - Intel NUC

## Problem: Start klappt nicht

### ✅ Lösung 1: CPU-optimierte Version nutzen

```bash
# WICHTIG: Nutze die CPU-optimierte Konfiguration!
./start-cpu.sh

# Oder:
make cpu-up
```

**NICHT verwenden:**
```bash
docker-compose up -d  # ❌ Falsches Compose File!
```

### ✅ Lösung 2: Docker Memory erhöhen

Docker auf 20GB Memory einstellen:

**Docker Desktop (wenn vorhanden):**
1. Docker Desktop öffnen
2. Settings → Resources → Memory
3. Schieberegler auf 20GB
4. Apply & Restart

**Linux:**
```bash
# Prüfe verfügbaren RAM
free -h

# Wenn wenig RAM: Erstelle Swap
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Permanent machen
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### ✅ Lösung 3: Kleineres Modell nutzen

In `docker-compose.cpu.yml`:
```yaml
environment:
  - MODEL_PATH=vibevoice/VibeVoice-1.5B  # ✅ Kleiner, schneller
  # - MODEL_PATH=vibevoice/VibeVoice-7B  # ❌ Zu groß für 8GB RAM
```

## Problem: "Cannot allocate memory"

```bash
# Prüfe Docker Stats
docker info | grep Memory

# Prüfe System RAM
free -h

# Swap erstellen (siehe oben)
```

## Problem: API antwortet nicht nach 5 Minuten

### Prüfe was los ist:

```bash
# 1. Container Status
docker-compose -f docker-compose.cpu.yml ps

# 2. Logs ansehen
docker-compose -f docker-compose.cpu.yml logs --tail=100

# 3. In Container einloggen
docker exec -it vibevoice-api-cpu bash
# Dann im Container:
curl http://localhost:8000/health
```

### Häufige Ursachen:

**"Downloading model..."**
→ Modell wird noch heruntergeladen, warte noch 5-10 Minuten

**"Loading model..."**
→ Modell wird geladen, warte noch 2-5 Minuten

**"CUDA/GPU Error"**
→ Prüfe ob `FORCE_CPU=true` gesetzt ist in docker-compose.cpu.yml

## Problem: Extrem langsam

### Das ist normal auf CPU!

**Erwartete Zeiten:**
- Erster Start: 3-5 Minuten
- Erstes Audio (10 Sek): ~60 Sekunden
- Weiteres Audio (1 Min): ~3 Minuten

### Schneller machen:

```yaml
# In docker-compose.cpu.yml
environment:
  - OMP_NUM_THREADS=16  # Erhöhe (Anzahl CPU Threads)
```

## Problem: Port 8000 bereits belegt

```bash
# Ändere Port in docker-compose.cpu.yml
ports:
  - "8001:8000"  # Nutze 8001 statt 8000

# Oder finde was Port 8000 nutzt:
sudo lsof -i :8000
sudo netstat -tlnp | grep 8000
```

## Problem: Container stoppt sofort nach Start

```bash
# Prüfe Fehler
docker-compose -f docker-compose.cpu.yml logs

# Rebuilde komplett neu
docker-compose -f docker-compose.cpu.yml down -v
docker-compose -f docker-compose.cpu.yml build --no-cache
docker-compose -f docker-compose.cpu.yml up -d
```

## Problem: Modell lädt nicht

```bash
# Prüfe Internetverbindung
ping huggingface.co

# Cache löschen
docker volume rm vibevoice-api_model-cache

# Neu starten
make cpu-up
```

## ✅ Kompletter Neustart (wenn alles andere fehlschlägt)

```bash
# 1. Alles stoppen und löschen
docker-compose -f docker-compose.cpu.yml down -v
docker system prune -a -f
docker volume prune -f

# 2. Neu builden
docker-compose -f docker-compose.cpu.yml build --no-cache

# 3. Starten
./start-cpu.sh

# 4. Logs live ansehen
make cpu-logs
```

## 📊 Diagnose Befehle

```bash
# System Info
free -h
nproc
uname -a

# Docker Info
docker --version
docker info | grep -A5 Memory
docker ps -a

# Container Logs
make cpu-logs

# Container Stats
make cpu-stats

# Ins Container einloggen
docker exec -it vibevoice-api-cpu bash
```

## 🆘 Wenn nichts hilft

Schicke mir diese Infos:

```bash
# Sammle alle Infos
echo "=== System ===" > debug.txt
free -h >> debug.txt
echo "" >> debug.txt
echo "=== Docker ===" >> debug.txt
docker --version >> debug.txt
docker info | grep -A5 Memory >> debug.txt
echo "" >> debug.txt
echo "=== Container ===" >> debug.txt
docker-compose -f docker-compose.cpu.yml ps >> debug.txt
echo "" >> debug.txt
echo "=== Logs ===" >> debug.txt
docker-compose -f docker-compose.cpu.yml logs --tail=100 >> debug.txt

cat debug.txt
```

Dann kann ich dir genau helfen!

## ⚡ Schnellstart für Ungeduldige

```bash
# Das hier einfach ausführen:
cd vibevoice-api
./start-cpu.sh

# Warte 5 Minuten, dann:
curl http://localhost:8000/health

# Wenn OK:
python3 examples/client.py
```

## 📞 Weitere Hilfe

- **Detaillierte Anleitung**: INTEL_NUC_SETUP.md
- **Vollständige Doku**: README.md
- **Deployment**: DEPLOYMENT.md
