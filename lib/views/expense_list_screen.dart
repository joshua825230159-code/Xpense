import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../services/currency_formatter_service.dart';

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
    final bool isSelectionMode = selectedTransactions.isNotEmpty;
    final bool showHeader = !isSearching && !isSelectionMode;

    if (transactions.isEmpty) {
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  if (showHeader) ...[
                    _buildBalanceCard(context, activeAccount, transactions),
                    const SizedBox(height: 20),
                  ],
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Text(
                        searchQuery.isNotEmpty
                            ? 'No transactions found.'
                            : "No transactions for this account yet.",
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showHeader) ...[
                  RepaintBoundary(
                      child: _buildBalanceCard(context, activeAccount, transactions)
                  ),
                  const SizedBox(height: 20),
                ],
                if (showHeader)
                  Text(
                    "Recent Transactions",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
          sliver: SliverList.separated(
            itemCount: transactions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 5),
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              final isSelected = selectedTransactions.contains(transaction);
              return _buildTransactionItem(
                context,
                transaction,
                activeAccount!.currencyCode,
                isSelected,
                isSelectionMode,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context, Account? activeAccount,
      List<Transaction> currentTransactions) {
    if (activeAccount == null) return const SizedBox.shrink();

    double balance = activeAccount.balance;
    double? budget = activeAccount.budget;
    String currencyCode = activeAccount.currencyCode;

    double monthlyExpense = 0.0;
    double totalIncome = 0.0;
    double overallExpense = 0.0;

    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    for (var t in currentTransactions) {
      if (t.type == TransactionType.income) {
        totalIncome += t.amount;
      } else {
        overallExpense += t.amount;
        if (t.date.year == currentYear && t.date.month == currentMonth) {
          monthlyExpense += t.amount;
        }
      }
    }

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
            CurrencyFormatterService.format(balance, currencyCode),
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
                child: _buildIncomeExpenseItem(
                    context,
                    Icons.arrow_downward,
                    "Income",
                    CurrencyFormatterService.format(totalIncome, currencyCode)),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildIncomeExpenseItem(
                    context,
                    Icons.arrow_upward,
                    "Expense",
                    CurrencyFormatterService.format(
                        overallExpense, currencyCode)),
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
                  '${CurrencyFormatterService.format(monthlyExpense, currencyCode)} spent',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                Text(
                  'of ${CurrencyFormatterService.format(budget, currencyCode)}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseItem(
      BuildContext context, IconData icon, String title, String value) {
    const textAndIconShadows = [
      Shadow(
        color: Colors.black38,
        offset: Offset(0, 1),
        blurRadius: 2.0,
      )
    ];

    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Total $title: $value',
              style: const TextStyle(color: Colors.white),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.black87,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      shadows: textAndIconShadows,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      shadows: textAndIconShadows,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(
      BuildContext context,
      Transaction transaction,
      String currencyCode,
      bool isSelected,
      bool isSelectionMode) {

    final color =
    transaction.type == TransactionType.income ? Colors.green : Colors.red;
    final amountSign = transaction.type == TransactionType.income ? '+' : '-';
    final tileColor = isSelected
        ? Colors.orange.withOpacity(0.1)
        : Theme.of(context).cardColor;

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

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat.yMMMd().add_jm().format(transaction.date),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$amountSign ${CurrencyFormatterService.format(transaction.amount, currencyCode)}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),

                if (isSelectionMode) ...[
                  const SizedBox(width: 8),
                  Transform.scale(
                    scale: 1.1,
                    child: Checkbox(
                      value: isSelected,
                      activeColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (bool? value) {
                        if (selectedTransactions.isNotEmpty) {
                          final newSelection = Set<Transaction>.from(selectedTransactions);
                          if (newSelection.contains(transaction)) {
                            newSelection.remove(transaction);
                          } else {
                            newSelection.add(transaction);
                          }
                          onSelectionChanged(newSelection);
                        }
                      },
                    ),
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }
}
