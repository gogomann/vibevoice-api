# 🔧 VibeVoice API - Patch v2

## Was ist das?

Nur die **geänderten Dateien** um den Fehler "Keine Audio-Datei generiert" zu beheben.

## 📦 Enthaltene Dateien

- `Dockerfile` - Korrigierte VibeVoice Installation
- `main.py` - Geht nach `app/main.py`
- `PATCH_README.md` - Diese Datei

## 🚀 Installation

### Option 1: Patch auf bestehendes Projekt anwenden

```bash
# 1. Gehe in dein vibevoice-api Verzeichnis
cd vibevoice-api

# 2. Backup erstellen
cp Dockerfile Dockerfile.backup
cp app/main.py app/main.py.backup

# 3. Neue Dateien kopieren
cp /pfad/zu/patch/Dockerfile .
cp /pfad/zu/patch/main.py app/main.py

# 4. Altes Image entfernen und neu bauen
docker-compose -f docker-compose.cpu.yml down
docker rmi vibevoice-api-cpu 2>/dev/null || true
docker-compose -f docker-compose.cpu.yml up -d --build
```

### Option 2: Manuell ändern

**Dockerfile - Zeile ~24, ersetze:**
```dockerfile
RUN pip install --no-cache-dir git+https://github.com/vibevoice-community/VibeVoice.git
```

**Mit:**
```dockerfile
# Clone und installiere VibeVoice
WORKDIR /tmp
RUN git clone https://github.com/vibevoice-community/VibeVoice.git && \
    cd VibeVoice && \
    pip install --no-cache-dir -e .

WORKDIR /app
```

**app/main.py:**
- Komplette Datei aus diesem Patch verwenden
- Oder die Änderungen aus dem Git Diff übernehmen

## ✅ Was wurde gefixt?

### Problem 1: ModuleNotFoundError
**Fix:** Dockerfile jetzt mit korrekter Installation

### Problem 2: Keine Audio-Datei generiert
**Fix:** 
- Besseres Logging
- Sucht in mehreren Output-Verzeichnissen
- Zeigt stdout/stderr vom Subprocess
- Fügt `cwd` Parameter hinzu

## 🧪 Testen

Nach dem Patch:

```bash
# 1. Starten
./start-cpu.bat

# 2. Logs prüfen (sollte jetzt mehr Info zeigen)
docker-compose -f docker-compose.cpu.yml logs -f

# 3. Testen
curl -X POST http://localhost:8000/api/v1/synthesize \
  -H "Content-Type: application/json" \
  -d '{
    "text": "[Alice] Hallo Test",
    "speakers": [{"name": "Alice"}],
    "output_format": "base64"
  }'
```

Du solltest jetzt sehen:
```
INFO:app.main:VibeVoice Output: [detaillierte Ausgabe]
INFO:app.main:Prüfe Verzeichnis: ...
INFO:app.main:Audio gefunden in ...: ...
```

## 🆘 Wenn es immer noch nicht geht

Die Logs zeigen jetzt mehr Details. Schicke mir:

```bash
docker-compose -f docker-compose.cpu.yml logs --tail=100
```

Dann sehe ich genau was das inference_from_file.py Script macht!

## 📝 Änderungslog

**v2 (dieser Patch):**
- Besseres Logging in main.py
- Sucht in mehreren Output-Verzeichnissen
- Zeigt subprocess stdout/stderr
- Fügt cwd Parameter hinzu

**v1:**
- Dockerfile Fix für Installation
- main.py mit subprocess Logik
