import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';

class TransactionDetailScreen extends StatefulWidget {
  final Transaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late TransactionType _transactionType;
  late DateTime _selectedDate;
  late IconData _selectedIcon;
  late String? _selectedCategory;

  final Map<IconData, String> expenseCategoryMap = {
    Icons.shopping_cart: 'Groceries',
    Icons.fastfood: 'Food',
    Icons.airplanemode_active: 'Travel',
    Icons.receipt: 'Bills',
    Icons.movie: 'Entertainment',
    Icons.health_and_safety: 'Health',
    Icons.school: 'Education',
    Icons.pets: 'Pets',
    Icons.home: 'Home',
    Icons.train: 'Transport',
    Icons.phone_android: 'Gadgets',
    Icons.local_gas_station: 'Fuel',
  };
  final Map<IconData, String> incomeCategoryMap = {
    Icons.work_outline: 'Salary',
    Icons.computer: 'Freelance',
    Icons.card_giftcard: 'Bonus',
    Icons.trending_up: 'Investment',
    Icons.redeem: 'Gift',
    Icons.attach_money: 'Other',
  };

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.transaction.description);
    _amountController =
        TextEditingController(text: widget.transaction.amount.toStringAsFixed(0));
    _transactionType = widget.transaction.type;
    _selectedDate = widget.transaction.date;
    _selectedIcon = widget.transaction.icon;
    _selectedCategory = widget.transaction.category;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final updatedTransaction = Transaction(
      description: _descriptionController.text,
      amount: double.tryParse(_amountController.text) ?? 0.0,
      type: _transactionType,
      date: _selectedDate,
      iconValue: _selectedIcon.codePoint,
      category: _selectedCategory!,
    );
    Navigator.pop(context, updatedTransaction);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCategoryMap = _transactionType == TransactionType.income
        ? incomeCategoryMap
        : expenseCategoryMap;
    final activeIcons = activeCategoryMap.keys.toList();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Transaction'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                prefixIcon: const Icon(Icons.description_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixIcon: Align(
                  widthFactor: 1.0,
                  heightFactor: 1.0,
                  child: Text(
                    'Rp',
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 16,
                    ),
                  ),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF414141) : const Color(0xFFECECEC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ToggleButtons(
                  isSelected: [
                    _transactionType == TransactionType.income,
                    _transactionType == TransactionType.expense,
                  ],
                  onPressed: (index) {
                    setState(() {
                      _transactionType = index == 0
                          ? TransactionType.income
                          : TransactionType.expense;
                      final newMap = _transactionType == TransactionType.income
                          ? incomeCategoryMap
                          : expenseCategoryMap;
                      _selectedIcon = newMap.keys.first;
                      _selectedCategory = newMap[_selectedIcon];
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                  selectedColor: Colors.white,
                  fillColor: _transactionType == TransactionType.income
                      ? Colors.green
                      : Colors.red,
                  borderColor: Colors.transparent,
                  selectedBorderColor: _transactionType == TransactionType.income
                      ? Colors.green
                      : Colors.red,
                  children: const <Widget>[
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text('Income')),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text('Expense')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
              leading: const Icon(Icons.calendar_today),
              title: Text(DateFormat('d MMMM yyyy').format(_selectedDate)),
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 20),
            Text('Select Category',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyMedium?.color)),
            const SizedBox(height: 10),
            SizedBox(
              height: 300,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: activeIcons.length,
                itemBuilder: (context, index) {
                  final icon = activeIcons[index];
                  final isSelected = icon == _selectedIcon;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIcon = icon;
                        _selectedCategory = activeCategoryMap[icon];
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.orange.withOpacity(0.2)
                            : (isDarkMode ? const Color(0xFF414141) : const Color(0xFFECECEC)),
                        borderRadius: BorderRadius.circular(15),
                        border: isSelected
                            ? Border.all(color: Colors.orange, width: 2)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon,
                              color: isSelected
                                  ? Colors.orange
                                  : (isDarkMode ? Colors.white70 : Colors.grey.shade700)),
                          const SizedBox(height: 4),
                          Text(
                            activeCategoryMap[icon]!,
                            style: TextStyle(
                                fontSize: 10,
                                color: isSelected
                                    ? Colors.orange
                                    : (isDarkMode ? Colors.white70 : Colors.grey.shade700)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Simpan Perubahan',
                style: TextStyle(fontSize: 16, color: Colors.white)),
            onPressed: _saveChanges,
          ),
        ),
      ),
    );
  }
}