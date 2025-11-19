import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../services/currency_formatter_service.dart';

class StatsData {
  final Map<String, double> expenseByCategory;
  final Map<String, double> incomeByCategory;
  final double totalExpense;
  final double totalIncome;

  StatsData({
    required this.expenseByCategory,
    required this.incomeByCategory,
    required this.totalExpense,
    required this.totalIncome,
  });
}

StatsData _computeStats(Map<String, dynamic> args) {
  final List<Transaction> transactions = args['transactions'];
  final String selectedPeriod = args['selectedPeriod'];
  final now = DateTime.now();
  List<Transaction> periodTransactions;
  switch (selectedPeriod) {
    case 'Daily':
      periodTransactions = transactions.where((t) {
        return t.date.year == now.year &&
            t.date.month == now.month &&
            t.date.day == now.day;
      }).toList();
      break;
    case 'Weekly':
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final firstDayOfWeek =
      DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      periodTransactions = transactions.where((t) {
        return t.date
            .isAfter(firstDayOfWeek.subtract(const Duration(seconds: 1)));
      }).toList();
      break;
    case 'Yearly':
      periodTransactions = transactions.where((t) {
        return t.date.year == now.year;
      }).toList();
      break;
    case 'Monthly':
    default:
      periodTransactions = transactions.where((t) {
        return t.date.year == now.year && t.date.month == now.month;
      }).toList();
      break;
  }

  final expenseData = <String, double>{};
  final incomeData = <String, double>{};
  double totalExpense = 0.0;
  double totalIncome = 0.0;

  for (var transaction in periodTransactions) {
    final category = transaction.category ?? 'Uncategorized';
    if (transaction.type == TransactionType.expense) {
      expenseData[category] =
          (expenseData[category] ?? 0) + transaction.amount;
      totalExpense += transaction.amount;
    } else {
      incomeData[category] =
          (incomeData[category] ?? 0) + transaction.amount;
      totalIncome += transaction.amount;
    }
  }

  final sortedExpenseByCategory = Map.fromEntries(
    expenseData.entries.toList()
      ..sort((e1, e2) => e2.value.compareTo(e1.value)),
  );
  final sortedIncomeByCategory = Map.fromEntries(
    incomeData.entries.toList()
      ..sort((e1, e2) => e2.value.compareTo(e1.value)),
  );

  return StatsData(
    expenseByCategory: sortedExpenseByCategory,
    incomeByCategory: sortedIncomeByCategory,
    totalExpense: totalExpense,
    totalIncome: totalIncome,
  );
}

class StatsScreen extends StatefulWidget {
  final Account account;
  final List<Transaction> transactions;
  final String selectedPeriod;
  final TransactionType selectedType;

  const StatsScreen({
    super.key,
    required this.account,
    required this.transactions,
    required this.selectedPeriod,
    required this.selectedType,
  });

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late Future<StatsData> _statsDataFuture;
  int _touchedIndex = -1;

  final List<Color> _categoryColors = [
    Colors.orange.shade400, Colors.red.shade400, Colors.green.shade400,
    Colors.blue.shade400, Colors.purple.shade400, Colors.teal.shade400,
    Colors.pink.shade300, Colors.amber.shade600, Colors.cyan.shade400,
    Colors.lime.shade500, Colors.indigo.shade300, Colors.brown.shade400,
  ];

  final Map<String, IconData> _categoryIcons = {
    'Groceries': Icons.shopping_cart, 'Food': Icons.fastfood,
    'Travel': Icons.airplanemode_active, 'Bills': Icons.receipt,
    'Entertainment': Icons.movie, 'Health': Icons.health_and_safety,
    'Education': Icons.school, 'Pets': Icons.pets,
    'Home': Icons.home, 'Transport': Icons.train,
    'Gadgets': Icons.phone_android, 'Fuel': Icons.local_gas_station,
    'Salary': Icons.work_outline,
    'Freelance': Icons.computer,
    'Bonus': Icons.card_giftcard,
    'Investment': Icons.trending_up,
    'Gift': Icons.redeem,
    'Interest': Icons.account_balance,
    'Rental': Icons.house_outlined,
    'Dividends': Icons.analytics_outlined,
    'Royalties': Icons.copyright,
    'Side Hustle': Icons.lightbulb_outline,
    'Refunds': Icons.refresh,
    'Other': Icons.attach_money,
    'Uncategorized': Icons.label_off_outlined,
  };


  @override
  void initState() {
    super.initState();
    _statsDataFuture = _processTransactionData();
  }

  @override
  void didUpdateWidget(covariant StatsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.transactions != oldWidget.transactions ||
        widget.selectedPeriod != oldWidget.selectedPeriod) {
      setState(() {
        _statsDataFuture = _processTransactionData();
      });
    }
  }

  Future<StatsData> _processTransactionData() async {
    final args = {
      'transactions': widget.transactions,
      'selectedPeriod': widget.selectedPeriod,
    };

    // use compute when large for speed
    if (widget.transactions.length > 500) {
      return await compute(_computeStats, args);
    } else {
      return _computeStats(args);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return FutureBuilder<StatsData>(
      future: _statsDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error calculating statistics: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (snapshot.hasData) {
          final stats = snapshot.data!;
          final Map<String, double> activeCategoryData =
          widget.selectedType == TransactionType.expense
              ? stats.expenseByCategory
              : stats.incomeByCategory;
          final double totalForActiveType =
          widget.selectedType == TransactionType.expense
              ? stats.totalExpense
              : stats.totalIncome;
          if (activeCategoryData.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 80.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.pie_chart_outline, size: 60, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'No ${widget.selectedType.name} data for this period.',
                      style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatisticsCard(isDarkMode, activeCategoryData, totalForActiveType),
                const SizedBox(height: 10),
                _buildExpensesList(isDarkMode, activeCategoryData, totalForActiveType),
              ],
            ),
          );
        }
        return const Center(child: Text('No data available.'));
      },
    );
  }

  Widget _buildStatisticsCard(bool isDarkMode, Map<String, double> activeCategoryData, double totalForActiveType) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 10,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.selectedType == TransactionType.expense
                ? 'Expense Statistics'
                : 'Income Statistics',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  height: 150,
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, right: 0.0),
                    itemCount: activeCategoryData.length,
                    itemBuilder: (context, index) {
                      final entry =
                      activeCategoryData.entries.elementAt(index);
                      final percentage = (totalForActiveType > 0)
                          ? (entry.value / totalForActiveType)
                          : 0.0;
                      final color =
                      _categoryColors[index % _categoryColors.length];

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              NumberFormat.percentPattern()
                                  .format(percentage),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 140,
                height: 140,
                // repaint boundary for heavy grpahics chart
                child: RepaintBoundary(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback:
                                (FlTouchEvent event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  _touchedIndex = -1;
                                  return;
                                }
                                _touchedIndex = pieTouchResponse
                                    .touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          sections: _getChartSections(activeCategoryData),
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                        ),
                      ),
                      Text(
                        '100%',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _getChartSections(Map<String, double> activeCategoryData) {
    return activeCategoryData.entries.mapIndexed((index, entry) {
      final isTouched = index == _touchedIndex;
      final radius = isTouched ? 34.0 : 28.0;

      return PieChartSectionData(
        color: _categoryColors[index % _categoryColors.length],
        value: entry.value,
        radius: radius,
        showTitle: false,
      );
    }).toList();
  }

  Widget _buildExpensesList(bool isDarkMode, Map<String, double> activeCategoryData, double totalForActiveType) {
    final title = widget.selectedType == TransactionType.expense
        ? 'Expenses by Category'
        : 'Income by Category';

    final currencyCode = widget.account.currencyCode;

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 10,
            )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total for ${widget.selectedPeriod}',
                  style: TextStyle(color: Colors.grey.shade600)),
              Text(
                CurrencyFormatterService.format(totalForActiveType, currencyCode),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const Divider(height: 20),
          ...activeCategoryData.entries.mapIndexed((index, entry) {
            final percentage = (totalForActiveType > 0)
                ? (entry.value / totalForActiveType)
                : 0.0;
            final color = _categoryColors[index % _categoryColors.length];
            final icon = _categoryIcons[entry.key] ?? Icons.category_outlined;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              CurrencyFormatterService.format(entry.value, currencyCode),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: percentage,
                                  backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                                  color: color,
                                  minHeight: 8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              NumberFormat.percentPattern().format(percentage),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
