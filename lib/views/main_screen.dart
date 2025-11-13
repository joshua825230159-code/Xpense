import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:xpense/viewmodels/main_viewmodel.dart';
import 'package:xpense/viewmodels/auth_viewmodel.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../providers/theme_provider.dart';
import '../widgets/add_transaction_sheet.dart';
import 'add_account_screen.dart';
import 'expense_list_screen.dart';
import 'manage_accounts_screen.dart';
import 'stats_screen.dart';
import 'transaction_detail_screen.dart';
import '../services/export_service.dart';
import '../services/api_service.dart';
import '../widgets/currency_converter_dialog.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_searchController.text.isEmpty && _searchQuery.isNotEmpty) {
        _updateSearchQuery('');
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

  // void _showExchangeRatesDialog() async {
  //   Navigator.of(context).pop();
  //
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (context) => const Dialog(
  //       child: Padding(
  //         padding: EdgeInsets.all(20.0),
  //         child: Row(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             CircularProgressIndicator(),
  //             SizedBox(width: 20),
  //             Text('Fetching rates...'),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  //
  //   try {
  //     final rates = await _apiService.getExchangeRates();
  //
  //     Navigator.of(context).pop();
  //
  //     final List<Widget> rateWidgets = rates.entries.map((entry) {
  //       String formattedRate = NumberFormat.currency(
  //         locale: 'id_ID',
  //         symbol: 'IDR ',
  //         decimalDigits: 2,
  //       ).format(entry.value);
  //
  //       return Padding(
  //         padding: const EdgeInsets.symmetric(vertical: 8.0),
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Text(
  //               '1 ${entry.key}',
  //               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //             ),
  //             Text(
  //               formattedRate,
  //               style: const TextStyle(fontSize: 16),
  //             ),
  //           ],
  //         ),
  //       );
  //     }).toList();
  //
  //     showDialog(
  //       context: context,
  //       builder: (context) => AlertDialog(
  //         title: const Text('Live Exchange Rates'),
  //         content: SingleChildScrollView(
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               const Text('Rates against Indonesian Rupiah (IDR):'),
  //               const Divider(height: 20),
  //               ...rateWidgets,
  //             ],
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.of(context).pop(),
  //             child: const Text('Close'),
  //           ),
  //         ],
  //       ),
  //     );
  //   } catch (e) {
  //     Navigator.of(context).pop();
  //
  //     showDialog(
  //       context: context,
  //       builder: (context) => AlertDialog(
  //         title: const Text('Error'),
  //         content: Text('Could not fetch exchange rates.\nPlease check your internet connection.\n\n${e.toString()}'),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.of(context).pop(),
  //             child: const Text('Close'),
  //           ),
  //         ],
  //       ),
  //     );
  //   }
  // }

  void _showCurrencyConverter() {
    Navigator.of(context).pop();

    final viewModel = context.read<MainViewModel>();
    final double currentBalance = viewModel.activeAccount?.balance ?? 0.0;

    const String baseCurrency = 'IDR';

    showDialog(
      context: context,
      builder: (context) => CurrencyConverterDialog(
        accountBalance: currentBalance,
        baseCurrency: baseCurrency,
      ),
    );
  }

  void _showExportDialog() {
    final auth = context.read<AuthViewModel>();
    if (!(auth.user?.isPremium ?? false)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Premium Feature'),
          content: const Text('Exporting data is a premium feature. Please upgrade your account to use it.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _scaffoldKey.currentState?.openDrawer(); 
              },
              child: const Text('Upgrade'),
            ),
          ],
        ),
      );
      return;
    }

    final viewModel = context.read<MainViewModel>();
    final List<Transaction> allTransactions =
        viewModel.transactionsForActiveAccount;

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
      context.read<MainViewModel>().addAccount(newAccount);
    }
  }

  void _navigateToManageAccounts() async {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
    await Navigator.push<List<Account>>(
      context,
      MaterialPageRoute(
        builder: (context) => const ManageAccountsScreen(),
      ),
    );
  }

  void _startSearch() {
    setState(() => _isSearching = true);
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _updateSearchQuery(String newQuery) {
    setState(() => _searchQuery = newQuery);
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
        title: const Text('Confirm Deletion'),
        content: Text(
            'Are you sure you want to delete ${_selectedTransactions.length} transactions? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      context
          .read<MainViewModel>()
          .deleteTransactions(_selectedTransactions);
      _exitSelectionMode();
    }
  }

  void _navigateToTransactionDetail(Transaction transaction) async {
    if (_isSelectionMode) return;

    final updatedTransaction = await Navigator.push<Transaction>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TransactionDetailScreen(transaction: transaction),
      ),
    );

    if (updatedTransaction != null) {
      context
          .read<MainViewModel>()
          .updateTransaction(transaction, updatedTransaction);
    }
  }

  void _changeActiveAccount(Account account) {
    context.read<MainViewModel>().changeActiveAccount(account);

    if (_isSearching) _stopSearch();
    if (_isSelectionMode) _exitSelectionMode();
    Navigator.pop(context);
  }

  void _addTransaction(Transaction transaction) {
    context.read<MainViewModel>().addTransaction(transaction);
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _showAddTransactionSheet(BuildContext context) {
    final activeAccount = context.read<MainViewModel>().activeAccount;
    if (activeAccount == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return AddTransactionSheet(
          accountId: activeAccount.id,
          onAddTransaction: (transaction) {
            _addTransaction(transaction);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MainViewModel>();
    final allTransactions = viewModel.transactionsForActiveAccount;
    final activeAccount = viewModel.activeAccount;
    final accounts = viewModel.accounts;

    if (viewModel.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final filteredTransactions = allTransactions.where((transaction) {
      return transaction.description
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
    }).toList();

    final List<Widget> pages = [
      ExpenseListScreen(
        activeAccount: activeAccount,
        transactions: filteredTransactions,
        isSearching: _isSearching,
        searchQuery: _searchQuery,
        selectedTransactions: _selectedTransactions,
        onSelectionChanged: _onSelectionChanged,
        onDeleteTransactions: (Set<Transaction> toDelete) {},
        onTransactionTap: _navigateToTransactionDetail,
      ),
      if (activeAccount != null)
        StatsScreen(
          account: activeAccount,
          transactions: List.from(allTransactions),
          selectedPeriod: _selectedPeriod,
          selectedType: _selectedTransactionType,
        ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      appBar: _isSelectionMode
          ? _buildSelectionAppBar()
          : (_isSearching
              ? _buildSearchAppBar()
              : _buildDefaultAppBar(activeAccount)),
      drawer: _buildDrawer(accounts, activeAccount),
      body: accounts.isEmpty
          ? _buildEmptyState()
          : IndexedStack(
              index: _selectedIndex,
              children: pages,
            ),
      floatingActionButton:
          (accounts.isEmpty || _isSearching || _isSelectionMode)
              ? null
              : FloatingActionButton(
                  onPressed: () => _showAddTransactionSheet(context),
                  backgroundColor: Colors.orange,
                  child:
                      const Icon(Icons.add, color: Colors.white, size: 30),
                  shape: const CircleBorder(),
                ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: accounts.isEmpty
          ? null
          : BottomAppBar(
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
      title: Text('${_selectedTransactions.length} chosen'),
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

  AppBar _buildDefaultAppBar(Account? activeAccount) {
    final String toggleTypeTitle =
        _selectedTransactionType == TransactionType.expense
            ? 'View Income'
            : 'View Expense';

    final IconData toggleTypeIcon =
        _selectedTransactionType == TransactionType.expense
            ? Icons.show_chart
            : Icons.score;

    final iconColor = Theme.of(context).appBarTheme.iconTheme?.color;
    
    final auth = context.watch<AuthViewModel>();
    final isPremium = auth.user?.isPremium ?? false;

    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.menu, size: 30, color: iconColor),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: Text(
        _selectedIndex == 0
            ? (activeAccount?.name ?? "No Account")
            : "Statistics",
      ),
      centerTitle: true,
      actions: [
        if (_selectedIndex == 0)
          IconButton(
            icon: Icon(Icons.search, size: 28, color: iconColor),
            onPressed: _startSearch,
          ),
        if (_selectedIndex == 1)
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: iconColor),
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
                    Icon(toggleTypeIcon),
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
                    Icon(Icons.sort),
                    SizedBox(width: 12),
                    Text('Sort by Period'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'export',
                enabled: isPremium,
                child: Row(
                  children: [
                    Icon(isPremium ? Icons.share_outlined : Icons.lock_outline),
                    const SizedBox(width: 12),
                    Text(isPremium ? 'Export Data' : 'Export (Premium)'),
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
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
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
            icon: const Icon(Icons.close),
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

  Drawer _buildDrawer(List<Account> accounts, Account? activeAccount) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    
    final authViewModel = context.watch<AuthViewModel>();
    final isPremium = authViewModel.user?.isPremium ?? false;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(authViewModel.user?.username ?? "Xpense"),
            accountEmail:
                Text(isPremium ? "Premium Member" : "Track your expenses"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                isPremium ? Icons.star : Icons.monetization_on,
                color: Colors.orange,
                size: 40,
              ),
            ),
            decoration: const BoxDecoration(color: Colors.orange),
          ),
          _buildDrawerSectionTitle("Manage accounts"),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Manage Accounts'),
            onTap: _navigateToManageAccounts,
          ),
          const Divider(),
          _buildDrawerSectionTitle("Accounts"),
          ...accounts.map((account) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: account.color,
                  radius: 16,
                ),
                title: Text(account.name),
                subtitle: Text(currencyFormatter.format(account.balance)),
                selected: account == activeAccount,
                selectedTileColor: Colors.orange.withOpacity(0.1),
                onTap: () => _changeActiveAccount(account),
              )),
          const Divider(),
          _buildDrawerSectionTitle("Settings & Tools"),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme(value);
            },
            secondary: Icon(
              isDarkMode
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
            ),
          ),

          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: const Text('Live Exchange Rates'),
            onTap: _showCurrencyConverter,
          ),
          
          const Divider(),
          _buildDrawerSectionTitle("Membership"),

          if (isPremium)
            const ListTile(
              leading: Icon(Icons.star, color: Colors.orange),
              title: Text('Premium Member'),
              subtitle: Text('You have access to all features!'),
            )
          else
            ListTile(
              leading: const Icon(Icons.star_border),
              title: const Text('Become Premium'),
              subtitle: const Text('Unlock data export and more!'),
              onTap: () async {
                await context.read<AuthViewModel>().becomePremium();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Congratulations, you are now a Premium Member!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.of(context).pop();
              context.read<AuthViewModel>().logout();
            },
          ),
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
}
