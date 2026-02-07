# VibeVoice TTS API

Eine vollständige REST API für Microsoft's VibeVoice Text-to-Speech System mit Multi-Speaker Support und Voice Cloning.

## Features

- ✅ **Multi-Speaker Support**: Bis zu 4 verschiedene Sprecher in einem Audio
- ✅ **Voice Cloning**: Klone Stimmen durch Upload von Audio-Referenzen
- ✅ **Lange Audiogenerierung**: Bis zu 90 Minuten Audio in einem Durchgang
- ✅ **Flexible Outputs**: Audio-Datei oder Base64-kodiert
- ✅ **Docker Support**: Läuft auf Intel NUC (CPU) und Mac M2 (MPS)
- ✅ **REST API**: Einfache Integration in bestehende Systeme

## Technische Details

### Unterstützte Modelle

- **VibeVoice-1.5B**: Standard-Modell (empfohlen für CPU)
- **VibeVoice-7B**: Größeres Modell (bessere Qualität, mehr RAM benötigt)

### Hardware-Anforderungen

#### Minimum (CPU-Only)
- **CPU**: Intel/AMD x86_64 oder Apple Silicon (M1/M2)
- **RAM**: 8 GB (16 GB empfohlen für 7B Modell)
- **Speicher**: 10 GB frei

#### Empfohlen
- **CPU**: 8+ Kerne
- **RAM**: 16 GB
- **GPU**: Optional (CUDA oder MPS für bessere Performance)

## Installation

### 1. Mit Docker (Empfohlen)

```bash
# Repository klonen
git clone https://github.com/DEIN-USERNAME/vibevoice-api.git
cd vibevoice-api

# Environment Variables kopieren
cp .env.example .env

# Docker Container bauen und starten
docker-compose up -d

# Logs anzeigen
docker-compose logs -f
```

### 2. Lokale Installation

```bash
# Repository klonen
git clone https://github.com/DEIN-USERNAME/vibevoice-api.git
cd vibevoice-api

# Virtual Environment erstellen
python3 -m venv venv
source venv/bin/activate  # Linux/Mac
# oder
.\venv\Scripts\activate  # Windows

# Dependencies installieren
pip install -r requirements.txt
pip install git+https://github.com/vibevoice-community/VibeVoice.git

# API starten
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

## API Verwendung

### Health Check

```bash
curl http://localhost:8000/health
```

### Einfache Synthese (JSON)

```bash
curl -X POST http://localhost:8000/api/v1/synthesize \
  -H "Content-Type: application/json" \
  -d '{
    "text": "[Alice] Hallo! Willkommen zu unserem Podcast. [Frank] Danke Alice! Heute sprechen wir über künstliche Intelligenz.",
    "speakers": [
      {"name": "Alice"},
      {"name": "Frank"}
    ],
    "output_format": "base64"
  }'
```

### Mit Voice Cloning (Multipart)

```bash
curl -X POST http://localhost:8000/api/v1/synthesize/multipart \
  -F "text=[Alice] Hallo aus meiner eigenen Stimme!" \
  -F "speaker_names=Alice" \
  -F "output_format=audio" \
  -F "voice_files=@alice_voice.wav"
```

### Python Client Beispiel

```python
import requests
import base64

url = "http://localhost:8000/api/v1/synthesize"

payload = {
    "text": "[Alice] Hallo Welt! [Bob] Hi Alice, wie geht's?",
    "speakers": [
        {"name": "Alice"},
        {"name": "Bob"}
    ],
    "output_format": "base64"
}

response = requests.post(url, json=payload)
result = response.json()

if result["success"]:
    # Base64 zu Audio speichern
    audio_bytes = base64.b64decode(result["audio_base64"])
    with open("output.wav", "wb") as f:
        f.write(audio_bytes)
    print(f"Audio gespeichert! Dauer: {result['duration_seconds']} Sekunden")
```

### Mit Voice Cloning

```python
import requests
import base64

url = "http://localhost:8000/api/v1/synthesize"

# Voice Reference als Base64 vorbereiten
with open("my_voice.wav", "rb") as f:
    voice_ref_base64 = base64.b64encode(f.read()).decode()

payload = {
    "text": "[Me] Das ist meine eigene Stimme!",
    "speakers": [
        {
            "name": "Me",
            "voice_reference": voice_ref_base64
        }
    ],
    "output_format": "base64"
}

response = requests.post(url, json=payload)
result = response.json()

if result["success"]:
    audio_bytes = base64.b64decode(result["audio_base64"])
    with open("cloned_output.wav", "wb") as f:
        f.write(audio_bytes)
```

## Text Format

### Einzelner Sprecher
```
"Dies ist ein einfacher Text der von einem Sprecher gesprochen wird."
```

### Mehrere Sprecher
```
"[Alice] Hallo! Willkommen zu unserem Podcast. [Frank] Danke Alice! Heute sprechen wir über KI. [Alice] Das ist ein spannendes Thema!"
```

### Tipps für bessere Ergebnisse

1. **Punktuation**: Nutze korrekte Satzzeichen für natürliche Pausen
2. **Länge**: Teile sehr lange Texte in mehrere Anfragen auf
3. **Sprecher-Tags**: Verwende klare, kurze Sprechernamen in eckigen Klammern
4. **Voice References**: 3-10 Sekunden klares Audio funktioniert am besten

## API Endpunkte

### GET `/`
Root-Endpunkt mit API-Informationen

### GET `/health`
Health Check für Monitoring

### POST `/api/v1/synthesize`
Haupt-Endpunkt für TTS mit JSON

**Request Body:**
```json
{
  "text": "string",
  "speakers": [
    {
      "name": "string",
      "description": "string (optional)",
      "voice_reference": "base64_string (optional)"
    }
  ],
  "output_format": "audio|base64",
  "sample_rate": 24000
}
```

**Response:**
```json
{
  "success": true,
  "audio_base64": "...",
  "duration_seconds": 12.5,
  "message": "Audio erfolgreich generiert"
}
```

### POST `/api/v1/synthesize/multipart`
TTS mit Multipart-Upload für Voice References

**Form Data:**
- `text`: Text der gesprochen werden soll
- `speaker_names`: Komma-getrennte Sprechernamen
- `output_format`: "audio" oder "base64"
- `sample_rate`: Sample Rate (default: 24000)
- `voice_files`: Audio-Dateien für Voice Cloning (optional)

## Docker Konfiguration

### Environment Variables

- `MODEL_PATH`: Pfad zum Modell (default: `vibevoice/VibeVoice-1.5B`)
- `API_HOST`: API Host (default: `0.0.0.0`)
- `API_PORT`: API Port (default: `8000`)

### Multi-Arch Build

Für verschiedene Architekturen:

```bash
# Für AMD64 (Intel NUC)
docker build --platform linux/amd64 -t vibevoice-api:amd64 .

# Für ARM64 (Mac M2)
docker build --platform linux/arm64 -t vibevoice-api:arm64 .

# Multi-Arch Build
docker buildx build --platform linux/amd64,linux/arm64 -t vibevoice-api:latest .
```

## Performance-Optimierung

### CPU-Only
- Nutze das 1.5B Modell
- Reduziere die maximale Textlänge
- Erhöhe RAM wenn möglich

### Mit GPU/MPS
- Das Modell erkennt automatisch CUDA oder MPS
- Deutlich schnellere Generierung
- Kann größere Batch-Sizes verarbeiten

## Troubleshooting

### "Modell nicht geladen"
- Stelle sicher, dass genug RAM verfügbar ist
- Prüfe die Logs: `docker-compose logs -f`
- Versuche das kleinere 1.5B Modell

### Langsame Generierung
- CPU-only ist langsam, das ist normal
- Erwäge GPU-Nutzung wenn verfügbar
- Reduziere die Textlänge

### Out of Memory
- Reduziere die Textlänge
- Nutze das kleinere 1.5B Modell
- Erhöhe Docker Memory Limit

## Entwicklung

### Tests ausführen
```bash
python -m pytest tests/
```

### Linting
```bash
black app/
flake8 app/
```

## Lizenz

Basierend auf VibeVoice (MIT License) von Microsoft Research und dem Community Fork.

Siehe [LICENSE](LICENSE) für Details.

## Credits

- **Microsoft Research**: Originales VibeVoice Modell
- **vibevoice-community**: Community Fork und Erhaltung des Codes
- **HuggingFace**: Model Hosting

## Wichtige Hinweise

⚠️ **Verantwortungsvolle Nutzung**: Dieses Tool kann hochwertige Sprachsynthese erzeugen. Nutze es verantwortungsvoll:
- Kein Voice Cloning ohne explizite Zustimmung
- Kennzeichne KI-generierte Inhalte
- Keine Deepfakes oder irreführende Inhalte
- Halte dich an lokale Gesetze

⚠️ **Research Only**: VibeVoice ist für Forschungszwecke konzipiert, nicht für kommerzielle Nutzung ohne weitere Tests.

## Support

Bei Fragen oder Problemen:
1. Prüfe die [Issues](https://github.com/DEIN-USERNAME/vibevoice-api/issues)
2. Erstelle ein neues Issue mit Details
3. Diskutiere im [VibeVoice Discord](https://discord.gg/ZDEYTTRxWG)
