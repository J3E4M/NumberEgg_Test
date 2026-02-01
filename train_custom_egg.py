#!/usr/bin/env python3
"""
Custom Egg Detection Training Script
ลบ classes ที่ไม่เกี่ยวข้อง เหลือแค่ไข่ไทย
"""

from ultralytics import YOLO
import yaml

def train_egg_model():
    print("🥚 เริ่มเทรน AI ตรวจจับไข่ไทย...")
    
    # 1. โหลด YOLOv8n แล้ว reset classes
    model = YOLO('yolov8n.pt')
    
    # 2. สร้าง model ใหม่มีแค่ 3 classes (ไข่)
    # โดยจะ ignore 80 classes เดิม
    print("🔄 Reset model ให้มีแค่ 3 classes...")
    
    # 3. เทรนด้วย dataset ไข่ (ถ้ามี)
    try:
        results = model.train(
            data='egg_classes.yaml',
            epochs=50,
            imgsz=640,
            batch=16,
            name='egg_detector_v1',
            save_period=10,
            device='cpu'  # เปลี่ยนเป็น 'cuda' ถ้ามี GPU
        )
        print("✅ เทรนสำเร็จ!")
        return results
        
    except Exception as e:
        print(f"❌ ยังไม่มี dataset: {e}")
        print("📸 ต้องเก็บรูปไข่ + annotations ก่อน")
        return None

def create_empty_dataset():
    """สร้างโฟลเดอร์ว่างสำหรับ dataset"""
    import os
    
    folders = [
        'dataset/egg_dataset/images/train',
        'dataset/egg_dataset/images/val', 
        'dataset/egg_dataset/labels/train',
        'dataset/egg_dataset/labels/val'
    ]
    
    for folder in folders:
        os.makedirs(folder, exist_ok=True)
        print(f"📁 สร้างโฟลเดอร์: {folder}")

if __name__ == "__main__":
    create_empty_dataset()
    train_egg_model()
