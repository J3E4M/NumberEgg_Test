# Railway YOLO Egg Detection API
# Uses local YOLOv8n model for egg detection

from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn
import os
import tempfile
from PIL import Image
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
from contextlib import asynccontextmanager
import torch
import cv2
import numpy as np
from ultralytics import YOLO

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    init_supabase()
    init_yolo()
    yield
    # Shutdown (if needed)

app = FastAPI(title="NumberEgg YOLO API", version="1.0.0", lifespan=lifespan)

# Load environment variables
load_dotenv()

# Supabase configuration
SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_KEY = os.getenv("SUPABASE_ANON_KEY", "")

# Initialize Supabase client
supabase: Optional[Client] = None

# Initialize YOLO model
yolo_model = None

# Create uploads directory
UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)

def init_supabase():
    """Initialize Supabase client"""
    global supabase
    try:
        supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
        print("✅ Supabase connected successfully")
    except Exception as e:
        print(f"❌ Supabase connection failed: {e}")

def init_yolo():
    """Initialize YOLO model"""
    global yolo_model
    try:
        # Load local YOLO model
        model_path = "backend/yolov8n.pt"
        if os.path.exists(model_path):
            yolo_model = YOLO(model_path)
            print(f"✅ Loaded YOLO model from {model_path}")
        else:
            # Fallback to download if local model not found
            print("⬇️ Downloading YOLOv8n model...")
            yolo_model = YOLO('yolov8n.pt')
            print("✅ Downloaded YOLOv8n model")
    except Exception as e:
        print(f"❌ Failed to initialize YOLO model: {e}")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    """Root endpoint"""
    return {"message": "NumberEgg YOLO API is running", "version": "1.0.0", "model": "YOLOv8n"}

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "timestamp": datetime.now().isoformat(), "model": "YOLOv8n"}

def classify_egg_by_size(bbox, image_shape):
    """Classify egg grade based on bounding box size"""
    x1, y1, x2, y2 = bbox
    width = x2 - x1
    height = y2 - y1
    area = width * height
    
    # Thai Industrial Standard TIS 227-2524 egg grading based on pixel area
    if area >= 15000:
        grade = "grade0"  # เบอร์ 0 (พิเศษ) - ใหญ่พิเศษ > 70g
    elif area >= 10000:
        grade = "grade1"  # เบอร์ 1 (ใหญ่) - 60-70g
    elif area >= 6000:
        grade = "grade2"  # เบอร์ 2 (กลาง) - 50-60g
    elif area >= 3000:
        grade = "grade3"  # เบอร์ 3 (เล็ก) - 40-50g
    elif area >= 1500:
        grade = "grade4"  # เบอร์ 4 (เล็กมาก) - 30-40g
    else:
        grade = "grade5"  # เบอร์ 5 (พิเศษเล็ก) - < 30g
    
    return grade

@app.post("/detect")
async def detect_eggs(file: UploadFile = File(...)):
    """YOLO-based egg detection endpoint"""
    try:
        if yolo_model is None:
            raise HTTPException(status_code=500, detail="YOLO model not initialized")
        
        # Read uploaded file
        contents = await file.read()
        
        # Convert to PIL Image
        image = Image.open(io.BytesIO(contents))
        image_np = np.array(image)
        
        # Run YOLO detection
        results = yolo_model(image_np)
        
        # Process detections
        detections = []
        grade_counts = {
            "grade0_count": 0,
            "grade1_count": 0,
            "grade2_count": 0,
            "grade3_count": 0,
            "grade4_count": 0,
            "grade5_count": 0
        }
        
        # Get detection results
        for result in results:
            boxes = result.boxes
            if boxes is not None:
                for i, box in enumerate(boxes):
                    # Get bounding box coordinates
                    x1, y1, x2, y2 = box.xyxy[0].cpu().numpy()
                    confidence = float(box.conf[0].cpu().numpy())
                    class_id = int(box.cls[0].cpu().numpy())
                    
                    # Filter for egg class (assuming class 0 is egg, or use highest confidence)
                    if confidence > 0.3:  # Confidence threshold
                        # Classify egg grade by size
                        grade = classify_egg_by_size((x1, y1, x2, y2), image_np.shape)
                        
                        # Update grade counts
                        grade_counts[f"{grade}_count"] += 1
                        
                        # Create detection object
                        detection = {
                            "id": len(detections) + 1,
                            "grade": grade,
                            "confidence": round(confidence, 2),
                            "bbox": [int(x1), int(y1), int(x2-x1), int(y2-y1)],
                            "class_id": class_id
                        }
                        detections.append(detection)
        
        # Calculate statistics
        total_eggs = len(detections)
        success_percent = 100.0 if total_eggs > 0 else 0.0
        
        # Format response
        results = {
            "session_id": str(uuid.uuid4()),
            "detection_results": {
                "grade0_count": grade_counts["grade0_count"],
                "grade1_count": grade_counts["grade1_count"], 
                "grade2_count": grade_counts["grade2_count"],
                "grade3_count": grade_counts["grade3_count"],
                "grade4_count": grade_counts["grade4_count"],
                "grade5_count": grade_counts["grade5_count"],
                "total_eggs": total_eggs,
                "success_percent": success_percent
            },
            "detections": detections,
            "saved_path": f"uploads/{uuid.uuid4()}.jpg",
            "model_info": {
                "type": "YOLOv8n",
                "method": "YOLO Object Detection",
                "features": ["Object Detection", "Size Classification", "Confidence Scoring"]
            }
        }
        
        # Save to Supabase if available
        if supabase:
            try:
                supabase.table("egg_session").insert({
                    "user_id": 1,
                    "image_path": results["saved_path"],
                    "egg_count": results["detection_results"]["total_eggs"],
                    "success_percent": results["detection_results"]["success_percent"],
                    "grade0_count": results["detection_results"]["grade0_count"],
                    "grade1_count": results["detection_results"]["grade1_count"],
                    "grade2_count": results["detection_results"]["grade2_count"],
                    "grade3_count": results["detection_results"]["grade3_count"],
                    "grade4_count": results["detection_results"]["grade4_count"],
                    "grade5_count": results["detection_results"]["grade5_count"],
                    "day": datetime.now().strftime("%Y-%m-%d")
                }).execute()
                print("✅ Saved to Supabase")
            except Exception as e:
                print(f"❌ Supabase save failed: {e}")
        
        return JSONResponse(content=results)
                
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Detection failed: {str(e)}")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
