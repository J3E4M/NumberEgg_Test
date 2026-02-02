# Railway Real Egg Detection API
# ใช้ real model ที่วัดขอบวัตถุจริงๆ ไม่ใช่ mock data

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

# Import our real egg detector
from egg_detector_real import RealEggDetector

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    try:
        global egg_detector
        egg_detector = RealEggDetector()
        init_supabase()
        print("✅ Real Egg Detector initialized successfully")
        print("✅ Supabase connected successfully")
    except Exception as e:
        print(f"❌ Initialization failed: {e}")
    yield
    # Shutdown (if needed)

app = FastAPI(title="NumberEgg Real API", version="1.0.0", lifespan=lifespan)

# Load environment variables
load_dotenv()

# Supabase configuration
SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_KEY = os.getenv("SUPABASE_ANON_KEY", "")

# Initialize Supabase client
supabase: Optional[Client] = None

# Initialize egg detector
egg_detector: Optional[RealEggDetector] = None

# Create uploads directory
UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)

def init_supabase():
    """Initialize Supabase client"""
    global supabase
    try:
        supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
    except Exception as e:
        print(f"❌ Supabase connection failed: {e}")

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
    return {
        "message": "NumberEgg Real API is running", 
        "version": "1.0.0", 
        "model": "Real Egg Detector (OpenCV)"
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy", 
        "timestamp": datetime.now().isoformat(), 
        "model": "Real Egg Detector",
        "detector_ready": egg_detector is not None
    }

@app.post("/detect")
async def detect_eggs(file: UploadFile = File(...), user_id: int = 1):
    """Real egg detection endpoint"""
    try:
        if egg_detector is None:
            raise HTTPException(status_code=503, detail="Egg detector not initialized")
        
        # Read uploaded file
        contents = await file.read()
        
        # Convert to PIL Image
        image = Image.open(io.BytesIO(contents))
        
        # Convert RGB if needed
        if image.mode != 'RGB':
            image = image.convert('RGB')
        
        # Use real egg detector
        results = egg_detector.detect_eggs(image)
        
        # Prepare response
        detection_results = {
            "session_id": str(uuid.uuid4()),
            "detection_results": {
                "grade0_count": results["grade_counts"]["grade0_count"],
                "grade1_count": results["grade_counts"]["grade1_count"],
                "grade2_count": results["grade_counts"]["grade2_count"],
                "grade3_count": results["grade_counts"]["grade3_count"],
                "grade4_count": results["grade_counts"]["grade4_count"],
                "grade5_count": results["grade_counts"]["grade5_count"],
                "total_eggs": results["total_eggs"],
                "success_percent": results["success_percent"]
            },
            "detections": results["detections"],
            "saved_path": f"uploads/{uuid.uuid4()}.jpg",
            "model_info": results.get("model_info", {
                "type": "Real Egg Detector",
                "method": "OpenCV Edge Detection + Contour Analysis"
            })
        }
        
        # Save to Supabase if available
        if supabase:
            try:
                supabase.table("egg_session").insert({
                    "user_id": user_id,
                    "image_path": detection_results["saved_path"],
                    "egg_count": detection_results["detection_results"]["total_eggs"],
                    "success_percent": detection_results["detection_results"]["success_percent"],
                    "grade0_count": detection_results["detection_results"]["grade0_count"],
                    "grade1_count": detection_results["detection_results"]["grade1_count"],
                    "grade2_count": detection_results["detection_results"]["grade2_count"],
                    "grade3_count": detection_results["detection_results"]["grade3_count"],
                    "grade4_count": detection_results["detection_results"]["grade4_count"],
                    "grade5_count": detection_results["detection_results"]["grade5_count"],
                    "day": datetime.now().strftime("%Y-%m-%d"),
                    "created_at": datetime.now().isoformat()
                }).execute()
                print(f"✅ Saved to Supabase (egg_session) for user_id: {user_id}")
            except Exception as e:
                print(f"❌ Supabase save failed: {e}")
        
        return JSONResponse(content=detection_results)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Detection failed: {str(e)}")

@app.get("/model-info")
async def model_info():
    """Get model information"""
    return {
        "model": "Real Egg Detector",
        "version": "1.0.0",
        "method": "OpenCV Edge Detection + Contour Analysis + Thai Egg Grading",
        "features": [
            "Canny Edge Detection",
            "Sobel Edge Detection", 
            "Contour Analysis",
            "Shape Filtering",
            "Size Classification",
            "Thai TIS 227-2524 Standards"
        ],
        "grade_thresholds": {
            "grade0": "เบอร์ 0 (พิเศษ) - ใหญ่พิเศษ > 70g",
            "grade1": "เบอร์ 1 (ใหญ่) - 60-70g",
            "grade2": "เบอร์ 2 (กลาง) - 50-60g", 
            "grade3": "เบอร์ 3 (เล็ก) - 40-50g",
            "grade4": "เบอร์ 4 (เล็กมาก) - 30-40g",
            "grade5": "เบอร์ 5 (พิเศษเล็ก) - < 30g"
        },
        "advantages": [
            "ตรวจจับวัตถุจริงๆ ด้วย edge detection",
            "ไม่ต้องการ AI libraries ใหญ่ๆ",
            "ขนาดเล็กกว่ามาก",
            "เร็วและมีประสิทธิภาพ",
            "ควบคุมได้ ปรับแต่งง่าย",
            "ทำงานบน CPU ได้ดี",
            "ใช้มาตรฐานไข่ไทย"
        ]
    }

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
