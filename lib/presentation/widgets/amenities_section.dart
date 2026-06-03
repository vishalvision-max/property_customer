import 'package:flutter/material.dart';

class AmenitiesSection extends StatelessWidget {
  final List<String> selectedAmenities;
  final ValueChanged<String> onAmenityToggled;

  const AmenitiesSection({
    super.key,
    required this.selectedAmenities,
    required this.onAmenityToggled,
  });

  /// Maps amenity display name → API numeric ID.
  /// Source: GET /api/v1/amenities
  static const Map<String, int> amenityIdMap = {
    'Lift': 1,
    'Gym': 2,
    'Security': 3,
    'Parking': 4,
    'Power Backup': 5,
    'AC': 46,
    'Swimming Pool': 49,
    'Intercom': 50,
    'CCTV': 51,
    'Garden': 52,
    'Gated Community': 55,
    'Club House': 56,
    'Regular Water Supply': 58,
    'Pet Friendly': 60,
    'Servant Room': 61,
    'Wifi': 62,
  };

  /// Resolves a list of selected amenity names to their numeric API IDs.
  /// Call this before passing amenities to the filter API.
  static List<String> toApiIds(List<String> selectedNames) {
    return selectedNames
        .map((name) => amenityIdMap[name])
        .whereType<int>()
        .map((id) => id.toString())
        .toList();
  }

  static const _options = [
    ('Lift', Icons.elevator_rounded),
    ('Gym', Icons.fitness_center_rounded),
    ('Security', Icons.security_rounded),
    ('Parking', Icons.local_parking_rounded),
    ('Power Backup', Icons.power_rounded),
    ('AC', Icons.ac_unit_rounded),
    ('Swimming Pool', Icons.pool_rounded),
    ('CCTV', Icons.videocam_rounded),
    ('Garden', Icons.eco_rounded),
    ('Gated Community', Icons.home_work_rounded),
    ('Club House', Icons.villa_rounded),
    ('Pet Friendly', Icons.pets_rounded),
    ('Servant Room', Icons.meeting_room_rounded),
    ('Wifi', Icons.wifi_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF7B2FF7);
    const borderColor = Color(0xFFE5E7EB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amenities',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1D2939),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _options.map((option) {
            final title = option.$1;
            final icon = option.$2;
            final isSelected = selectedAmenities.contains(title);

            return GestureDetector(
              onTap: () => onAmenityToggled(title),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF9F5FF) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? activeColor : borderColor,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Stack(
                  children: [
                    if (isSelected)
                      const Positioned(
                        top: 8,
                        left: 8,
                        child: Icon(Icons.check_box_rounded, color: activeColor, size: 20),
                      )
                    else
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFD0D5DD), width: 1.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 12),
                          Icon(icon, size: 28, color: isSelected ? activeColor : const Color(0xFF667085)),
                          const SizedBox(height: 8),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? activeColor : const Color(0xFF344054),
                            ),
                          ),
                        ],
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
