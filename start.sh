#!/bin/bash

echo "======================================"
echo "🎙️  VibeVoice API Startup"
echo "======================================"
echo ""

check_docker() {
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker ist nicht installiert!"
        echo "   Installiere Docker: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        echo "❌ Docker Compose ist nicht installiert!"
        echo "   Installiere Docker Compose: https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    echo "✅ Docker ist installiert"
}

setup_env() {
    if [ ! -f .env ]; then
        echo "📝 Erstelle .env Datei..."
        cp .env.example .env
        echo "✅ .env Datei erstellt"
    else
        echo "✅ .env Datei existiert bereits"
    fi
}

build_and_start() {
    echo ""
    echo "🔨 Baue Docker Image..."
    docker-compose build
    
    if [ $? -ne 0 ]; then
        echo "❌ Build fehlgeschlagen!"
        exit 1
    fi
    
    echo ""
    echo "🚀 Starte Container..."
    docker-compose up -d
    
    if [ $? -ne 0 ]; then
        echo "❌ Start fehlgeschlagen!"
        exit 1
    fi
}

wait_for_api() {
    echo ""
    echo "⏳ Warte auf API..."
    
    max_attempts=30
    attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s http://localhost:8000/health > /dev/null 2>&1; then
            echo "✅ API ist bereit!"
            return 0
        fi
        
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done
    
    echo ""
    echo "⚠️  API antwortet nicht nach ${max_attempts} Versuchen"
    echo "   Prüfe die Logs: docker-compose logs -f"
    return 1
}

show_info() {
    echo ""
    echo "======================================"
    echo "✅ VibeVoice API läuft!"
    echo "======================================"
    echo ""
    echo "🌐 API:           http://localhost:8000"
    echo "📚 Dokumentation: http://localhost:8000/docs"
    echo "❤️  Health Check:  http://localhost:8000/health"
    echo ""
    echo "Nützliche Befehle:"
    echo "  make logs       - Logs anzeigen"
    echo "  make down       - API stoppen"
    echo "  make restart    - API neu starten"
    echo "  make test       - Test Client ausführen"
    echo ""
    echo "📋 Logs anzeigen: docker-compose logs -f"
    echo ""
}

check_docker
setup_env
build_and_start

if wait_for_api; then
    show_info
else
    echo ""
    echo "⚠️  Die API läuft möglicherweise noch nicht."
    echo "   Warte einige Minuten und prüfe dann:"
    echo "   curl http://localhost:8000/health"
fi
