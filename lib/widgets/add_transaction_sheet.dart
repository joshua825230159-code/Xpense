import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../services/currency_formatter_service.dart';

class AddTransactionSheet extends StatefulWidget {
  final Function(Transaction) onAddTransaction;
  final String accountId;
  final String accountCurrencyCode;

  const AddTransactionSheet({
    super.key,
    required this.onAddTransaction,
    required this.accountId,
    required this.accountCurrencyCode,
  });

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  TransactionType _transactionType = TransactionType.expense;
  DateTime _selectedDate = DateTime.now();
  late IconData _selectedIcon;
  late String? _selectedCategory;

  final Map<IconData, String> expenseCategoryMap = {
    Icons.shopping_cart: 'Groceries', Icons.fastfood: 'Food',
    Icons.airplanemode_active: 'Travel', Icons.receipt: 'Bills',
    Icons.movie: 'Entertainment', Icons.health_and_safety: 'Health',
    Icons.school: 'Education', Icons.pets: 'Pets',
    Icons.home: 'Home', Icons.train: 'Transport',
    Icons.phone_android: 'Gadgets', Icons.local_gas_station: 'Fuel',
  };
  final Map<IconData, String> incomeCategoryMap = {
    Icons.work_outline: 'Salary', Icons.computer: 'Freelance',
    Icons.card_giftcard: 'Bonus', Icons.trending_up: 'Investment',
    Icons.redeem: 'Gift', Icons.attach_money: 'Other',
  };

  @override
  void initState() {
    super.initState();
    _selectedIcon = expenseCategoryMap.keys.first;
    _selectedCategory = expenseCategoryMap.values.first;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  double _parseAmount(String amountText, String currencyCode) {
    String cleanBalance;
    if (currencyCode == 'IDR' || currencyCode == 'JPY') {
      cleanBalance = amountText.replaceAll('.', '');
    } else {
      cleanBalance = amountText.replaceAll(',', '');
    }
    return double.tryParse(cleanBalance) ?? 0.0;
  }

  void _submitData() {
    if (_formKey.currentState!.validate()) {
      final double amount = _parseAmount(
          _amountController.text,
          widget.accountCurrencyCode
      );

      final newTransaction = Transaction(
        accountId: widget.accountId,
        description: _descriptionController.text,
        amount: amount,
        type: _transactionType,
        date: _selectedDate,
        iconValue: _selectedIcon.codePoint,
        category: _selectedCategory!,
      );
      widget.onAddTransaction(newTransaction);
      Navigator.of(context).pop();
    }
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

    final String currencySymbol = CurrencyFormatterService.getSymbol(
        widget.accountCurrencyCode
    );

    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 30,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Add New Transaction', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  prefixIcon: const Icon(Icons.description_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Align(
                    widthFactor: 1.0,
                    heightFactor: 1.0,
                    child: Text(
                      currencySymbol,
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter an amount';

                  final double? amount = double.tryParse(
                      value.replaceAll('.', '').replaceAll(',', '')
                  );

                  if (amount == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 15),
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ToggleButtons(
                    isSelected: [
                      _transactionType == TransactionType.expense,
                      _transactionType == TransactionType.income,
                    ],
                    onPressed: (index) {
                      setState(() {
                        _transactionType = index == 0 ? TransactionType.expense : TransactionType.income;
                        final newMap = _transactionType == TransactionType.income ? incomeCategoryMap : expenseCategoryMap;
                        _selectedIcon = newMap.keys.first;
                        _selectedCategory = newMap[_selectedIcon];
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    selectedColor: Colors.white,
                    fillColor: _transactionType == TransactionType.expense ? Colors.red : Colors.green,
                    borderColor: Colors.grey.shade300,
                    selectedBorderColor: _transactionType == TransactionType.expense ? Colors.red : Colors.green,
                    children: const <Widget>[
                      Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Text('Expense')),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Text('Income')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
                leading: const Icon(Icons.calendar_today),
                title: Text(DateFormat('d MMMM yyyy').format(_selectedDate)),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 15),
              Text(
                'Select Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 60,
                child: GridView.builder(
                  scrollDirection: Axis.horizontal,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 1, mainAxisSpacing: 10),
                  itemCount: activeIcons.length,
                  itemBuilder: (context, index) {
                    final icon = activeIcons[index];
                    final isSelected = icon == _selectedIcon;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedIcon = icon;
                        _selectedCategory = activeCategoryMap[icon];
                      }),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.orange.withOpacity(0.2) : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(15),
                          border: isSelected ? Border.all(color: Colors.orange, width: 2) : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon, color: isSelected ? Colors.orange : (isDarkMode ? Colors.white70 : Colors.grey.shade700)),
                            const SizedBox(height: 4),
                            Text(
                              activeCategoryMap[icon]!,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: isSelected ? Colors.orange : (isDarkMode ? Colors.white70 : Colors.grey.shade700)),
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
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Add Transaction', style: TextStyle(fontSize: 16, color: Colors.white)),
                  onPressed: _submitData,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}