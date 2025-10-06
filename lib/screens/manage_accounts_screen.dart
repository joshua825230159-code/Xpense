import 'package:flutter/material.dart';
import '../models/account_model.dart';
import 'add_account_screen.dart';

class ManageAccountsScreen extends StatefulWidget {
  final List<Account> accounts;

  const ManageAccountsScreen({super.key, required this.accounts});

  @override
  _ManageAccountsScreenState createState() => _ManageAccountsScreenState();
}

class _ManageAccountsScreenState extends State<ManageAccountsScreen> {
  late List<Account> _accounts;

  @override
  void initState() {
    super.initState();
    _accounts = widget.accounts;
  }

  void _navigateAndAddAccount(BuildContext context) async {
    final newAccount = await Navigator.push<Account>(
      context,
      MaterialPageRoute(builder: (context) => const AddAccountScreen()),
    );

    if (newAccount != null) {
      setState(() {
        _accounts.add(newAccount);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_accounts);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Manage Accounts"),
        ),
        body: ListView.builder(
          itemCount: _accounts.length,
          itemBuilder: (context, index) {
            final account = _accounts[index];
            return ListTile(
              leading: CircleAvatar(backgroundColor: account.color),
              title: Text(account.name),
              subtitle: Text(account.type.name),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _navigateAndAddAccount(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}