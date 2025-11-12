import 'package:flutter/material.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../services/sqlite_service.dart';

class MainViewModel extends ChangeNotifier {
  final SqliteService _dbService = SqliteService.instance;

  int? _userId;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<Account> _accounts = [];
  List<Account> get accounts => _accounts;

  Account? _activeAccount;
  Account? get activeAccount => _activeAccount;

  final Map<String, List<Transaction>> _transactionsMap = {};
  List<Transaction> get transactionsForActiveAccount {
    if (_activeAccount == null) return [];
    return _transactionsMap[_activeAccount!.id] ?? [];
  }

  MainViewModel(this._userId) {
    loadInitialData();
  }

  Future<void> updateUser(int? newUserId) async {
    if (_userId == newUserId) return; // No change

    _userId = newUserId;

    _accounts = [];
    _activeAccount = null;
    _transactionsMap.clear();

    if (_userId == null) {
      _isLoading = false;
      notifyListeners();
    } else {
      await loadInitialData();
    }
  }

  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    if (_userId == null) {
      _accounts = [];
      _activeAccount = null;
      _transactionsMap.clear();
      _isLoading = false;
      notifyListeners();
      return;
    }

    _accounts = await _dbService.getAllAccountsForUser(_userId!);
    if (_accounts.isNotEmpty) {
      _activeAccount = _accounts.first;
      await _loadTransactionsForAccount(_activeAccount!.id);
    } else {
      _activeAccount = null; // Ensure no active account
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadTransactionsForAccount(String accountId) async {
    _transactionsMap[accountId] =
        await _dbService.getTransactionsForAccount(accountId);
  }

  Future<void> changeActiveAccount(Account account) async {
    _activeAccount = account;
    if (!_transactionsMap.containsKey(account.id)) {
      _isLoading = true;
      notifyListeners();
      await _loadTransactionsForAccount(account.id);
      _isLoading = false;
    }
    notifyListeners();
  }

  Future<void> addAccount(Account account) async {
    if (_userId == null) return;

    final accountWithUser = account.copyWith(userId: _userId);

    await _dbService.createAccount(accountWithUser);
    _accounts.add(accountWithUser);
    if (_accounts.length == 1) {
      _activeAccount = accountWithUser;
      await _loadTransactionsForAccount(accountWithUser.id);
    }
    notifyListeners();
  }

  Future<void> updateAccount(Account account) async {
    final accountWithUser = account.copyWith(userId: _userId);

    await _dbService.updateAccount(accountWithUser);
    final index = _accounts.indexWhere((a) => a.id == accountWithUser.id);
    if (index != -1) {
      _accounts[index] = accountWithUser;
    }
    if (_activeAccount?.id == accountWithUser.id) {
      _activeAccount = accountWithUser;
    }
    notifyListeners();
  }

  Future<void> deleteAccounts(Set<Account> accountsToDelete) async {
    final ids = accountsToDelete.map((a) => a.id).toList();
    await _dbService.deleteAccounts(ids);

    _accounts.removeWhere((a) => accountsToDelete.contains(a));

    if (_activeAccount != null && ids.contains(_activeAccount!.id)) {
      _activeAccount = _accounts.isNotEmpty ? _accounts.first : null;
      if (_activeAccount != null) {
        await _loadTransactionsForAccount(_activeAccount!.id);
      }
    }
    notifyListeners();
  }

  Future<void> addTransaction(Transaction transaction) async {
    if (_activeAccount == null) return;

    await _dbService.createTransaction(transaction);

    if (transaction.type == TransactionType.income) {
      _activeAccount!.balance += transaction.amount;
    } else {
      _activeAccount!.balance -= transaction.amount;
    }
    await _dbService.updateAccount(_activeAccount!);

    _transactionsMap[_activeAccount!.id]?.insert(0, transaction);
    notifyListeners();
  }

  Future<void> updateTransaction(
      Transaction oldTransaction, Transaction newTransaction) async {
    if (_activeAccount == null) return;

    await _dbService.updateTransaction(newTransaction);

    if (oldTransaction.type == TransactionType.income) {
      _activeAccount!.balance -= oldTransaction.amount;
    } else {
      _activeAccount!.balance += oldTransaction.amount;
    }
    if (newTransaction.type == TransactionType.income) {
      _activeAccount!.balance += newTransaction.amount;
    } else {
      _activeAccount!.balance -= newTransaction.amount;
    }
    await _dbService.updateAccount(_activeAccount!);

    final txList = _transactionsMap[_activeAccount!.id];
    if (txList != null) {
      final index = txList.indexWhere((t) => t.id == oldTransaction.id);
      if (index != -1) {
        txList[index] = newTransaction;
      }
    }
    notifyListeners();
  }

  Future<void> deleteTransactions(Set<Transaction> transactionsToDelete) async {
    if (_activeAccount == null) return;

    final ids = transactionsToDelete.map((t) => t.id).toList();

    await _dbService.deleteTransactions(ids);

    double balanceChange = 0;
    for (var tx in transactionsToDelete) {
      if (tx.type == TransactionType.income) {
        balanceChange -= tx.amount;
      } else {
        balanceChange += tx.amount;
      }
    }
    _activeAccount!.balance += balanceChange;
    await _dbService.updateAccount(_activeAccount!);

    _transactionsMap[_activeAccount!.id]
        ?.removeWhere((t) => transactionsToDelete.contains(t));
    notifyListeners();
  }
}
