import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/budget_item.dart';
import '../services/database_service.dart';
import '../widgets/empty_state.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _db = DatabaseService();
  List<BudgetItem> _items = [];
  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  String _type = 'Gasto';

  final List<String> _monthNames = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await _db.getBudgetItems(_currentMonth, _currentYear);
    setState(() => _items = items);
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentMonth += delta;
      if (_currentMonth > 12) {
        _currentMonth = 1;
        _currentYear++;
      } else if (_currentMonth < 1) {
        _currentMonth = 12;
        _currentYear--;
      }
    });
    _loadItems();
  }

  void _showItemDialog() {
    _descController.clear();
    _amountController.clear();
    _type = 'Gasto';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Movimiento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Descripción *'),
            ),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monto *'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: ['Ingreso', 'Gasto']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final desc = _descController.text.trim();
              final amount = double.tryParse(_amountController.text.trim()) ?? 0;
              if (desc.isEmpty || amount <= 0) return;

              final item = BudgetItem(
                description: desc,
                amount: amount,
                type: _type,
                month: _currentMonth,
                year: _currentYear,
                createdAt: DateTime.now().toIso8601String(),
              );
              await _db.insertBudgetItem(item);
              if (mounted) {
                Navigator.pop(context);
                _loadItems();
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar movimiento?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm == true) {
      await _db.deleteBudgetItem(id);
      _loadItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    final income = _items.where((i) => i.type == 'Ingreso').fold(0.0, (s, i) => s + i.amount);
    final expense = _items.where((i) => i.type == 'Gasto').fold(0.0, (s, i) => s + i.amount);
    final balance = income - expense;
    final formatter = NumberFormat.currency(locale: 'es_CL', symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Presupuesto'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  '${_monthNames[_currentMonth - 1]} $_currentYear',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard('Ingresos', income, Colors.green),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard('Gastos', expense, Colors.red),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard('Disponible', balance, balance >= 0 ? Colors.blue : Colors.orange),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _items.isEmpty
                ? EmptyState(
                    message: 'Todavía no has registrado movimientos este mes.',
                    buttonText: 'Agregar movimiento',
                    onPressed: _showItemDialog,
                  )
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: Icon(
                            item.type == 'Ingreso' ? Icons.arrow_upward : Icons.arrow_downward,
                            color: item.type == 'Ingreso' ? Colors.green : Colors.red,
                          ),
                          title: Text(item.description),
                          subtitle: Text(item.type),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                formatter.format(item.amount),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: item.type == 'Ingreso' ? Colors.green : Colors.red,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () => _deleteItem(item.id!),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showItemDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double value, Color color) {
    final formatter = NumberFormat.compactCurrency(locale: 'es_CL', symbol: '\$');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              formatter.format(value),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
