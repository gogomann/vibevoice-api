.PHONY: help build up down logs test clean

help:
	@echo "VibeVoice API - Verfügbare Befehle:"
	@echo ""
	@echo "  make build      - Docker Image bauen"
	@echo "  make up         - Container starten"
	@echo "  make down       - Container stoppen"
	@echo "  make logs       - Logs anzeigen"
	@echo "  make restart    - Container neu starten"
	@echo "  make test       - Beispiel Client ausführen"
	@echo "  make clean      - Aufräumen"
	@echo ""

build:
	@echo "🔨 Baue Docker Image..."
	docker-compose build

up:
	@echo "🚀 Starte Container..."
	docker-compose up -d
	@echo "✅ API läuft auf http://localhost:8000"
	@echo "📚 Dokumentation: http://localhost:8000/docs"

down:
	@echo "🛑 Stoppe Container..."
	docker-compose down

logs:
	@echo "📋 Zeige Logs..."
	docker-compose logs -f

restart:
	@echo "🔄 Starte Container neu..."
	docker-compose restart

test:
	@echo "🧪 Führe Test Client aus..."
	python3 examples/client.py

clean:
	@echo "🧹 Räume auf..."
	docker-compose down -v
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	find . -type f -name "output_*.wav" -delete 2>/dev/null || true
	@echo "✅ Aufgeräumt!"

install-local:
	@echo "📦 Installiere lokale Dependencies..."
	pip install -r requirements.txt
	pip install git+https://github.com/vibevoice-community/VibeVoice.git
	@echo "✅ Installation abgeschlossen!"

run-local:
	@echo "🚀 Starte API lokal..."
	python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
