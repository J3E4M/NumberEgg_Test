# SQLite database module for local data storage
import sqlite3
import os
from datetime import datetime
from typing import Dict, Any, Optional
import json

class SQLiteManager:
    def __init__(self, db_path: str = "egg_detection.db"):
        """Initialize SQLite database manager"""
        self.db_path = db_path
        self.init_database()
    
    def init_database(self):
        """Initialize database and create tables"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Create egg_session table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS egg_session (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    session_id TEXT UNIQUE NOT NULL,
                    user_id INTEGER DEFAULT 1,
                    image_path TEXT,
                    egg_count INTEGER DEFAULT 0,
                    success_percent REAL DEFAULT 0.0,
                    grade0_count INTEGER DEFAULT 0,
                    grade1_count INTEGER DEFAULT 0,
                    grade2_count INTEGER DEFAULT 0,
                    grade3_count INTEGER DEFAULT 0,
                    grade4_count INTEGER DEFAULT 0,
                    grade5_count INTEGER DEFAULT 0,
                    day TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    detection_results TEXT,
                    detections TEXT
                )
            ''')
            
            conn.commit()
            conn.close()
            print("✅ SQLite database initialized successfully")
            
        except Exception as e:
            print(f"❌ SQLite database initialization failed: {e}")
    
    def save_detection(self, session_data: Dict[str, Any]) -> bool:
        """Save detection results to SQLite"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Prepare data
            detection_results_json = json.dumps(session_data.get("detection_results", {}))
            detections_json = json.dumps(session_data.get("detections", []))
            
            # Insert data
            cursor.execute('''
                INSERT OR REPLACE INTO egg_session (
                    session_id, user_id, image_path, egg_count, success_percent,
                    grade0_count, grade1_count, grade2_count, grade3_count, grade4_count, grade5_count,
                    day, detection_results, detections
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                session_data.get("session_id"),
                session_data.get("user_id", 1),
                session_data.get("saved_path"),
                session_data.get("detection_results", {}).get("total_eggs", 0),
                session_data.get("detection_results", {}).get("success_percent", 0.0),
                session_data.get("detection_results", {}).get("grade0_count", 0),
                session_data.get("detection_results", {}).get("grade1_count", 0),
                session_data.get("detection_results", {}).get("grade2_count", 0),
                session_data.get("detection_results", {}).get("grade3_count", 0),
                session_data.get("detection_results", {}).get("grade4_count", 0),
                session_data.get("detection_results", {}).get("grade5_count", 0),
                datetime.now().strftime("%Y-%m-%d"),
                detection_results_json,
                detections_json
            ))
            
            conn.commit()
            conn.close()
            print("✅ Data saved to SQLite successfully")
            return True
            
        except Exception as e:
            print(f"❌ SQLite save failed: {e}")
            return False
    
    def get_recent_detections(self, limit: int = 10) -> list:
        """Get recent detection records"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('''
                SELECT session_id, egg_count, success_percent, day, created_at,
                       grade0_count, grade1_count, grade2_count, grade3_count, grade4_count, grade5_count
                FROM egg_session 
                ORDER BY created_at DESC 
                LIMIT ?
            ''', (limit,))
            
            records = cursor.fetchall()
            conn.close()
            
            return [
                {
                    "session_id": record[0],
                    "egg_count": record[1],
                    "success_percent": record[2],
                    "day": record[3],
                    "created_at": record[4],
                    "grade0_count": record[5],
                    "grade1_count": record[6],
                    "grade2_count": record[7],
                    "grade3_count": record[8],
                    "grade4_count": record[9],
                    "grade5_count": record[10]
                }
                for record in records
            ]
            
        except Exception as e:
            print(f"❌ Failed to get recent detections: {e}")
            return []
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get database statistics"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Total sessions
            cursor.execute("SELECT COUNT(*) FROM egg_session")
            total_sessions = cursor.fetchone()[0]
            
            # Total eggs detected
            cursor.execute("SELECT SUM(egg_count) FROM egg_session")
            total_eggs = cursor.fetchone()[0] or 0
            
            # Grade distribution
            cursor.execute('''
                SELECT SUM(grade0_count), SUM(grade1_count), SUM(grade2_count), 
                       SUM(grade3_count), SUM(grade4_count), SUM(grade5_count)
                FROM egg_session
            ''')
            grade_totals = cursor.fetchone()
            
            conn.close()
            
            return {
                "total_sessions": total_sessions,
                "total_eggs": total_eggs,
                "grade_distribution": {
                    "grade0": grade_totals[0] or 0,
                    "grade1": grade_totals[1] or 0,
                    "grade2": grade_totals[2] or 0,
                    "grade3": grade_totals[3] or 0,
                    "grade4": grade_totals[4] or 0,
                    "grade5": grade_totals[5] or 0
                }
            }
            
        except Exception as e:
            print(f"❌ Failed to get statistics: {e}")
            return {
                "total_sessions": 0,
                "total_eggs": 0,
                "grade_distribution": {
                    "grade0": 0, "grade1": 0, "grade2": 0,
                    "grade3": 0, "grade4": 0, "grade5": 0
                }
            }
