import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

enum TransactionType {
  income,
  expense,
}

class Transaction with EquatableMixin {
  final String id;
  final String accountId;
  String description;
  double amount;
  TransactionType type;
  DateTime date;
  int iconValue;
  String? category;

  IconData get icon => IconData(iconValue, fontFamily: 'MaterialIcons');

  Transaction({
    required this.accountId,
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'accountId': accountId,
      'description': description,
      'amount': amount,
      'type': type.name,
      'date': date.toIso8601String(),
      'iconValue': iconValue,
      'category': category,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      accountId: map['accountId'],
      description: map['description'],
      amount: map['amount'],
      type: TransactionType.values.firstWhere(
            (e) => e.name == map['type'],
      ),
      date: DateTime.parse(map['date']),
      iconValue: map['iconValue'],
      category: map['category'],
    );
  }
}