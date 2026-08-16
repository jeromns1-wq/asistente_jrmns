import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';
import '../models/budget_item.dart';
import '../models/vault_item.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'asistente_jrmns.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        category TEXT NOT NULL,
        priority TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE budget_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE vault_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        username TEXT,
        secret TEXT NOT NULL,
        note TEXT,
        category TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE vault_config (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertTask(Task task) async {
    final db = await database;
    return await db.insert('tasks', task.toMap());
  }

  Future<List<Task>> getTasksByDate(String date) async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'priority DESC, createdAt DESC',
    );
    return maps.map((m) => Task.fromMap(m)).toList();
  }

  Future<List<Task>> getTasksByCategory(String category) async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      where: 'category = ?',
      orderBy: 'isCompleted ASC, priority DESC, createdAt DESC',
      whereArgs: [category],
    );
    return maps.map((m) => Task.fromMap(m)).toList();
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertBudgetItem(BudgetItem item) async {
    final db = await database;
    return await db.insert('budget_items', item.toMap());
  }

  Future<List<BudgetItem>> getBudgetItems(int month, int year) async {
    final db = await database;
    final maps = await db.query(
      'budget_items',
      where: 'month = ? AND year = ?',
      whereArgs: [month, year],
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => BudgetItem.fromMap(m)).toList();
  }

  Future<int> deleteBudgetItem(int id) async {
    final db = await database;
    return await db.delete('budget_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertVaultItem(VaultItem item) async {
    final db = await database;
    return await db.insert('vault_items', item.toMap());
  }

  Future<List<VaultItem>> getVaultItems({String? category}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (category != null && category != 'Todos') {
      maps = await db.query(
        'vault_items',
        where: 'category = ?',
        whereArgs: [category],
        orderBy: 'name ASC',
      );
    } else {
      maps = await db.query('vault_items', orderBy: 'name ASC');
    }
    return maps.map((m) => VaultItem.fromMap(m)).toList();
  }

  Future<int> deleteVaultItem(int id) async {
    final db = await database;
    return await db.delete('vault_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setVaultPin(String pinHash) async {
    final db = await database;
    await db.insert(
      'vault_config',
      {'key': 'pin_hash', 'value': pinHash},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getVaultPin() async {
    final db = await database;
    final result = await db.query(
      'vault_config',
      where: 'key = ?',
      whereArgs: ['pin_hash'],
    );
    if (result.isNotEmpty) return result.first['value'] as String;
    return null;
  }
}
