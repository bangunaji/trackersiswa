class ActivityLog {
  final int? id;
  final String nis;
  final String studentName;
  final String activityType; // e.g. 'Belajar', 'Sholat', 'Sholat Dzuhur', etc.
  final String timestamp;    // ISO8601 string or formatted date
  final String notes;

  ActivityLog({
    this.id,
    required this.nis,
    required this.studentName,
    required this.activityType,
    required this.timestamp,
    this.notes = '',
  });

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
      activityType: map['activity_type'] as String,
      timestamp: map['timestamp'] as String,
      notes: map['notes'] as String? ?? '',
    );
  }
}
