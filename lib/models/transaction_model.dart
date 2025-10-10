import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

enum TransactionType {
  income,
  expense,
}

class Transaction with EquatableMixin {
  final String id;
  String description;
  double amount;
  TransactionType type;
  DateTime date;
  int iconValue;
  String? category;

  IconData get icon => IconData(iconValue, fontFamily: 'MaterialIcons');

  Transaction({
    required this.description,
    required this.amount,
    required this.type,
    required this.date,
    required this.iconValue,
    this.category,
    String? id,
  }) : id = id ?? const Uuid().v4();

  @override
  List<Object?> get props => [id];

  @override
  bool get stringify => true;
}