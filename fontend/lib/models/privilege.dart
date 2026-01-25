class Privilege {
  final int id;
  final String name;
  final String? description;
  final int level;
  final String createdAt;
  final String updatedAt;

  Privilege({
    required this.id,
    required this.name,
    this.description,
    required this.level,
    required this.createdAt,
    required this.updatedAt,
  });

  /// สร้าง Privilege จาก JSON ที่ได้จาก API
  factory Privilege.fromApiJson(List<dynamic> json) {
    // API ส่งค่ากลับมาเป็น List ตามลำดับคอลัมน์
    return Privilege(
      id: json[0] as int,
      name: json[1] as String,
      description: json[2] as String?,
      level: json[3] as int,
      createdAt: json[4] as String,
      updatedAt: json[5] as String,
    );
  }

  /// สร้าง Privilege จาก JSON ที่ได้จาก API (single privilege)
  factory Privilege.fromSingleApiJson(List<dynamic> json) {
    return Privilege.fromApiJson(json);
  }

  /// แปลงเป็น Map สำหรับส่งไป API
  Map<String, dynamic> toApiJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'level': level,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// แปลงเป็น Map สำหรับการแสดงผล
  Map<String, dynamic> toDisplayJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'level': level,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// สร้าง Privilege จาก Map (สำหรับ local storage)
  factory Privilege.fromMap(Map<String, dynamic> map) {
    return Privilege(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      level: map['level'] as int,
      createdAt: map['createdAt'] as String,
      updatedAt: map['updatedAt'] as String,
    );
  }

  /// แปลงเป็น Map (สำหรับ local storage)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'level': level,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// คัดลอก Privilege พร้อมแก้ไขค่าบางอย่าง
  Privilege copyWith({
    int? id,
    String? name,
    String? description,
    int? level,
    String? createdAt,
    String? updatedAt,
  }) {
    return Privilege(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      level: level ?? this.level,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// ตรวจสอบว่าเป็นสิทธิ์ระดับ Admin หรือไม่
  bool get isAdmin => level >= 3;

  /// ตรวจสอบว่าเป็นสิทธิ์ระดับ User ทั่วไปหรือไม่
  bool get isRegularUser => level == 1;

  /// ตรวจสอบว่าเป็นสิทธิ์ระดับ Manager หรือไม่
  bool get isManager => level == 2;

  /// แปลงระดับสิทธิ์เป็นข้อความภาษาไทย
  String get levelText {
    switch (level) {
      case 1:
        return 'ผู้ใช้ทั่วไป';
      case 2:
        return 'ผู้จัดการ';
      case 3:
        return 'ผู้ดูแลระบบ';
      default:
        return 'ไม่ทราบระดับ';
    }
  }

  /// แปลงระดับสิทธิ์เป็นสีสำหรับ UI
  String get levelColor {
    switch (level) {
      case 1:
        return 'green'; // สีเขียวสำหรับผู้ใช้ทั่วไป
      case 2:
        return 'orange'; // สีส้มสำหรับผู้จัดการ
      case 3:
        return 'red'; // สีแดงสำหรับผู้ดูแลระบบ
      default:
        return 'grey'; // สีเทาสำหรับไม่ทราบระดับ
    }
  }

  @override
  String toString() {
    return 'Privilege(id: $id, name: $name, level: $level, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Privilege &&
      other.id == id &&
      other.name == name &&
      other.level == level;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ level.hashCode;
}
