# ONNX YOLO - < 400MB
FROM python:3.11-slim

WORKDIR /app

# ✅ Install ALL required system dependencies for OpenCV headless
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    libglib2.0-0 \
    libsm6 \
    libxrender1 \
    libxext6 \
    libgomp1 \
    libxcb1 \
    && rm -rf /var/lib/apt/lists/*

# ✅ Install opencv-headless FIRST
RUN pip install --no-cache-dir opencv-python-headless==4.8.1.78

# Install base packages
RUN pip install --no-cache-dir \
    numpy==1.24.4 \
    pillow==10.0.0

# Install ML packages
RUN pip install --no-cache-dir \
    onnxruntime==1.16.3 \
    ultralytics==8.0.196

# Install web framework
RUN pip install --no-cache-dir \
    fastapi==0.104.1 \
    uvicorn==0.24.0

# Copy application
COPY railway_app_real.py .

# ✅ Set ALL headless environment variables
ENV DISPLAY=
ENV QT_QPA_PLATFORM=offscreen
ENV MPLBACKEND=Agg
ENV DEBIAN_FRONTEND=noninteractive

# Download YOLO model
RUN wget -q -O yolov8n.pt https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8n.pt

# ✅ Convert to ONNX
RUN python -c "from ultralytics import YOLO; model = YOLO('yolov8n.pt'); model.export(format='onnx', imgsz=640)"

# Clean up
RUN rm yolov8n.pt && \
    rm -rf /root/.cache/pip

# Create uploads directory
RUN mkdir -p /app/uploads

EXPOSE 8000
CMD ["python", "railway_app_real.py"]