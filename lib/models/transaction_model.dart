import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 3)
enum TransactionType {
  @HiveField(0)
  income,

  @HiveField(1)
  expense,
}

@HiveType(typeId: 2)
class Transaction extends HiveObject {
  @HiveField(0)
  String description;

  @HiveField(1)
  double amount;

  @HiveField(2)
  TransactionType type;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  int iconValue;

  @HiveField(5)
  String? category;

  IconData get icon => IconData(iconValue, fontFamily: 'MaterialIcons');

  Transaction({
    required this.description,
    required this.amount,
    required this.type,
    required this.date,
    required this.iconValue,
    this.category,
  });
}