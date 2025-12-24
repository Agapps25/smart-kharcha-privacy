import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';

class StatsCard extends StatelessWidget {
  final double balance;
  final double income;
  final double expense;

  const StatsCard({
    super.key,
    required this.balance,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final lang = context.watch<LanguageService>();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // BALANCE
          Text(
            lang.translate('balance'),
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            format.format(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          // INCOME + EXPENSE
          Row(
            children: [
              Expanded(
                child: _miniTile(
                  lang.translate('income'),
                  income,
                  Colors.greenAccent,
                  Icons.arrow_upward_rounded,
                  format,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _miniTile(
                  lang.translate('expense'),
                  expense,
                  Colors.redAccent,
                  Icons.arrow_downward_rounded,
                  format,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniTile(
    String title,
    double amount,
    Color color,
    IconData icon,
    NumberFormat format,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  format.format(amount),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
