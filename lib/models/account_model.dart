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
  String currencyCode;
  double? budget;
  final String id;
  final int? userId;

  Color get color => Color(colorValue);

  Account({
    required this.name,
    this.balance = 0.0,
    required this.colorValue,
    required this.type,
    this.currencyCode = 'IDR',
    this.budget,
    String? id,
    this.userId,
  }) : id = id ?? const Uuid().v4();

  @override
  List<Object?> get props => [
    id,
    name,
    balance,
    colorValue,
    type,
    currencyCode,
    budget,
    userId
  ];

  @override
  bool get stringify => true;

  Account copyWith({
    String? name,
    double? balance,
    int? colorValue,
    AccountType? type,
    String? currencyCode,
    double? budget,
    String? id,
    int? userId,
  }) {
    return Account(
      name: name ?? this.name,
      balance: balance ?? this.balance,
      colorValue: colorValue ?? this.colorValue,
      type: type ?? this.type,
      currencyCode: currencyCode ?? this.currencyCode,
      budget: budget ?? this.budget,
      id: id ?? this.id,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'colorValue': colorValue,
      'type': type.name,
      'currencyCode': currencyCode,
      'budget': budget,
      'userId': userId,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      name: map['name'],
      balance: map['balance'],
      colorValue: map['colorValue'],
      type: AccountType.values.firstWhere(
            (e) => e.name == map['type'],
      ),
      currencyCode: map['currencyCode'] ?? 'IDR',
      budget: map['budget'],
      userId: map['userId'],
    );
  }
}