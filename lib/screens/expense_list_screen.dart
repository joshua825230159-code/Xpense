import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';

class ExpenseListScreen extends StatelessWidget {
  final Account? activeAccount;
  final List<Transaction> transactions;
  final bool isSearching;
  final String searchQuery;

  const ExpenseListScreen({
    super.key,
    required this.activeAccount,
    required this.transactions,
    required this.isSearching,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isSearching) ...[
                  _buildBalanceCard(currencyFormatter, activeAccount, transactions),
                  const SizedBox(height: 20),
                ],
                _buildRecentTransactions(transactions, currencyFormatter, isSearching, searchQuery),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(List<Transaction> transactions, NumberFormat currencyFormatter, bool isSearching, String searchQuery) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isSearching)
          const Text(
            "Recent Transactions",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        if (!isSearching) const SizedBox(height: 20),
        transactions.isEmpty
            ? Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40.0),
            child: Text(
              searchQuery.isNotEmpty ? 'No transactions found.' : "No transactions for this account yet.",
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
        )
            : ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 15),
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return _buildTransactionItem(transaction, currencyFormatter);
          },
        ),
      ],
    );
  }

  Widget _buildBalanceCard(NumberFormat currencyFormatter, Account? activeAccount, List<Transaction> currentTransactions) {
    double balance = activeAccount?.balance ?? 0;
    double? budget = activeAccount?.budget;

    final now = DateTime.now();
    final monthlyExpense = currentTransactions
        .where((t) =>
    t.type == TransactionType.expense &&
        t.date.year == now.year &&
        t.date.month == now.month)
        .fold(0.0, (sum, item) => sum + item.amount);

    final totalIncome = currentTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, item) => sum + item.amount);

    final overallExpense = currentTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.amount);

    double budgetProgress = 0.0;
    if (budget != null && budget > 0) {
      budgetProgress = (monthlyExpense / budget).clamp(0.0, 1.0);
    }

    Color progressColor = Colors.green;
    if (budgetProgress >= 0.9) {
      progressColor = Colors.red;
    } else if (budgetProgress >= 0.5) {
      progressColor = Colors.yellow.shade700;
    }

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
                  Icons.arrow_downward, "Total Income", currencyFormatter.format(totalIncome)),
              const SizedBox(width: 30),
              _buildIncomeExpenseItem(
                  Icons.arrow_upward, "Total Expense", currencyFormatter.format(overallExpense)),
            ],
          ),
          if (budget != null && budget > 0) ...[
            const SizedBox(height: 25),
            const Text(
              "Monthly Budget",
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: budgetProgress,
                minHeight: 10,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${currencyFormatter.format(monthlyExpense)} spent',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                Text(
                  'of ${currencyFormatter.format(budget)}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            )
          ]
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
  Widget _buildTransactionItem(Transaction transaction, NumberFormat currencyFormatter) {
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