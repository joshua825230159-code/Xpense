import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';
import 'manage_accounts_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  final List<IconData> _categoryIcons = [
    Icons.shopping_cart, Icons.fastfood, Icons.airplanemode_active,
    Icons.receipt, Icons.movie, Icons.health_and_safety,
    Icons.school, Icons.pets, Icons.home,
    Icons.train, Icons.phone_android, Icons.local_gas_station,
  ];

  List<Account> _accounts = [];

  Account? _activeAccount;

  final Map<Account, List<Transaction>> _accountTransactions = {};

  final currencyFormatter =
  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    for (var account in _accounts) {
      _accountTransactions[account] = [];
    }
    if (_accounts.isNotEmpty) {
      _activeAccount = _accounts[0];
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _changeActiveAccount(Account account) {
    setState(() {
      _activeAccount = account;
    });
    Navigator.pop(context);
  }

  void _navigateToManageAccounts() async {
    // Safely close the drawer only if it's open
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
        _accounts = updatedAccounts;
        for (var account in _accounts) {
          _accountTransactions.putIfAbsent(account, () => []);
        }
        if (!_accounts.contains(_activeAccount) && _accounts.isNotEmpty) {
          _activeAccount = _accounts[0];
        } else if (_accounts.isEmpty) {
          _activeAccount = null;
        }
      });
    }
  }

  void _addTransaction(Transaction transaction) {
    setState(() {
      if (_activeAccount != null) {
        _accountTransactions[_activeAccount!]?.insert(0, transaction);
        if (transaction.type == TransactionType.income) {
          _activeAccount!.balance += transaction.amount;
        } else {
          _activeAccount!.balance -= transaction.amount;
        }
      }
    });

    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _showAddTransactionSheet(BuildContext context) {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    var transactionType = TransactionType.expense;
    var selectedIcon = _categoryIcons[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                top: 20, left: 20, right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 40, height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Add New Transaction', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        prefixIcon: const Icon(Icons.description_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixIcon: const Icon(Icons.attach_money),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ToggleButtons(
                          isSelected: [
                            transactionType == TransactionType.income,
                            transactionType == TransactionType.expense,
                          ],
                          onPressed: (index) {
                            setModalState(() {
                              transactionType = index == 0 ? TransactionType.income : TransactionType.expense;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          selectedColor: Colors.white,
                          fillColor: transactionType == TransactionType.income ? Colors.green : Colors.red,
                          borderColor: Colors.grey.shade300,
                          selectedBorderColor: transactionType == TransactionType.income ? Colors.green : Colors.red,
                          children: const <Widget>[
                            Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Text('Income')),
                            Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Text('Expense')),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Select Icon', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 60,
                      child: GridView.builder(
                        scrollDirection: Axis.horizontal,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 1),
                        itemCount: _categoryIcons.length,
                        itemBuilder: (context, index) {
                          final icon = _categoryIcons[index];
                          final isSelected = icon == selectedIcon;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedIcon = icon;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.orange.withOpacity(0.2) : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(15),
                                border: isSelected ? Border.all(color: Colors.orange, width: 2) : null,
                              ),
                              child: Icon(icon, color: isSelected ? Colors.orange : Colors.grey.shade700),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save Transaction', style: TextStyle(fontSize: 16, color: Colors.white)),
                        onPressed: () {
                          final description = descriptionController.text;
                          final amount = double.tryParse(amountController.text) ?? 0.0;

                          if (description.isEmpty || amount <= 0) return;

                          final newTransaction = Transaction(
                            description: description,
                            amount: amount,
                            type: transactionType,
                            date: DateTime.now(),
                            icon: selectedIcon,
                          );

                          _addTransaction(newTransaction);
                          Navigator.of(ctx).pop();
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF6F7F9),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const UserAccountsDrawerHeader(
              accountName: Text("Xpense"),
              accountEmail: Text("Track your expenses"),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.monetization_on, color: Colors.orange, size: 40),
              ),
              decoration: BoxDecoration(
                color: Colors.orange,
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
      ),
      body: SafeArea(
        child: _accounts.isEmpty
            ? _buildEmptyState()
            : SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 15),
                _buildBalanceCard(),
                const SizedBox(height: 20),
                _buildRecentTransactions(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _accounts.isEmpty
          ? null
          : FloatingActionButton(
        onPressed: () => _showAddTransactionSheet(context),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
        shape: const CircleBorder(),
      ),
      floatingActionButtonLocation: _accounts.isEmpty
          ? null
          : FloatingActionButtonLocation.centerDocked,
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
            SizedBox(
              width: 48,
              height: 48,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {},
                child: const Icon(
                  Icons.home,
                  color: Colors.orange,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(width: 40),
            SizedBox(
              width: 48,
              height: 48,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {},
                child: const Icon(
                  Icons.bar_chart,
                  color: Colors.grey,
                  size: 30,
                ),
              ),
            ),
          ],
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
              label: const Text('Add Your First Account', style: TextStyle(color: Colors.white)),
              onPressed: _navigateToManageAccounts,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  )
              ),
            )
          ],
        ),
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

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.menu, size: 30),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          visualDensity: const VisualDensity(horizontal: -4.0),
        ),
        Text(
          _activeAccount?.name ?? "No Account",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.search, size: 28),
              onPressed: () {},
              visualDensity: const VisualDensity(horizontal: -4.0),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, size: 28),
              onPressed: () {},
              visualDensity: const VisualDensity(horizontal: -4.0),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildBalanceCard() {
    double balance = _activeAccount?.balance ?? 0;

    final currentTransactions = _activeAccount != null
        ? _accountTransactions[_activeAccount!] ?? []
        : [];

    final totalIncome = currentTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, item) => sum + item.amount);

    final totalExpense = currentTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.amount);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Total Balance",
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 5),
          Text(
            currencyFormatter.format(balance),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIncomeExpenseItem(
                  Icons.arrow_downward, "Income", currencyFormatter.format(totalIncome)),
              const SizedBox(width: 30),
              _buildIncomeExpenseItem(
                  Icons.arrow_upward, "Expense", currencyFormatter.format(totalExpense)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseItem(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    final currentTransactions = _activeAccount != null
        ? _accountTransactions[_activeAccount!] ?? []
        : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recent Transactions",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20),
        currentTransactions.isEmpty
            ? const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40.0),
            child: Text(
              "No transactions for this account yet.",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
        )
            : ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: currentTransactions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 15),
          itemBuilder: (context, index) {
            final transaction = currentTransactions[index];
            return _buildTransactionItem(transaction);
          },
        ),
      ],
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final color = transaction.type == TransactionType.income ? Colors.green : Colors.red;
    final amountSign = transaction.type == TransactionType.income ? '+' : '-';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(transaction.icon, color: color, size: 24),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat.yMMMd().add_jm().format(transaction.date),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          Text(
            "$amountSign ${currencyFormatter.format(transaction.amount)}",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          )
        ],
      ),
    );
  }
}
