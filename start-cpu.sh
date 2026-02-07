#!/bin/bash

echo "======================================"
echo "🖥️  VibeVoice API - Intel NUC Setup"
echo "======================================"
echo ""
echo "CPU-Only Modus mit 20GB RAM"
echo ""

check_system() {
    echo "📊 System-Check..."
    
    # Prüfe RAM
    available_ram=$(free -g | awk '/^Mem:/{print $7}')
    total_ram=$(free -g | awk '/^Mem:/{print $2}')
    
    echo "   RAM: ${available_ram}GB verfügbar von ${total_ram}GB gesamt"
    
    if [ "$available_ram" -lt 8 ]; then
        echo "   ⚠️  Warnung: Weniger als 8GB RAM verfügbar!"
        echo "   Schließe andere Programme oder erstelle Swap."
    else
        echo "   ✅ Genug RAM verfügbar"
    fi
    
    # Prüfe CPU Kerne
    cpu_cores=$(nproc)
    echo "   CPU: ${cpu_cores} Kerne"
    
    # Prüfe Docker
    if ! command -v docker &> /dev/null; then
        echo "   ❌ Docker ist nicht installiert!"
        exit 1
    fi
    echo "   ✅ Docker installiert"
    
    # Prüfe Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        echo "   ❌ Docker Compose ist nicht installiert!"
        exit 1
    fi
    echo "   ✅ Docker Compose installiert"
}

check_docker_resources() {
    echo ""
    echo "🐳 Docker Ressourcen-Check..."
    
    # Prüfe Docker Memory Limit
    docker_mem=$(docker info 2>/dev/null | grep "Total Memory" | awk '{print $3}')
    
    if [ -n "$docker_mem" ]; then
        echo "   Docker Memory: ${docker_mem}"
    fi
    
    echo "   Stelle sicher dass Docker mindestens 20GB Memory hat"
}

build_and_start() {
    echo ""
    echo "🔨 Baue Docker Image..."
    docker-compose -f docker-compose.cpu.yml build
    
    if [ $? -ne 0 ]; then
        echo "❌ Build fehlgeschlagen!"
        exit 1
    fi
    
    echo ""
    echo "🚀 Starte CPU-optimierte Version..."
    echo "   - 20GB RAM Limit"
    echo "   - 8 CPU Kerne"
    echo "   - CPU-only (kein GPU)"
    echo ""
    
    docker-compose -f docker-compose.cpu.yml up -d
    
    if [ $? -ne 0 ]; then
        echo "❌ Start fehlgeschlagen!"
        echo ""
        echo "Mögliche Lösungen:"
        echo "1. Erhöhe Docker Memory Limit auf mindestens 20GB"
        echo "2. Prüfe Logs: docker-compose -f docker-compose.cpu.yml logs"
        echo "3. Erstelle Swap: siehe INTEL_NUC_SETUP.md"
        exit 1
    fi
}

wait_for_api() {
    echo ""
    echo "⏳ Warte auf API (dies kann 3-5 Minuten dauern beim ersten Start)..."
    echo "   Das Modell wird heruntergeladen und geladen..."
    echo ""
    
    max_attempts=60
    attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s http://localhost:8000/health > /dev/null 2>&1; then
            echo ""
            echo "✅ API ist bereit!"
            return 0
        fi
        
        attempt=$((attempt + 1))
        
        # Zeige Fortschritt
        if [ $((attempt % 6)) -eq 0 ]; then
            echo "   Warte... (${attempt}/${max_attempts})"
        else
            echo -n "."
        fi
        
        sleep 5
    done
    
    echo ""
    echo "⚠️  API antwortet nicht nach $((max_attempts * 5)) Sekunden"
    echo ""
    echo "Das Modell lädt möglicherweise noch. Prüfe:"
    echo "  docker-compose -f docker-compose.cpu.yml logs -f"
    echo ""
    echo "Oder warte weitere 5 Minuten und prüfe dann:"
    echo "  curl http://localhost:8000/health"
    return 1
}

show_info() {
    echo ""
    echo "======================================"
    echo "✅ VibeVoice API läuft auf CPU!"
    echo "======================================"
    echo ""
    echo "🌐 API:           http://localhost:8000"
    echo "📚 Dokumentation: http://localhost:8000/docs"
    echo "❤️  Health Check:  http://localhost:8000/health"
    echo ""
    echo "⚙️  Konfiguration:"
    echo "   - Device: CPU-only"
    echo "   - RAM: 20GB Limit"
    echo "   - CPU: Bis zu 8 Kerne"
    echo ""
    echo "⏱️  Performance (CPU-only):"
    echo "   - Erster Request: 2-5 Minuten"
    echo "   - Weitere Requests: ~30-60 Sek. pro Minute Audio"
    echo ""
    echo "Nützliche Befehle:"
    echo "  make cpu-logs    - Logs anzeigen"
    echo "  make cpu-down    - API stoppen"
    echo "  make cpu-restart - API neu starten"
    echo "  make cpu-stats   - Ressourcen überwachen"
    echo "  make test        - Test Client ausführen"
    echo ""
    echo "📋 Logs live: docker-compose -f docker-compose.cpu.yml logs -f"
    echo ""
}

show_troubleshooting() {
    echo ""
    echo "⚠️  Die API läuft möglicherweise noch nicht."
    echo ""
    echo "📝 Troubleshooting Schritte:"
    echo ""
    echo "1. Prüfe ob Container läuft:"
    echo "   docker-compose -f docker-compose.cpu.yml ps"
    echo ""
    echo "2. Prüfe Logs:"
    echo "   docker-compose -f docker-compose.cpu.yml logs --tail=50"
    echo ""
    echo "3. Prüfe RAM Nutzung:"
    echo "   docker stats vibevoice-api-cpu"
    echo ""
    echo "4. Warte weitere 5 Minuten, dann teste:"
    echo "   curl http://localhost:8000/health"
    echo ""
    echo "5. Wenn weiterhin Probleme:"
    echo "   Lies INTEL_NUC_SETUP.md für detaillierte Hilfe"
    echo ""
}

# Main
echo ""
check_system
check_docker_resources

echo ""
read -p "Fortfahren? (j/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[JjYy]$ ]]; then
    echo "Abgebrochen."
    exit 0
fi

build_and_start

if wait_for_api; then
    show_info
else
    show_troubleshooting
fi
