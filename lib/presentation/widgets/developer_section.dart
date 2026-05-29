import 'package:flutter/material.dart';

class DeveloperSection extends StatelessWidget {
  final List<String> selectedDevelopers;
  final ValueChanged<String> onDeveloperToggled;

  const DeveloperSection({
    super.key,
    required this.selectedDevelopers,
    required this.onDeveloperToggled,
  });

  static const _developers = [
    'Essel Realty Pvt Ltd',
    'DLF',
    'IREO Developers',
    'Aravali Infratech',
  ];

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF7B2FF7);
    const borderColor = Color(0xFFE5E7EB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Developer',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1D2939),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: _developers.map((developer) {
              final isSelected = selectedDevelopers.contains(developer);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onDeveloperToggled(developer),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFF9F5FF) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? activeColor : borderColor,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (isSelected) ...[
                          const Icon(Icons.check_circle_rounded, color: activeColor, size: 16),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          developer,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected ? activeColor : const Color(0xFF344054),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
