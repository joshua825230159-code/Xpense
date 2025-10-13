import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  bool _isSelectionMode = false;
  final Set<Account> _selectedAccounts = {};

  final currencyFormatter =
  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _accounts = List.from(widget.accounts);
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
      } else {
        _isSelectionMode = true;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedAccounts.clear();
      _isSelectionMode = false;
    });
  }

  void _deleteSelectedAccounts() {
    setState(() {
      _accounts.removeWhere((account) => _selectedAccounts.contains(account));
      _clearSelection();
    });
  }

  void _showMassDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text(
              'Are you sure you want to delete ${_selectedAccounts.length} selected accounts? This action cannot be undone and will delete all related transactions.'),
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

  void _navigateAndAddAccount() async {
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

  void _editAccount(Account account) async {
    final updatedAccount = await Navigator.push<Account>(
      context,
      MaterialPageRoute(
        builder: (context) => AddAccountScreen(account: account),
      ),
    );

    if (updatedAccount != null) {
      setState(() {
        final index = _accounts.indexWhere((a) => a.id == updatedAccount.id);
        if (index != -1) {
          final finalUpdatedAccount = Account(
            id: updatedAccount.id,
            name: updatedAccount.name,
            balance: updatedAccount.balance,
            colorValue: updatedAccount.colorValue,
            type: updatedAccount.type,
            budget: updatedAccount.budget,
          );
          _accounts[index] = finalUpdatedAccount;
        }
      });
    }
  }

  void _deleteSingleAccount(Account account) {
    setState(() {
      _accounts.removeWhere((a) => a.id == account.id);
    });
  }

  void _showSingleDeleteConfirmationDialog(Account account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
            'Are you sure you want to delete "${account.name}"? All transactions in this account will also be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteSingleAccount(account);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
        appBar:
        _isSelectionMode ? _buildSelectionAppBar() : _buildDefaultAppBar(),
        body: _accounts.isEmpty
            ? const Center(
          child: Text('No accounts available.'),
        )
            : ListView.builder(
          itemCount: _accounts.length,
          itemBuilder: (context, index) {
            final account = _accounts[index];
            final isSelected = _selectedAccounts.contains(account);
            return Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: 8.0),
              child: GestureDetector(
                onLongPress: () {
                  if (!_isSelectionMode) {
                    setState(() {
                      _isSelectionMode = true;
                    });
                  }
                  _toggleSelection(account);
                },
                onTap: () {
                  if (_isSelectionMode) {
                    _toggleSelection(account);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.orange.withOpacity(0.1)
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      if (!isDarkMode)
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.08),
                          spreadRadius: 1,
                          blurRadius: 10,
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: account.color.withOpacity(0.8),
                        radius: 20,
                        child: isSelected
                            ? const Icon(Icons.check,
                            color: Colors.white, size: 20)
                            : Icon(
                          _getIconForAccountType(account.type),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormatter.format(account.balance),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (account.budget != null)
                              Padding(
                                padding:
                                const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Budget: ${currencyFormatter.format(account.budget)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      if (_isSelectionMode)
                        Checkbox(
                          value: isSelected,
                          onChanged: (value) => _toggleSelection(account),
                          activeColor: Colors.orange,
                        )
                      else
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _editAccount(account);
                            } else if (value == 'delete') {
                              _showSingleDeleteConfirmationDialog(
                                  account);
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
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        floatingActionButton: _isSelectionMode
            ? null
            : FloatingActionButton(
          onPressed: _navigateAndAddAccount,
          backgroundColor: Colors.orange,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  AppBar _buildDefaultAppBar() {
    return AppBar(
      title: const Text('Manage Accounts'),
      centerTitle: true,
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
          onPressed: _selectedAccounts.isNotEmpty
              ? _showMassDeleteConfirmationDialog
              : null,
        ),
      ],
    );
  }

  IconData _getIconForAccountType(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return Icons.money;
      case AccountType.bank:
        return Icons.credit_card;
      case AccountType.investment:
        return Icons.trending_up;
      case AccountType.other:
        return Icons.account_balance_wallet;
      default:
        return Icons.account_balance_wallet;
    }
  }
}
