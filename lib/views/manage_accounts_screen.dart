import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xpense/viewmodels/main_viewmodel.dart';
import '../models/account_model.dart';
import 'add_account_screen.dart';
import '../services/currency_formatter_service.dart';

class ManageAccountsScreen extends StatefulWidget {
  const ManageAccountsScreen({super.key});

  @override
  _ManageAccountsScreenState createState() => _ManageAccountsScreenState();
}

class _ManageAccountsScreenState extends State<ManageAccountsScreen> {

  bool _isSelectionMode = false;
  final Set<Account> _selectedAccounts = {};

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
    context.read<MainViewModel>().deleteAccounts(_selectedAccounts);
    _clearSelection();
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
    final viewModel = context.read<MainViewModel>();
    final List<int> usedColors = viewModel.accounts.map((a) => a.colorValue).toList();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AddAccountScreen(
            usedColorValues: usedColors,
          )
      ),
    );
    if (result != null && result is Account) {
      context.read<MainViewModel>().addAccount(result);
    }
  }

  void _editAccount(Account account) async {
    final viewModel = context.read<MainViewModel>();
    final List<int> usedColors = viewModel.accounts
        .where((a) => a.id != account.id)
        .map((a) => a.colorValue)
        .toList();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddAccountScreen(
          account: account,
          usedColorValues: usedColors,
        ),
      ),
    );

    if (result != null && result is Map) {
      final Account updatedAccount = result['account'];
      final String oldCurrency = result['oldCurrency'];

      context.read<MainViewModel>().convertAndUpdateAccount(
          updatedAccount,
          oldCurrency
      );
    } else if (result != null && result is Account) {
      context.read<MainViewModel>().updateAccount(result);
    }
  }

  void _deleteSingleAccount(Account account) {
    context.read<MainViewModel>().deleteAccounts({account});
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
    final viewModel = context.watch<MainViewModel>();
    final accounts = viewModel.accounts;

    return WillPopScope(
      onWillPop: () async {
        if (_isSelectionMode) {
          _clearSelection();
          return false;
        }
        Navigator.of(context).pop();
        return true;
      },
      child: Scaffold(
        appBar:
        _isSelectionMode ? _buildSelectionAppBar() : _buildDefaultAppBar(),
        body: accounts.isEmpty
            ? const Center(
          child: Text('No accounts available.'),
        )
            : ListView.builder(
          itemCount: accounts.length,
          itemBuilder: (context, index) {
            final account = accounts[index];
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
                        backgroundColor:
                        account.color.withOpacity(0.8),
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
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
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
                              CurrencyFormatterService.format(
                                  account.balance,
                                  account.currencyCode
                              ),
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
                                  'Budget: ${CurrencyFormatterService.format(account.budget!, account.currencyCode)}',
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
                          onChanged: (value) =>
                              _toggleSelection(account),
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