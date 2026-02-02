# YOLO Detection with PyTorch support
FROM python:3.9-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY railway_requirements_fixed.txt requirements.txt

# Install Python packages
RUN pip install --no-cache-dir -r requirements.txt

# Copy app
COPY railway_app.py .

# Create uploads
RUN mkdir -p /app/uploads

EXPOSE 8000
CMD ["python", "railway_app.py"]
