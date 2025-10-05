import 'package:flutter/material.dart';

class Account {
  final String name;
  double balance;
  final Color color;

  Account({
    required this.name,
    this.balance = 0.0,
    required this.color,
  });
}