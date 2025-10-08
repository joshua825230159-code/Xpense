import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';
import 'add_account_screen.dart';
import 'expense_list_screen.dart';
import 'manage_accounts_screen.dart';
import 'stats_screen.dart';
import 'transaction_detail_screen.dart';
import '../services/export_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Account> _accounts = [];
  Account? _activeAccount;
  Map<Account, List<Transaction>> _accountTransactions = {};

  final currencyFormatter =
  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  int _selectedIndex = 0;
  String _selectedPeriod = 'Monthly';
  TransactionType _selectedTransactionType = TransactionType.expense;

  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  bool _isSelectionMode = false;
  final Set<Transaction> _selectedTransactions = {};

  final ExportService _exportService = ExportService();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_searchController.text.isEmpty && _searchQuery.isNotEmpty) {
        _updateSearchQuery('');
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_accounts.isEmpty) {
        _navigateToAddAccount();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleTransactionType() {
    setState(() {
      _selectedTransactionType =
      _selectedTransactionType == TransactionType.expense
          ? TransactionType.income
          : TransactionType.expense;
    });
  }

  void _showSortDialog() {
    final periods = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Select Period'),
          children: periods.map((period) {
            return SimpleDialogOption(
              onPressed: () {
                setState(() {
                  _selectedPeriod = period;
                });
                Navigator.pop(context);
              },
              child: Text(period),
            );
          }).toList(),
        );
      },
    );
  }

  void _showExportDialog() {
    final List<Transaction> allTransactions =
    _activeAccount != null ? _accountTransactions[_activeAccount!] ?? [] : [];

    final now = DateTime.now();
    List<Transaction> periodTransactions;

    switch (_selectedPeriod) {
      case 'Daily':
        periodTransactions = allTransactions.where((t) {
          return t.date.year == now.year &&
              t.date.month == now.month &&
              t.date.day == now.day;
        }).toList();
        break;
      case 'Weekly':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final firstDayOfWeek =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        periodTransactions = allTransactions.where((t) {
          return t.date
              .isAfter(firstDayOfWeek.subtract(const Duration(seconds: 1)));
        }).toList();
        break;
      case 'Yearly':
        periodTransactions = allTransactions.where((t) {
          return t.date.year == now.year;
        }).toList();
        break;
      case 'Monthly':
      default:
        periodTransactions = allTransactions.where((t) {
          return t.date.year == now.year && t.date.month == now.month;
        }).toList();
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Expenses'),
        content: const Text(
            'Choose the format to export your expenses for the selected period.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportService.exportToCsv(periodTransactions, _selectedPeriod);
            },
            child: const Text('CSV'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportService.exportToPdf(periodTransactions, _selectedPeriod);
            },
            child: const Text('PDF'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddAccount() async {
    final newAccount = await Navigator.push<Account>(
      context,
      MaterialPageRoute(builder: (context) => const AddAccountScreen()),
    );

    if (newAccount != null) {
      setState(() {
        _accounts.add(newAccount);
        _activeAccount = newAccount;
        _accountTransactions.putIfAbsent(newAccount, () => []);
      });
    }
  }

  void _navigateToManageAccounts() async {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
    final updatedAccounts = await Navigator.push<List<Account>>(
      context,
      MaterialPageRoute(
        builder: (context) => ManageAccountsScreen(accounts: _accounts),
      ),
    );

    if (updatedAccounts != null) {
      setState(() {
        final newTransactionMap = <Account, List<Transaction>>{};
        for (final newAccount in updatedAccounts) {
          final existingTransactions = _accountTransactions[newAccount];
          newTransactionMap[newAccount] = existingTransactions ?? [];
        }

        Account? newActiveAccount;
        if (_activeAccount != null) {
          for (final account in updatedAccounts) {
            if (account.id == _activeAccount!.id) {
              newActiveAccount = account;
              break;
            }
          }
        }

        if (newActiveAccount == null && updatedAccounts.isNotEmpty) {
          newActiveAccount = updatedAccounts.first;
        }

        _accounts = updatedAccounts;
        _accountTransactions = newTransactionMap;
        _activeAccount = newActiveAccount;
      });
    }
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _updateSearchQuery(String newQuery) {
    setState(() {
      _searchQuery = newQuery;
    });
  }

  void _onSelectionChanged(Set<Transaction> selected) {
    setState(() {
      _selectedTransactions.clear();
      _selectedTransactions.addAll(selected);
      _isSelectionMode = _selectedTransactions.isNotEmpty;
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectedTransactions.clear();
      _isSelectionMode = false;
    });
  }

  void _handleDeleteTransactions() async {
    final bool? confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text(
            'Anda yakin ingin menghapus ${_selectedTransactions.length} transaksi? Aksi ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        if (_activeAccount == null) return;

        for (var transaction in _selectedTransactions) {
          if (transaction.type == TransactionType.income) {
            _activeAccount!.balance -= transaction.amount;
          } else {
            _activeAccount!.balance += transaction.amount;
          }
        }
        _accountTransactions[_activeAccount!]?.removeWhere(
              (t) => _selectedTransactions.contains(t),
        );
        _exitSelectionMode();
      });
    }
  }

  void _navigateToTransactionDetail(Transaction transaction) async {
    if (_isSelectionMode) return;

    final Transaction originalTransaction = transaction;
    final List<Transaction>? transactionList =
    _accountTransactions[_activeAccount!];

    if (transactionList == null) return;

    final updatedTransaction = await Navigator.push<Transaction>(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionDetailScreen(transaction: transaction),
      ),
    );

    if (updatedTransaction != null) {
      setState(() {
        final index = transactionList.indexOf(originalTransaction);
        if (index != -1) {
          if (originalTransaction.type == TransactionType.income) {
            _activeAccount!.balance -= originalTransaction.amount;
          } else {
            _activeAccount!.balance += originalTransaction.amount;
          }

          if (updatedTransaction.type == TransactionType.income) {
            _activeAccount!.balance += updatedTransaction.amount;
          } else {
            _activeAccount!.balance -= updatedTransaction.amount;
          }

          transactionList[index] = updatedTransaction;
        }
      });
    }
  }

  void _changeActiveAccount(Account account) {
    setState(() {
      _activeAccount = account;
      if (_isSearching) _stopSearch();
      if (_isSelectionMode) _exitSelectionMode();
    });
    Navigator.pop(context);
  }

  void _addTransaction(Transaction transaction) {
    setState(() {
      if (_activeAccount != null) {
        _accountTransactions.putIfAbsent(_activeAccount!, () => []);
        _accountTransactions[_activeAccount!]?.insert(0, transaction);
        if (transaction.type == TransactionType.income) {
          _activeAccount!.balance += transaction.amount;
        } else {
          _activeAccount!.balance -= transaction.amount;
        }
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Transaction> allTransactions =
    _activeAccount != null ? _accountTransactions[_activeAccount!] ?? [] : [];

    final filteredTransactions = allTransactions.where((transaction) {
      return transaction.description
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
    }).toList();

    final List<Widget> pages = [
      ExpenseListScreen(
        activeAccount: _activeAccount,
        transactions: filteredTransactions,
        isSearching: _isSearching,
        searchQuery: _searchQuery,
        selectedTransactions: _selectedTransactions,
        onSelectionChanged: _onSelectionChanged,
        onDeleteTransactions: (Set<Transaction> toDelete) {},
        onTransactionTap: _navigateToTransactionDetail,
      ),
      if (_activeAccount != null)
        StatsScreen(
          account: _activeAccount!,
          transactions: List.from(allTransactions),
          selectedPeriod: _selectedPeriod,
          selectedType: _selectedTransactionType,
        ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      appBar: _isSelectionMode
          ? _buildSelectionAppBar()
          : (_isSearching ? _buildSearchAppBar() : _buildDefaultAppBar()),
      drawer: _buildDrawer(),
      body: _accounts.isEmpty
          ? _buildEmptyState()
          : IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      floatingActionButton:
      (_accounts.isEmpty || _isSearching || _isSelectionMode)
          ? null
          : FloatingActionButton(
        onPressed: () => _showAddTransactionSheet(context),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
        shape: const CircleBorder(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _accounts.isEmpty
          ? null
          : BottomAppBar(
        color: Colors.white,
        height: 60.0,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildBottomNavItem(
                icon: Icons.home,
                isSelected: _selectedIndex == 0,
                onTap: () => _onItemTapped(0)),
            const SizedBox(width: 40),
            _buildBottomNavItem(
                icon: Icons.bar_chart,
                isSelected: _selectedIndex == 1,
                onTap: () => _onItemTapped(1)),
          ],
        ),
      ),
    );
  }

  AppBar _buildSelectionAppBar() {
    return AppBar(
      title: Text('${_selectedTransactions.length} dipilih'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _exitSelectionMode,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: _handleDeleteTransactions,
        ),
      ],
    );
  }

  AppBar _buildDefaultAppBar() {
    final String toggleTypeTitle =
    _selectedTransactionType == TransactionType.expense
        ? 'View Income'
        : 'View Expense';

    final IconData toggleTypeIcon =
    _selectedTransactionType == TransactionType.expense
        ? Icons.show_chart
        : Icons.score;

    return AppBar(
      backgroundColor: const Color(0xFFF6F7F9),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, size: 30, color: Colors.black),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: Text(
        _selectedIndex == 0
            ? (_activeAccount?.name ?? "No Account")
            : "Statistics",
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
      ),
      centerTitle: true,
      actions: [
        if (_selectedIndex == 0)
          IconButton(
            icon: const Icon(Icons.search, size: 28, color: Colors.black),
            onPressed: _startSearch,
          ),

        if (_selectedIndex == 1)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) {
              if (value == 'toggle_type') {
                _toggleTransactionType();
              } else if (value == 'sort') {
                _showSortDialog();
              } else if (value == 'export') {
                _showExportDialog();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'toggle_type',
                child: Row(
                  children: [
                    Icon(toggleTypeIcon, color: Colors.black54),
                    const SizedBox(width: 12),
                    Text(toggleTypeTitle),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'sort',
                child: Row(
                  children: [
                    Icon(Icons.sort, color: Colors.black54),
                    SizedBox(width: 12),
                    Text('Sort by Period'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.share_outlined, color: Colors.black54),
                    SizedBox(width: 12),
                    Text('Export Data'),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  AppBar _buildSearchAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: _stopSearch,
      ),
      title: TextField(
        controller: _searchController,
        onChanged: _updateSearchQuery,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Search transactions...',
          border: InputBorder.none,
        ),
      ),
      actions: [
        if (_searchQuery.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () {
              _searchController.clear();
            },
          )
      ],
    );
  }

  Widget _buildBottomNavItem(
      {required IconData icon,
        required bool isSelected,
        required VoidCallback onTap}) {
    return SizedBox(
      width: 48,
      height: 48,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Icon(
          icon,
          color: isSelected ? Colors.orange : Colors.grey,
          size: 30,
        ),
      ),
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const UserAccountsDrawerHeader(
            accountName: Text("Xpense"),
            accountEmail: Text("Track your expenses"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child:
              Icon(Icons.monetization_on, color: Colors.orange, size: 40),
            ),
            decoration: BoxDecoration(color: Colors.orange),
          ),
          _buildDrawerSectionTitle("Manage accounts"),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Manage Accounts'),
            onTap: _navigateToManageAccounts,
          ),
          const Divider(),
          _buildDrawerSectionTitle("Accounts"),
          ..._accounts.map((account) => ListTile(
            leading: CircleAvatar(
              backgroundColor: account.color,
              radius: 16,
            ),
            title: Text(account.name),
            subtitle: Text(currencyFormatter.format(account.balance)),
            selected: account == _activeAccount,
            selectedTileColor: Colors.orange.withOpacity(0.1),
            onTap: () => _changeActiveAccount(account),
          )),
        ],
      ),
    );
  }

  Widget _buildDrawerSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            const Text(
              'No Accounts Found',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Please add an account from the side menu to start tracking your finances.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Your First Account',
                  style: TextStyle(color: Colors.white)),
              onPressed: _navigateToAddAccount,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  )),
            )
          ],
        ),
      ),
    );
  }

  void _showAddTransactionSheet(BuildContext context) {
  }
}