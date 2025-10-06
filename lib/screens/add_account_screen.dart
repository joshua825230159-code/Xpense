import 'package:flutter/material.dart';
import '../models/account_model.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  _AddAccountScreenState createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers untuk input text
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _tagsController = TextEditingController();
  final _goalController = TextEditingController();

  AccountType _selectedType = AccountType.cash;
  Color _selectedColor = Colors.teal;
  final List<Color> _availableColors = [
    Colors.teal, Colors.blue, Colors.red, Colors.green,
    Colors.purple, Colors.orange, Colors.pink, Colors.amber,
  ];

  void _saveAccount() {
    if (_formKey.currentState!.validate()) {
      final newAccount = Account(
        name: _nameController.text,
        balance: double.tryParse(_balanceController.text) ?? 0.0,
        colorValue: _selectedColor.value, // <-- Ubah menjadi .value
        type: _selectedType,
        tags: _tagsController.text,
        goalLimit: double.tryParse(_goalController.text),
      );
      Navigator.of(context).pop(newAccount);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _tagsController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Account'),
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
                decoration: const InputDecoration(labelText: 'Opening Balance'),
                keyboardType: TextInputType.number,
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
                    child: Text(type.name[0].toUpperCase() + type.name.substring(1)),
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 1),
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
                              ? Border.all(color: Theme.of(context).primaryColor, width: 3)
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(labelText: 'Tags (optional)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _goalController,
                decoration: const InputDecoration(labelText: 'Goal Limit (optional)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
    );
  }
}