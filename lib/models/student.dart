class Student {
  final String nis;
  final String name;
  final String className;

  Student({
    required this.nis,
    required this.name,
    required this.className,
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
      'nis': nis,
      'name': name,
      'class_name': className,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      nis: map['nis'] as String,
      name: map['name'] as String,
      className: map['class_name'] as String? ?? '',
    );
  }
}
