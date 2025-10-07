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
      MaterialPageRoute(
        builder: (context) => AddAccountScreen(allAvailableTags: _allTags),
      ),
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

    final resultAccount = await Navigator.push<Account>(
      context,
      MaterialPageRoute(
        builder: (context) => AddAccountScreen(
          account: account,
          allAvailableTags: _allTags,
        ),
      ),
    );

    if (resultAccount != null) {
      setState(() {
        final updatedAccount = Account(
          id: account.id,
          name: resultAccount.name,
          balance: resultAccount.balance,
          colorValue: resultAccount.colorValue,
          type: resultAccount.type,
          tags: resultAccount.tags,
          goalLimit: resultAccount.goalLimit,
          budget: resultAccount.budget,
        );

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

  void _deleteSingleAccount(Account account) {
    setState(() {
      _accounts.remove(account);
    });
    _extractAllTags();
    _filterAccounts();
  }

  void _showSingleDeleteConfirmationDialog(Account account) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete the account "${account.name}"? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () {
                _deleteSingleAccount(account);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    );
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

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String searchQuery = '';

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final displayedTags = _allTags
                .where((tag) => tag.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 16, right: 16, top: 16
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter by Tag',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (value) {
                      setModalState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Search tags',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                  ListTile(
                    title: const Text('All Accounts', style: TextStyle(fontWeight: FontWeight.w500)),
                    leading: Icon(_selectedTag == null ? Icons.check_circle : Icons.radio_button_unchecked, color: Colors.orange),
                    onTap: () {
                      setState(() => _selectedTag = null);
                      _filterAccounts();
                      Navigator.pop(context);
                    },
                  ),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: displayedTags.length,
                      itemBuilder: (context, index) {
                        final tag = displayedTags[index];
                        return ListTile(
                          title: Text(tag),
                          leading: Icon(_selectedTag == tag ? Icons.check_circle : Icons.radio_button_unchecked, color: Colors.orange),
                          onTap: () {
                            setState(() => _selectedTag = tag);
                            _filterAccounts();
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
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
                        } else if (value == 'delete') {
                          _showSingleDeleteConfirmationDialog(account);
                        }
                      },
                      itemBuilder: (BuildContext context) => [
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
          onPressed: _isSelectionMode ? null : () => _navigateAndAddAccount(context),
          backgroundColor: _isSelectionMode ? Colors.grey : Colors.orange,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  AppBar _buildDefaultAppBar() {
    return AppBar(
      title: const Text("Manage Accounts"),
      actions: [
        if (_allTags.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.filter_list),
            color: _selectedTag == null ? null : Colors.orange,
            tooltip: 'Filter by Tag',
            onPressed: _showFilterSheet,
          ),
      ],
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