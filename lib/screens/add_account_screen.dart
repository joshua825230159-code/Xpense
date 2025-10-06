import 'package:flutter/material.dart';
import '../models/account_model.dart';

class AddAccountScreen extends StatefulWidget {
  final Account? account;
  final List<String> allAvailableTags;

  const AddAccountScreen({
    super.key,
    this.account,
    this.allAvailableTags = const [],
  });

  @override
  _AddAccountScreenState createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _goalController = TextEditingController();
  final _budgetController = TextEditingController();

  List<String> _tags = [];

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
      _tags = List<String>.from(widget.account!.tags);
      _goalController.text = widget.account!.goalLimit?.toString() ?? '';
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
        tags: _tags,
        goalLimit: double.tryParse(_goalController.text),
        budget: double.tryParse(_budgetController.text),
      );
      Navigator.of(context).pop(newOrUpdatedAccount);
    }
  }

  void _removeTag(String tagToRemove) {
    setState(() {
      _tags.remove(tagToRemove);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _goalController.dispose();
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
              const SizedBox(height: 24),
              const Text('Tags (optional)', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _tags
                    .map((tag) => Chip(
                  label: Text(tag),
                  onDeleted: () => _removeTag(tag),
                ))
                    .toList(),
              ),
              const SizedBox(height: 8),

              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  return widget.allAvailableTags.where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase()) && !_tags.contains(option);
                  });
                },
                onSelected: (String selection) {
                  setState(() {
                    _tags.add(selection);
                  });
                },
                fieldViewBuilder: (BuildContext context,
                    TextEditingController fieldController,
                    FocusNode fieldFocusNode,
                    VoidCallback onFieldSubmitted) {
                  return TextFormField(
                    controller: fieldController,
                    focusNode: fieldFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Add a tag',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          final tagText = fieldController.text.trim();
                          if (tagText.isNotEmpty && !_tags.contains(tagText)) {
                            setState(() {
                              _tags.add(tagText);
                              fieldController.clear();
                            });
                          }
                        },
                      ),
                    ),
                    onFieldSubmitted: (String value) {
                      final tagText = value.trim();
                      if (tagText.isNotEmpty && !_tags.contains(tagText)) {
                        setState(() {
                          _tags.add(tagText);
                          fieldController.clear();
                        });
                      }
                    },
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      child: SizedBox(
                        width: 300,
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: options.length,
                          shrinkWrap: true,
                          itemBuilder: (BuildContext context, int index) {
                            final String option = options.elementAt(index);
                            return ListTile(
                              title: Text(option),
                              onTap: () {
                                onSelected(option);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),
              TextFormField(
                controller: _budgetController,
                decoration: const InputDecoration(
                    labelText: 'Monthly Budget (optional)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _goalController,
                decoration:
                const InputDecoration(labelText: 'Goal Limit (optional)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
    );
  }
}