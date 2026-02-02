import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_easy/supabase_easy.dart';
import '../../todo_model.dart';

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final todoRepository = EasyRepository<Todo>(
    tableName: 'todos',
    fromJson: Todo.fromJson,
  );

  bool _isUploading = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final user = EasyAuth.currentUser;
    if (user != null) {
      try {
        // Try to get public URL if it exists
        final url = EasyStorage.getPublicUrl(
          bucketId: 'profiles',
          path: '${user.id}/avatar.png',
        );
        setState(() => _avatarUrl = url);
      } catch (_) {}
    }
  }

  Future<void> _uploadAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      final user = EasyAuth.currentUser;
      if (user == null) return;

      final bytes = await image.readAsBytes();
      await EasyStorage.upload(
        bucketId: 'profiles',
        path: '${user.id}/avatar.png',
        bytes: bytes,
        options: const FileOptions(upsert: true),
      );

      await _loadAvatar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _showAddTodoDialog() async {
    final controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Todo'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'What needs to be done?',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                try {
                  await todoRepository.create(
                    Todo(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: controller.text,
                    ),
                  );
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Tasks',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              try {
                await EasyAuth.signOut();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout failed: $e'),
                      backgroundColor: colorScheme.error,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildProfileHeader(colorScheme),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<Todo>>(
              stream: todoRepository.stream(primaryKey: ['id']),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 64,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${snapshot.error}',
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final todos = snapshot.data!;
                if (todos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_alt_rounded,
                          size: 80,
                          color: colorScheme.primaryContainer,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'All caught up!',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        const Text('Add a todo to get started'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: todos.length,
                  itemBuilder: (context, index) {
                    final todo = todos[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: colorScheme.outlineVariant),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          title: Text(
                            todo.title,
                            style: TextStyle(
                              decoration: todo.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: todo.isCompleted
                                  ? colorScheme.onSurfaceVariant
                                  : colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          leading: Checkbox(
                            value: todo.isCompleted,
                            shape: const CircleBorder(),
                            onChanged: (val) async {
                              try {
                                await todoRepository.update(
                                  Todo(
                                    id: todo.id,
                                    title: todo.title,
                                    isCompleted: val ?? false,
                                  ),
                                );
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Update failed: $e'),
                                      backgroundColor: colorScheme.error,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: colorScheme.error,
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Task?'),
                                  content: const Text(
                                    'This action cannot be undone.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      style: TextButton.styleFrom(
                                        foregroundColor: colorScheme.error,
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                try {
                                  await todoRepository.delete(todo.id);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Delete failed: $e'),
                                        backgroundColor: colorScheme.error,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTodoDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProfileHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: colorScheme.surfaceVariant.withOpacity(0.3),
      child: Row(
        children: [
          GestureDetector(
            onTap: _isUploading ? null : _uploadAvatar,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: colorScheme.primaryContainer,
                  backgroundImage: _avatarUrl != null
                      ? NetworkImage(_avatarUrl!)
                      : null,
                  child: _avatarUrl == null
                      ? Icon(
                          Icons.person,
                          size: 30,
                          color: colorScheme.onPrimaryContainer,
                        )
                      : null,
                ),
                if (_isUploading)
                  const Positioned.fill(child: CircularProgressIndicator()),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, User!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                'Tap avatar to upload',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
