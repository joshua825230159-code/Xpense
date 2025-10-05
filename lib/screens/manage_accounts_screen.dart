import 'package:flutter/material.dart';

class ManageAccountsScreen extends StatelessWidget {
  const ManageAccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Accounts"),
        backgroundColor: Colors.orange,
      ),
      body: const Center(
        child: Text("Halaman untuk mengelola akun akan ada di sini."),
      ),
    );
  }
}