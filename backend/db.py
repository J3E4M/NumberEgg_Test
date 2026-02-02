"""
db.py - SQLite ฝั่ง backend เท่านั้น
จัดการ app.db ใน backend/database/
Flutter (frontend) ไม่มีสิทธิ์เข้าถึงไฟล์นี้โดยตรง ต้องเรียก API
"""
import os
import sqlite3
from pathlib import Path

# โฟลเดอร์ database อยู่ฝั่ง backend เท่านั้น
DB_DIR = Path(__file__).resolve().parent / "database"
DB_PATH = DB_DIR / "app.db"


def ensure_db_dir():
    """สร้างโฟลเดอร์ database/ ถ้ายังไม่มี"""
    DB_DIR.mkdir(parents=True, exist_ok=True)


def get_connection():
    """ได้ connection ไปยัง app.db"""
    ensure_db_dir()
    return sqlite3.connect(str(DB_PATH))


def init_db():
    """สร้าง tables ถ้ายังไม่มี (privileges, users, egg_session, egg_item)"""
    conn = get_connection()
    cur = conn.cursor()

    # Drop existing tables to recreate with new schema
    cur.execute("DROP TABLE IF EXISTS egg_item")
    cur.execute("DROP TABLE IF EXISTS egg_session")
    cur.execute("DROP TABLE IF EXISTS users")
    cur.execute("DROP TABLE IF EXISTS privileges")

    # Create Privilege table first
    cur.execute("""
        CREATE TABLE privileges (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            description TEXT,
            level INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )
    """)

    # Create Users table with privilege_id foreign key
    cur.execute("""
        CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL,
            name TEXT NOT NULL,
            privilege_id INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (privilege_id) REFERENCES privileges(id)
        )
    """)

    cur.execute("""
        CREATE TABLE egg_session (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            image_path TEXT NOT NULL,
            egg_count INTEGER NOT NULL,
            success_percent REAL NOT NULL,
            grade0_count INTEGER NOT NULL,
            grade1_count INTEGER NOT NULL,
            grade2_count INTEGER NOT NULL,
            grade3_count INTEGER NOT NULL,
            grade4_count INTEGER NOT NULL,
            grade5_count INTEGER NOT NULL,
            day TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users(id)
        )
    """)

    cur.execute("""
        CREATE TABLE egg_item (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id INTEGER NOT NULL,
            grade INTEGER NOT NULL,
            confidence REAL NOT NULL,
            FOREIGN KEY (session_id) REFERENCES egg_session(id)
        )
    """)

    # Insert sample data
    from datetime import datetime
    now = datetime.now().isoformat()
    
    # Insert default privileges
    cur.execute("""
        INSERT INTO privileges (name, description, level, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?)
    """, ("Admin", "System administrator", 1, now, now))
    
    cur.execute("""
        INSERT INTO privileges (name, description, level, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?)
    """, ("User", "Regular user", 2, now, now))
    
    cur.execute("""
        INSERT INTO privileges (name, description, level, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?)
    """, ("Guest", "Guest user", 3, now, now))
    
    # Insert sample users
    cur.execute("""
        INSERT INTO users (email, password, name, privilege_id, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?)
    """, ("admin@number.egg.com", "admin123", "Administrator", 1, now, now))
    
    cur.execute("""
        INSERT INTO users (email, password, name, privilege_id, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?)
    """, ("user@number.egg.com", "user123", "Regular User", 2, now, now))
    
    cur.execute("""
        INSERT INTO users (email, password, name, privilege_id, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?)
    """, ("demo@number.egg.com", "demo123", "Demo User", 2, now, now))

    conn.commit()
    conn.close()


def insert_privilege(name, description, level=1):
    """เพิ่มข้อมูล privilege"""
    from datetime import datetime
    conn = get_connection()
    cur = conn.cursor()
    now = datetime.now().isoformat()
    cur.execute("""
        INSERT INTO privileges (name, description, level, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?)
    """, (name, description, level, now, now))
    conn.commit()
    privilege_id = cur.lastrowid
    conn.close()
    return privilege_id


def get_privileges():
    """ดึงข้อมูล privileges ทั้งหมด"""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM privileges ORDER BY level")
    privileges = cur.fetchall()
    conn.close()
    return privileges


def get_privilege_by_id(privilege_id):
    """ดึงข้อมูล privilege ตาม id"""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM privileges WHERE id = ?", (privilege_id,))
    privilege = cur.fetchone()
    conn.close()
    return privilege


def update_privilege(privilege_id, name=None, description=None, level=None):
    """อัพเดทข้อมูล privilege"""
    from datetime import datetime
    conn = get_connection()
    cur = conn.cursor()
    now = datetime.now().isoformat()
    
    fields = []
    values = []
    
    if name is not None:
        fields.append("name = ?")
        values.append(name)
    if description is not None:
        fields.append("description = ?")
        values.append(description)
    if level is not None:
        fields.append("level = ?")
        values.append(level)
    
    if fields:
        fields.append("updated_at = ?")
        values.extend([now, privilege_id])
        
        query = f"UPDATE privileges SET {', '.join(fields)} WHERE id = ?"
        cur.execute(query, values)
        conn.commit()
    
    conn.close()


def delete_privilege(privilege_id):
    """ลบข้อมูล privilege"""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("DELETE FROM privileges WHERE id = ?", (privilege_id,))
    conn.commit()
    conn.close()


def search_privileges(keyword):
    """ค้นหา privileges"""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT * FROM privileges 
        WHERE name LIKE ? OR description LIKE ?
        ORDER BY level
    """, (f"%{keyword}%", f"%{keyword}%"))
    privileges = cur.fetchall()
    conn.close()
    return privileges


def insert_user(email, password, name, privilege_id):
    """เพิ่มข้อมูล user"""
    from datetime import datetime
    conn = get_connection()
    cur = conn.cursor()
    now = datetime.now().isoformat()
    cur.execute("""
        INSERT INTO users (email, password, name, privilege_id, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?)
    """, (email, password, name, privilege_id, now, now))
    conn.commit()
    user_id = cur.lastrowid
    conn.close()
    return user_id


def get_users():
    """ดึงข้อมูล users ทั้งหมดพร้อม privilege"""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT u.*, p.name as privilege_name, p.level as privilege_level
        FROM users u
        LEFT JOIN privileges p ON u.privilege_id = p.id
        ORDER BY u.created_at DESC
    """)
    users = cur.fetchall()
    conn.close()
    return users


def get_user_by_id(user_id):
    """ดึงข้อมูล user ตาม id พร้อม privilege"""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT u.*, p.name as privilege_name, p.level as privilege_level
        FROM users u
        LEFT JOIN privileges p ON u.privilege_id = p.id
        WHERE u.id = ?
    """, (user_id,))
    user = cur.fetchone()
    conn.close()
    return user


def update_user(user_id, email=None, password=None, name=None, privilege_id=None):
    """อัพเดทข้อมูล user"""
    from datetime import datetime
    conn = get_connection()
    cur = conn.cursor()
    now = datetime.now().isoformat()
    
    fields = []
    values = []
    
    if email is not None:
        fields.append("email = ?")
        values.append(email)
    if password is not None:
        fields.append("password = ?")
        values.append(password)
    if name is not None:
        fields.append("name = ?")
        values.append(name)
    if privilege_id is not None:
        fields.append("privilege_id = ?")
        values.append(privilege_id)
    
    if fields:
        fields.append("updated_at = ?")
        values.extend([now, user_id])
        
        query = f"UPDATE users SET {', '.join(fields)} WHERE id = ?"
        cur.execute(query, values)
        conn.commit()
    
    conn.close()


def delete_user(user_id):
    """ลบข้อมูล user"""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("DELETE FROM users WHERE id = ?", (user_id,))
    conn.commit()
    conn.close()


def search_users(keyword):
    """ค้นหา users"""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT u.*, p.name as privilege_name, p.level as privilege_level
        FROM users u
        LEFT JOIN privileges p ON u.privilege_id = p.id
        WHERE u.email LIKE ? OR u.name LIKE ? OR p.name LIKE ?
        ORDER BY u.created_at DESC
    """, (f"%{keyword}%", f"%{keyword}%", f"%{keyword}%"))
    users = cur.fetchall()
    conn.close()
    return users


# Egg Session CRUD functions
def insert_egg_session(user_id, image_path, egg_count, success_percent, grade0_count, grade1_count, grade2_count, grade3_count, grade4_count, grade5_count, day):
    """เพิ่มข้อมูล egg session ใหม่"""
    from datetime import datetime
    conn = get_connection()
    cur = conn.cursor()
    now = datetime.now().isoformat()
    cur.execute("""
        INSERT INTO egg_session (user_id, image_path, egg_count, success_percent, grade0_count, grade1_count, grade2_count, grade3_count, grade4_count, grade5_count, day, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (user_id, image_path, egg_count, success_percent, grade0_count, grade1_count, grade2_count, grade3_count, grade4_count, grade5_count, day, now))
    conn.commit()
    session_id = cur.lastrowid
    conn.close()
    return session_id


def get_egg_sessions():
    """ดึงข้อมูล egg sessions ทั้งหมด"""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM egg_session ORDER BY created_at DESC")
    sessions = cur.fetchall()
    conn.close()
    return sessions


def get_egg_sessions_by_user(user_id):
    """ดึงข้อมูล egg sessions ตาม user_id"""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM egg_session WHERE user_id = ? ORDER BY created_at DESC", (user_id,))
    sessions = cur.fetchall()
    conn.close()
    return sessions


def get_egg_session_by_id(session_id):
    """ดึงข้อมูล egg session ตาม id"""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM egg_session WHERE id = ?", (session_id,))
    session = cur.fetchone()
    conn.close()
    return session


def update_egg_session(session_id, user_id=None, image_path=None, egg_count=None, success_percent=None, grade0_count=None, grade1_count=None, grade2_count=None, grade3_count=None, grade4_count=None, grade5_count=None, day=None):
    """อัพเดทข้อมูล egg session"""
    from datetime import datetime
    conn = get_connection()
    cur = conn.cursor()
    
    fields = []
    values = []
    
    if user_id is not None:
        fields.append("user_id = ?")
        values.append(user_id)
    if image_path is not None:
        fields.append("image_path = ?")
        values.append(image_path)
    if egg_count is not None:
        fields.append("egg_count = ?")
        values.append(egg_count)
    if success_percent is not None:
        fields.append("success_percent = ?")
        values.append(success_percent)
    if grade0_count is not None:
        fields.append("grade0_count = ?")
        values.append(grade0_count)
    if grade1_count is not None:
        fields.append("grade1_count = ?")
        values.append(grade1_count)
    if grade2_count is not None:
        fields.append("grade2_count = ?")
        values.append(grade2_count)
    if grade3_count is not None:
        fields.append("grade3_count = ?")
        values.append(grade3_count)
    if grade4_count is not None:
        fields.append("grade4_count = ?")
        values.append(grade4_count)
    if grade5_count is not None:
        fields.append("grade5_count = ?")
        values.append(grade5_count)
    if day is not None:
        fields.append("day = ?")
        values.append(day)
    
    if fields:
        query = f"UPDATE egg_session SET {', '.join(fields)} WHERE id = ?"
        values.append(session_id)
        cur.execute(query, values)
        conn.commit()
    
    conn.close()


def delete_egg_session(session_id):
    """ลบข้อมูล egg session และ egg items ที่เกี่ยวข้อง"""
    conn = get_connection()
    cur = conn.cursor()
    
    # Delete related egg items first
    cur.execute("DELETE FROM egg_item WHERE session_id = ?", (session_id,))
    
    # Delete the session
    cur.execute("DELETE FROM egg_session WHERE id = ?", (session_id,))
    
    conn.commit()
    conn.close()


def search_egg_sessions(keyword):
    """ค้นหา egg sessions"""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT * FROM egg_session 
        WHERE image_path LIKE ? OR day LIKE ?
        ORDER BY created_at DESC
    """, (f"%{keyword}%", f"%{keyword}%"))
    sessions = cur.fetchall()
    conn.close()
    return sessions


# Egg Item CRUD functions
def insert_egg_item(session_id, grade, confidence):
    """เพิ่มข้อมูล egg item ใหม่"""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        INSERT INTO egg_item (session_id, grade, confidence)
        VALUES (?, ?, ?)
    """, (session_id, grade, confidence))
    conn.commit()
    item_id = cur.lastrowid
    conn.close()
    return item_id


def get_egg_items_by_session(session_id):
    """ดึงข้อมูล egg items ตาม session_id"""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM egg_item WHERE session_id = ?", (session_id,))
    items = cur.fetchall()
    conn.close()
    return items


def get_all_egg_items():
    """ดึงข้อมูล egg items ทั้งหมด"""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT ei.*, es.image_path, es.day
        FROM egg_item ei
        LEFT JOIN egg_session es ON ei.session_id = es.id
        ORDER BY ei.session_id DESC
    """)
    items = cur.fetchall()
    conn.close()
    return items


def update_egg_item(item_id, grade=None, confidence=None):
    """อัพเดทข้อมูล egg item"""
    conn = get_connection()
    cur = conn.cursor()
    
    fields = []
    values = []
    
    if grade is not None:
        fields.append("grade = ?")
        values.append(grade)
    if confidence is not None:
        fields.append("confidence = ?")
        values.append(confidence)
    
    if fields:
        query = f"UPDATE egg_item SET {', '.join(fields)} WHERE id = ?"
        values.append(item_id)
        cur.execute(query, values)
        conn.commit()
    
    conn.close()


def delete_egg_item(item_id):
    """ลบข้อมูล egg item"""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("DELETE FROM egg_item WHERE id = ?", (item_id,))
    conn.commit()
    conn.close()


def delete_egg_items_by_session(session_id):
    """ลบข้อมูล egg items ทั้งหมดตาม session_id"""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("DELETE FROM egg_item WHERE session_id = ?", (session_id,))
    conn.commit()
    conn.close()


# Special functions for egg management
def add_egg_with_quantities(user_id, image_path, egg_count, success_percent, grade0_count, grade1_count, grade2_count, grade3_count, grade4_count, grade5_count, day, egg_items_data):
    """เพิ่มข้อมูล session พร้อม egg items พร้อมกัน"""
    from datetime import datetime
    conn = get_connection()
    cur = conn.cursor()
    
    try:
        # Insert session
        now = datetime.now().isoformat()
        cur.execute("""
            INSERT INTO egg_session (user_id, image_path, egg_count, success_percent, grade0_count, grade1_count, grade2_count, grade3_count, grade4_count, grade5_count, day, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (user_id, image_path, egg_count, success_percent, grade0_count, grade1_count, grade2_count, grade3_count, grade4_count, grade5_count, day, now))
        
        session_id = cur.lastrowid
        
        # Insert egg items
        for item in egg_items_data:
            grade = item.get('grade', 0)
            confidence = item.get('confidence', 0.0)
            cur.execute("""
                INSERT INTO egg_item (session_id, grade, confidence)
                VALUES (?, ?, ?)
            """, (session_id, grade, confidence))
        
        conn.commit()
        return session_id
        
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        conn.close()


def clear_all_egg_data():
    """ลบข้อมูล egg sessions และ egg items ทั้งหมด"""
    conn = get_connection()
    cur = conn.cursor()
    
    # Delete all egg items first
    cur.execute("DELETE FROM egg_item")
    
    # Delete all egg sessions
    cur.execute("DELETE FROM egg_session")
    
    conn.commit()
    conn.close()


def get_egg_statistics():
    """ดึงข้อมูลสถิติไข่ทั้งหมด"""
    conn = get_connection()
    cur = conn.cursor()
    
    # Get total sessions
    cur.execute("SELECT COUNT(*) FROM egg_session")
    total_sessions = cur.fetchone()[0]
    
    # Get total eggs
    cur.execute("SELECT SUM(egg_count) FROM egg_session")
    total_eggs = cur.fetchone()[0] or 0
    
    # Get total by size
    cur.execute("SELECT SUM(grade0_count), SUM(grade1_count), SUM(grade2_count), SUM(grade3_count), SUM(grade4_count), SUM(grade5_count) FROM egg_session")
    size_totals = cur.fetchone()
    total_grade0 = size_totals[0] or 0
    total_grade1 = size_totals[1] or 0
    total_grade2 = size_totals[2] or 0
    total_grade3 = size_totals[3] or 0
    total_grade4 = size_totals[4] or 0
    total_grade5 = size_totals[5] or 0
    
    # Get average success rate
    cur.execute("SELECT AVG(success_percent) FROM egg_session")
    avg_success = cur.fetchone()[0] or 0
    
    conn.close()
    
    return {
        'total_sessions': total_sessions,
        'total_eggs': total_eggs,
        'total_grade0': total_grade0,
        'total_grade1': total_grade1,
        'total_grade2': total_grade2,
        'total_grade3': total_grade3,
        'total_grade4': total_grade4,
        'total_grade5': total_grade5,
        'average_success_percent': round(avg_success, 2)
    }


# โฟลเดอร์ database/ จะถูกสร้างตอน import
# app.db + tables สร้างตอน server startup (ดู server.py)
ensure_db_dir()
