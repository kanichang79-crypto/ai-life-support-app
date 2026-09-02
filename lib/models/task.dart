class Task {
  final String id;
  final String title;
  final String memo;
  final DateTime? dueDate;
  final bool isDone;

  const Task({
    required this.id,
    required this.title,
    this.memo = '',
    this.dueDate,
    this.isDone = false,
  });

  Task copyWith({
    String? title,
    String? memo,
    DateTime? dueDate,
    bool clearDueDate = false,
    bool? isDone,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      memo: memo ?? this.memo,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'memo': memo,
      'dueDate': dueDate?.toIso8601String(),
      'isDone': isDone,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      memo: json['memo'] as String? ?? '',
      dueDate: json['dueDate'] == null
          ? null
          : DateTime.parse(json['dueDate'] as String),
      isDone: json['isDone'] as bool? ?? false,
    );
  }
}
