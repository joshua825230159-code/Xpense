import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../services/currency_formatter_service.dart';

class TransactionDetailScreen extends StatefulWidget {
  final Transaction transaction;
  final String currencyCode;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
    required this.currencyCode,
  });

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late TextEditingController _dateController;
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
    Icons.account_balance: 'Interest',
    Icons.house_outlined: 'Rental',
    Icons.analytics_outlined: 'Dividends',
    Icons.copyright: 'Royalties',
    Icons.lightbulb_outline: 'Side Hustle',
    Icons.refresh: 'Refunds',
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

    _dateController = TextEditingController(
      text: DateFormat('d MMMM yyyy').format(_selectedDate),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final updatedTransaction = Transaction(
      id: widget.transaction.id,
      accountId: widget.transaction.accountId,
      description: _descriptionController.text,
      amount: double.tryParse(_amountController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0.0,
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
        _dateController.text = DateFormat('d MMMM yyyy').format(_selectedDate);
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
    final inputFillColor = isDarkMode
        ? Theme.of(context).inputDecorationTheme.fillColor
        : Colors.grey.shade200;

    final inputBorderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    );

    final String currencySymbol = CurrencyFormatterService.getSymbol(
        widget.currencyCode
    );

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
            const SizedBox(height: 10),

            Center(
              child: SegmentedButton<TransactionType>(
                segments: <ButtonSegment<TransactionType>>[
                  ButtonSegment<TransactionType>(
                    value: TransactionType.expense,
                    label: Text(
                      'Expense',
                      style: TextStyle(
                          color: _transactionType == TransactionType.expense
                              ? Colors.white
                              : (isDarkMode ? Colors.white70 : Colors.black87)
                      ),
                    ),
                    icon: Icon(
                      Icons.arrow_upward,
                      color: _transactionType == TransactionType.expense
                          ? Colors.white
                          : Colors.red,
                    ),
                  ),
                  ButtonSegment<TransactionType>(
                    value: TransactionType.income,
                    label: Text(
                      'Income',
                      style: TextStyle(
                          color: _transactionType == TransactionType.income
                              ? Colors.white
                              : (isDarkMode ? Colors.white70 : Colors.black87)
                      ),
                    ),
                    icon: Icon(
                      Icons.arrow_downward,
                      color: _transactionType == TransactionType.income
                          ? Colors.white
                          : Colors.green,
                    ),
                  ),
                ],
                selected: {_transactionType},
                onSelectionChanged: (Set<TransactionType> newSelection) {
                  setState(() {
                    _transactionType = newSelection.first;
                    final newMap = _transactionType == TransactionType.income
                        ? incomeCategoryMap
                        : expenseCategoryMap;
                    if (!newMap.containsKey(_selectedIcon)) {
                      _selectedIcon = newMap.keys.first;
                      _selectedCategory = newMap[_selectedIcon];
                    }
                  });
                },
                style: SegmentedButton.styleFrom(
                  backgroundColor: inputFillColor,
                  selectedBackgroundColor: _transactionType == TransactionType.expense
                      ? Colors.red.shade400
                      : Colors.green.shade400,
                  selectedForegroundColor: Colors.white,
                  side: BorderSide.none,
                ),
                showSelectedIcon: false,
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _amountController,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Amount',
                filled: true,
                fillColor: inputFillColor,
                border: inputBorderStyle,
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                  child: Text(
                    currencySymbol,
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                filled: true,
                fillColor: inputFillColor,
                border: inputBorderStyle,
                prefixIcon: const Icon(Icons.description_outlined),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _dateController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Date',
                filled: true,
                fillColor: inputFillColor,
                border: inputBorderStyle,
                prefixIcon: const Icon(Icons.calendar_today_outlined),
              ),
              onTap: () => _selectDate(context),
            ),

            const SizedBox(height: 20),
            Text('Select Category',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyMedium?.color)),
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.0,
              ),
              itemCount: activeIcons.length,
              itemBuilder: (context, index) {
                final icon = activeIcons[index];
                final isSelected = icon == _selectedIcon;
                final categoryName = activeCategoryMap[icon]!;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedIcon = icon;
                      _selectedCategory = categoryName;
                    });
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.orange.withOpacity(0.2)
                          : inputFillColor,
                      borderRadius: BorderRadius.circular(15),
                      border: isSelected
                          ? Border.all(color: Colors.orange, width: 2)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon,
                            size: 28,
                            color: isSelected
                                ? Colors.orange
                                : (isDarkMode ? Colors.white70 : Colors.grey.shade700)),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Text(
                            categoryName,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected
                                    ? Colors.orange
                                    : (isDarkMode ? Colors.white70 : Colors.grey.shade700)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
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
            child: const Text('Save Changes',
                style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: _saveChanges,
          ),
        ),
      ),
    );
  }
}