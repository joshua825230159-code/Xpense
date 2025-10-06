import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/account_model.dart';
import 'models/transaction_model.dart';
import 'screens/main_screen.dart';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(AccountAdapter());
  Hive.registerAdapter(AccountTypeAdapter());
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(TransactionTypeAdapter());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xpense App',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: const Color(0xFFF6F7F9),
      ),
      home: const MainScreen(),
    );
  }
}