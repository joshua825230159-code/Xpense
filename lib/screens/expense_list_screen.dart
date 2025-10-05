import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/account_model.dart';
import 'manage_accounts_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Account> _accounts = [
    Account(name: "Ada Deg", balance: 0.0, color: Colors.teal),
    Account(name: "Budget Book", balance: 1000000.0, color: Colors.green),
  ];

  Account? _activeAccount;

  final currencyFormatter =
  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    if (_accounts.isNotEmpty) {
      _activeAccount = _accounts[0];
    }
  }

  void _changeActiveAccount(Account account) {
    setState(() {
      _activeAccount = account;
    });
    Navigator.pop(context);
  }

  void _navigateToManageAccounts() {
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const ManageAccountsScreen(),
    ));
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
            const SizedBox(height: 16.0),

            _buildDrawerSectionTitle("Manage accounts"),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('New account'),
              onTap: _navigateToManageAccounts,
            ),
            ListTile(
              leading: const Icon(Icons.account_tree_outlined),
              title: const Text('Account types'),
              onTap: () {},
            ),
            const Divider(),

            _buildDrawerSectionTitle("Cash"),
            ..._accounts.map((account) => ListTile(
              leading: CircleAvatar(
                backgroundColor: account.color,
                radius: 16,
              ),
              title: Text(account.name),
              subtitle: Text(currencyFormatter.format(account.balance)),
              selected: account == _activeAccount,
              onTap: () => _changeActiveAccount(account),
            )),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
        shape: const CircleBorder(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        height: 50.0,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            SizedBox(width: 48, height: 48,
              child: InkWell(borderRadius: BorderRadius.circular(24), onTap: () {},
                child: const Icon(Icons.home, color: Colors.orange, size: 30,),
              ),
            ),
            const SizedBox(width: 40),
            SizedBox(width: 48, height: 48,
              child: InkWell(borderRadius: BorderRadius.circular(24), onTap: () {},
                child: const Icon(Icons.bar_chart, color: Colors.grey, size: 30,),
              ),
            ),
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
                  Icons.arrow_downward, "Income", currencyFormatter.format(0)),
              const SizedBox(width: 30),
              _buildIncomeExpenseItem(
                  Icons.arrow_upward, "Expense", currencyFormatter.format(0)),
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
    final List<Map<String, dynamic>> transactions = [];
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Recent Transactions",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            return const Text("Transaksi akan muncul di sini");
          },
        )
      ],
    );
  }
}