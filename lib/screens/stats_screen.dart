import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';

class StatsScreen extends StatefulWidget {
  final Account account;
  final List<Transaction> transactions;
  final String selectedPeriod;

  const StatsScreen({
    super.key,
    required this.account,
    required this.transactions,
    required this.selectedPeriod,
  });

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late Map<String, double> _expenseByCategory;
  late Map<String, double> _incomeByCategory;
  late double _totalExpense;
  late double _totalIncome;

  TransactionType _selectedType = TransactionType.expense;

  int _touchedIndex = -1;

  final List<Color> _categoryColors = [
    Colors.orange.shade400,
    Colors.red.shade400,
    Colors.green.shade400,
    Colors.blue.shade400,
    Colors.purple.shade400,
    Colors.teal.shade400,
    Colors.pink.shade300,
  ];

  final Map<String, IconData> _categoryIcons = {
    'Groceries': Icons.shopping_cart,
    'Food': Icons.fastfood,
    'Travel': Icons.airplanemode_active,
    'Bills': Icons.receipt,
    'Entertainment': Icons.movie,
    'Health': Icons.health_and_safety,
    'Education': Icons.school,
    'Pets': Icons.pets,
    'Home': Icons.home,
    'Transport': Icons.train,
    'Gadgets': Icons.phone_android,
    'Fuel': Icons.local_gas_station,
    'Salary': Icons.attach_money,
    'Freelance': Icons.work,
    'Bonus': Icons.card_giftcard,
    'Investment': Icons.trending_up,
    'Gift': Icons.redeem,
    'Other': Icons.attach_money,
  };

  @override
  void initState() {
    super.initState();
    _processTransactionData();
  }

  @override
  void didUpdateWidget(covariant StatsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.transactions != oldWidget.transactions ||
        widget.account != oldWidget.account ||
        widget.selectedPeriod != oldWidget.selectedPeriod) {
      _processTransactionData();
    }
  }

  void _processTransactionData() {
    final now = DateTime.now();
    List<Transaction> periodTransactions;

    switch (widget.selectedPeriod) {
      case 'Daily':
        periodTransactions = widget.transactions.where((t) {
          return t.date.year == now.year &&
              t.date.month == now.month &&
              t.date.day == now.day;
        }).toList();
        break;
      case 'Weekly':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final firstDayOfWeek =
            DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        periodTransactions = widget.transactions.where((t) {
          return t.date
              .isAfter(firstDayOfWeek.subtract(const Duration(seconds: 1)));
        }).toList();
        break;
      case 'Yearly':
        periodTransactions = widget.transactions.where((t) {
          return t.date.year == now.year;
        }).toList();
        break;
      case 'Monthly':
      default:
        periodTransactions = widget.transactions.where((t) {
          return t.date.year == now.year && t.date.month == now.month;
        }).toList();
        break;
    }

    final expenseData = <String, double>{};
    final incomeData = <String, double>{};
    _totalExpense = 0.0;
    _totalIncome = 0.0;

    for (var transaction in periodTransactions) {
      final category = transaction.category ?? 'Uncategorized';
      if (transaction.type == TransactionType.expense) {
        expenseData[category] =
            (expenseData[category] ?? 0) + transaction.amount;
        _totalExpense += transaction.amount;
      } else {
        incomeData[category] =
            (incomeData[category] ?? 0) + transaction.amount;
        _totalIncome += transaction.amount;
      }
    }

    setState(() {
      _expenseByCategory = Map.fromEntries(
        expenseData.entries.toList()
          ..sort((e1, e2) => e2.value.compareTo(e1.value)),
      );
      _incomeByCategory = Map.fromEntries(
        incomeData.entries.toList()
          ..sort((e1, e2) => e2.value.compareTo(e1.value)),
      );
    });
  }

  Map<String, double> get _activeCategoryData {
    return _selectedType == TransactionType.expense
        ? _expenseByCategory
        : _incomeByCategory;
  }

  double get _totalForActiveType {
    return _selectedType == TransactionType.expense
        ? _totalExpense
        : _totalIncome;
  }

  @override
  Widget build(BuildContext context) {
    final bool noData = _selectedType == TransactionType.expense
        ? _expenseByCategory.isEmpty
        : _incomeByCategory.isEmpty;

    return Container(
      color: Colors.grey.shade50,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),
            _buildToggleButtons(),
            const SizedBox(height: 15),
            if (noData)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.pie_chart_outline,
                        size: 60, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'No ${_selectedType.name} data for this period.',
                      style:
                          TextStyle(fontSize: 18, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              )
            else ...[
              _buildStatisticsCard(),
              const SizedBox(height: 15),
              _buildExpensesList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Center(
      child: ToggleButtons(
        isSelected: [
          _selectedType == TransactionType.expense,
          _selectedType == TransactionType.income,
        ],
        onPressed: (index) {
          setState(() {
            _selectedType =
                index == 0 ? TransactionType.expense : TransactionType.income;
            _touchedIndex = -1;
          });
        },
        borderRadius: BorderRadius.circular(12),
        selectedColor: Colors.white,
        fillColor:
            _selectedType == TransactionType.expense ? Colors.red : Colors.green,
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Expense'),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Income'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
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
          const Text(
            'Statistics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  height: 160,
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(right: 12.0),
                      itemCount: _activeCategoryData.length,
                      itemBuilder: (context, index) {
                        final entry =
                            _activeCategoryData.entries.elementAt(index);
                        final percentage = (_totalForActiveType > 0)
                            ? (entry.value / _totalForActiveType)
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
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 140,
                height: 140,
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
                        sections: _getChartSections(),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                    Text(
                      '100%',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _getChartSections() {
    return _activeCategoryData.entries.mapIndexed((index, entry) {
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

  Widget _buildExpensesList() {
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);
    final title = _selectedType == TransactionType.expense
        ? 'Expenses List'
        : 'Income List';

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
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
                NumberFormat.currency(
                        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                    .format(_totalForActiveType),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const Divider(height: 20),
          ..._activeCategoryData.entries.mapIndexed((index, entry) {
            final percentage = (_totalForActiveType > 0)
                ? (entry.value / _totalForActiveType)
                : 0.0;
            final color = _categoryColors[index % _categoryColors.length];
            final icon = _categoryIcons[entry.key] ?? Icons.category;

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
                              currencyFormatter.format(entry.value),
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
                                  backgroundColor: Colors.grey.shade200,
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
