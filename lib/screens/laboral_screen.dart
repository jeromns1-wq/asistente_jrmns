import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../widgets/task_card.dart';
import '../widgets/empty_state.dart';

class LaboralScreen extends StatefulWidget {
  const LaboralScreen({super.key});

  @override
  State<LaboralScreen> createState() => _LaboralScreenState();
}

class _LaboralScreenState extends State<LaboralScreen> {
  final _db = DatabaseService();
  List<Task> _tasks = [];
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _priority = 'Media';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await _db.getTasksByCategory('Laboral');
    setState(() => _tasks = tasks);
  }

  void _showTaskDialog({Task? task}) {
    _titleController.text = task?.title ?? '';
    _descController.text = task?.description ?? '';
    _priority = task?.priority ?? 'Media';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task == null ? 'Nueva Tarea Laboral' : 'Editar Tarea'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título *'),
            ),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            DropdownButtonFormField<String>(
              value: _priority,
              decoration: const InputDecoration(labelText: 'Prioridad'),
              items: ['Baja', 'Media', 'Alta']
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => _priority = v!),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (_titleController.text.trim().isEmpty) return;
              final newTask = Task(
                id: task?.id,
                title: _titleController.text.trim(),
                description: _descController.text.trim(),
                date: DateTime.now().toIso8601String().split('T')[0],
                category: 'Laboral',
                priority: _priority,
                isCompleted: task?.isCompleted ?? false,
                createdAt: task?.createdAt ?? DateTime.now().toIso8601String(),
              );
              if (task == null) await _db.insertTask(newTask);
              else await _db.updateTask(newTask);
              if (mounted) {
                Navigator.pop(context);
                _loadTasks();
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleTask(Task task) async {
    await _db.updateTask(task.copyWith(isCompleted: !task.isCompleted));
    _loadTasks();
  }

  Future<void> _deleteTask(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar tarea?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm == true) {
      await _db.deleteTask(id);
      _loadTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laboral')),
      body: _tasks.isEmpty
          ? EmptyState(
              message: 'Todavía no tienes tareas laborales.',
              buttonText: 'Crear tarea',
              onPressed: _showTaskDialog,
            )
          : ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return TaskCard(
                  task: task,
                  onToggle: () => _toggleTask(task),
                  onEdit: () => _showTaskDialog(task: task),
                  onDelete: () => _deleteTask(task.id!),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
