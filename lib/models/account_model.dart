import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:equatable/equatable.dart';

enum AccountType {
  cash,
  bank,
  investment,
  other,
}

class Account with EquatableMixin {
  String name;
  double balance;
  int colorValue;
  AccountType type;
  double? budget;
  final String id;

  Color get color => Color(colorValue);

  Account({
    required this.name,
    this.balance = 0.0,
    required this.colorValue,
    required this.type,
    this.budget,
    String? id,
  }) : id = id ?? const Uuid().v4();

  @override
  List<Object?> get props => [id];

  @override
  bool get stringify => true;
}