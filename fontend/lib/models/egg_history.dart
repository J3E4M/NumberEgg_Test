class EggHistory {
  final int id;
  final String imageName;
  final double widthCm;
  final double heightCm;
  final int grade;
  final double confidence;
  final DateTime createdAt;

  EggHistory({
    required this.id,
    required this.imageName,
    required this.widthCm,
    required this.heightCm,
    required this.grade,
    required this.confidence,
    required this.createdAt,
  });

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
