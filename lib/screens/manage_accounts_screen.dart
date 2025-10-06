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

  bool _isSelectionMode = false;
  final Set<Account> _selectedAccounts = {};

  @override
  void initState() {
    super.initState();
    _accounts = List<Account>.from(widget.accounts);
    _filteredAccounts = List<Account>.from(_accounts);
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
      _filteredAccounts = _accounts
          .where((account) =>
      _selectedTag == null || account.tags.contains(_selectedTag!))
          .toList();
    });
  }

  void _toggleSelection(Account account) {
    setState(() {
      if (_selectedAccounts.contains(account)) {
        _selectedAccounts.remove(account);
      } else {
        _selectedAccounts.add(account);
      }
      if (_selectedAccounts.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedAccounts.clear();
      _isSelectionMode = false;
    });
  }

  void _navigateAndAddAccount(BuildContext context) async {
    final newAccount = await Navigator.push<Account>(
      context,
      MaterialPageRoute(builder: (context) => const AddAccountScreen()),
    );

    if (newAccount != null) {
      setState(() {
        _accounts.add(newAccount);
        _extractAllTags();
        _filterAccounts();
      });
    }
  }

  void _navigateAndEditAccount(BuildContext context, Account account, int index) async {
    final originalIndex = _accounts.indexOf(account);
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
        _extractAllTags();
        _filterAccounts();
      });
    }
  }

  void _deleteSelectedAccounts() {
    setState(() {
      _accounts.removeWhere((account) => _selectedAccounts.contains(account));
      _clearSelection();
    });
    _extractAllTags();
    _filterAccounts();
  }

  void _showMassDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete ${_selectedAccounts.length} selected accounts? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () {
                _deleteSelectedAccounts();
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
        if (_isSelectionMode) {
          _clearSelection();
          return false;
        }
        Navigator.of(context).pop(_accounts);
        return true;
      },
      child: Scaffold(
        appBar: _isSelectionMode ? _buildSelectionAppBar() : _buildDefaultAppBar(),
        body: Column(
          children: [
            if (_allTags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                  final isSelected = _selectedAccounts.contains(account);
                  return ListTile(
                    onLongPress: () {
                      if (!_isSelectionMode) {
                        setState(() {
                          _isSelectionMode = true;
                          _toggleSelection(account);
                        });
                      }
                    },
                    onTap: () {
                      if (_isSelectionMode) {
                        _toggleSelection(account);
                      }
                    },
                    leading: CircleAvatar(
                      backgroundColor: isSelected ? Colors.orange : account.color,
                      child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                    ),
                    title: Text(account.name),
                    subtitle: Text(account.type.name),
                    trailing: _isSelectionMode
                        ? Checkbox(
                      value: isSelected,
                      onChanged: (bool? value) {
                        _toggleSelection(account);
                      },
                    )
                        : PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _navigateAndEditAccount(context, account, index);
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Text('Edit'),
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
          onPressed: _isSelectionMode ? null : () => _navigateAndAddAccount(context),
          backgroundColor: _isSelectionMode ? Colors.grey : Colors.orange,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  AppBar _buildDefaultAppBar() {
    return AppBar(
      title: const Text("Manage Accounts"),
    );
  }

  AppBar _buildSelectionAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _clearSelection,
      ),
      title: Text('${_selectedAccounts.length} selected'),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: _showMassDeleteConfirmationDialog,
        ),
      ],
    );
  }
}