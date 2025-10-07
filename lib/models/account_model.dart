import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:equatable/equatable.dart';

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
class Account extends HiveObject with EquatableMixin {
  @HiveField(0)
  String name;

  @HiveField(1)
  double balance;

  @HiveField(2)
  int colorValue;

  @HiveField(3)
  AccountType type;

  @HiveField(4)
  List<String> tags;

  @HiveField(5)
  double? goalLimit;

  @HiveField(6)
  double? budget;

  @HiveField(7)
  final String id;

  Color get color => Color(colorValue);

  Account({
    required this.name,
    this.balance = 0.0,
    required this.colorValue,
    required this.type,
    List<String>? tags,
    this.goalLimit,
    this.budget,
    String? id,
  })  : this.tags = tags ?? [],
        this.id = id ?? const Uuid().v4();

  @override
  List<Object?> get props => [id];

  @override
  bool get stringify => true;
}