import 'package:supabase_easy/supabase_easy.dart';

class Todo extends EasyModel {
  @override
  final String id;
  final String title;
  final bool isCompleted;

  Todo({required this.id, required this.title, this.isCompleted = false});

  @override
  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'is_completed': isCompleted};
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: json['is_completed'] as bool? ?? false,
    );
  }
}
