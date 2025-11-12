// lib/services/sqlite_service.dart

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;
import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

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
      version: 2, // <-- CHANGED FROM 1 TO 2
      onCreate: _createDB,
      onUpgrade: _onUpgrade, // <-- ADDED THIS LINE
      onConfigure: _onConfigure,
    );
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // _createDB runs ONLY if the database file does not exist.
  Future _createDB(Database db, int version) async {
    // User table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    // Your existing tables
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

  // --- ADDED THIS NEW METHOD ---
  // _onUpgrade runs if the database file EXISTS but the version is LOWER
  // than the one passed to openDatabase (we new-version 2, old-version 1)
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // We are upgrading from version 1 to 2
      // We need to add the 'users' table
      await db.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT UNIQUE NOT NULL,
          password TEXT NOT NULL
        )
      ''');
    }
    // Add other 'if (oldVersion < 3) { ... }' blocks here for future upgrades
  }

  // --- User Methods ---

  String _hashPassword(String password) {
    final bytes = utf8.encode(password); // data being hashed
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<User?> registerUser(String username, String password) async {
    final db = await instance.database;

    // Check if username already exists
    final existing =
        await db.query('users', where: 'username = ?', whereArgs: [username]);

    if (existing.isNotEmpty) {
      return null; // Username already taken
    }

    final hashedPassword = _hashPassword(password);
    final user = User(username: username, password: hashedPassword);

    final id = await db.insert('users', user.toMap());
    return user.copyWith(id: id);
  }

  Future<User?> login(String username, String password) async {
    final db = await instance.database;
    final hashedPassword = _hashPassword(password);

    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, hashedPassword],
    );

    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    } else {
      return null;
    }
  }

  Future<User?> getUserById(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    } else {
      return null;
    }
  }

  // --- Account Methods ---

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

  // --- Transaction Methods ---

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
