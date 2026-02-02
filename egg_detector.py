# Custom Egg Detection Model
# ใช้ OpenCV headless ตรวจจับไข่โดยไม่ต้องการ AI
# จำแนกขนาดตาม TIS 227-2524 (grade0-5)

import cv2
import numpy as np
from PIL import Image
import io
import base64
from typing import List, Dict, Tuple
import math

class EggDetector:
    def __init__(self):
        """Initialize egg detector with Thai egg grading standards"""
        # Thai Industrial Standard TIS 227-2524 egg grading (pixels)
        # ค่าประมาณสำหรับภาพปกติ สามารถ calibrate ได้
        self.grade_thresholds = {
            "grade0": 25000,  # เบอร์ 0 (พิเศษ) - ใหญ่พิเศษ > 70g
            "grade1": 20000,  # เบอร์ 1 (ใหญ่) - 60-70g
            "grade2": 16000,  # เบอร์ 2 (กลาง) - 50-60g
            "grade3": 12000,  # เบอร์ 3 (เล็ก) - 40-50g
            "grade4": 8000,   # เบอร์ 4 (เล็กมาก) - 30-40g
            "grade5": 0      # เบอร์ 5 (พิเศษเล็ก) - < 30g
        }
        
        # Egg shape filters
        self.min_area = 2000      # พื้นที่น้อยสุด (noise)
        self.max_area = 50000     # พื้นที่มากสุด (ไม่ใช่ไข่)
        self.min_aspect = 0.5     # aspect ratio น้อยสุด (รี)
        self.max_aspect = 2.0     # aspect ratio มากสุด (รี)
        self.min_circularity = 0.3 # ความกลมน้อยสุด
        
    def preprocess_image(self, image: Image.Image) -> np.ndarray:
        """Preprocess image for egg detection"""
        # Convert PIL to OpenCV format
        cv_image = cv2.cvtColor(np.array(image), cv2.COLOR_RGB2BGR)
        
        # Convert to grayscale
        gray = cv2.cvtColor(cv_image, cv2.COLOR_BGR2GRAY)
        
        # Apply Gaussian blur to reduce noise
        blurred = cv2.GaussianBlur(gray, (7, 7), 0)
        
        return blurred, cv_image
    
    def detect_eggs(self, image: Image.Image) -> Dict:
        """Detect eggs and classify by grade"""
        try:
            # Preprocess
            blurred, original = self.preprocess_image(image)
            
            # Adaptive threshold for better egg detection
            thresh = cv2.adaptiveThreshold(
                blurred, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, 
                cv2.THRESH_BINARY_INV, 11, 2
            )
            
            # Morphological operations to clean up
            kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
            thresh = cv2.morphologyEx(thresh, cv2.MORPH_OPEN, kernel)
            thresh = cv2.morphologyEx(thresh, cv2.MORPH_CLOSE, kernel)
            
            # Find contours
            contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
            
            # Process each contour
            detections = []
            grade_counts = {
                "grade0_count": 0,
                "grade1_count": 0,
                "grade2_count": 0,
                "grade3_count": 0,
                "grade4_count": 0,
                "grade5_count": 0
            }
            
            for i, contour in enumerate(contours):
                # Calculate contour properties
                area = cv2.contourArea(contour)
                
                # Skip if too small or too large
                if area < self.min_area or area > self.max_area:
                    continue
                
                # Calculate bounding box
                x, y, w, h = cv2.boundingRect(contour)
                aspect_ratio = w / h
                
                # Skip if not egg-shaped
                if aspect_ratio < self.min_aspect or aspect_ratio > self.max_aspect:
                    continue
                
                # Calculate circularity (4π*Area/Perimeter²)
                perimeter = cv2.arcLength(contour, True)
                if perimeter > 0:
                    circularity = (4 * math.pi * area) / (perimeter * perimeter)
                    if circularity < self.min_circularity:
                        continue
                
                # Classify egg grade based on area
                grade = self.classify_grade(area)
                grade_counts[f"{grade}_count"] += 1
                
                # Calculate confidence based on shape properties
                confidence = self.calculate_confidence(area, aspect_ratio, circularity if perimeter > 0 else 0)
                
                detection = {
                    "id": len(detections) + 1,
                    "grade": grade,
                    "confidence": round(confidence, 2),
                    "area": int(area),
                    "bbox": [int(x), int(y), int(w), int(h)]
                }
                detections.append(detection)
            
            # Calculate total and success rate
            total_eggs = len(detections)
            success_percent = (total_eggs / max(len(contours), 1)) * 100
            
            return {
                "detections": detections,
                "grade_counts": grade_counts,
                "total_eggs": total_eggs,
                "success_percent": round(success_percent, 1),
                "processed_contours": len(contours)
            }
            
        except Exception as e:
            print(f"Egg detection error: {e}")
            return {
                "detections": [],
                "grade_counts": {f"grade{i}_count": 0 for i in range(6)},
                "total_eggs": 0,
                "success_percent": 0.0,
                "error": str(e)
            }
    
    def classify_grade(self, area: float) -> str:
        """Classify egg grade based on area"""
        if area >= self.grade_thresholds["grade0"]:
            return "grade0"
        elif area >= self.grade_thresholds["grade1"]:
            return "grade1"
        elif area >= self.grade_thresholds["grade2"]:
            return "grade2"
        elif area >= self.grade_thresholds["grade3"]:
            return "grade3"
        elif area >= self.grade_thresholds["grade4"]:
            return "grade4"
        else:
            return "grade5"
    
    def calculate_confidence(self, area: float, aspect_ratio: float, circularity: float) -> float:
        """Calculate detection confidence based on egg properties"""
        confidence = 0.5  # Base confidence
        
        # Area confidence (not too small or too large)
        if 5000 <= area <= 30000:
            confidence += 0.2
        
        # Aspect ratio confidence (egg-shaped)
        if 0.7 <= aspect_ratio <= 1.5:
            confidence += 0.2
        
        # Circularity confidence (round-ish)
        if circularity > 0.4:
            confidence += 0.1
        
        return min(confidence, 0.95)  # Max 95% confidence

# Test function
def test_detector():
    """Test the egg detector"""
    detector = EggDetector()
    
    # Create a test image (white circle on black background)
    test_image = Image.new('RGB', (400, 400), 'black')
    # This would normally be a real egg image
    
    print("Egg Detector initialized successfully!")
    print("Grade thresholds:", detector.grade_thresholds)
    return detector

if __name__ == "__main__":
    test_detector()
