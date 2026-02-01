# Simple Railway API - No AI (for testing)
from fastapi import FastAPI, File, UploadFile
from fastapi.responses import JSONResponse
import os
import uuid
from datetime import datetime
from supabase import create_client, Client
import uvicorn

app = FastAPI(title="NumberEgg API (Simple)")

# Supabase setup
SUPABASE_URL = "https://gbxxwojlihgrbtthmusq.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdieHh3b2psaWhncmJ0dGhtdXNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM5NTQ1MjYsImV4cCI6MjA3OTUzMDUyNn0.-XKw6NOhrWBxp4gLvQbPExLU2PHhUfUWdD3zsSc_9_k"

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

@app.get("/")
async def root():
    return {"message": "NumberEgg API - Simple Version", "status": "running"}

@app.get("/health")
async def health():
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

@app.post("/detect")
async def detect_eggs(file: UploadFile = File(...)):
    """Mock egg detection - returns random results"""
    try:
        # Save uploaded file
        file_id = str(uuid.uuid4())
        file_path = f"uploads/{file_id}_{file.filename}"
        
        os.makedirs("uploads", exist_ok=True)
        with open(file_path, "wb") as buffer:
            content = await file.read()
            buffer.write(content)
        
        # Mock detection results (no AI)
        import random
        egg_count = random.randint(1, 10)
        big_count = random.randint(0, egg_count)
        medium_count = random.randint(0, egg_count - big_count)
        small_count = egg_count - big_count - medium_count
        
        success_percent = random.uniform(60, 95)
        
        # Save to Supabase
        session_data = {
            "user_id": 1,
            "image_path": file_path,
            "egg_count": egg_count,
            "success_percent": success_percent,
            "big_count": big_count,
            "medium_count": medium_count,
            "small_count": small_count,
            "day": datetime.now().strftime("%Y-%m-%d"),
            "created_at": datetime.now().isoformat()
        }
        
        try:
            result = supabase.table("egg_session").insert(session_data).execute()
            session_id = result.data[0]["id"]
        except Exception as e:
            print(f"Supabase error: {e}")
            session_id = None
        
        return JSONResponse({
            "success": True,
            "timestamp": datetime.now().isoformat(),
            "detection_results": {
                "egg_count": egg_count,
                "big_count": big_count,
                "medium_count": medium_count,
                "small_count": small_count,
                "success_percent": success_percent,
                "detections": []
            },
            "session_id": session_id,
            "image_info": {
                "filename": file.filename,
                "saved_path": file_path,
                "size": len(content)
            }
        })
        
    except Exception as e:
        return JSONResponse(
            {"error": f"Detection failed: {str(e)}"},
            status_code=500
        )

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
