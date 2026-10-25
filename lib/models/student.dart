class Student {
  final String nis;
  final String name;
  final String className;

  Student({
    required this.nis,
    required this.name,
    required this.className,
  });

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
