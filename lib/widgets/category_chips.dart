import 'package:flutter/material.dart';
import '../models/transaction.dart';

class CategoryChips extends StatelessWidget {
  final TransactionType transactionType;
  final Category? selectedCategory;
  final ValueChanged<Category> onSelected;
  final String Function(Category)? getCategoryDisplayName; // ✅ Added parameter

  const CategoryChips({
    super.key,
    required this.transactionType,
    required this.selectedCategory,
    required this.onSelected,
    this.getCategoryDisplayName, // ✅ Added optional parameter
  });

  List<Category> get _categories {
    return transactionType == TransactionType.income
        ? TransactionModel.incomeCategories
        : TransactionModel.expenseCategories;
  }

  String _categoryLabel(Category category) {
    // ✅ Use custom display name if provided
    if (getCategoryDisplayName != null) {
      return getCategoryDisplayName!(category);
    }
    // Default: capitalize first letter
    return category.name[0].toUpperCase() + category.name.substring(1);
  }

  IconData _categoryIcon(Category category) {
    switch (category) {
      case Category.food:
        return Icons.restaurant;
      case Category.transport:
        return Icons.directions_car;
      case Category.shopping:
        return Icons.shopping_bag;
      case Category.entertainment:
        return Icons.movie;
      case Category.bills:
        return Icons.receipt_long;
      case Category.health:
        return Icons.medical_services;
      case Category.education:
        return Icons.school;
      case Category.salary:
        return Icons.payments;
      case Category.investment:
        return Icons.trending_up;
      case Category.gift:
        return Icons.card_giftcard;
      case Category.other:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((category) {
        final isSelected = category == selectedCategory;

        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _categoryIcon(category),
                size: 16,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
              const SizedBox(width: 6),
              Text(_categoryLabel(category)),
            ],
          ),
          selected: isSelected,
          selectedColor: transactionType == TransactionType.income
              ? Colors.green
              : Colors.red,
          backgroundColor: Colors.grey.shade200,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          onSelected: (_) => onSelected(category),
        );
      }).toList(),
    );
  }
}