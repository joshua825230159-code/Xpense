// lib/screens/stats_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';

class StatsScreen extends StatefulWidget {
  final Account account;
  final List<Transaction> transactions;

  const StatsScreen({
    super.key,
    required this.account,
    required this.transactions,
  });

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late Map<String, double> _expenseByCategory;
  late double _totalExpense;
  String _selectedPeriod = 'Monthly'; // State for the dropdown

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
  };

  @override
  void initState() {
    super.initState();
    _processTransactionData();
  }

  void _processTransactionData() {
    final data = <String, double>{};
    _totalExpense = 0.0;

    for (var transaction in widget.transactions) {
      if (transaction.type == TransactionType.expense) {
        final category = transaction.category ?? 'Uncategorized';
        data[category] = (data[category] ?? 0) + transaction.amount;
        _totalExpense += transaction.amount;
      }
    }

    _expenseByCategory = Map.fromEntries(
      data.entries.toList()
        ..sort((e1, e2) => e2.value.compareTo(e1.value)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: _expenseByCategory.isEmpty
          ? const Center(
        child: Text(
          'No expense data available.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatisticsCard(),
            const SizedBox(height: 24),
            _buildExpensesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final Map<String, IconData> periodIcons = {
      'Daily': Icons.today,
      'Weekly': Icons.view_week_outlined,
      'Monthly': Icons.calendar_month_outlined,
      'Yearly': Icons.calendar_today_outlined,
    };

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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Expense Statistics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPeriod,
                    elevation: 4,
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    items: periodIcons.entries.map((entry) {
                      final String value = entry.key;
                      final IconData icon = entry.value;
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Row(
                          children: [
                            Icon(icon, size: 18, color: Colors.grey.shade700),
                            const SizedBox(width: 8),
                            Text(
                              value,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedPeriod = newValue!;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              SizedBox(
                height: 150,
                width: 150,
                child: PieChart(
                  PieChartData(
                    sections: _getChartSections(),
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _expenseByCategory.entries.mapIndexed((index, entry) {
                    final percentage = (_totalExpense > 0) ? (entry.value / _totalExpense) : 0.0;
                    return _buildLegendItem(
                      _categoryColors[index % _categoryColors.length],
                      entry.key,
                      percentage,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- METHOD INI TELAH DIPERBARUI ---
  Widget _buildExpensesList() {
    final currencyFormatter =
    NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);

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
          // Judul sekarang ada di dalam Container
          const Text(
            'Expenses List',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Menggunakan spread operator (...) untuk memasukkan daftar item
          ..._expenseByCategory.entries.mapIndexed((index, entry) {
            final percentage = (_totalExpense > 0) ? (entry.value / _totalExpense) : 0.0;
            final color = _categoryColors[index % _categoryColors.length];
            final icon = _categoryIcons[entry.key] ?? Icons.category;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
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

  Widget _buildLegendItem(Color color, String text, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(text),
          const SizedBox(width: 4),
          Text(
            NumberFormat.percentPattern().format(percentage),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _getChartSections() {
    return _expenseByCategory.entries.mapIndexed((index, entry) {
      final percentage = (_totalExpense > 0) ? (entry.value / _totalExpense) * 100 : 0.0;
      return PieChartSectionData(
        color: _categoryColors[index % _categoryColors.length],
        value: entry.value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
}