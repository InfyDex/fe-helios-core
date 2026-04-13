/// Single todo row from Helios Todo service.
class Todo {
  const Todo({
    required this.id,
    required this.title,
    required this.done,
    required this.createdAt,
  });

  final String id;
  final String title;
  final bool done;
  final DateTime createdAt;

  factory Todo.fromJson(Map<String, dynamic> json) {
    final createdRaw = json['created_at'] ?? json['createdAt'];
    DateTime created;
    if (createdRaw is String) {
      created = DateTime.tryParse(createdRaw) ?? DateTime.fromMillisecondsSinceEpoch(0);
    } else if (createdRaw is int) {
      created = DateTime.fromMillisecondsSinceEpoch(createdRaw);
    } else {
      created = DateTime.fromMillisecondsSinceEpoch(0);
    }
    return Todo(
      id: json['id'] as String,
      title: (json['title'] as String?)?.trim() ?? '',
      done: json['done'] as bool? ?? false,
      createdAt: created,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'done': done,
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  Todo copyWith({
    String? id,
    String? title,
    bool? done,
    DateTime? createdAt,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      done: done ?? this.done,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
