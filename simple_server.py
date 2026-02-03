from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from ultralytics import YOLO
import cv2
import numpy as np
import os
import uvicorn
from contextlib import asynccontextmanager
from datetime import datetime
import json
from supabase import create_client, Client
from dotenv import load_dotenv
from typing import Optional
import uuid
import base64
from pathlib import Path

# Load environment variables
load_dotenv()

# Railway environment variables
PORT = int(os.getenv("PORT", "8000"))

# Supabase configuration
SUPABASE_URL = os.getenv("SUPABASE_URL", "https://gbxxwojlihgrbtthmusq.supabase.co")
SUPABASE_KEY = os.getenv("SUPABASE_ANON_KEY", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdieHh3b2psaWhncmJ0dGhtdXNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM5NTQ1MjYsImV4cCI6MjA3OTUzMDUyNn0.-XKw6NOhrWBxp4gLvQbPExLU2PHhUfUWdD3zsSc_9_k")

# Initialize Supabase client
supabase: Optional[Client] = None

# Create uploads directory
UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup - initialize model and Supabase
    global model, supabase
    print("Loading YOLO model...")
    model = YOLO("yolov8n.pt")  # หรือใช้โมเดลไข่ที่ฝึกไว้
    print("Model loaded successfully!")
    
    # Initialize Supabase
    try:
        supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
        print("✅ Supabase connected successfully")
    except Exception as e:
        print(f"❌ Supabase connection failed: {e}")
    
    yield
    # Shutdown (if needed)

app = FastAPI(
    title="NumberEgg Detection API",
    version="1.0.0",
    lifespan=lifespan
)

# เพิ่ม CORS middleware เพื่อรองรับการเรียกจาก mobile app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # สำคัญ: อนุญาตให้เรียกจากทุก origin
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.options("/{path:path}")
async def options_handler(path: str):
    return {}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "model": "loaded", "supabase": "connected" if supabase else "disconnected"}

@app.get("/detect")
async def detect_get():
    return {"status": "ok", "message": "NumberEgg Detection API is running"}

# Global model variable
model = None

CLASS_NAMES = {
    0: "egg",
    1: "broken_egg",  # ถ้ามีการฝึกโมเดลไข่แตก
}

async def save_to_supabase(detections: list, image_data: bytes = None):
    """Save detection results to Supabase"""
    if not supabase:
        print("❌ Supabase not connected")
        return None
    
    try:
        # Create session record
        session_data = {
            "user_id": 1,  # You might want to get this from authentication
            "image_path": f"egg_detection_{datetime.now().strftime('%Y%m%d_%H%M%S')}.jpg",
            "egg_count": len([d for d in detections if d["class_id"] == 0]),
            "success_percent": 100.0,  # You might want to calculate this
            "grade0_count": len([d for d in detections if d["class_id"] == 0]),
            "grade1_count": 0,
            "grade2_count": 0,
            "grade3_count": 0,
            "grade4_count": 0,
            "grade5_count": 0,
            "day": datetime.now().strftime("%Y-%m-%d"),
            "created_at": datetime.now().isoformat()
        }
        
        # Insert session
        session_result = supabase.table("egg_session").insert(session_data).execute()
        
        if session_result.data:
            session_id = session_result.data[0]["id"]
            print(f"✅ Session created with ID: {session_id}")
            
            # Insert egg items
            for detection in detections:
                if detection["class_id"] == 0:  # Only save eggs
                    egg_item_data = {
                        "session_id": session_id,
                        "grade": 0,  # You might want to calculate this based on size
                        "confidence": detection["confidence"],
                        "x1": detection["x1"],
                        "y1": detection["y1"],
                        "x2": detection["x2"],
                        "y2": detection["y2"]
                    }
                    
                    supabase.table("egg_item").insert(egg_item_data).execute()
            
            print(f"✅ Saved {len([d for d in detections if d['class_id'] == 0])} egg items to Supabase")
            return session_id
        
    except Exception as e:
        print(f"❌ Error saving to Supabase: {e}")
        return None

@app.post("/detect")
async def detect(file: UploadFile = File(...)):
    try:
        # Check if model is loaded
        if model is None:
            raise HTTPException(status_code=503, detail="Model not loaded yet")
        
        # Read image
        image_bytes = await file.read()
        np_img = np.frombuffer(image_bytes, np.uint8)
        img = cv2.imdecode(np_img, cv2.IMREAD_COLOR)
        
        if img is None:
            raise HTTPException(status_code=400, detail="Invalid image file")

        # Run detection
        results = model(img)[0]

        detections = []
        for box in results.boxes:
            x1, y1, x2, y2 = box.xyxy[0].tolist()

            detections.append({
                "x1": x1,
                "y1": y1,
                "x2": x2,
                "y2": y2,
                "width_px": x2 - x1,
                "height_px": y2 - y1,
                "confidence": float(box.conf[0]),
                "class_id": int(box.cls[0]),
                "class_name": CLASS_NAMES.get(int(box.cls[0]), "unknown")
            })

        # Save to Supabase
        session_id = await save_to_supabase(detections, image_bytes)
        
        response_data = {
            "count": len(detections),
            "detections": detections,
            "session_id": session_id
        }
        
        if session_id:
            response_data["supabase_status"] = "saved"
        else:
            response_data["supabase_status"] = "failed"
        
        return response_data
        
    except Exception as e:
        print(f"Detection error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Detection failed: {str(e)}")

@app.post("/save-session")
async def save_session_endpoint(session_data: dict):
    """Manual endpoint to save session data"""
    try:
        session_id = await save_to_supabase(session_data.get("detections", []))
        return {"status": "success", "session_id": session_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save session: {str(e)}")

if __name__ == "__main__":
    # For local development
    uvicorn.run(
        "simple_server:app",
        host="0.0.0.0",
        port=PORT,
        reload=True
    )
