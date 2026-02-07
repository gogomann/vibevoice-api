import os
import base64
import tempfile
import logging
import subprocess
import json
from pathlib import Path
from typing import List, Optional
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from fastapi.responses import JSONResponse, FileResponse
from pydantic import BaseModel, Field

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

MODEL_PATH = None
VIBEVOICE_DIR = "/tmp/VibeVoice"

@asynccontextmanager
async def lifespan(app: FastAPI):
    global MODEL_PATH
    
    MODEL_PATH = os.getenv("MODEL_PATH", "vibevoice/VibeVoice-1.5B")
    logger.info(f"VibeVoice Modell-Pfad: {MODEL_PATH}")
    logger.info("API bereit - Modell wird beim ersten Request geladen")
    
    yield

app = FastAPI(
    title="VibeVoice TTS API",
    description="API für Text-to-Speech mit Multi-Speaker Support und Voice Cloning",
    version="1.0.0",
    lifespan=lifespan
)

class Speaker(BaseModel):
    name: str = Field(..., description="Name des Sprechers (z.B. Alice, Frank)")
    description: Optional[str] = Field(None, description="Beschreibung des Sprechers")
    voice_reference: Optional[str] = Field(None, description="Base64-kodiertes Audio für Voice Cloning")

class TTSRequest(BaseModel):
    text: str = Field(..., description="Text der gesprochen werden soll. Format: '[Speaker1] Text [Speaker2] Text'")
    speakers: List[Speaker] = Field(..., description="Liste der Sprecher")
    output_format: str = Field("audio", description="'audio' für Audio-Datei oder 'base64' für Base64-String")
    sample_rate: int = Field(24000, description="Sample Rate (default: 24000)")
    
    class Config:
        json_schema_extra = {
            "example": {
                "text": "[Alice] Hallo! Willkommen zu unserem Podcast. [Frank] Danke Alice! Heute sprechen wir über KI.",
                "speakers": [
                    {"name": "Alice"},
                    {"name": "Frank"}
                ],
                "output_format": "audio"
            }
        }

class TTSResponse(BaseModel):
    success: bool
    audio_base64: Optional[str] = None
    file_path: Optional[str] = None
    duration_seconds: Optional[float] = None
    message: Optional[str] = None

async def save_voice_reference(voice_ref_base64: str) -> str:
    """Speichere Voice Reference als temporäre Datei"""
    audio_bytes = base64.b64decode(voice_ref_base64)
    temp_file = tempfile.NamedTemporaryFile(delete=False, suffix=".wav")
    temp_file.write(audio_bytes)
    temp_file.close()
    return temp_file.name

@app.get("/")
async def root():
    return {
        "message": "VibeVoice TTS API",
        "version": "1.0.0",
        "model": MODEL_PATH,
        "endpoints": {
            "synthesize": "/api/v1/synthesize",
            "synthesize_multipart": "/api/v1/synthesize/multipart",
            "health": "/health"
        }
    }

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "model_path": MODEL_PATH
    }

@app.post("/api/v1/synthesize", response_model=TTSResponse)
async def synthesize_speech(request: TTSRequest):
    """
    Generiere Speech aus Text mit einem oder mehreren Sprechern.
    
    Text Format:
    - Einzelner Sprecher: "Dies ist ein Text"
    - Mehrere Sprecher: "[Alice] Hallo! [Frank] Hi Alice!"
    """
    try:
        # Erstelle temporäre Textdatei
        text_file = tempfile.NamedTemporaryFile(mode='w', delete=False, suffix=".txt", encoding='utf-8')
        text_file.write(request.text)
        text_file.close()
        
        speaker_names = [s.name for s in request.speakers]
        voice_refs = {}
        
        # Voice References speichern
        for speaker in request.speakers:
            if speaker.voice_reference:
                try:
                    voice_ref_path = await save_voice_reference(speaker.voice_reference)
                    voice_refs[speaker.name] = voice_ref_path
                except Exception as e:
                    logger.error(f"Fehler beim Voice Reference für {speaker.name}: {e}")
        
        logger.info(f"Generiere Audio für {len(speaker_names)} Sprecher...")
        
        # Baue Befehl für VibeVoice
        cmd = [
            "python",
            f"{VIBEVOICE_DIR}/demo/inference_from_file.py",
            "--model_path", MODEL_PATH,
            "--txt_path", text_file.name,
            "--speaker_names"
        ] + speaker_names
        
        # Füge voice references hinzu wenn vorhanden
        if voice_refs:
            voice_paths = []
            for speaker_name in speaker_names:
                if speaker_name in voice_refs:
                    voice_paths.append(voice_refs[speaker_name])
                else:
                    # Nutze default voice
                    voice_paths.append("None")
            
            if any(p != "None" for p in voice_paths):
                cmd.extend(["--voice_paths"] + voice_paths)
        
        # Führe VibeVoice aus
        logger.info(f"Führe aus: {' '.join(cmd)}")
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=600  # 10 Minuten Timeout
        )
        
        # Cleanup
        os.unlink(text_file.name)
        for temp_file in voice_refs.values():
            try:
                os.unlink(temp_file)
            except:
                pass
        
        if result.returncode != 0:
            logger.error(f"VibeVoice Fehler: {result.stderr}")
            raise HTTPException(status_code=500, detail=f"VibeVoice Fehler: {result.stderr[:500]}")
        
        # Finde generierte Audio-Datei (VibeVoice speichert in outputs/)
        output_dir = Path(VIBEVOICE_DIR) / "demo" / "outputs"
        output_files = sorted(output_dir.glob("*.wav"), key=lambda x: x.stat().st_mtime, reverse=True)
        
        if not output_files:
            raise HTTPException(status_code=500, detail="Keine Audio-Datei generiert")
        
        output_path = str(output_files[0])
        logger.info(f"Audio generiert: {output_path}")
        
        # Berechne Dauer (approximativ)
        file_size = os.path.getsize(output_path)
        duration = file_size / (request.sample_rate * 2)  # Approximation für 16-bit mono
        
        if request.output_format == "base64":
            with open(output_path, "rb") as f:
                audio_base64 = base64.b64encode(f.read()).decode()
            
            return TTSResponse(
                success=True,
                audio_base64=audio_base64,
                duration_seconds=duration,
                message="Audio erfolgreich generiert"
            )
        else:
            return JSONResponse(
                content={
                    "success": True,
                    "duration_seconds": duration,
                    "message": "Audio erfolgreich generiert",
                    "download_url": f"/api/v1/download/{Path(output_path).name}"
                }
            )
    
    except subprocess.TimeoutExpired:
        logger.error("Timeout bei Audio-Generierung")
        raise HTTPException(status_code=504, detail="Timeout bei Audio-Generierung (>10 Minuten)")
    except Exception as e:
        logger.error(f"Fehler bei Synthese: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/synthesize/multipart")
async def synthesize_speech_multipart(
    text: str = Form(...),
    speaker_names: str = Form(...),
    output_format: str = Form("audio"),
    sample_rate: int = Form(24000),
    voice_files: Optional[List[UploadFile]] = File(None)
):
    """
    Generiere Speech mit Upload von Voice References als Multipart Form.
    """
    try:
        speaker_list = [s.strip() for s in speaker_names.split(",")]
        
        # Konvertiere zu TTSRequest Format
        speakers = []
        for idx, speaker_name in enumerate(speaker_list):
            speaker = {"name": speaker_name}
            
            if voice_files and idx < len(voice_files):
                content = await voice_files[idx].read()
                voice_ref_base64 = base64.b64encode(content).decode()
                speaker["voice_reference"] = voice_ref_base64
            
            speakers.append(Speaker(**speaker))
        
        request = TTSRequest(
            text=text,
            speakers=speakers,
            output_format=output_format,
            sample_rate=sample_rate
        )
        
        return await synthesize_speech(request)
    
    except Exception as e:
        logger.error(f"Fehler bei Synthese: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
