# API Configuration Guide

## การตั้งค่า API Endpoint สำหรับ NumberEgg App

### 1. Local Development (localhost:8000)
- ใช้สำหรับทดสอบบนเครื่อง local
- ต้องรัน server ที่ port 8000
- ตั้งค่า `_currentEnvironment = 'development'` ใน `server_config.dart`

### 2. Railway Production
- ใช้สำหรับ production บน Railway
- ตั้งค่า `_currentEnvironment = 'production'` ใน `server_config.dart`

### 3. Local Network Testing
- ใช้สำหรับทดสอบบนอุปกรณ์อื่นในเครือข่ายเดียวกัน
- เปลี่ยน IP ใน `_localNetworkUrl` ตาม IP เครื่อง server
- ตั้งค่า `_currentEnvironment = 'local_network'` ใน `server_config.dart`

### 4. Simple Server
- ใช้กับ `simple_server.py` ที่สร้างไว้
- ตั้งค่า `_currentEnvironment = 'simple'` ใน `server_config.dart`

## วิธีการเปลี่ยน Environment

แก้ไขไฟล์ `lib/utils/server_config.dart`:
```dart
static const String _currentEnvironment = 'development'; // เปลี่ยนตรงนี้
```

## วิธีการรัน Server

### Simple Server (สำหรับทดสอบ)
```bash
cd c:\Project01_NumberEgg
pip install -r requirements_simple.txt
uvicorn simple_server:app --host 0.0.0.0 --port 8000 --reload
```

### Railway Server
```bash
# ใช้ Railway CLI หรือ deploy ผ่าน GitHub
railway up
```

## การตรวจสอบ Server Health

สามารถใช้ฟังก์ชัน `checkServerHealth()` เพื่อตรวจสอบว่า server พร้อมใช้งาน:
```dart
bool isHealthy = await ServerConfig.checkServerHealth('http://localhost:8000');
```

## การตั้งค่า IP สำหรับ Local Network

1. หา IP เครื่อง server:
   - Windows: `ipconfig`
   - Mac/Linux: `ifconfig` หรือ `ip addr`

2. อัพเดท IP ใน `server_config.dart`:
   ```dart
   static const String _localNetworkUrl = 'http://YOUR_IP:8000';
   ```

## การทดสอบ API

สามารถทดสอบ API ด้วย curl:
```bash
curl -X POST -F "file=@test_image.jpg" http://localhost:8000/detect
```
