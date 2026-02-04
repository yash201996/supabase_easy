# Supabase Easy 🚀

Reduce Supabase + Flutter boilerplate by 60–70% while keeping type safety, flexibility, and performance.

## Features

- **Simplified Initialization**: Initialize Supabase with a single call.
- **EasyAuth**: Simplified authentication API for common tasks.
- **EasyRepository**: Generic repository for type-safe CRUD operations.
- **EasyStorage**: Simplified file management for buckets.
- **Simplified Real-time**: Easy-to-use streams for real-time updates.

---

**Note**: This plugin is designed to be highly useful for rapid development. We are committed to continuously optimizing the codebase and keeping it updated with the latest Supabase and Flutter features.

## Screenshots

| Login & Signup | Task Management |
| :---: | :---: |
| ![Login](screenshots/Screenshot_1769849818.png) | ![TodoList](screenshots/Screenshot_1769849837.png) |
| ![Signup](screenshots/Screenshot_1769849821.png) | ![Add Task](screenshots/Screenshot_1769849858.png) |
| | ![Empty State](screenshots/Screenshot_1769849865.png) |

## Getting Started

Add `supabase_easy` to your `pubspec.yaml`:

```yaml
dependencies:
  supabase_easy: ^0.0.3
```

## Setup Supabase

To use this plugin, you need to:

1. Create a Supabase project at [supabase.com](https://supabase.com).
2. Create your tables (e.g., `todos`).
3. Enable **Row Level Security (RLS)** on your tables.
4. Add policies to allow authenticated or public access. For testing, you can use:
   ```sql
   CREATE POLICY "Allow public access" ON todos FOR ALL TO public USING (true) WITH CHECK (true);
   ```
5. Get your **Project URL** and **Anon Key** from the Supabase Dashboard (Settings > API).

### Important: OAuth & Storage Setup

To ensure **OAuth** and **Storage** work correctly, please verify the following in your Supabase Dashboard:

#### 🔐 OAuth Configuration
1. **Enable Providers**: Go to `Auth > Providers` and enable your desired providers (e.g., Google, GitHub).
2. **Redirect URLs**: Add your application's deep link URL (e.g., `io.supabase.flutter://callback`) to `Auth > URL Configuration > Redirect URLs`.
3. **Platform Setup**: Follow the [Supabase Auth guide](https://supabase.com/docs/guides/auth/social-login) for specific platform configurations (Android/iOS deep linking).

#### 📁 Storage Configuration
1. **Create Buckets**: Go to `Storage > Buckets` and create the buckets you reference in your code (e.g., `profiles`, `avatars`).
2. **Set RLS Policies**: By default, buckets are private. You **must** add policies to allow users to upload or view files.
   - For public viewing: `Allow SELECT for everyone`.
   - For user uploads: `Allow INSERT/UPDATE for authenticated users`.
3. **Public/Private**: Decide if your bucket should be "Public" (files accessible via public URL) or "Private" (files require a signed URL).

## Usage

### 1. Initialize

```dart
await SupabaseEasy.initialize(
  url: const String.fromEnvironment('SUPABASE_URL'),
  anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
);
```

> **Security Note**: Never hardcode your Supabase credentials in your code, especially if you plan to share your repository. Use `--dart-define` or environment variables to inject them at build time:
> ```bash
> flutter run --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key
> ```

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

### 5. Storage

```dart
// Upload file
await EasyStorage.upload(
  bucketId: 'avatars',
  path: 'user_1.png',
  file: File('path/to/image.png'),
);

// Get public URL
final url = EasyStorage.getPublicUrl(
  bucketId: 'avatars',
  path: 'user_1.png',
);
```

## Example

Check out the [example](example/) folder for a complete Todo app implementation using this plugin.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.


