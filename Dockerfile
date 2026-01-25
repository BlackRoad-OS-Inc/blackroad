# BlackRoad AI - Qwen2.5 Model Container
# License: Apache 2.0 (model) + BlackRoad proprietary enhancements
# Platform: ARM64 (Raspberry Pi) + AMD64 (Cloud)

FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy BlackRoad AI infrastructure
COPY src/ ./src/
COPY config/ ./config/
COPY memory-bridge/ ./memory-bridge/

# Environment variables
ENV MODEL_NAME=Qwen/Qwen2.5-7B
ENV HUGGINGFACE_HUB_CACHE=/app/models
ENV BLACKROAD_MEMORY_ENABLED=true
ENV ENABLE_EMOJI_SUPPORT=true
ENV ENABLE_ACTION_EXECUTION=true

# Expose API port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Start the service
CMD ["python", "src/main.py"]
