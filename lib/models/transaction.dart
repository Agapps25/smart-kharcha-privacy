import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
enum TransactionType { 
  @HiveField(0) income, 
  @HiveField(1) expense 
}

@HiveType(typeId: 1)
enum Category {
  @HiveField(0) food, @HiveField(1) transport, @HiveField(2) shopping,
  @HiveField(3) entertainment, @HiveField(4) bills, @HiveField(5) health,
  @HiveField(6) education, @HiveField(7) salary, @HiveField(8) investment,
  @HiveField(9) gift, @HiveField(10) other
}

@HiveType(typeId: 2)
enum PaymentMethod { 
  @HiveField(0) cash, @HiveField(1) upi, @HiveField(2) card, 
  @HiveField(3) netBanking, @HiveField(4) wallet, @HiveField(5) other 
}

@HiveType(typeId: 3)
class TransactionModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final double amount;
  @HiveField(3)
  final DateTime date;
  @HiveField(4)
  final Category category;
  @HiveField(5)
  final PaymentMethod paymentMethod;
  @HiveField(6)
  final TransactionType type;
  @HiveField(7)
  final String? description;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.paymentMethod,
    required this.type,
    this.description,
  });

  // UI Helpers for Icons
  IconData get categoryIcon {
    switch (category) {
      case Category.food: return Icons.restaurant;
      case Category.transport: return Icons.directions_car;
      case Category.shopping: return Icons.shopping_bag;
      case Category.bills: return Icons.receipt_long;
      case Category.salary: return Icons.payments;
      case Category.health: return Icons.medical_services;
      case Category.entertainment: return Icons.movie;
      case Category.education: return Icons.school;
      case Category.investment: return Icons.trending_up;
      case Category.gift: return Icons.card_giftcard; // ✅ Fixed
      case Category.other: return Icons.category;
    }
  }

  Color get typeColor => type == TransactionType.income ? Colors.green : Colors.red;

  // MARK: - New Helper Methods for Category Filtering

  /// Returns a list of categories specific to expenses.
  static List<Category> get expenseCategories => [
    Category.food,
    Category.transport,
    Category.shopping,
    Category.entertainment,
    Category.bills,
    Category.health,
    Category.education,
    Category.other,
  ];

  /// Returns a list of categories specific to income.
  static List<Category> get incomeCategories => [
    Category.salary,
    Category.investment,
    Category.gift,
    Category.other,
  ];
}