import 'package:flutter/material.dart';

class PropertyTypeSection extends StatelessWidget {
  final List<String> selectedTypes;
  final ValueChanged<String> onTypeToggled;

  const PropertyTypeSection({
    super.key,
    required this.selectedTypes,
    required this.onTypeToggled,
  });

  static const _options = [
    'Apartments',
    'Independent House',
    'Builder Floor',
    'Plot',
    'Studio',
    'Duplex',
    // 'Penthouse',
    'Villa',
  ];

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF7B2FF7);
    const borderColor = Color(0xFFE5E7EB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Property Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D2939),
              ),
            ),
            SizedBox(width: 6),
            Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: Color(0xFF667085),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _options.map((option) {
            final isSelected = selectedTypes.contains(option);
            return GestureDetector(
              onTap: () => onTypeToggled(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF9F5FF) : Colors.white,
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
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      option,
                      style: TextStyle(
                        fontSize: 13,
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
