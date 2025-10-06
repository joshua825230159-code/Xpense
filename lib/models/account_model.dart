import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'account_model.g.dart';

@HiveType(typeId: 1)
enum AccountType {
  @HiveField(0)
  cash,
  @HiveField(1)
  bank,
  @HiveField(2)
  investment,
  @HiveField(3)
  other,
}

@HiveType(typeId: 0)
class Account extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double balance;

  @HiveField(2)
  int colorValue;

  @HiveField(3)
  AccountType type;

  @HiveField(4)
  String? tags;

  @HiveField(5)
  double? goalLimit;

  @HiveField(6)
  double? budget;

  Color get color => Color(colorValue);

  Account({
    required this.name,
    this.balance = 0.0,
    required this.colorValue,
    required this.type,
    this.tags,
    this.goalLimit,
    this.budget,
  });
}
