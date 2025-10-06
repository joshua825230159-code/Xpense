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

  late List<Account> _filteredAccounts;
  List<String> _allTags = [];
  String? _selectedTag;

  @override
  void initState() {
    super.initState();
    _accounts = List<Account>.from(widget.accounts);
    _filteredAccounts = List<Account>.from(_accounts); // Awalnya tampilkan semua
    _extractAllTags();
  }

  void _extractAllTags() {
    final allTagsSet = <String>{};
    for (var account in _accounts) {
      allTagsSet.addAll(account.tags);
    }
    setState(() {
      _allTags = allTagsSet.toList()..sort();
    });
  }

  void _filterAccounts() {
    setState(() {
      if (_selectedTag == null) {
        _filteredAccounts = List<Account>.from(_accounts);
      } else {
        _filteredAccounts = _accounts
            .where((account) => account.tags.contains(_selectedTag!))
            .toList();
      }
    });
  }
  // --------------------------------------------

  void _navigateAndAddAccount(BuildContext context) async {
    final newAccount = await Navigator.push<Account>(
      context,
      MaterialPageRoute(builder: (context) => const AddAccountScreen()),
    );

    if (newAccount != null) {
      setState(() {
        _accounts.add(newAccount);
      });
      _extractAllTags();
      _filterAccounts();
    }
  }

  void _navigateAndEditAccount(BuildContext context, Account account, int index) async {
    final originalIndex = _accounts.indexWhere((acc) => acc.key == account.key);
    if (originalIndex == -1) return;

    final updatedAccount = await Navigator.push<Account>(
      context,
      MaterialPageRoute(
        builder: (context) => AddAccountScreen(account: account),
      ),
    );

    if (updatedAccount != null) {
      setState(() {
        _accounts[originalIndex] = updatedAccount;
      });
      _extractAllTags();
      _filterAccounts();
    }
  }

  void _deleteAccount(Account accountToDelete) {
    setState(() {
      _accounts.remove(accountToDelete);
    });
    _extractAllTags();
    _filterAccounts();
  }

  void _showDeleteConfirmationDialog(Account account) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this account? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () {
                _deleteAccount(account);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    );
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
        body: Column(
          children: [
            if (_allTags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _allTags.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final tag = _allTags[index];
                      return ChoiceChip(
                        label: Text(tag),
                        selected: _selectedTag == tag,
                        onSelected: (isSelected) {
                          setState(() {
                            _selectedTag = isSelected ? tag : null;
                          });
                          _filterAccounts();
                        },
                      );
                    },
                  ),
                ),
              ),

            Expanded(
              child: ListView.builder(
                itemCount: _filteredAccounts.length,
                itemBuilder: (context, index) {
                  final account = _filteredAccounts[index];
                  return ListTile(
                    leading: CircleAvatar(backgroundColor: account.color),
                    title: Text(account.name),
                    subtitle: Text(account.type.name),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _navigateAndEditAccount(context, account, index);
                        } else if (value == 'delete') {
                          _showDeleteConfirmationDialog(account);
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _navigateAndAddAccount(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}