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

  // --- STATE BARU UNTUK FILTER TAGS ---
  late List<Account> _filteredAccounts;
  List<String> _allTags = [];
  String? _selectedTag;
  // ------------------------------------

  @override
  void initState() {
    super.initState();
    _accounts = List<Account>.from(widget.accounts);
    _filteredAccounts = List<Account>.from(_accounts); // Awalnya tampilkan semua
    _extractAllTags();
  }

  // --- FUNGSI BARU UNTUK MENGELOLA FILTER ---
  void _extractAllTags() {
    // Kumpulkan semua tag unik dari semua akun
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
        // Jika tidak ada tag yang dipilih, tampilkan semua
        _filteredAccounts = List<Account>.from(_accounts);
      } else {
        // Jika ada, filter berdasarkan tag yang dipilih
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
    // Cari index asli di list _accounts, bukan di _filteredAccounts
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
      _accounts.removeWhere((account) => account.key == accountToDelete.key);
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
          // Tombol filter sebelumnya dihapus dari sini
        ),
        // --- BODY DIUBAH UNTUK MENAMPUNG UI TAGS DAN LIST ---
        body: Column(
          children: [
            // Widget untuk menampilkan filter tags
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
                      return ChoiceChip( // <-- Ini adalah widget tag-nya
                        label: Text(tag),
                        selected: _selectedTag == tag,
                        onSelected: (isSelected) {
                          setState(() {
                            // Jika chip dipilih, set _selectedTag.
                            // Jika pilihan dibatalkan, set jadi null.
                            _selectedTag = isSelected ? tag : null;
                          });
                          _filterAccounts();
                        },
                      );
                    },
                  ),
                ),
              ),

            // Widget untuk menampilkan daftar akun
            Expanded(
              child: ListView.builder(
                // Gunakan _filteredAccounts, bukan _accounts
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
        // ----------------------------------------------------
        floatingActionButton: FloatingActionButton(
          onPressed: () => _navigateAndAddAccount(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}