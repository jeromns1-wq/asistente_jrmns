import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../widgets/task_card.dart';
import '../widgets/empty_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = DatabaseService();
  List<Task> _tasks = [];
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _priority = 'Media';
  String _category = 'Personal';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  String get _today {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  String get _todayFormatted {
    final now = DateTime.now();
    final weekdays = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
    final months = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
    return 'Hoy, ${weekdays[now.weekday - 1]} ${now.day} de ${months[now.month - 1]}';
  }

  Future<void> _loadTasks() async {
    final tasks = await _db.getTasksByDate(_today);
    setState(() => _tasks = tasks);
  }

  void _showTaskDialog({Task? task}) {
    if (task != null) {
      _titleController.text = task.title;
      _descController.text = task.description ?? '';
      _priority = task.priority;
      _category = task.category;
    } else {
      _titleController.clear();
      _descController.clear();
      _priority = 'Media';
      _category = 'Personal';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task == null ? 'Nueva Tarea' : 'Editar Tarea'),
        content: SingleChildScrollView(
          child: Column(
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
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: const InputDecoration(labelText: 'Prioridad'),
                items: ['Baja', 'Media', 'Alta']
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => _priority = v!),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: ['Personal', 'Laboral', 'Familiar']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (_titleController.text.trim().isEmpty) return;
              final newTask = Task(
                id: task?.id,
                title: _titleController.text.trim(),
                description: _descController.text.trim(),
                date: _today,
                category: _category,
                priority: _priority,
                isCompleted: task?.isCompleted ?? false,
                createdAt: task?.createdAt ?? DateTime.now().toIso8601String(),
              );
              if (task == null) {
                await _db.insertTask(newTask);
              } else {
                await _db.updateTask(newTask);
              }
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
    final completed = _tasks.where((t) => t.isCompleted).length;
    final progress = _tasks.isEmpty ? 0.0 : completed / _tasks.length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_todayFormatted, style: const TextStyle(fontSize: 14)),
            const Text('Inicio', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: _tasks.isEmpty
          ? EmptyState(
              message: '¿Qué quieres hacer hoy?\nTodavía no tienes tareas para hoy.',
              buttonText: 'Agregar tarea',
              onPressed: _showTaskDialog,
            )
          : Column(
              children: [
                if (_tasks.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$completed de ${_tasks.length} tareas completadas',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              '${(progress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
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
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
