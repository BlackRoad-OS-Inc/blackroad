# BlackRoad AI - Ollama Runtime with Multi-Model Support
# License: MIT (Ollama) + BlackRoad proprietary enhancements

FROM ollama/ollama:latest

# Install additional tools
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies for [MEMORY] integration
COPY requirements.txt /tmp/
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt

# Copy BlackRoad enhancements
COPY blackroad-wrapper/ /app/blackroad-wrapper/
COPY models/ /app/models/
COPY scripts/ /app/scripts/

# Environment
ENV OLLAMA_HOST=0.0.0.0
ENV BLACKROAD_MEMORY_ENABLED=true
ENV OLLAMA_MODELS=/root/.ollama/models

# Expose ports
EXPOSE 11434  # Ollama API
EXPOSE 8001   # BlackRoad wrapper API

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s \
    CMD curl -f http://localhost:11434/api/tags || exit 1

# Start script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
