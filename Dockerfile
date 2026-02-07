FROM python:3.11-slim

LABEL maintainer="VibeVoice API"
LABEL description="VibeVoice TTS API für Intel NUC (CPU) und Mac M2"

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV MODEL_PATH=vibevoice/VibeVoice-1.5B

RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    ffmpeg \
    libsndfile1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Clone und installiere VibeVoice
WORKDIR /tmp
RUN git clone https://github.com/vibevoice-community/VibeVoice.git && \
    cd VibeVoice && \
    pip install --no-cache-dir -e .

WORKDIR /app
COPY app/ ./app/

RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app
USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/health')"

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
