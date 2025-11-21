import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/account_model.dart';
import '../viewmodels/main_viewmodel.dart';

class AddAccountScreen extends StatefulWidget {
  final Account? account;
  final List<int>? usedColorValues;

  const AddAccountScreen({
    super.key,
    this.account,
    this.usedColorValues,
  });

  @override
  _AddAccountScreenState createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _budgetController = TextEditingController();

  bool _isConverting = false;

  final List<String> _allCurrencies = [
    'IDR', 'USD', 'EUR', 'JPY', 'GBP', 'AUD', 'SGD', 'MYR'
  ];
  String _selectedCurrency = 'IDR';

  AccountType _selectedType = AccountType.cash;

  final List<Color> _availableColors = [
    Colors.teal, Colors.blue, Colors.red, Colors.green,
    Colors.purple, Colors.orange, Colors.pink, Colors.amber,
    Colors.indigo, Colors.brown, Colors.cyan, Colors.lime,
  ];

  late Color _selectedColor;

  Color _findNextAvailableColor() {
    final usedValues = widget.usedColorValues ?? [];
    for (final color in _availableColors) {
      if (!usedValues.contains(color.value)) {
        return color;
      }
    }
    return _availableColors.first;
  }

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _nameController.text = widget.account!.name;
      _budgetController.text = widget.account!.budget != null
          ? _formatBalance(widget.account!.budget!, widget.account!.currencyCode)
          : '';
      _selectedType = widget.account!.type;
      _selectedColor = widget.account!.color;
      _selectedCurrency = widget.account!.currencyCode;

      _balanceController.text = _formatBalance(
          widget.account!.balance,
          _selectedCurrency
      );
    } else {
      _selectedColor = _findNextAvailableColor();
    }
  }

  String _formatBalance(double balance, String currencyCode) {
    if (currencyCode == 'IDR' || currencyCode == 'JPY') {
      return NumberFormat.currency(
        locale: 'id_ID',
        symbol: '',
        decimalDigits: 0,
      ).format(balance).trim();
    } else {
      return NumberFormat.currency(
        locale: 'en_US',
        symbol: '',
        decimalDigits: 2,
      ).format(balance).trim();
    }
  }
  double _parseBalance(String balanceText, String currencyCode) {
    if (balanceText.isEmpty) return 0.0;

    String clean = balanceText.replaceAll(RegExp(r'[^\d.,-]'), '');

    if (currencyCode == 'IDR' || currencyCode == 'JPY') {
      clean = clean.replaceAll('.', '');
    } else {
      clean = clean.replaceAll(',', '');
    }

    return double.tryParse(clean) ?? 0.0;
  }

  void _convertBalance(String newCurrency) async {
    if (_balanceController.text.isEmpty) {
      setState(() {
        _selectedCurrency = newCurrency;
      });
      return;
    }

    setState(() {
      _isConverting = true;
    });

    final viewModel = context.read<MainViewModel>();

    if (viewModel.allConversionRates.isEmpty) {
      await viewModel.calculateTotalBalance('IDR');
    }

    final rates = viewModel.allConversionRates;

    if (rates.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Rate cache not found. Please check internet.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isConverting = false);
      }
      return;
    }

    final String fromCurrency = _selectedCurrency;
    final double currentBalance = _parseBalance(_balanceController.text, fromCurrency);

    final String currentBudgetText = _budgetController.text;
    double? currentBudget;
    if (currentBudgetText.isNotEmpty) {
      currentBudget = _parseBalance(currentBudgetText, fromCurrency);
    }

    final double? fromRate = (fromCurrency == 'IDR') ? 1.0 : rates[fromCurrency];
    final double? toRate = (newCurrency == 'IDR') ? 1.0 : rates[newCurrency];

    if (fromRate == null || toRate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: Rate for $fromCurrency or $newCurrency not found.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isConverting = false);
      }
      return;
    }

    final double crossRate = toRate / fromRate;
    final double newBalance = currentBalance * crossRate;

    double? newBudget;
    if (currentBudget != null) {
      newBudget = currentBudget * crossRate;
    }

    if (mounted) {
      setState(() {
        _balanceController.text = _formatBalance(newBalance, newCurrency);

        if (newBudget != null) {
          _budgetController.text = _formatBalance(newBudget, newCurrency);
        }
        _selectedCurrency = newCurrency;
        _isConverting = false;
      });
    }
  }

  void _saveAccount() {
    if (_formKey.currentState!.validate()) {
      final double finalBalance = _parseBalance(
          _balanceController.text,
          _selectedCurrency
      );

      final String budgetText = _budgetController.text;

      final double? finalBudget = budgetText.isEmpty
          ? null
          : _parseBalance(budgetText, _selectedCurrency);

      final newOrUpdatedAccount = Account(
        name: _nameController.text,
        balance: finalBalance,
        colorValue: _selectedColor.value,
        type: _selectedType,
        currencyCode: _selectedCurrency,
        budget: finalBudget,
        id: widget.account?.id,
      );

      if (widget.account != null) {
        Navigator.of(context).pop({
          'account': newOrUpdatedAccount,
          'oldCurrency': widget.account!.currencyCode,
        });
      } else {
        Navigator.of(context).pop(newOrUpdatedAccount);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.account != null;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final inputFillColor = isDarkMode
        ? Theme.of(context).inputDecorationTheme.fillColor
        : Colors.grey.shade200;

    final inputBorderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Account' : 'Add New Account'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveAccount,
          ),
        ],
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Account Name',
                      prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                      filled: true,
                      fillColor: inputFillColor,
                      border: inputBorderStyle,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an account name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Account Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10.0,
                    runSpacing: 10.0,
                    children: AccountType.values.map((AccountType type) {
                      final bool isSelected = _selectedType == type;
                      IconData icon;
                      switch (type) {
                        case AccountType.cash: icon = Icons.money; break;
                        case AccountType.bank: icon = Icons.account_balance; break;
                        case AccountType.investment: icon = Icons.trending_up; break;
                        case AccountType.other: icon = Icons.wallet; break;
                      }

                      return ChoiceChip(
                        label: Text(type.name[0].toUpperCase() + type.name.substring(1)),
                        avatar: Icon(icon, size: 18, color: isSelected ? Colors.white : null),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          setState(() {
                            _selectedType = type;
                          });
                        },
                        selectedColor: Colors.orange,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : (isDarkMode ? Colors.white : Colors.black),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        backgroundColor: inputFillColor,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _selectedCurrency,
                          decoration: InputDecoration(
                            labelText: 'Currency',
                            filled: true,
                            fillColor: inputFillColor,
                            border: inputBorderStyle,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          ),
                          items: _allCurrencies.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null && newValue != _selectedCurrency) {
                              if (_balanceController.text.isNotEmpty) {
                                _convertBalance(newValue);
                              } else {
                                setState(() {
                                  _selectedCurrency = newValue;
                                });
                              }
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 4,
                        child: TextFormField(
                          controller: _balanceController,
                          decoration: InputDecoration(
                            labelText: isEditing ? 'Balance' : 'Opening Balance',
                            filled: true,
                            fillColor: inputFillColor,
                            border: inputBorderStyle,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          readOnly: isEditing,
                          enabled: !isEditing,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _budgetController,
                    decoration: InputDecoration(
                      labelText: 'Monthly Budget (Optional)',
                      prefixIcon: const Icon(Icons.pie_chart_outline),
                      filled: true,
                      fillColor: inputFillColor,
                      border: inputBorderStyle,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Account Color',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _availableColors.length,
                      itemBuilder: (context, index) {
                        final color = _availableColors[index];
                        final isSelected = _selectedColor == color;

                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = color),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: isDarkMode ? Colors.white : Colors.black87, width: 3)
                                    : null,
                                boxShadow: [
                                  if(isSelected)
                                    BoxShadow(
                                        color: color.withOpacity(0.4),
                                        blurRadius: 8,
                                        spreadRadius: 2
                                    )
                                ]
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 28)
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                          isEditing ? 'Save Changes' : 'Create Account',
                          style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          if (_isConverting)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.orange),
                    SizedBox(height: 16),
                    Text(
                        'Converting balance...',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}