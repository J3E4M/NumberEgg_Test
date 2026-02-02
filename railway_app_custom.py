# Railway Custom Egg Detection API
# ใช้ custom model ที่เขียนเอง ไม่ต้องการ AI/ML libraries ใหญ่ๆ

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

# Import our custom egg detector
from egg_detector import EggDetector

app = FastAPI(title="NumberEgg Custom API", version="1.0.0")

# Load environment variables
load_dotenv()

# Supabase configuration
SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_KEY = os.getenv("SUPABASE_ANON_KEY", "")

# Initialize Supabase client
supabase: Optional[Client] = None

# Initialize egg detector
egg_detector = EggDetector()

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

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def startup_event():
    """Initialize services on startup"""
    init_supabase()
    print("✅ Custom Egg Detector initialized")

@app.get("/")
async def root():
    """Root endpoint"""
    return {"message": "NumberEgg Custom API is running", "version": "1.0.0", "model": "Custom Egg Detector"}

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "timestamp": datetime.now().isoformat(), "model": "Custom Egg Detector"}

@app.post("/detect")
async def detect_eggs(file: UploadFile = File(...)):
    """Custom egg detection endpoint"""
    try:
        # Read uploaded file
        contents = await file.read()
        
        # Convert to PIL Image
        image = Image.open(io.BytesIO(contents))
        
        # Convert RGB if needed
        if image.mode != 'RGB':
            image = image.convert('RGB')
        
        # Use custom egg detector
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
            "model_info": {
                "type": "Custom Egg Detector",
                "method": "OpenCV Contour Detection",
                "processed_contours": results.get("processed_contours", 0)
            }
        }
        
        # Save to Supabase if available
        if supabase:
            try:
                supabase.table("egg_session").insert({
                    "user_id": 1,
                    "image_path": detection_results["saved_path"],
                    "egg_count": detection_results["detection_results"]["total_eggs"],
                    "success_percent": detection_results["detection_results"]["success_percent"],
                    "grade0_count": detection_results["detection_results"]["grade0_count"],
                    "grade1_count": detection_results["detection_results"]["grade1_count"],
                    "grade2_count": detection_results["detection_results"]["grade2_count"],
                    "grade3_count": detection_results["detection_results"]["grade3_count"],
                    "grade4_count": detection_results["detection_results"]["grade4_count"],
                    "grade5_count": detection_results["detection_results"]["grade5_count"],
                    "day": datetime.now().strftime("%Y-%m-%d")
                }).execute()
                print("✅ Saved to Supabase")
            except Exception as e:
                print(f"❌ Supabase save failed: {e}")
        
        return JSONResponse(content=detection_results)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Detection failed: {str(e)}")

@app.get("/model-info")
async def model_info():
    """Get model information"""
    return {
        "model": "Custom Egg Detector",
        "version": "1.0.0",
        "method": "OpenCV Contour Detection + Thai Egg Grading",
        "grades": {
            "grade0": "เบอร์ 0 (พิเศษ) - ใหญ่พิเศษ > 70g",
            "grade1": "เบอร์ 1 (ใหญ่) - 60-70g",
            "grade2": "เบอร์ 2 (กลาง) - 50-60g",
            "grade3": "เบอร์ 3 (เล็ก) - 40-50g",
            "grade4": "เบอร์ 4 (เล็กมาก) - 30-40g",
            "grade5": "เบอร์ 5 (พิเศษเล็ก) - < 30g"
        },
        "advantages": [
            "ไม่ต้องการ AI libraries ใหญ่ๆ",
            "ขนาดเล็กกว่ามาก",
            "เร็วและมีประสิทธิภาพ",
            "ควบคุมได้ ปรับแต่งง่าย",
            "ทำงานบน CPU ได้ดี"
        ]
    }

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
