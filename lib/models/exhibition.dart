class Exhibition {
  String id;
  String title;
  List<String> pictures;
  DateTime? lastScan;

  Exhibition({
    required this.id,
    required this.title,
    required this.pictures,
    this.lastScan,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'pictures': pictures,
      'lastScan': lastScan?.toIso8601String(),
    };
  }

  factory Exhibition.fromMap(Map<String, dynamic> map) {
    return Exhibition(
      id: map['id'],
      title: map['title'],
      pictures: List<String>.from(map['pictures'] ?? []),
      lastScan: map['lastScan'] != null ? DateTime.parse(map['lastScan']) : null,
    );
  }
}
