#!/usr/bin/env python3
"""
VibeVoice API Client Beispiel
Zeigt verschiedene Nutzungsszenarien der API
"""

import requests
import base64
import time
from pathlib import Path

API_URL = "http://localhost:8000"

def check_health():
    """Prüfe ob die API läuft"""
    print("🔍 Prüfe API Status...")
    try:
        response = requests.get(f"{API_URL}/health", timeout=5)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ API ist bereit! Device: {data['device']}")
            return True
        else:
            print(f"❌ API antwortet mit Status {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"❌ API nicht erreichbar: {e}")
        return False

def beispiel_einfach():
    """Beispiel 1: Einfache TTS ohne Voice Cloning"""
    print("\n" + "="*60)
    print("📝 Beispiel 1: Einfache Text-to-Speech Synthese")
    print("="*60)
    
    payload = {
        "text": "[Alice] Hallo! Willkommen zu unserem ersten Beispiel. [Bob] Hi Alice! Das ist wirklich spannend!",
        "speakers": [
            {"name": "Alice"},
            {"name": "Bob"}
        ],
        "output_format": "base64"
    }
    
    print("🚀 Sende Anfrage...")
    start_time = time.time()
    
    response = requests.post(f"{API_URL}/api/v1/synthesize", json=payload)
    
    if response.status_code == 200:
        result = response.json()
        duration = time.time() - start_time
        
        if result["success"]:
            audio_bytes = base64.b64decode(result["audio_base64"])
            output_file = "output_einfach.wav"
            
            with open(output_file, "wb") as f:
                f.write(audio_bytes)
            
            print(f"✅ Erfolg!")
            print(f"   📁 Datei: {output_file}")
            print(f"   ⏱️  Audio-Dauer: {result['duration_seconds']:.2f} Sekunden")
            print(f"   ⌛ Verarbeitungszeit: {duration:.2f} Sekunden")
        else:
            print(f"❌ Fehler: {result.get('message', 'Unbekannter Fehler')}")
    else:
        print(f"❌ API Fehler: {response.status_code}")
        print(f"   {response.text}")

def beispiel_multi_speaker():
    """Beispiel 2: Konversation mit 3 Sprechern"""
    print("\n" + "="*60)
    print("📝 Beispiel 2: Multi-Speaker Konversation")
    print("="*60)
    
    konversation = """
[Alice] Willkommen zu unserem Podcast über künstliche Intelligenz!
[Bob] Danke Alice. Heute haben wir einen besonderen Gast.
[Charlie] Hallo zusammen! Ich freue mich hier zu sein.
[Alice] Charlie, erzähl uns von deiner Arbeit mit KI.
[Charlie] Gerne! Ich arbeite an natürlichsprachlichen Modellen.
[Bob] Das klingt faszinierend! Wie funktioniert das genau?
[Charlie] Im Kern geht es darum, dass Computer menschliche Sprache verstehen und generieren können.
[Alice] Unglaublich! Was sind die größten Herausforderungen?
[Charlie] Die Hauptherausforderung ist es, Kontext und Nuancen zu verstehen.
[Bob] Vielen Dank für diese Einblicke!
"""
    
    payload = {
        "text": konversation.strip(),
        "speakers": [
            {"name": "Alice", "description": "Moderatorin"},
            {"name": "Bob", "description": "Co-Moderator"},
            {"name": "Charlie", "description": "KI Experte"}
        ],
        "output_format": "base64"
    }
    
    print("🚀 Generiere längere Konversation...")
    start_time = time.time()
    
    response = requests.post(f"{API_URL}/api/v1/synthesize", json=payload)
    
    if response.status_code == 200:
        result = response.json()
        duration = time.time() - start_time
        
        if result["success"]:
            audio_bytes = base64.b64decode(result["audio_base64"])
            output_file = "output_multi_speaker.wav"
            
            with open(output_file, "wb") as f:
                f.write(audio_bytes)
            
            print(f"✅ Erfolg!")
            print(f"   📁 Datei: {output_file}")
            print(f"   ⏱️  Audio-Dauer: {result['duration_seconds']:.2f} Sekunden")
            print(f"   ⌛ Verarbeitungszeit: {duration:.2f} Sekunden")
            print(f"   🎭 Sprecher: Alice, Bob, Charlie")
        else:
            print(f"❌ Fehler: {result.get('message', 'Unbekannter Fehler')}")
    else:
        print(f"❌ API Fehler: {response.status_code}")

def beispiel_voice_cloning():
    """Beispiel 3: Voice Cloning mit Multipart"""
    print("\n" + "="*60)
    print("📝 Beispiel 3: Voice Cloning (Multipart Upload)")
    print("="*60)
    
    voice_file = "voice_reference.wav"
    
    if not Path(voice_file).exists():
        print(f"⚠️  Voice Reference Datei '{voice_file}' nicht gefunden.")
        print(f"   Lege eine WAV-Datei mit 3-10 Sekunden Sprache an.")
        return
    
    text = "[Me] Das ist ein Test mit meiner eigenen Stimme! Hoffentlich klingt es gut."
    
    print("🚀 Sende mit Voice Reference...")
    start_time = time.time()
    
    with open(voice_file, "rb") as f:
        files = {"voice_files": f}
        data = {
            "text": text,
            "speaker_names": "Me",
            "output_format": "audio"
        }
        
        response = requests.post(
            f"{API_URL}/api/v1/synthesize/multipart",
            data=data,
            files=files
        )
    
    if response.status_code == 200:
        duration = time.time() - start_time
        output_file = "output_cloned.wav"
        
        with open(output_file, "wb") as f:
            f.write(response.content)
        
        print(f"✅ Erfolg!")
        print(f"   📁 Datei: {output_file}")
        print(f"   ⌛ Verarbeitungszeit: {duration:.2f} Sekunden")
        print(f"   🎤 Voice Cloning aktiviert")
    else:
        print(f"❌ API Fehler: {response.status_code}")

def main():
    """Hauptfunktion"""
    print("\n" + "="*60)
    print("🎙️  VibeVoice API Client - Beispiele")
    print("="*60)
    
    if not check_health():
        print("\n❌ API ist nicht erreichbar. Bitte starte sie zuerst:")
        print("   docker-compose up -d")
        print("   oder")
        print("   python -m uvicorn app.main:app --host 0.0.0.0 --port 8000")
        return
    
    try:
        beispiel_einfach()
        
        time.sleep(1)
        beispiel_multi_speaker()
        
        time.sleep(1)
        beispiel_voice_cloning()
        
        print("\n" + "="*60)
        print("✅ Alle Beispiele abgeschlossen!")
        print("="*60)
        
    except KeyboardInterrupt:
        print("\n\n⚠️  Abgebrochen durch Benutzer")
    except Exception as e:
        print(f"\n❌ Fehler: {e}")

if __name__ == "__main__":
    main()
