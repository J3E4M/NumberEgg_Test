# Railway YOLO Egg Detection API
# FastAPI server for egg detection using YOLOv8
# Integrates with Supabase for authentication and data storage

from fastapi import FastAPI, File, UploadFile, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, FileResponse
import uvicorn
import os
import tempfile
from PIL import Image
import numpy as np
import torch
from ultralytics import YOLO
import base64
import io
from datetime import datetime
import json
from supabase import create_client, Client
from dotenv import load_dotenv
from typing import Optional
import uuid
import shutil
from pathlib import Path

app = FastAPI(title="NumberEgg YOLO API", version="1.0.0")

# Load environment variables
load_dotenv()

# Supabase configuration
SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_KEY = os.getenv("SUPABASE_ANON_KEY", "")

# Initialize Supabase client
supabase: Optional[Client] = None

# Create uploads directory
UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)

def init_supabase():
    global supabase
    if SUPABASE_URL and SUPABASE_KEY:
        supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
        print("✅ Supabase client initialized")
    else:
        print("⚠️ Supabase credentials not found in environment variables")

def save_uploaded_file(upload_file: UploadFile) -> str:
    """Save uploaded file to uploads directory and return the file path"""
    file_extension = os.path.splitext(upload_file.filename)[1]
    unique_filename = f"{uuid.uuid4()}{file_extension}"
    file_path = UPLOAD_DIR / unique_filename
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(upload_file.file, buffer)
    
    return str(file_path)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your Flutter app domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load YOLO model
model = None

def load_model():
    global model
    try:
        model = YOLO('yolov8n.pt')  # You can replace with your custom trained model
        # For egg detection, you might want to use a custom trained model
        # model = YOLO('egg_detection_model.pt')
        print("✅ YOLO model loaded successfully")
    except Exception as e:
        print(f"❌ Failed to load YOLO model: {e}")
        raise

@app.on_event("startup")
async def startup_event():
    load_model()
    init_supabase()

@app.get("/")
async def root():
    return {
        "message": "NumberEgg YOLO Detection API",
        "version": "1.0.0",
        "status": "running",
        "endpoints": {
            "detect": "/detect - POST: Upload image for egg detection",
            "health": "/health - GET: Check API health"
        }
    }

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "model_loaded": model is not None,
        "timestamp": datetime.now().isoformat()
    }

@app.post("/detect")
async def detect_eggs(file: UploadFile = File(...)):
    """
    Detect eggs in uploaded image using YOLO
    Returns egg count, sizes, and confidence scores
    Saves image to Railway server and results to Supabase
    """
    if not model:
        raise HTTPException(status_code=500, detail="Model not loaded")
    
    if not file.content_type.startswith('image/'):
        raise HTTPException(status_code=400, detail="File must be an image")
    
    try:
        # Save uploaded file to Railway server
        saved_file_path = save_uploaded_file(file)
        
        # Read and process image
        with open(saved_file_path, "rb") as f:
            contents = f.read()
        
        image = Image.open(io.BytesIO(contents))
        
        # Convert to RGB if needed
        if image.mode != 'RGB':
            image = image.convert('RGB')
        
        # Run YOLO detection
        results = model(image)
        
        # Process detection results
        detections = []
        egg_count = 0
        big_count = 0
        medium_count = 0
        small_count = 0
        
        for result in results:
            boxes = result.boxes
            if boxes is not None:
                for box in boxes:
                    # Get box coordinates and confidence
                    x1, y1, x2, y2 = box.xyxy[0].cpu().numpy()
                    confidence = float(box.conf[0].cpu().numpy())
                    class_id = int(box.cls[0].cpu().numpy())
                    
                    # Calculate egg size based on bounding box area
                    width = x2 - x1
                    height = y2 - y1
                    area = width * height
                    
                    # Classify egg size (you may need to adjust these thresholds)
                    egg_grade = "small"
                    if area > 15000:  # Large eggs
                        egg_grade = "big"
                        big_count += 1
                    elif area > 8000:  # Medium eggs
                        egg_grade = "medium"
                        medium_count += 1
                    else:  # Small eggs
                        small_count += 1
                    
                    egg_count += 1
                    
                    detection = {
                        "id": len(detections) + 1,
                        "grade": egg_grade,
                        "confidence": round(confidence, 3),
                        "bbox": {
                            "x1": round(float(x1), 2),
                            "y1": round(float(y1), 2),
                            "x2": round(float(x2), 2),
                            "y2": round(float(y2), 2),
                            "width": round(float(width), 2),
                            "height": round(float(height), 2),
                            "area": round(float(area), 2)
                        }
                    }
                    detections.append(detection)
        
        # Calculate success percentage
        success_percent = min(100.0, round((len(detections) / max(1, egg_count)) * 100, 2))
        
        # Convert image to base64 for response
        buffered = io.BytesIO()
        image.save(buffered, format="JPEG")
        img_base64 = base64.b64encode(buffered.getvalue()).decode()
        
        # Save detection results to Supabase
        session_id = None
        if supabase:
            try:
                # Create egg session record
                session_data = {
                    "user_id": 1,  # Default user ID, should be from authentication
                    "image_path": saved_file_path,  # Save Railway server path
                    "egg_count": egg_count,
                    "success_percent": success_percent,
                    "big_count": big_count,
                    "medium_count": medium_count,
                    "small_count": small_count,
                    "day": datetime.now().strftime("%Y-%m-%d")
                }
                
                session_result = supabase.table("egg_session").insert(session_data).execute()
                
                if session_result.data:
                    session_id = session_result.data[0]['id']
                    
                    # Create egg item records
                    for detection in detections:
                        item_data = {
                            "session_id": session_id,
                            "grade": 1 if detection["grade"] == "big" else 2 if detection["grade"] == "medium" else 3,
                            "confidence": detection["confidence"]
                        }
                        supabase.table("egg_item").insert(item_data).execute()
                    
                    print(f"✅ Detection results saved to Supabase with session ID: {session_id}")
                
            except Exception as e:
                print(f"❌ Failed to save to Supabase: {e}")
        
        response = {
            "success": True,
            "timestamp": datetime.now().isoformat(),
            "session_id": session_id,
            "image_info": {
                "filename": file.filename,
                "saved_path": saved_file_path,  # Railway server path
                "size": len(contents),
                "format": image.format,
                "dimensions": f"{image.width}x{image.height}"
            },
            "detection_results": {
                "egg_count": egg_count,
                "big_count": big_count,
                "medium_count": medium_count,
                "small_count": small_count,
                "success_percent": success_percent,
                "detections": detections
            },
            "processed_image": f"data:image/jpeg;base64,{img_base64}"
        }
        
        return response
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Detection failed: {str(e)}")

@app.get("/uploads/{filename}")
async def get_uploaded_file(filename: str):
    """Serve uploaded files"""
    file_path = UPLOAD_DIR / filename
    if not file_path.exists():
        raise HTTPException(status_code=404, detail="File not found")
    
    return FileResponse(file_path)

@app.post("/train")
async def train_model():
    """
    Endpoint for training custom egg detection model
    This would require training data to be uploaded
    """
    return {
        "message": "Training endpoint - requires implementation with training data",
        "status": "not_implemented"
    }

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
