# VibeVoice API - Schnellstart

## Schritt 1: Installation

```bash
# Repository klonen
git clone https://github.com/DEIN-USERNAME/vibevoice-api.git
cd vibevoice-api
```

## Schritt 2: Starten (mit Docker)

```bash
# Einfach das Startup Script ausführen
./start.sh
```

Das war's! Die API läuft jetzt auf `http://localhost:8000`

## Schritt 3: Testen

### Mit cURL:

```bash
curl -X POST http://localhost:8000/api/v1/synthesize \
  -H "Content-Type: application/json" \
  -d '{
    "text": "[Alice] Hallo Welt!",
    "speakers": [{"name": "Alice"}],
    "output_format": "base64"
  }'
```

### Mit dem Python Client:

```bash
python3 examples/client.py
```

### Im Browser:

Öffne: http://localhost:8000/docs

## Nützliche Befehle

```bash
# Logs anzeigen
make logs

# API stoppen
make down

# API neu starten
make restart

# Aufräumen
make clean
```

## Alternative: Lokale Installation (ohne Docker)

```bash
# Virtual Environment
python3 -m venv venv
source venv/bin/activate

# Dependencies installieren
pip install -r requirements.txt
pip install git+https://github.com/vibevoice-community/VibeVoice.git

# API starten
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

## Troubleshooting

### API startet nicht?
```bash
# Prüfe die Logs
docker-compose logs -f

# Prüfe ob genug RAM verfügbar ist (min. 8 GB)
```

### Zu langsam?
- Das ist normal auf CPU (Intel NUC)
- Nutze das kleinere 1.5B Modell (Standard)
- Für Produktion: Nutze eine GPU

### Port bereits belegt?
```bash
# Ändere den Port in docker-compose.yml
ports:
  - "8001:8000"  # Nutze Port 8001 statt 8000
```

## Nächste Schritte

- Lies die vollständige [README.md](README.md)
- Probiere die [Beispiele](examples/)
- Schau dir die [API Dokumentation](http://localhost:8000/docs) an
