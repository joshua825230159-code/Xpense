import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;
import '../models/account_model.dart';
import '../models/transaction_model.dart';

class SqliteService {
  static final SqliteService instance = SqliteService._init();
  SqliteService._init();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('xpense.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: _onConfigure,
    );
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        balance REAL NOT NULL,
        colorValue INTEGER NOT NULL,
        type TEXT NOT NULL,
        budget REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        accountId TEXT NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        iconValue INTEGER NOT NULL,
        category TEXT,
        FOREIGN KEY (accountId) REFERENCES accounts (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> createAccount(Account account) async {
    final db = await instance.database;
    await db.insert('accounts', account.toMap());
  }

  Future<Account?> getAccount(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Account.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<List<Account>> getAllAccounts() async {
    final db = await instance.database;
    final result = await db.query('accounts', orderBy: 'name ASC');
    return result.map((json) => Account.fromMap(json)).toList();
  }

  Future<int> updateAccount(Account account) async {
    final db = await instance.database;
    return db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> deleteAccount(String id) async {
    final db = await instance.database;
    return db.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAccounts(List<String> ids) async {
    final db = await instance.database;
    final batch = db.batch();
    for (final id in ids) {
      batch.delete('accounts', where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }

  Future<void> createTransaction(Transaction transaction) async {
    final db = await instance.database;
    await db.insert('transactions', transaction.toMap());
  }

  Future<List<Transaction>> getTransactionsForAccount(String accountId) async {
    final db = await instance.database;
    final result = await db.query(
      'transactions',
      where: 'accountId = ?',
      whereArgs: [accountId],
      orderBy: 'date DESC',
    );
    return result.map((json) => Transaction.fromMap(json)).toList();
  }

  Future<int> updateTransaction(Transaction transaction) async {
    final db = await instance.database;
    return db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(String id) async {
    final db = await instance.database;
    return db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteTransactions(List<String> ids) async {
    final db = await instance.database;
    final batch = db.batch();
    for (final id in ids) {
      batch.delete('transactions', where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }
}