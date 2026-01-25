# BlackRoad AI - API Gateway
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source
COPY src/ ./src/
COPY config/ ./config/

# Environment
ENV PYTHONUNBUFFERED=1

# Expose port
EXPOSE 7000

# Health check
HEALTHCHECK --interval=30s --timeout=10s \
    CMD curl -f http://localhost:7000/health || exit 1

# Run
CMD ["python", "src/main.py"]
