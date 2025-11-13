import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../services/sqlite_service.dart';
import '../services/api_service.dart';

class MainViewModel extends ChangeNotifier {
  final SqliteService _dbService = SqliteService.instance;
  final ApiService _apiService = ApiService();

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

  double? _totalBalanceInBaseCurrency;
  double? get totalBalanceInBaseCurrency => _totalBalanceInBaseCurrency;

  bool _isCalculatingTotal = false;
  bool get isCalculatingTotal => _isCalculatingTotal;

  String _calculationError = '';
  String get calculationError => _calculationError;

  Map<String, double> allConversionRates = {};

  static const String _kLastActiveAccountKey = 'lastActiveAccountId';

  MainViewModel(this._userId) {
    loadInitialData();
  }

  Future<void> updateUser(int? newUserId) async {
    if (_userId == newUserId) return;

    _userId = newUserId;

    _accounts = [];
    _activeAccount = null;
    _transactionsMap.clear();
    _totalBalanceInBaseCurrency = null;
    _isCalculatingTotal = false;
    _calculationError = '';
    allConversionRates = {};

    if (_userId == null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kLastActiveAccountKey);
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

    final prefs = await SharedPreferences.getInstance();
    final String? savedAccountId = prefs.getString(_kLastActiveAccountKey);

    _accounts = await _dbService.getAllAccountsForUser(_userId!);

    if (_accounts.isNotEmpty) {
      Account? accountToLoad;
      if (savedAccountId != null) {
        accountToLoad = _accounts.firstWhere(
              (acc) => acc.id == savedAccountId,
          orElse: () => _accounts.first,
        );
      } else {
        accountToLoad = _accounts.first;
      }
      _activeAccount = accountToLoad;
      await _loadTransactionsForAccount(_activeAccount!.id);
    } else {
      _activeAccount = null;
    }

    _isLoading = false;
    notifyListeners();

    if (_accounts.isNotEmpty) {
      calculateTotalBalance('IDR');
    }
  }

  Future<void> _loadTransactionsForAccount(String accountId) async {
    _transactionsMap[accountId] =
    await _dbService.getTransactionsForAccount(accountId);
  }

  Future<void> calculateTotalBalance(String baseCurrency) async {
    if (_accounts.isEmpty) return;

    _isCalculatingTotal = true;
    _totalBalanceInBaseCurrency = null;
    _calculationError = '';
    notifyListeners();

    try {
      final rates = await _apiService.getAllRates(baseCurrency);

      allConversionRates = rates;

      double total = 0.0;

      for (final account in _accounts) {
        if (account.currencyCode == baseCurrency) {
          total += account.balance;
        } else {
          final rate = rates[account.currencyCode];
          if (rate != null) {
            total += account.balance / rate;
          } else {
            _calculationError = 'No rate for ${account.currencyCode}';
            print('Warning: No rate found for ${account.currencyCode}');
          }
        }
      }

      _totalBalanceInBaseCurrency = total;

    } catch (e) {
      _calculationError = 'Failed to fetch rates';
      print('Error calculating total balance: $e');
    }

    _isCalculatingTotal = false;
    notifyListeners();
  }

  Future<void> changeActiveAccount(Account account) async {
    _activeAccount = account;
    if (!_transactionsMap.containsKey(account.id)) {
      _isLoading = true;
      notifyListeners();
      await _loadTransactionsForAccount(account.id);
      _isLoading = false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastActiveAccountKey, account.id);

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
    calculateTotalBalance('IDR');
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
    calculateTotalBalance('IDR');
  }

  Future<void> convertAndUpdateAccount(Account updatedAccount, String oldCurrency) async {
    final newCurrency = updatedAccount.currencyCode;

    if (oldCurrency == newCurrency) {
      return updateAccount(updatedAccount);
    }

    _isLoading = true;
    notifyListeners();

    try {
      final rates = await _apiService.getRatesForBaseCurrency(oldCurrency, [newCurrency]);
      final rate = rates[newCurrency];

      if (rate == null) {
        throw Exception('Could not find rate for $newCurrency');
      }

      List<Transaction> transactionsToUpdate =
      await _dbService.getTransactionsForAccount(updatedAccount.id);

      for (final tx in transactionsToUpdate) {
        tx.amount = tx.amount * rate;
      }

      await _dbService.batchUpdateTransactions(transactionsToUpdate);
      _transactionsMap[updatedAccount.id] = transactionsToUpdate;

      await updateAccount(updatedAccount);

    } catch (e) {
      print('Error during account conversion: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAccounts(Set<Account> accountsToDelete) async {
    final ids = accountsToDelete.map((a) => a.id).toList();
    await _dbService.deleteAccounts(ids);

    _accounts.removeWhere((a) => accountsToDelete.contains(a));
    _transactionsMap.removeWhere((key, value) => ids.contains(key));

    if (_activeAccount != null && ids.contains(_activeAccount!.id)) {
      _activeAccount = _accounts.isNotEmpty ? _accounts.first : null;
      if (_activeAccount != null && !_transactionsMap.containsKey(_activeAccount!.id)) {
        await _loadTransactionsForAccount(_activeAccount!.id);
      }
    }
    notifyListeners();
    calculateTotalBalance('IDR');
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
    calculateTotalBalance('IDR');
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
    calculateTotalBalance('IDR');
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
    calculateTotalBalance('IDR');
  }
}