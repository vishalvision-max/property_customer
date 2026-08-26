import 'package:flutter/material.dart';

class BhkSection extends StatelessWidget {
  final List<String> selectedBhk;
  final ValueChanged<String> onBhkToggled;

  const BhkSection({
    super.key,
    required this.selectedBhk,
    required this.onBhkToggled,
  });

  static const _options = [
    '1 RK',
    '1 BHK',
    '2 BHK',
    '3 BHK',
    '4 BHK',
    '5 BHK',
    '6 BHK',
    '6+ BHK',
  ];

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFFF8000);
    const borderColor = Color(0xFFE5E7EB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BHK Type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1D2939),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _options.map((option) {
            final isSelected = selectedBhk.contains(option);
            return GestureDetector(
              onTap: () => onBhkToggled(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFF1E0) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? activeColor : borderColor,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      const Icon(
                        Icons.check_circle_rounded,
                        color: activeColor,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      option,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: isSelected
                            ? activeColor
                            : const Color(0xFF344054),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
