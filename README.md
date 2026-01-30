# Supabase Easy 🚀

Reduce Supabase + Flutter boilerplate by 60–70% while keeping type safety, flexibility, and performance.

## Features

- **Simplified Initialization**: Initialize Supabase with a single call.
- **EasyAuth**: Simplified authentication API for common tasks.
- **EasyRepository**: Generic repository for type-safe CRUD operations.
- **Simplified Real-time**: Easy-to-use streams for real-time updates.

## Getting Started

Add `supabase_easy` to your `pubspec.yaml`:

```yaml
dependencies:
  supabase_easy: ^0.0.1
```

## Usage

### 1. Initialize

```dart
await SupabaseEasy.initialize(
  url: 'https://your-project.supabase.co',
  anonKey: 'your-anon-key',
);
```

### 2. Define your Model

```dart
class Todo extends EasyModel {
  @override
  final String id;
  final String title;

  Todo({required this.id, required this.title});

  @override
  Map<String, dynamic> toJson() => {'id': id, 'title': title};

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
    id: json['id'],
    title: json['title'],
  );
}
```

### 3. Use Repository

```dart
final todoRepo = EasyRepository<Todo>(
  tableName: 'todos',
  fromJson: Todo.fromJson,
);

// Get all
final todos = await todoRepo.getAll();

// Create
await todoRepo.create(Todo(id: '1', title: 'Buy milk'));

// Real-time stream
todoRepo.stream(primaryKey: ['id']).listen((todos) {
  print(todos);
});
```

### 4. Simplified Auth

```dart
await EasyAuth.signIn(email: '...', password: '...');
print(EasyAuth.currentUser?.email);
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.


