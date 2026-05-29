import 'package:flutter/material.dart';

class BudgetSection extends StatelessWidget {
  final double minBudget;
  final double maxBudget;
  final void Function(double min, double max) onBudgetChanged;

  const BudgetSection({
    super.key,
    required this.minBudget,
    required this.maxBudget,
    required this.onBudgetChanged,
  });

  String _formatValue(double value) {
    if (value <= 0.0) return '₹0 L';
    if (value >= 20.0) return '₹20.0 Cr+';
    return '₹${value.toStringAsFixed(1)} Cr';
  }

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF7B2FF7);
    const inactiveColor = Color(0xFFE5E7EB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Budget in ₹',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D2939),
              ),
            ),
            Text(
              '${_formatValue(minBudget)} - ${_formatValue(maxBudget)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: activeColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        RangeSlider(
          values: RangeValues(minBudget, maxBudget),
          min: 0.0,
          max: 20.0,
          divisions: 20,
          activeColor: activeColor,
          inactiveColor: inactiveColor,
          onChanged: (values) {
            onBudgetChanged(values.start, values.end);
          },
        ),
        const SizedBox(height: 4),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('₹0 L', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF667085))),
            Text('₹5 Cr', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF667085))),
            Text('₹10 Cr', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF667085))),
            Text('₹15 Cr', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF667085))),
            Text('₹20 Cr+', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF667085))),
          ],
        ),
      ],
    );
  }
}
