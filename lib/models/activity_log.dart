class ActivityLog {
  final int? id;
  final String nis;
  final String studentName;
  final String className;
  final String activityType; // e.g. 'Belajar', 'Sholat', 'Sholat Dzuhur', etc.
  final String timestamp;    // ISO8601 string or formatted date
  final String notes;

  ActivityLog({
    this.id,
    required this.nis,
    required this.studentName,
    this.className = '',
    required this.activityType,
    required this.timestamp,
    this.notes = '',
  });

  int get gradeLevel {
    final upper = className.trim().toUpperCase();
    if (upper.startsWith('XII') ||
        upper.startsWith('12') ||
        upper.contains('KELAS 12') ||
        upper.contains('KELAS XII')) {
      return 12;
    }
    if (upper.startsWith('XI') ||
        upper.startsWith('11') ||
        upper.contains('KELAS 11') ||
        upper.contains('KELAS XI')) {
      return 11;
    }
    if (upper.startsWith('X') ||
        upper.startsWith('10') ||
        upper.contains('KELAS 10') ||
        upper.contains('KELAS X')) {
      return 10;
    }
    return 0;
  }

  String get gradeLabel {
    final g = gradeLevel;
    if (g == 10) return 'Kelas 10';
    if (g == 11) return 'Kelas 11';
    if (g == 12) return 'Kelas 12';
    return 'Lainnya';
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nis': nis,
      'student_name': studentName,
      'activity_type': activityType,
      'timestamp': timestamp,
      'notes': notes,
    };
  }

  factory ActivityLog.fromMap(Map<String, dynamic> map) {
    return ActivityLog(
      id: map['id'] as int?,
      nis: map['nis'] as String,
      studentName: map['student_name'] as String,
      className: map['class_name'] as String? ?? '',
      activityType: map['activity_type'] as String,
      timestamp: map['timestamp'] as String,
      notes: map['notes'] as String? ?? '',
    );
  }
}
