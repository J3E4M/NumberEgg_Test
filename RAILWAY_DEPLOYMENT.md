# Railway Deployment Guide with Supabase Integration

## 🚀 การติดตั้งและ Deploy บน Railway พร้อม Supabase

### 1. เตรียมไฟล์สำหรับการ Deploy

ไฟล์ที่จำเป็น:
- `simple_server.py` - Server หลักที่มี Supabase integration
- `requirements_simple.txt` - Dependencies ที่อัพเดตแล้ว
- `Dockerfile.simple` - Dockerfile สำหรับ Railway
- `railway_simple.toml` - Railway configuration
- `yolov8n.pt` - YOLO model file

### 2. การ Deploy บน Railway

#### วิธีที่ 1: ใช้ Railway CLI
```bash
# คัดลอก configuration file
cp railway_simple.toml railway.toml

# Deploy ไปยัง Railway
railway up
```

#### วิธีที่ 2: ผ่าน GitHub
1. Push ไฟล์ทั้งหมดขึ้น GitHub
2. ไปที่ Railway dashboard
3. Connect repository และเลือก branch
4. Railway จะ build และ deploy อัตโนมัติ

#### วิธีที่ 3: Railway Dashboard
1. สร้าง project ใหม่บน Railway
2. Upload ไฟล์หรือ connect GitHub
3. ตั้งค่า environment variables ถ้าจำเป็น

### 3. Environment Variables สำหรับ Railway

Railway จะใช้ environment variables จาก `railway_simple.toml`:
```
PORT=8000
PYTHONUNBUFFERED=1
SUPABASE_URL=https://gbxxwojlihgrbtthmusq.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 4. การทำงานของ Server

#### Endpoints ที่มี:
- `GET /health` - Health check พร้อม Supabase status
- `GET /detect` - Status check
- `POST /detect` - Main detection endpoint (บันทึกลง Supabase อัตโนมัติ)
- `POST /save-session` - Manual session saving

#### Response Format ของ `/detect`:
```json
{
  "count": 3,
  "detections": [...],
  "session_id": 123,
  "supabase_status": "saved"
}
```

### 5. การตรวจสอบการทำงาน

#### Health Check:
```bash
curl https://your-app-url.railway.app/health
```

Response:
```json
{
  "status": "healthy",
  "model": "loaded",
  "supabase": "connected"
}
```

#### Test Detection:
```bash
curl -X POST -F "file=@test_image.jpg" \
  https://your-app-url.railway.app/detect
```

### 6. Supabase Integration

#### ข้อมูลที่บันทึก:
1. **egg_session table**:
   - user_id, image_path, egg_count
   - success_percent, grade counts
   - day, created_at

2. **egg_item table**:
   - session_id, grade, confidence
   - x1, y1, x2, y2 (coordinates)

#### การตรวจสอบข้อมูลใน Supabase:
1. ไปที่ Supabase dashboard
2. เลือก table `egg_session` และ `egg_item`
3. ตรวจสอบข้อมูลที่ถูกบันทึก

### 7. Monitoring บน Railway

- **Logs**: ดู logs ใน Railway dashboard
- **Metrics**: ตรวจสอบ performance และ errors
- **Health Checks**: Railway จะตรวจสอบ `/health` endpoint อัตโนมัติ

### 8. Troubleshooting

#### ปัญหาที่อาจเกิดขึ้น:

1. **Supabase Connection Failed**:
   - ตรวจสอบ SUPABASE_URL และ SUPABASE_ANON_KEY
   - ตรวจสอบว่า Supabase project ยังทำงานอยู่

2. **Model Loading Failed**:
   - ตรวจสอบว่า `yolov8n.pt` อยู่ใน project
   - ตรวจสอบว่ามีพื้นที่เพียงพอ

3. **Memory Issues**:
   - Railway free tier มี memory จำกัด
   - พิจารณาใช้ model ที่เล็กกว่า

4. **CORS Issues**:
   - Server ได้เปิด CORS สำหรับทุก origin แล้ว
   - ตรวจสอบว่า Flutter app เรียก API ถูกต้อง

### 9. Production Tips

1. **Security**:
   - ใช้ environment variables สำหรับ sensitive data
   - พิจารณาใช้ service role key แทน anon key

2. **Performance**:
   - ตรวจสอบ response time
   - พิจารณาใช้ CDN สำหรับ images

3. **Scaling**:
   - Railway จะ auto-scale ตาม traffic
   - ตรวจสอบ billing limits

### 10. Flutter App Integration

อัพเดต `server_config.dart` ให้ชี้ไปที่ Railway URL:
```dart
static const String _currentEnvironment = 'production';
```

หรือใช้ Railway URL โดยตรง:
```dart
static const String _railwayUrl = 'https://your-app-url.railway.app';
```

---

## ✅ การ Deploy สำเร็จ!

หลังจาก deploy สำเร็จ คุณจะได้:
- Railway API พร้อม YOLO detection
- Supabase integration สำหรับบันทึกข้อมูล
- Health monitoring และ auto-restart
- CORS support สำหรับ Flutter app
