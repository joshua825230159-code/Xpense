import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';

class ExpenseListScreen extends StatelessWidget {
  final Account? activeAccount;
  final List<Transaction> transactions;
  final bool isSearching;
  final String searchQuery;
  final Set<Transaction> selectedTransactions;
  final Function(Set<Transaction>) onSelectionChanged;
  final Function(Set<Transaction>) onDeleteTransactions;
  final Function(Transaction) onTransactionTap;

  const ExpenseListScreen({
    super.key,
    required this.activeAccount,
    required this.transactions,
    required this.isSearching,
    required this.searchQuery,
    required this.selectedTransactions,
    required this.onSelectionChanged,
    required this.onDeleteTransactions,
    required this.onTransactionTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final bool isSelectionMode = selectedTransactions.isNotEmpty;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isSearching && !isSelectionMode) ...[
                _buildBalanceCard(
                    currencyFormatter, activeAccount, transactions),
                const SizedBox(height: 20),
              ],
              _buildRecentTransactions(
                  transactions, currencyFormatter, isSearching, searchQuery, context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(
      List<Transaction> transactions,
      NumberFormat currencyFormatter,
      bool isSearching,
      String searchQuery,
      BuildContext context) {
    final bool isSelectionMode = selectedTransactions.isNotEmpty;
    final bool showTitle = !isSearching && !isSelectionMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle)
          Text(
            "Recent Transactions",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        if (showTitle) const SizedBox(height: 10),
        transactions.isEmpty
            ? Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40.0),
            child: Text(
              searchQuery.isNotEmpty
                  ? 'No transactions found.'
                  : "No transactions for this account yet.",
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
        )
            : ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 5),
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            final isSelected = selectedTransactions.contains(transaction);
            return _buildTransactionItem(
                context, transaction, currencyFormatter, isSelected);
          },
        ),
      ],
    );
  }

  Widget _buildBalanceCard(NumberFormat currencyFormatter,
      Account? activeAccount, List<Transaction> currentTransactions) {
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white70),
          ),
          const SizedBox(height: 0),
          Text(
            currencyFormatter.format(balance),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: _buildIncomeExpenseItem(Icons.arrow_downward,
                    "Total Income", currencyFormatter.format(totalIncome)),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildIncomeExpenseItem(Icons.arrow_upward,
                    "Total Expense", currencyFormatter.format(overallExpense)),
              ),
            ],
          ),
          if (budget != null && budget > 0) ...[
            const SizedBox(height: 10),
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
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
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
    const textAndIconShadows = [
      Shadow(
        color: Colors.black38,
        offset: Offset(0, 1),
        blurRadius: 2.0,
      )
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
              shadows: textAndIconShadows,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  shadows: textAndIconShadows,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  shadows: textAndIconShadows,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, Transaction transaction,
      NumberFormat currencyFormatter, bool isSelected) {
    final color =
    transaction.type == TransactionType.income ? Colors.green : Colors.red;
    final amountSign = transaction.type == TransactionType.income ? '+' : '-';
    final tileColor =
    isSelected ? Colors.blue.shade100 : Theme.of(context).cardColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onLongPress: () {
        final newSelection = Set<Transaction>.from(selectedTransactions);
        newSelection.add(transaction);
        onSelectionChanged(newSelection);
      },
      onTap: () {
        if (selectedTransactions.isNotEmpty) {
          final newSelection = Set<Transaction>.from(selectedTransactions);
          if (newSelection.contains(transaction)) {
            newSelection.remove(transaction);
          } else {
            newSelection.add(transaction);
          }
          onSelectionChanged(newSelection);
        } else {
          onTransactionTap(transaction);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (!isSelected && !isDarkMode)
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
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(transaction.icon, color: color, size: 24),
                      ),
                      if (isSelected)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Theme.of(context).cardColor,
                                  width: 1.5),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
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
      ),
    );
  }
}