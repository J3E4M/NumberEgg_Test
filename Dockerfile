# ONNX YOLO - Simple & Fast
FROM python:3.11-slim

WORKDIR /app

# Minimal dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Install packages (no ultralytics needed for inference)
RUN pip install --no-cache-dir \
    fastapi==0.104.1 \
    uvicorn==0.24.0 \
    onnxruntime==1.16.3 \
    numpy==1.24.4 \
    pillow==10.0.0 \
    opencv-python-headless==4.8.1.78

# Copy application
COPY railway_app_real.py .

# ✅ Download pre-converted ONNX model (skip conversion)
RUN wget -q -O yolov8n.onnx https://github.com/ultralytics/assets/releases/download/v8.0.0/yolov8n.onnx

# Create uploads
RUN mkdir -p /app/uploads

# Clean cache
RUN rm -rf /root/.cache/pip

EXPOSE 8000
CMD ["python", "railway_app_real.py"]