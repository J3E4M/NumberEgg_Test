class User {
  final int id;
  final String email;
  final String password;
  final String name;
  final int privilegeId;
  final String createdAt;
  final String updatedAt;
  final String? privilegeName;
  final int? privilegeLevel;
  final String? profileImagePath; // เพิ่ม field สำหรับ path ของรูปโปรไฟล์

  User({
    required this.id,
    required this.email,
    required this.password,
    required this.name,
    required this.privilegeId,
    required this.createdAt,
    required this.updatedAt,
    this.privilegeName,
    this.privilegeLevel,
    this.profileImagePath, // เพิ่ม parameter
  });

  /// ดึงข้อมูล privilege สำหรับความเข้ากันใช้งาน
  String get privilegeNameDisplay => privilegeName ?? 'Unknown';
  int get privilegeLevelDisplay => privilegeLevel ?? 0;

  /// สร้าง User จาก JSON ที่ได้จาก API
  factory User.fromApiJson(dynamic json) {
    if (json is List) {
      // API ส่งค่ากลับมาเป็น List ตามลำดับคอลัมน์
      return User(
        id: json[0] as int,
        email: json[1] as String,
        password: json[2] as String,
        name: json[3] as String,
        privilegeId: json[4] as int,
        createdAt: json[5] as String,
        updatedAt: json[6] as String,
        privilegeName: json.length > 7 ? json[7] as String? : null,
        privilegeLevel: json.length > 8 ? json[8] as int? : null,
      );
    } else if (json is Map) {
      // API ส่งค่ากลับมาเป็น Map
      return User(
        id: json['id'] as int,
        email: json['email'] as String,
        password: json['password'] as String,
        name: json['name'] as String,
        privilegeId: json['privilege_id'] as int,
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String,
        privilegeName: json['privilege_name'] as String?,
        privilegeLevel: json['privilege_level'] as int?,
      );
    } else {
      throw Exception('Invalid JSON format for User');
    }
  }

  /// สร้าง User จาก JSON ที่ได้จาก API (single user)
  factory User.fromSingleApiJson(List<dynamic> json) {
    return User.fromApiJson(json);
  }

  /// สร้าง User จาก JSON ที่ได้จาก login API response
  factory User.fromLoginJson(Map<String, dynamic> json) {
    final userData = json['user'] as Map<String, dynamic>;
    return User(
      id: userData['id'] as int,
      email: userData['email'] as String,
      password: userData['password'] as String,
      name: userData['name'] as String,
      privilegeId: userData['privilege_id'] as int,
      createdAt: userData['created_at'] as String,
      updatedAt: userData['updated_at'] as String,
      privilegeName: userData['privilege_name'] as String?,
      privilegeLevel: userData['privilege_level'] as int?,
      profileImagePath: userData['profile_image_path'] as String?, // เพิ่ม field นี้
    );
  }

  /// แปลงเป็น Map สำหรับส่งไป API
  Map<String, dynamic> toApiJson() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'name': name,
      'privilege_id': privilegeId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'privilege_name': privilegeName,
      'privilege_level': privilegeLevel,
      'profile_image_path': profileImagePath, // เพิ่ม field นี้
    };
  }

  /// แปลงเป็น Map สำหรับการแสดงผล (ไม่รวม password)
  Map<String, dynamic> toDisplayJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'privilegeId': privilegeId,
      'privilegeName': privilegeName,
      'privilegeLevel': privilegeLevel,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'profileImagePath': profileImagePath, // เพิ่ม field นี้
    };
  }

  /// สร้าง User จาก Map (สำหรับ local storage)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int,
      email: map['email'] as String,
      password: map['password'] as String,
      name: map['name'] as String,
      privilegeId: map['privilegeId'] as int,
      createdAt: map['createdAt'] as String,
      updatedAt: map['updatedAt'] as String,
      privilegeName: map['privilegeName'] as String?,
      privilegeLevel: map['privilegeLevel'] as int?,
      profileImagePath: map['profileImagePath'] as String?, // เพิ่ม field นี้
    );
  }

  /// แปลงเป็น Map (สำหรับ local storage)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'name': name,
      'privilegeId': privilegeId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'privilegeName': privilegeName,
      'privilegeLevel': privilegeLevel,
      'profileImagePath': profileImagePath, // เพิ่ม field นี้
    };
  }

  /// คัดลอก User พร้อมแก้ไขค่าบางอย่าง
  User copyWith({
    int? id,
    String? email,
    String? password,
    String? name,
    int? privilegeId,
    String? createdAt,
    String? updatedAt,
    String? privilegeName,
    int? privilegeLevel,
    String? profileImagePath, // เพิ่ม parameter นี้
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      name: name ?? this.name,
      privilegeId: privilegeId ?? this.privilegeId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      privilegeName: privilegeName ?? this.privilegeName,
      privilegeLevel: privilegeLevel ?? this.privilegeLevel,
      profileImagePath: profileImagePath ?? this.profileImagePath, // เพิ่ม parameter นี้
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name, privilege: $privilegeName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is User &&
      other.id == id &&
      other.email == email &&
      other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ email.hashCode ^ name.hashCode;
}
