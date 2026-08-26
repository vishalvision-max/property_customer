import 'package:flutter/material.dart';

class FurnishingTypeSection extends StatelessWidget {
  final List<String> selectedFurnishing;
  final ValueChanged<String> onFurnishingToggled;

  const FurnishingTypeSection({
    super.key,
    required this.selectedFurnishing,
    required this.onFurnishingToggled,
  });

  static const _options = ['Unfurnished', 'Semi Furnished', 'Fully Furnished'];

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFFF8000);
    const borderColor = Color(0xFFE5E7EB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Furnishing Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1D2939),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _options.map((option) {
            final isSelected = selectedFurnishing.contains(option);
            return GestureDetector(
              onTap: () => onFurnishingToggled(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
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
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: isSelected ? activeColor : Colors.white,
                        border: Border.all(
                          color: isSelected
                              ? activeColor
                              : const Color(0xFFD0D5DD),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
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
