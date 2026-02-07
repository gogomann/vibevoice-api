.PHONY: help build up down logs test clean cpu-up cpu-down cpu-logs cpu-restart

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
	@echo "CPU-Optimierte Befehle (für Intel NUC):"
	@echo "  make cpu-up     - CPU-optimierte Version starten"
	@echo "  make cpu-down   - CPU Version stoppen"
	@echo "  make cpu-logs   - CPU Version Logs"
	@echo "  make cpu-restart - CPU Version neu starten"
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

# CPU-Optimierte Befehle
cpu-up:
	@echo "🚀 Starte CPU-optimierte Version..."
	@echo "⚙️  Konfiguration: 20GB RAM, 8 CPU Kerne, CPU-only"
	docker-compose -f docker-compose.cpu.yml up -d
	@echo "✅ API läuft auf http://localhost:8000"
	@echo "⏳ Erster Start dauert 3-5 Minuten (Modell wird geladen)"
	@echo "📋 Logs: make cpu-logs"

cpu-down:
	@echo "🛑 Stoppe CPU-optimierte Version..."
	docker-compose -f docker-compose.cpu.yml down

cpu-logs:
	@echo "📋 Zeige CPU Version Logs..."
	docker-compose -f docker-compose.cpu.yml logs -f

cpu-restart:
	@echo "🔄 Starte CPU Version neu..."
	docker-compose -f docker-compose.cpu.yml restart

cpu-stats:
	@echo "📊 CPU Version Stats..."
	docker stats vibevoice-api-cpu

test:
	@echo "🧪 Führe Test Client aus..."
	python3 examples/client.py

clean:
	@echo "🧹 Räume auf..."
	docker-compose down -v
	docker-compose -f docker-compose.cpu.yml down -v
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
