import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xpense/services/api_service.dart';
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
import '../services/currency_formatter_service.dart';
import '../widgets/currency_converter_dialog.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex = 0;
  String _selectedPeriod = 'Monthly';
  TransactionType _selectedTransactionType = TransactionType.expense;

  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  bool _isSelectionMode = false;
  final Set<Transaction> _selectedTransactions = {};

  final ExportService _exportService = ExportService();

  bool _isAutoUpdateEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _searchController.addListener(() {
      if (_searchController.text.isEmpty && _searchQuery.isNotEmpty) {
        _updateSearchQuery('');
      }
    });
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAutoUpdateEnabled = prefs.getBool(ApiService.kAutoUpdateKey) ?? true;
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

  void _showSortBottomSheet() {
    final periods = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                child: Text(
                  'Select Period',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              ...periods.map((period) {
                final bool isSelected = (_selectedPeriod == period);
                return ListTile(
                  title: Text(
                    period,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.orange : theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.orange)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedPeriod = period;
                    });
                    Navigator.pop(context);

                    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: Colors.white),
                            const SizedBox(width: 10),
                            Text(
                              'Period changed to $period',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: isDarkMode ? theme.cardColor : Colors.black87,
                        duration: const Duration(milliseconds: 1500),
                      ),
                    );
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  selected: isSelected,
                  selectedTileColor: Colors.orange.withOpacity(0.1),
                );
              }).toList(),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showCurrencyConverter() {
    Navigator.of(context).pop();

    final viewModel = context.read<MainViewModel>();
    final double currentBalance = viewModel.activeAccount?.balance ?? 0.0;
    final String baseCurrency = viewModel.activeAccount?.currencyCode ?? 'IDR';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Theme.of(context).cardColor,
      builder: (context) {
        return CurrencyConverterSheet(
          accountBalance: currentBalance,
          baseCurrency: baseCurrency,
        );
      },
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
    final viewModel = context.read<MainViewModel>();
    final List<int> usedColors = viewModel.accounts.map((a) => a.colorValue).toList();

    final newAccount = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AddAccountScreen(
            usedColorValues: usedColors,
          )
      ),
    );

    if (newAccount != null && newAccount is Account) {
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

    final activeAccount = context.read<MainViewModel>().activeAccount;
    if (activeAccount == null) return;

    final updatedTransaction = await Navigator.push<Transaction>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TransactionDetailScreen(
              transaction: transaction,
              currencyCode: activeAccount.currencyCode,
            ),
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
          accountCurrencyCode: activeAccount.currencyCode,
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
                _showSortBottomSheet();
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
    final viewModel = context.watch<MainViewModel>();

    final String username = authViewModel.user?.username ?? "Xpense User";
    final String userInitial = (username.isNotEmpty) ? username[0].toUpperCase() : "X";

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [

          DrawerHeader(
            padding: EdgeInsets.zero,
            decoration: const BoxDecoration(
              color: Colors.orange,
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: 16.0,
                  left: 16.0,
                  right: 16.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white,
                            child: Text(
                              userInitial,
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Consumer<MainViewModel>(
                        builder: (context, vm, child) {
                          Widget balanceWidget;

                          if (vm.isCalculatingTotal) {
                            balanceWidget = const Text(
                              'Calculating total...',
                              key: ValueKey(1),
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                            );
                          } else if (vm.totalBalanceInBaseCurrency != null) {
                            final formattedTotal = CurrencyFormatterService.format(
                                vm.totalBalanceInBaseCurrency!, 'IDR');
                            balanceWidget = Text(
                              'Total: $formattedTotal',
                              key: ValueKey(2),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            );
                          } else if (vm.calculationError.isNotEmpty) {
                            balanceWidget = const Text(
                              'Error loading balance',
                              key: ValueKey(3),
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                            );
                          } else {
                            balanceWidget = Text(
                                authViewModel.user?.isPremium ?? false
                                    ? "Premium Member"
                                    : "Track your expenses",
                                key: ValueKey(4),
                                style: const TextStyle(color: Colors.white70, fontSize: 16)
                            );
                          }

                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: balanceWidget,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
            subtitle: Text(
                CurrencyFormatterService.format(
                    account.balance,
                    account.currencyCode
                )
            ),
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
          SwitchListTile(
            title: const Text('Auto-update Exchange Rates'),
            subtitle: Text(_isAutoUpdateEnabled ? 'Enabled (Every 24h)' : 'Disabled'),
            value: _isAutoUpdateEnabled,
            onChanged: (value) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool(ApiService.kAutoUpdateKey, value);
              setState(() {
                _isAutoUpdateEnabled = value;
              });
            },
            secondary: Icon(
              _isAutoUpdateEnabled
                  ? Icons.sync
                  : Icons.sync_disabled,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: const Text('Live Exchange Rates'),
            onTap: _showCurrencyConverter,
          ),
          const Divider(),
          _buildDrawerSectionTitle("Membership"),
          Consumer<AuthViewModel>(
              builder: (context, authViewModel, child) {
                final isPremium = authViewModel.user?.isPremium ?? false;
                if (isPremium) {
                  return const ListTile(
                    leading: Icon(Icons.star, color: Colors.orange),
                    title: Text('Premium Member'),
                    subtitle: Text('You have access to all features!'),
                  );
                } else {
                  return ListTile(
                    leading: const Icon(Icons.star_border),
                    title: const Text('Become Premium'),
                    subtitle: const Text('Unlock data export and more!'),
                    onTap: () async {
                      await authViewModel.becomePremium();
                      Navigator.of(context).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.star, color: Colors.white),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Congratulations, you are now a Premium Member!',
                                  style: TextStyle(fontSize: 14),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.green.shade600,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                  );
                }
              }
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