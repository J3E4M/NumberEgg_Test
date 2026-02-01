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
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load YOLO model
model = None

def load_model():
    global model
    try:
        model = YOLO('yolov8n.pt')
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
        "timestamp": datetime.now().isoformat(),
        "model_loaded": model is not None,
        "supabase_connected": supabase is not None
    }

@app.post("/detect")
async def detect_eggs(file: UploadFile = File(...)):
    try:
        # Save uploaded file
        file_path = save_uploaded_file(file)
        
        # Run YOLO detection
        results = model(file_path)
        
        # Process results
        detections = []
        egg_count = 0
        big_count = 0
        medium_count = 0
        small_count = 0
        
        for result in results:
            boxes = result.boxes
            if boxes is not None:
                for box in boxes:
                    # Get detection info
                    x1, y1, x2, y2 = box.xyxy[0].cpu().numpy()
                    confidence = float(box.conf[0].cpu().numpy())
                    class_id = int(box.cls[0].cpu().numpy())
                    
                    # Only process if confidence is high enough
                    if confidence > 0.5:
                        egg_count += 1
                        
                        # Calculate area and classify size
                        width = x2 - x1
                        height = y2 - y1
                        area = width * height
                        
                        if area > 10000:
                            grade = "big"
                            big_count += 1
                        elif area > 5000:
                            grade = "medium"
                            medium_count += 1
                        else:
                            grade = "small"
                            small_count += 1
                        
                        detections.append({
                            "id": egg_count,
                            "grade": grade,
                            "confidence": confidence,
                            "bbox": {
                                "x1": float(x1),
                                "y1": float(y1),
                                "x2": float(x2),
                                "y2": float(y2),
                                "width": float(width),
                                "height": float(height),
                                "area": float(area)
                            }
                        })
        
        # Calculate success percentage
        success_percent = (egg_count / max(egg_count, 1)) * 100
        
        # Save to Supabase if connected
        if supabase:
            try:
                session_data = {
                    "user_id": "demo_user",
                    "egg_count": egg_count,
                    "big_count": big_count,
                    "medium_count": medium_count,
                    "small_count": small_count,
                    "success_percent": success_percent,
                    "created_at": datetime.now().isoformat()
                }
                supabase.table("egg_session").insert(session_data).execute()
                print("✅ Data saved to Supabase")
            except Exception as e:
                print(f"⚠️ Failed to save to Supabase: {e}")
        
        # Clean up uploaded file
        os.remove(file_path)
        
        return {
            "success": True,
            "timestamp": datetime.now().isoformat(),
            "image_info": {
                "filename": file.filename,
                "size": file.size if hasattr(file, 'size') else 0,
                "format": file.content_type,
                "dimensions": f"{results[0].orig_shape[1]}x{results[0].orig_shape[0]}"
            },
            "detection_results": {
                "egg_count": egg_count,
                "big_count": big_count,
                "medium_count": medium_count,
                "small_count": small_count,
                "success_percent": success_percent,
                "detections": detections
            }
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Detection failed: {str(e)}")

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
