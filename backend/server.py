"""
server.py - Backend API (YOLO detection)
รวม CORS, /detect และใช้ db.py สำหรับ SQLite ฝั่ง backend เท่านั้น
"""
from pathlib import Path

from fastapi import FastAPI, UploadFile, File, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
from ultralytics import YOLO
import cv2
import numpy as np

import db  # SQLite ฝั่ง backend (database/app.db)

# โมเดล YOLO (ใช้จาก serverYOLO หรือวาง yolov8n.pt ใน backend/)
_MODEL = Path(__file__).resolve().parent.parent / "serverYOLO" / "yolov8n.pt"
if not _MODEL.exists():
    _MODEL = Path(__file__).resolve().parent / "yolov8n.pt"

app = FastAPI()

# Pydantic models for API
class PrivilegeCreate(BaseModel):
    name: str
    description: Optional[str] = None
    level: int = 1

class PrivilegeUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    level: Optional[int] = None

class UserCreate(BaseModel):
    email: str
    password: str
    name: str
    privilege_id: int

class UserUpdate(BaseModel):
    email: Optional[str] = None
    password: Optional[str] = None
    name: Optional[str] = None
    privilege_id: Optional[int] = None

class EggSessionCreate(BaseModel):
    image_path: str
    egg_count: int
    success_percent: float
    big_count: int
    medium_count: int
    small_count: int
    day: str

class EggSessionUpdate(BaseModel):
    image_path: Optional[str] = None
    egg_count: Optional[int] = None
    success_percent: Optional[float] = None
    big_count: Optional[int] = None
    medium_count: Optional[int] = None
    small_count: Optional[int] = None
    day: Optional[str] = None

class EggItemCreate(BaseModel):
    session_id: int
    grade: int
    confidence: float

class EggItemUpdate(BaseModel):
    grade: Optional[int] = None
    confidence: Optional[float] = None

class EggSessionWithItems(BaseModel):
    image_path: str
    egg_count: int
    success_percent: float
    big_count: int
    medium_count: int
    small_count: int
    day: str
    egg_items: list[dict]

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
async def startup():
    db.init_db()


@app.options("/{path:path}")
async def options_handler(path: str):
    return {}


@app.get("/detect")
async def detect_get():
    return {"status": "ok"}


@app.get("/db/status")
async def db_status():
    """ตรวจสอบว่า backend มี app.db และติดต่อได้"""
    try:
        conn = db.get_connection()
        cur = conn.cursor()
        cur.execute("SELECT name FROM sqlite_master WHERE type='table'")
        tables = [r[0] for r in cur.fetchall()]
        conn.close()
        return {"status": "ok", "database": str(db.DB_PATH), "tables": tables}
    except Exception as e:
        return {"status": "error", "message": str(e)}


model = YOLO(str(_MODEL))
CLASS_NAMES = {0: "egg", 1: "broken_egg"}


@app.post("/detect")
async def detect(file: UploadFile = File(...)):
    image_bytes = await file.read()
    np_img = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(np_img, cv2.IMREAD_COLOR)

    results = model(img)[0]
    detections = []
    for box in results.boxes:
        x1, y1, x2, y2 = box.xyxy[0].tolist()
        detections.append({
            "x1": x1, "y1": y1, "x2": x2, "y2": y2,
            "width_px": x2 - x1, "height_px": y2 - y1,
            "confidence": float(box.conf[0]),
            "class_id": int(box.cls[0]),
            "class_name": CLASS_NAMES.get(int(box.cls[0]), "unknown"),
        })

    return {"count": len(detections), "detections": detections}


# Privilege CRUD endpoints
@app.post("/privileges", status_code=201)
async def create_privilege(privilege: PrivilegeCreate):
    """สร้าง privilege ใหม่"""
    try:
        privilege_id = db.insert_privilege(
            name=privilege.name,
            description=privilege.description,
            level=privilege.level
        )
        return {"id": privilege_id, "message": "Privilege created successfully"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/privileges")
async def get_privileges():
    """ดึงข้อมูล privileges ทั้งหมด"""
    try:
        privileges = db.get_privileges()
        return {"privileges": privileges}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/privileges/{privilege_id}")
async def get_privilege(privilege_id: int):
    """ดึงข้อมูล privilege ตาม id"""
    try:
        privilege = db.get_privilege_by_id(privilege_id)
        if not privilege:
            raise HTTPException(status_code=404, detail="Privilege not found")
        return {"privilege": privilege}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.put("/privileges/{privilege_id}")
async def update_privilege(privilege_id: int, privilege: PrivilegeUpdate):
    """อัพเดทข้อมูล privilege"""
    try:
        # Check if privilege exists
        existing = db.get_privilege_by_id(privilege_id)
        if not existing:
            raise HTTPException(status_code=404, detail="Privilege not found")
        
        db.update_privilege(
            privilege_id=privilege_id,
            name=privilege.name,
            description=privilege.description,
            level=privilege.level
        )
        return {"message": "Privilege updated successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.delete("/privileges/{privilege_id}")
async def delete_privilege(privilege_id: int):
    """ลบข้อมูล privilege"""
    try:
        # Check if privilege exists
        existing = db.get_privilege_by_id(privilege_id)
        if not existing:
            raise HTTPException(status_code=404, detail="Privilege not found")
        
        db.delete_privilege(privilege_id)
        return {"message": "Privilege deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/privileges/search/{keyword}")
async def search_privileges(keyword: str):
    """ค้นหา privileges"""
    try:
        privileges = db.search_privileges(keyword)
        return {"privileges": privileges}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# Authentication endpoints
@app.post("/login")
async def login(request: Request):
    """ตรวจสอบการเข้าสู่ระบบ"""
    try:
        form = await request.form()
        email = form.get("email")
        password = form.get("password")
        
        if not email or not password:
            raise HTTPException(status_code=400, detail="Email and password are required")
        
        users = db.get_users()
        
        for user in users:
            # user is a tuple: (id, email, password, name, privilege_id, created_at, updated_at, privilege_name, privilege_level)
            if user[1] == email and user[2] == password:
                return {
                    "user": {
                        "id": user[0],
                        "email": user[1],
                        "password": user[2],
                        "name": user[3],
                        "privilege_id": user[4],
                        "created_at": user[5],
                        "updated_at": user[6],
                        "privilege_name": user[7],
                        "privilege_level": user[8]
                    },
                    "privilege": user[7] if user[7] else 'User',
                    "message": "Login successful"
                }
        
        raise HTTPException(status_code=401, detail="Invalid email or password")
    except Exception as e:
        if "Invalid email or password" in str(e) or "Email and password are required" in str(e):
            raise
        raise HTTPException(status_code=500, detail=str(e))


# User CRUD endpoints
@app.post("/users", status_code=201)
async def create_user(user: UserCreate):
    """สร้าง user ใหม่"""
    try:
        # Check if privilege exists
        privilege = db.get_privilege_by_id(user.privilege_id)
        if not privilege:
            raise HTTPException(status_code=400, detail="Invalid privilege_id")
        
        user_id = db.insert_user(
            email=user.email,
            password=user.password,
            name=user.name,
            privilege_id=user.privilege_id
        )
        return {"id": user_id, "message": "User created successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/users")
async def get_users():
    """ดึงข้อมูล users ทั้งหมดพร้อม privilege"""
    try:
        users = db.get_users()
        # Convert list of tuples to list of dictionaries
        users_list = []
        for user in users:
            user_dict = {
                "id": user[0],
                "email": user[1],
                "password": user[2],
                "name": user[3],
                "privilege_id": user[4],
                "created_at": user[5],
                "updated_at": user[6],
                "privilege_name": user[7],
                "privilege_level": user[8]
            }
            users_list.append(user_dict)
        return {"users": users_list}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/users/{user_id}")
async def get_user(user_id: int):
    """ดึงข้อมูล user ตาม id พร้อม privilege"""
    try:
        user = db.get_user_by_id(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        # Convert tuple to dictionary
        user_dict = {
            "id": user[0],
            "email": user[1],
            "password": user[2],
            "name": user[3],
            "privilege_id": user[4],
            "created_at": user[5],
            "updated_at": user[6],
            "privilege_name": user[7],
            "privilege_level": user[8]
        }
        return {"user": user_dict}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.put("/users/{user_id}")
async def update_user(user_id: int, user: UserUpdate):
    """อัพเดทข้อมูล user"""
    try:
        # Check if user exists
        existing = db.get_user_by_id(user_id)
        if not existing:
            raise HTTPException(status_code=404, detail="User not found")
        
        # Check if privilege_id is valid
        if user.privilege_id is not None:
            privilege = db.get_privilege_by_id(user.privilege_id)
            if not privilege:
                raise HTTPException(status_code=400, detail="Invalid privilege_id")
        
        db.update_user(
            user_id=user_id,
            email=user.email,
            password=user.password,
            name=user.name,
            privilege_id=user.privilege_id
        )
        return {"message": "User updated successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.delete("/users/{user_id}")
async def delete_user(user_id: int):
    """ลบข้อมูล user"""
    try:
        # Check if user exists
        existing = db.get_user_by_id(user_id)
        if not existing:
            raise HTTPException(status_code=404, detail="User not found")
        
        db.delete_user(user_id)
        return {"message": "User deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/users/search/{keyword}")
async def search_users(keyword: str):
    """ค้นหา users"""
    try:
        users = db.search_users(keyword)
        return {"users": users}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# Egg Session CRUD endpoints
@app.post("/egg-sessions", status_code=201)
async def create_egg_session(session: EggSessionCreate):
    """สร้าง egg session ใหม่"""
    try:
        session_id = db.insert_egg_session(
            image_path=session.image_path,
            egg_count=session.egg_count,
            success_percent=session.success_percent,
            big_count=session.big_count,
            medium_count=session.medium_count,
            small_count=session.small_count,
            day=session.day
        )
        return {"id": session_id, "message": "Egg session created successfully"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/egg-sessions")
async def get_egg_sessions():
    """ดึงข้อมูล egg sessions ทั้งหมด"""
    try:
        sessions = db.get_egg_sessions()
        return {"sessions": sessions}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/egg-sessions/{session_id}")
async def get_egg_session(session_id: int):
    """ดึงข้อมูล egg session ตาม id"""
    try:
        session = db.get_egg_session_by_id(session_id)
        if not session:
            raise HTTPException(status_code=404, detail="Egg session not found")
        return {"session": session}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.put("/egg-sessions/{session_id}")
async def update_egg_session(session_id: int, session: EggSessionUpdate):
    """อัพเดทข้อมูล egg session"""
    try:
        # Check if session exists
        existing = db.get_egg_session_by_id(session_id)
        if not existing:
            raise HTTPException(status_code=404, detail="Egg session not found")
        
        db.update_egg_session(
            session_id=session_id,
            image_path=session.image_path,
            egg_count=session.egg_count,
            success_percent=session.success_percent,
            big_count=session.big_count,
            medium_count=session.medium_count,
            small_count=session.small_count,
            day=session.day
        )
        return {"message": "Egg session updated successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.delete("/egg-sessions/{session_id}")
async def delete_egg_session(session_id: int):
    """ลบข้อมูล egg session และ egg items ที่เกี่ยวข้อง"""
    try:
        # Check if session exists
        existing = db.get_egg_session_by_id(session_id)
        if not existing:
            raise HTTPException(status_code=404, detail="Egg session not found")
        
        db.delete_egg_session(session_id)
        return {"message": "Egg session deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/egg-sessions/search/{keyword}")
async def search_egg_sessions(keyword: str):
    """ค้นหา egg sessions"""
    try:
        sessions = db.search_egg_sessions(keyword)
        return {"sessions": sessions}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# Egg Item CRUD endpoints
@app.post("/egg-items", status_code=201)
async def create_egg_item(item: EggItemCreate):
    """สร้าง egg item ใหม่"""
    try:
        # Check if session exists
        session = db.get_egg_session_by_id(item.session_id)
        if not session:
            raise HTTPException(status_code=400, detail="Invalid session_id")
        
        item_id = db.insert_egg_item(
            session_id=item.session_id,
            grade=item.grade,
            confidence=item.confidence
        )
        return {"id": item_id, "message": "Egg item created successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/egg-items/session/{session_id}")
async def get_egg_items_by_session(session_id: int):
    """ดึงข้อมูล egg items ตาม session_id"""
    try:
        # Check if session exists
        session = db.get_egg_session_by_id(session_id)
        if not session:
            raise HTTPException(status_code=404, detail="Egg session not found")
        
        items = db.get_egg_items_by_session(session_id)
        return {"items": items}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/egg-items")
async def get_all_egg_items():
    """ดึงข้อมูล egg items ทั้งหมด"""
    try:
        items = db.get_all_egg_items()
        return {"items": items}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.put("/egg-items/{item_id}")
async def update_egg_item(item_id: int, item: EggItemUpdate):
    """อัพเดทข้อมูล egg item"""
    try:
        db.update_egg_item(
            item_id=item_id,
            grade=item.grade,
            confidence=item.confidence
        )
        return {"message": "Egg item updated successfully"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.delete("/egg-items/{item_id}")
async def delete_egg_item(item_id: int):
    """ลบข้อมูล egg item"""
    try:
        db.delete_egg_item(item_id)
        return {"message": "Egg item deleted successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.delete("/egg-items/session/{session_id}")
async def delete_egg_items_by_session(session_id: int):
    """ลบข้อมูล egg items ทั้งหมดตาม session_id"""
    try:
        # Check if session exists
        session = db.get_egg_session_by_id(session_id)
        if not session:
            raise HTTPException(status_code=404, detail="Egg session not found")
        
        db.delete_egg_items_by_session(session_id)
        return {"message": "Egg items deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# Special Egg Management endpoints
@app.post("/egg-sessions/with-items", status_code=201)
async def add_egg_with_quantities(data: EggSessionWithItems):
    """เพิ่มข้อมูล session พร้อม egg items พร้อมกัน"""
    try:
        session_id = db.add_egg_with_quantities(
            image_path=data.image_path,
            egg_count=data.egg_count,
            success_percent=data.success_percent,
            big_count=data.big_count,
            medium_count=data.medium_count,
            small_count=data.small_count,
            day=data.day,
            egg_items_data=data.egg_items
        )
        return {"id": session_id, "message": "Egg session with items created successfully"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.delete("/egg-data/clear", status_code=200)
async def clear_all_egg_data():
    """ลบข้อมูล egg sessions และ egg items ทั้งหมด"""
    try:
        db.clear_all_egg_data()
        return {"message": "All egg data cleared successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/egg-statistics")
async def get_egg_statistics():
    """ดึงข้อมูลสถิติไข่ทั้งหมด"""
    try:
        stats = db.get_egg_statistics()
        return {"statistics": stats}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
