# supabase_easy

[![pub package](https://img.shields.io/pub/v/supabase_easy.svg)](https://pub.dev/packages/supabase_easy)
[![pub points](https://img.shields.io/pub/points/supabase_easy)](https://pub.dev/packages/supabase_easy/score)
[![likes](https://img.shields.io/pub/likes/supabase_easy)](https://pub.dev/packages/supabase_easy)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-android%20%7C%20ios-lightgrey)]()

A thin, type-safe Flutter wrapper around [supabase_flutter](https://pub.dev/packages/supabase_flutter) that cuts Auth, CRUD, real-time, and Storage boilerplate by **60–70%** — without hiding any power.

---

## Why supabase_easy?

| Without `supabase_easy` | With `supabase_easy` |
|-------------------------|----------------------|
| Repeated `Supabase.instance.client.from(...)` | `todoRepo.getAll()` |
| Manual `PostgrestException` catching everywhere | One `EasyException` type across all APIs |
| Writing `select`, `insert`, `update`, `delete`, `.single()` every time | 9 ready-made repository methods |
| Re-implementing count, bulk-delete, search | `count()`, `deleteMany()`, `updateWhere()` built-in |
| Hand-rolling auth try/catch blocks | `EasyAuth.signIn / signOut / signInWithOtp` etc. |

---

## Features

- **Single import** — `import 'package:supabase_easy/supabase_easy.dart'`
- **`EasyAuth`** — email/password, OAuth, magic-link/OTP, password reset, session refresh
- **`EasyRepository<T>`** — generic type-safe CRUD, bulk ops, search, pagination, real-time streams
- **`EasyStorage`** — upload (File or bytes), download, delete, signed URLs, image transforms
- **`EasyException`** — one exception type wrapping `PostgrestException`, `AuthException`, `StorageException`
- Full DartDoc on every public API

---

## Screenshots

| Login & Signup | Task Management |
| :---: | :---: |
| ![Login](screenshots/Screenshot_1769849818.png) | ![TodoList](screenshots/Screenshot_1769849837.png) |
| ![Signup](screenshots/Screenshot_1769849821.png) | ![Add Task](screenshots/Screenshot_1769849858.png) |
| | ![Empty State](screenshots/Screenshot_1769849865.png) |

---

## Getting Started

### 1. Add dependency

```yaml
dependencies:
  supabase_easy: ^0.0.6
```

### 2. Supabase project checklist

1. Create a project at [supabase.com](https://supabase.com).
2. Create your tables and enable **Row Level Security (RLS)**.
3. Copy your **Project URL** and **Anon Key** from _Settings › API_.

> **Security tip:** Never hardcode credentials. Pass them at build time:
> ```bash
> flutter run \
>   --dart-define=SUPABASE_URL=https://xyz.supabase.co \
>   --dart-define=SUPABASE_ANON_KEY=your_anon_key
> ```

### 3. Initialise (once, in `main()`)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseEasy.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  runApp(const MyApp());
}
```

---

## Usage

### EasyAuth

```dart
// Email + password
await EasyAuth.signUp(email: 'user@example.com', password: 'secret');
await EasyAuth.signIn(email: 'user@example.com', password: 'secret');
await EasyAuth.signOut();

// Magic link / OTP
await EasyAuth.signInWithOtp(email: 'user@example.com');
await EasyAuth.verifyOtp(email: 'user@example.com', token: '123456');

// OAuth (Google, GitHub, …)
await EasyAuth.signInWithOAuth(OAuthProvider.google);

// Helpers
print(EasyAuth.isSignedIn);       // bool
print(EasyAuth.currentUser?.id);  // String?

// React to auth changes
StreamBuilder<AuthState>(
  stream: EasyAuth.onAuthStateChange,
  builder: (context, snapshot) { ... },
);
```

### EasyRepository

Define a model:

```dart
class Todo extends EasyModel {
  @override final String id;
  final String title;
  final bool isDone;

  Todo({required this.id, required this.title, this.isDone = false});

  @override
  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'is_done': isDone};

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
        id: json['id'] as String,
        title: json['title'] as String,
        isDone: json['is_done'] as bool? ?? false,
      );
}
```

Use the repository:

```dart
final repo = EasyRepository<Todo>(
  tableName: 'todos',
  fromJson: Todo.fromJson,
);

// --- Read ---
final all    = await repo.getAll();
final done   = await repo.getAll(filter: {'is_done': true});
final paged  = await repo.getAll(orderBy: 'created_at', limit: 20, from: 0, to: 19);
final search = await repo.getAll(searchColumn: 'title', searchQuery: 'milk');
final single = await repo.getById('some-uuid');  // returns null if missing
final total  = await repo.count();

// --- Write ---
final created = await repo.create(Todo(id: 'uuid', title: 'Buy milk'));
final updated = await repo.update(created.copyWith(isDone: true));
final upserted = await repo.upsert(todo);

// Bulk operations
await repo.createMany([todo1, todo2]);
await repo.deleteMany(['id-1', 'id-2']);
await repo.updateWhere(
  filter: {'is_done': true},
  data: {'archived': true},
);
await repo.delete('some-uuid');

// --- Real-time ---
StreamBuilder<List<Todo>>(
  stream: repo.stream(primaryKey: ['id'], orderBy: 'created_at'),
  builder: (context, snapshot) {
    final todos = snapshot.data ?? [];
    return ListView.builder(...);
  },
);
```

### EasyStorage

```dart
// Upload
await EasyStorage.upload(
  bucketId: 'avatars',
  path: 'user_123.png',
  file: File('/path/to/image.png'),            // from dart:io
  // bytes: imageBytes,                        // or raw Uint8List
  options: const FileOptions(upsert: true),
);

// Public URL (with optional image transform)
final url = EasyStorage.getPublicUrl(
  bucketId: 'avatars',
  path: 'user_123.png',
  transform: TransformOptions(width: 200, height: 200),
);

// Signed URL for private buckets
final signed = await EasyStorage.createSignedUrl(
  bucketId: 'private-docs',
  path: 'report.pdf',
  expiresIn: 3600, // 1 hour
);

// Download / delete / list / move / copy
final bytes = await EasyStorage.download(bucketId: 'avatars', path: 'user_123.png');
await EasyStorage.delete(bucketId: 'avatars', paths: ['user_123.png']);
final files = await EasyStorage.list(bucketId: 'avatars', path: 'subfolder/');
```

### Error handling

Every method throws `EasyException` — one type for all Supabase errors:

```dart
try {
  await EasyAuth.signIn(email: email, password: password);
} on EasyException catch (e) {
  print(e.message); // human-readable
  print(e.cause);   // original AuthException / PostgrestException / etc.
}
```

---

## OAuth & Storage setup

<details>
<summary>OAuth (Google, GitHub, …)</summary>

1. Go to **Auth › Providers** and enable desired providers.
2. Add your deep-link URL (e.g. `io.supabase.flutter://callback`) to **Auth › URL Configuration › Redirect URLs**.
3. Follow the [Supabase social login guide](https://supabase.com/docs/guides/auth/social-login) for Android/iOS deep-link config.

</details>

<details>
<summary>Storage buckets</summary>

1. Create buckets in **Storage › Buckets**.
2. Add RLS policies:
   - Public read: `Allow SELECT for everyone`
   - Authenticated upload: `Allow INSERT for authenticated users`
3. Mark a bucket **Public** for `getPublicUrl` to work without a signed URL.

</details>

---

## API reference

| Class | Key members |
|-------|------------|
| `SupabaseEasy` | `initialize()`, `isInitialized` |
| `EasyAuth` | `signUp`, `signIn`, `signOut`, `signInWithOAuth`, `signInWithOtp`, `verifyOtp`, `resetPassword`, `updateUser`, `refreshSession`, `currentUser`, `isSignedIn`, `onAuthStateChange` |
| `EasyRepository<T>` | `getAll`, `getById`, `count`, `create`, `createMany`, `update`, `updateWhere`, `upsert`, `delete`, `deleteMany`, `stream` |
| `EasyStorage` | `upload`, `download`, `delete`, `getPublicUrl`, `createSignedUrl`, `list`, `move`, `copy`, `bucket` |
| `EasyException` | `message`, `cause` |

---

## Example app

See the [example/](example/) folder for a full Todo app — auth, CRUD, and real-time all wired up.

---

## License

MIT — see [LICENSE](LICENSE).

