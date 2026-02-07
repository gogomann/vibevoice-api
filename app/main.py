import os
import base64
import tempfile
import logging
from pathlib import Path
from typing import List, Optional
from contextlib import asynccontextmanager

import torch
import torchaudio
from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from fastapi.responses import JSONResponse, FileResponse
from pydantic import BaseModel, Field

from vibevoice.model import VibeVoice
from vibevoice.inference import inference

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

model_instance = None
device = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    global model_instance, device
    
    model_path = os.getenv("MODEL_PATH", "vibevoice/VibeVoice-1.5B")
    
    if torch.cuda.is_available():
        device = "cuda"
        logger.info("CUDA verfügbar - nutze GPU")
    elif hasattr(torch.backends, 'mps') and torch.backends.mps.is_available():
        device = "mps"
        logger.info("MPS verfügbar - nutze Apple Silicon GPU")
    else:
        device = "cpu"
        logger.info("Nutze CPU - dies kann langsam sein")
    
    logger.info(f"Lade VibeVoice Modell: {model_path}")
    try:
        model_instance = VibeVoice.from_pretrained(
            model_path,
            device=device,
            torch_dtype=torch.float32 if device == "cpu" else torch.float16
        )
        logger.info("Modell erfolgreich geladen")
    except Exception as e:
        logger.error(f"Fehler beim Laden des Modells: {e}")
        raise
    
    yield
    
    del model_instance
    if device != "cpu":
        torch.cuda.empty_cache() if device == "cuda" else None

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
        "device": device,
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
        "model_loaded": model_instance is not None,
        "device": device
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
        if model_instance is None:
            raise HTTPException(status_code=503, detail="Modell nicht geladen")
        
        speaker_names = [s.name for s in request.speakers]
        voice_refs = {}
        
        for speaker in request.speakers:
            if speaker.voice_reference:
                try:
                    voice_ref_path = await save_voice_reference(speaker.voice_reference)
                    voice_refs[speaker.name] = voice_ref_path
                except Exception as e:
                    logger.error(f"Fehler beim Voice Reference für {speaker.name}: {e}")
        
        logger.info(f"Generiere Audio für Text: {request.text[:100]}...")
        
        output_audio = inference(
            model=model_instance,
            text=request.text,
            speaker_names=speaker_names,
            voice_refs=voice_refs if voice_refs else None,
            device=device
        )
        
        for temp_file in voice_refs.values():
            try:
                os.unlink(temp_file)
            except:
                pass
        
        output_path = tempfile.mktemp(suffix=".wav")
        torchaudio.save(
            output_path,
            output_audio.cpu(),
            request.sample_rate
        )
        
        duration = output_audio.shape[-1] / request.sample_rate
        
        if request.output_format == "base64":
            with open(output_path, "rb") as f:
                audio_base64 = base64.b64encode(f.read()).decode()
            
            os.unlink(output_path)
            
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
                    "download_url": f"/api/v1/download/{os.path.basename(output_path)}"
                }
            )
    
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
    
    - text: Text der gesprochen werden soll
    - speaker_names: Komma-getrennte Sprechernamen (z.B. "Alice,Frank")
    - output_format: 'audio' oder 'base64'
    - voice_files: Optional Audio-Dateien für Voice Cloning (in der gleichen Reihenfolge wie speaker_names)
    """
    try:
        if model_instance is None:
            raise HTTPException(status_code=503, detail="Modell nicht geladen")
        
        speaker_list = [s.strip() for s in speaker_names.split(",")]
        voice_refs = {}
        
        if voice_files:
            for idx, voice_file in enumerate(voice_files):
                if idx < len(speaker_list):
                    content = await voice_file.read()
                    temp_file = tempfile.NamedTemporaryFile(delete=False, suffix=".wav")
                    temp_file.write(content)
                    temp_file.close()
                    voice_refs[speaker_list[idx]] = temp_file.name
        
        logger.info(f"Generiere Audio für Text: {text[:100]}...")
        
        output_audio = inference(
            model=model_instance,
            text=text,
            speaker_names=speaker_list,
            voice_refs=voice_refs if voice_refs else None,
            device=device
        )
        
        for temp_file in voice_refs.values():
            try:
                os.unlink(temp_file)
            except:
                pass
        
        output_path = tempfile.mktemp(suffix=".wav")
        torchaudio.save(
            output_path,
            output_audio.cpu(),
            sample_rate
        )
        
        duration = output_audio.shape[-1] / sample_rate
        
        if output_format == "base64":
            with open(output_path, "rb") as f:
                audio_base64 = base64.b64encode(f.read()).decode()
            
            os.unlink(output_path)
            
            return {
                "success": True,
                "audio_base64": audio_base64,
                "duration_seconds": duration,
                "message": "Audio erfolgreich generiert"
            }
        else:
            return FileResponse(
                path=output_path,
                media_type="audio/wav",
                filename="output.wav"
            )
    
    except Exception as e:
        logger.error(f"Fehler bei Synthese: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
