import 'package:flutter/material.dart';
import '../models/account_model.dart';

class AddAccountScreen extends StatefulWidget {
  final Account? account;

  const AddAccountScreen({
    super.key,
    this.account,
  });

  @override
  _AddAccountScreenState createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _budgetController = TextEditingController();

  AccountType _selectedType = AccountType.cash;
  Color _selectedColor = Colors.teal;
  final List<Color> _availableColors = [
    Colors.teal, Colors.blue, Colors.red, Colors.green,
    Colors.purple, Colors.orange, Colors.pink, Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _nameController.text = widget.account!.name;
      _balanceController.text = widget.account!.balance.toString();
      _budgetController.text = widget.account!.budget?.toString() ?? '';
      _selectedType = widget.account!.type;
      _selectedColor = widget.account!.color;
    }
  }

  void _saveAccount() {
    if (_formKey.currentState!.validate()) {
      final newOrUpdatedAccount = Account(
        name: _nameController.text,
        balance: double.tryParse(_balanceController.text) ?? 0.0,
        colorValue: _selectedColor.value,
        type: _selectedType,
        budget: double.tryParse(_budgetController.text),
        id: widget.account?.id,
      );
      Navigator.of(context).pop(newOrUpdatedAccount);
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

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Account' : 'Add New Account'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveAccount,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Account Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an account name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _balanceController,
                decoration: InputDecoration(
                    labelText: isEditing ? 'Balance' : 'Opening Balance'),
                keyboardType: TextInputType.number,
                readOnly: isEditing,
                enabled: !isEditing,
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                initialValue: 'Indonesian Rupiah (IDR)',
                decoration: const InputDecoration(
                  labelText: 'Currency',
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AccountType>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Type of Balance'),
                items: AccountType.values.map((AccountType type) {
                  return DropdownMenuItem<AccountType>(
                    value: type,
                    child: Text(
                        type.name[0].toUpperCase() + type.name.substring(1)),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedType = newValue!;
                  });
                },
              ),
              const SizedBox(height: 24),
              const Text('Color for Account', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: GridView.builder(
                  scrollDirection: Axis.horizontal,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1),
                  itemCount: _availableColors.length,
                  itemBuilder: (context, index) {
                    final color = _availableColors[index];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: _selectedColor == color
                              ? Border.all(
                              color: Theme.of(context).primaryColor,
                              width: 3)
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
              TextFormField(
                controller: _budgetController,
                decoration: const InputDecoration(
                    labelText: 'Monthly Budget (optional)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}