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
      version: 4,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _createDB(Database db, int version) async {
    // User table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        isPremium INTEGER NOT NULL DEFAULT 0 
      )
    ''');

    // Accounts table
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        balance REAL NOT NULL,
        colorValue INTEGER NOT NULL,
        type TEXT NOT NULL,
        budget REAL,
        userId INTEGER,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Transactions table
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

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT UNIQUE NOT NULL,
          password TEXT NOT NULL,
          isPremium INTEGER NOT NULL DEFAULT 0 
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        ALTER TABLE accounts ADD COLUMN userId INTEGER 
        REFERENCES users(id) ON DELETE CASCADE
      ''');
    }
    if (oldVersion < 4) {
      // Add isPremium column to existing users table
      await db.execute('''
        ALTER TABLE users ADD COLUMN isPremium INTEGER NOT NULL DEFAULT 0
      ''');
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<User?> registerUser(String username, String password) async {
    final db = await instance.database;
    final existing =
        await db.query('users', where: 'username = ?', whereArgs: [username]);
    if (existing.isNotEmpty) {
      return null;
    }
    // New users are not premium by default (isPremium defaults to 0)
    final hashedPassword = _hashPassword(password);
    final user = User(
      username: username,
      password: hashedPassword,
      isPremium: false,
    );
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

  Future<void> updateUserPremiumStatus(int userId, bool isPremium) async {
    final db = await instance.database;
    await db.update(
      'users',
      {'isPremium': isPremium ? 1 : 0},
      where: 'id = ?',
      whereArgs: [userId],
    );
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

  Future<List<Account>> getAllAccountsForUser(int userId) async {
    final db = await instance.database;
    final result = await db.query(
      'accounts',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );
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
