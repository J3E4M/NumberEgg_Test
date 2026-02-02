# ONNX YOLO - Simple & Working
FROM python:3.11-slim

WORKDIR /app

# Minimal system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages (NO ultralytics - only for inference)
RUN pip install --no-cache-dir \
    fastapi==0.104.1 \
    uvicorn==0.24.0 \
    onnxruntime==1.16.3 \
    numpy==1.24.4 \
    pillow==10.0.0 \
    opencv-python-headless==4.8.1.78

# Copy application
COPY railway_app_real.py .

# ✅ Download pre-converted ONNX model (ข้ามการ convert)
RUN wget -q -O yolov8n.onnx https://github.com/ultralytics/assets/releases/download/v8.0.0/yolov8n.onnx

# Create uploads directory
RUN mkdir -p /app/uploads

# Clean pip cache
RUN rm -rf /root/.cache/pip

EXPOSE 8000
CMD ["python", "railway_app_real.py"]