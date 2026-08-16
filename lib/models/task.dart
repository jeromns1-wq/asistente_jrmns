class Task {
  final int? id;
  final String title;
  final String? description;
  final String date;
  final String category;
  final String priority;
  final bool isCompleted;
  final String createdAt;

  Task({
    this.id,
    required this.title,
    this.description,
    required this.date,
    required this.category,
    required this.priority,
    this.isCompleted = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date,
      'category': category,
      'priority': priority,
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      date: map['date'] as String,
      category: map['category'] as String,
      priority: map['priority'] as String,
      isCompleted: map['isCompleted'] == 1,
      createdAt: map['createdAt'] as String,
    );
  }

  Task copyWith({
    int? id,
    String? title,
    String? description,
    String? date,
    String? category,
    String? priority,
    bool? isCompleted,
    String? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
