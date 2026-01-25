// โมเดลข้อมูลประวัติการตรวจจับไข่
class EggHistory {
  final int id; // รหัสประวัติ
  final String imageName; // ชื่อรูปภาพ
  final double widthCm; // ความกว้างในเซนติเมตร
  final double heightCm; // ความสูงในเซนติเมตร
  final int grade; // เกรดของไข่ (0-5)
  final double confidence; //ความมั่นใจในการตรวจจับ (0.0-1.0)
  final DateTime createdAt; // วันที่สร้างข้อมูล

  // Constructor สำหรับสร้าง EggHistory
  EggHistory({
    required this.id,
    required this.imageName,
    required this.widthCm,
    required this.heightCm,
    required this.grade,
    required this.confidence,
    required this.createdAt,
  });

  // สร้าง EggHistory จาก Map (สำหรับดึงข้อมูลจากฐานข้อมูล)
  factory EggHistory.fromMap(Map<String, dynamic> map) {
    return EggHistory(
      id: map['id'],
      imageName: map['imageName'],
      widthCm: map['widthCm'],
      heightCm: map['heightCm'],
      grade: map['grade'],
      confidence: map['confidence'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
