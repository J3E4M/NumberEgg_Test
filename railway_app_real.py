from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
import onnxruntime as ort
import cv2
import numpy as np

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ✅ Load ONNX model
session = ort.InferenceSession("yolov8n.onnx")
input_name = session.get_inputs()[0].name

CLASS_NAMES = {
    0: "egg",
}

@app.get("/")
async def root():
    return {"status": "ok", "model": "YOLOv8n ONNX"}

@app.post("/detect")
async def detect(file: UploadFile = File(...)):
    # Read image
    image_bytes = await file.read()
    np_img = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(np_img, cv2.IMREAD_COLOR)
    
    # Preprocess
    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    img_resized = cv2.resize(img_rgb, (640, 640))
    img_normalized = img_resized.astype(np.float32) / 255.0
    img_transposed = np.transpose(img_normalized, (2, 0, 1))
    img_batch = np.expand_dims(img_transposed, axis=0)
    
    # ✅ Run ONNX inference
    outputs = session.run(None, {input_name: img_batch})
    predictions = outputs[0]
    
    # ✅ Post-process (NMS and bbox extraction)
    detections = []
    
    # YOLOv8 output shape: [1, 84, 8400]
    # 84 = 4 (bbox) + 80 (classes)
    predictions = predictions[0].T  # [8400, 84]
    
    for pred in predictions:
        # Extract bbox and confidence
        x_center, y_center, width, height = pred[:4]
        class_scores = pred[4:]
        
        class_id = np.argmax(class_scores)
        confidence = class_scores[class_id]
        
        if confidence > 0.5:  # Confidence threshold
            # Convert to x1, y1, x2, y2
            x1 = (x_center - width / 2) * img.shape[1] / 640
            y1 = (y_center - height / 2) * img.shape[0] / 640
            x2 = (x_center + width / 2) * img.shape[1] / 640
            y2 = (y_center + height / 2) * img.shape[0] / 640
            
            detections.append({
                "x1": float(x1),
                "y1": float(y1),
                "x2": float(x2),
                "y2": float(y2),
                "width_px": float(x2 - x1),
                "height_px": float(y2 - y1),
                "confidence": float(confidence),
                "class_id": int(class_id),
                "class_name": CLASS_NAMES.get(int(class_id), "unknown")
            })
    
    # ✅ Simple NMS (remove overlapping boxes)
    detections = non_max_suppression(detections)
    
    return {
        "count": len(detections),
        "detections": detections
    }

def non_max_suppression(detections, iou_threshold=0.5):
    """Simple NMS implementation"""
    if not detections:
        return []
    
    # Sort by confidence
    detections = sorted(detections, key=lambda x: x['confidence'], reverse=True)
    keep = []
    
    while detections:
        best = detections.pop(0)
        keep.append(best)
        
        detections = [
            det for det in detections
            if iou(best, det) < iou_threshold
        ]
    
    return keep

def iou(box1, box2):
    """Calculate IoU between two boxes"""
    x1 = max(box1['x1'], box2['x1'])
    y1 = max(box1['y1'], box2['y1'])
    x2 = min(box1['x2'], box2['x2'])
    y2 = min(box1['y2'], box2['y2'])
    
    intersection = max(0, x2 - x1) * max(0, y2 - y1)
    area1 = (box1['x2'] - box1['x1']) * (box1['y2'] - box1['y1'])
    area2 = (box2['x2'] - box2['x1']) * (box2['y2'] - box2['y1'])
    union = area1 + area2 - intersection
    
    return intersection / union if union > 0 else 0

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)