# Minimal YOLO backend - < 800MB
FROM python:3.11-slim

WORKDIR /app

# Install minimal system deps for OpenCV
RUN apt-get update && apt-get install -y --no-install-recommends \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    wget \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Install exact minimal versions
COPY backend/requirements.txt requirements.txt
RUN pip install --no-cache-dir \
    fastapi==0.104.1 \
    uvicorn==0.24.0 \
    ultralytics==8.0.196 \
    opencv-python==4.8.1.78 \
    numpy==1.24.4 \
    && rm -rf /root/.cache/pip

# Copy app
COPY railway_app_real.py .

# Download YOLO weights
RUN wget -O yolov8n.pt https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8n.pt

# Create uploads
RUN mkdir -p /app/uploads

# Remove Python cache and docs
RUN find /usr/local/lib/python3.11 -name "*.pyc" -delete || true
RUN find /usr/local/lib/python3.11 -name "__pycache__" -type d -exec rm -rf {} + || true
RUN rm -rf /root/.cache/pip /root/.cache

EXPOSE 8000
CMD ["python", "railway_app_real.py"]
