import 'package:flutter/material.dart';
import '../models/vault_item.dart';
import '../services/database_service.dart';
import '../services/vault_crypto_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/vault_pin_dialog.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final _db = DatabaseService();
  List<VaultItem> _items = [];
  bool _isAuthenticated = false;
  bool _hasPin = false;

  final _nameController = TextEditingController();
  final _userController = TextEditingController();
  final _secretController = TextEditingController();
  final _noteController = TextEditingController();
  String _category = 'Contraseñas';
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _categories = [
    'Contraseñas', 'API Keys', 'Correos', 'Teléfonos', 'Notas', 'Otros'
  ];

  @override
  void initState() {
    super.initState();
    _checkPin();
  }

  Future<void> _checkPin() async {
    final pinHash = await _db.getVaultPin();
    setState(() => _hasPin = pinHash != null);
  }

  Future<void> _authenticate() async {
    if (!_hasPin) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => const VaultPinDialog(isSetup: true),
      );
      if (result == true) {
        setState(() {
          _hasPin = true;
          _isAuthenticated = true;
        });
        _loadItems();
      }
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const VaultPinDialog(isSetup: false),
    );
    if (result == true) {
      setState(() => _isAuthenticated = true);
      _loadItems();
    }
  }

  Future<void> _loadItems() async {
    final items = await _db.getVaultItems();
    setState(() => _items = items);
  }

  void _showItemDialog({VaultItem? item}) {
    _nameController.text = item?.name ?? '';
    _userController.text = item?.username ?? '';
    _secretController.text = item?.secret ?? '';
    _noteController.text = item?.note ?? '';
    _category = item?.category ?? 'Contraseñas';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? 'Nuevo Elemento' : 'Editar Elemento'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre *'),
              ),
              TextField(
                controller: _userController,
                decoration: const InputDecoration(labelText: 'Usuario / Correo'),
              ),
              TextField(
                controller: _secretController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Clave / Secret *'),
              ),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Nota'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (_nameController.text.trim().isEmpty || _secretController.text.trim().isEmpty) return;

              final pinHash = await _db.getVaultPin();
              if (pinHash == null) return;

              final encrypted = VaultCryptoService.encryptSecret(
                _secretController.text.trim(),
                _secretController.text.trim(),
              );

              final vaultItem = VaultItem(
                id: item?.id,
                name: _nameController.text.trim(),
                username: _userController.text.trim(),
                secret: encrypted,
                note: _noteController.text.trim(),
                category: _category,
                createdAt: item?.createdAt ?? DateTime.now().toIso8601String(),
              );

              if (item == null) await _db.insertVaultItem(vaultItem);
              else await _db.insertVaultItem(vaultItem);

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
        title: const Text('¿Eliminar elemento?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm == true) {
      await _db.deleteVaultItem(id);
      _loadItems();
    }
  }

  List<VaultItem> get _filteredItems {
    if (_searchQuery.isEmpty) return _items;
    return _items.where((i) =>
      i.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      (i.username?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bóveda')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64),
              const SizedBox(height: 16),
              Text(
                _hasPin ? 'La bóveda está protegida' : 'Configura un PIN para tu bóveda',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _authenticate,
                icon: const Icon(Icons.lock_open),
                label: Text(_hasPin ? 'Desbloquear' : 'Crear PIN'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bóveda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => setState(() => _isAuthenticated = false),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: _filteredItems.isEmpty
                ? EmptyState(
                    message: 'Tu bóveda está vacía.',
                    buttonText: 'Guardar información',
                    onPressed: _showItemDialog,
                    icon: Icons.lock_outline,
                  )
                : ListView.builder(
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: const Icon(Icons.vpn_key_outlined),
                          title: Text(item.name),
                          subtitle: Text('${item.category}${item.username != null ? ' • ${item.username}' : ''}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () => _deleteItem(item.id!),
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
}
