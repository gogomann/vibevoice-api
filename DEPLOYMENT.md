# VibeVoice API - Deployment Anleitung

## 🎉 Projekt erfolgreich erstellt!

Deine VibeVoice TTS API ist bereit für GitHub und Deployment.

## 📁 Projektstruktur

```
vibevoice-api/
├── app/
│   ├── __init__.py         # Package Initialisierung
│   └── main.py             # FastAPI Hauptanwendung
├── examples/
│   └── client.py           # Beispiel Python Client
├── .dockerignore           # Docker Ignore Rules
├── .env.example            # Beispiel Environment Variables
├── .gitattributes          # Git Attribute Rules
├── .gitignore              # Git Ignore Rules
├── Dockerfile              # Docker Image Definition
├── docker-compose.yml      # Docker Compose Konfiguration
├── LICENSE                 # MIT Lizenz
├── Makefile                # Convenience Commands
├── QUICKSTART.md           # Schnellstart Guide
├── README.md               # Vollständige Dokumentation
├── requirements.txt        # Python Dependencies
└── start.sh                # Startup Script
```

## 🚀 Nächste Schritte

### 1. GitHub Repository erstellen

```bash
# Navigiere zum Projektverzeichnis
cd vibevoice-api

# Füge dein GitHub Repository als Remote hinzu
git remote add origin https://github.com/DEIN-USERNAME/vibevoice-api.git

# Push zum GitHub
git push -u origin main
```

### 2. Lokales Testen

```bash
# Mit Docker (empfohlen)
./start.sh

# Oder mit Make
make build
make up
make logs

# Oder lokal ohne Docker
python3 -m venv venv
source venv/bin/activate
make install-local
make run-local
```

### 3. API Testen

```bash
# Health Check
curl http://localhost:8000/health

# Test Synthese
python3 examples/client.py

# Oder manuell mit cURL
curl -X POST http://localhost:8000/api/v1/synthesize \
  -H "Content-Type: application/json" \
  -d '{
    "text": "[Alice] Hallo Welt!",
    "speakers": [{"name": "Alice"}],
    "output_format": "base64"
  }'
```

## 🔧 Konfiguration

### Environment Variables (.env)

```bash
# Kopiere die Beispiel-Datei
cp .env.example .env

# Bearbeite die Werte
MODEL_PATH=vibevoice/VibeVoice-1.5B  # oder VibeVoice-7B
API_HOST=0.0.0.0
API_PORT=8000
```

### Modell Auswahl

- **VibeVoice-1.5B**: Schneller, weniger RAM (8GB), gut für CPU
- **VibeVoice-7B**: Bessere Qualität, mehr RAM (16GB), langsamer auf CPU

## 🐳 Docker Deployment

### Intel NUC (CPU-Only)

```bash
docker-compose up -d
```

### Mac M2 (mit MPS)

```bash
docker-compose up -d
# MPS wird automatisch erkannt
```

### Multi-Arch Build

```bash
# Für verschiedene Plattformen
docker buildx build --platform linux/amd64,linux/arm64 \
  -t dein-username/vibevoice-api:latest .
```

## 📊 Performance Erwartungen

### Intel NUC (CPU-Only)
- Erste Generierung: ~60-120 Sekunden (Modell wird geladen)
- Folgende Generierungen: ~30-60 Sekunden pro Minute Audio
- RAM Nutzung: 6-8 GB (1.5B Modell)

### Mac M2 (mit MPS)
- Erste Generierung: ~30-60 Sekunden
- Folgende Generierungen: ~10-20 Sekunden pro Minute Audio
- RAM Nutzung: 6-8 GB (1.5B Modell)

### Mit GPU (CUDA)
- Erste Generierung: ~10-20 Sekunden
- Folgende Generierungen: ~5-10 Sekunden pro Minute Audio
- VRAM: 6-8 GB

## 🛠️ Troubleshooting

### Problem: Modell lädt nicht
**Lösung**: Prüfe RAM-Verfügbarkeit und Docker Memory Limit
```bash
docker stats
# Erhöhe Memory Limit in docker-compose.yml wenn nötig
```

### Problem: API ist sehr langsam
**Lösung**: 
- Nutze 1.5B statt 7B Modell
- Reduziere Textlänge
- Erwäge GPU-Nutzung

### Problem: Port bereits belegt
**Lösung**: Ändere Port in docker-compose.yml
```yaml
ports:
  - "8001:8000"  # Nutze 8001 statt 8000
```

## 📚 API Dokumentation

Nach dem Start verfügbar unter:
- **OpenAPI/Swagger**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **Health Check**: http://localhost:8000/health

## 🔐 Sicherheitshinweise

⚠️ **Wichtig für Produktion**:

1. **Keine Voice Cloning ohne Zustimmung**
2. **Rate Limiting implementieren**
3. **Authentifizierung hinzufügen**
4. **HTTPS verwenden**
5. **Input Validierung**

## 📝 Nächste Erweiterungen

Mögliche Verbesserungen:
- [ ] Redis Cache für generierte Audios
- [ ] Batch Processing für mehrere Anfragen
- [ ] Websocket Support für Streaming
- [ ] Admin Dashboard
- [ ] Prometheus Metriken
- [ ] S3/MinIO Integration für Audio Storage
- [ ] Rate Limiting mit Redis
- [ ] API Key Authentication

## 🤝 Beitragen

Das Projekt ist Open Source (MIT License). Pull Requests sind willkommen!

## 📞 Support

Bei Problemen:
1. Prüfe die Logs: `make logs`
2. Erstelle ein GitHub Issue
3. Diskutiere im VibeVoice Discord: https://discord.gg/ZDEYTTRxWG

## ✅ Checkliste vor GitHub Push

- [x] .gitignore vorhanden
- [x] README.md vollständig
- [x] LICENSE Datei
- [x] Beispiele funktionieren
- [x] Docker Build erfolgreich
- [x] Dokumentation aktuell
- [ ] GitHub Repository erstellt
- [ ] Ersten Commit gepusht
- [ ] README auf GitHub prüfen

## 🎯 Produktions-Deployment Tipps

### VPS/Cloud Server

```bash
# SSH auf Server
ssh user@your-server.com

# Projekt klonen
git clone https://github.com/DEIN-USERNAME/vibevoice-api.git
cd vibevoice-api

# Starten
./start.sh

# Als Service einrichten (optional)
sudo cp vibevoice-api.service /etc/systemd/system/
sudo systemctl enable vibevoice-api
sudo systemctl start vibevoice-api
```

### Nginx Reverse Proxy (optional)

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        client_max_body_size 50M;
    }
}
```

## 🎊 Viel Erfolg!

Deine VibeVoice API ist bereit für den Einsatz. Bei Fragen oder Problemen, melde dich!
