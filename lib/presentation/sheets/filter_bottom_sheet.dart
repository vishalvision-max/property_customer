import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/property_filter_provider.dart';
import '../widgets/bhk_section.dart';
import '../widgets/budget_section.dart';
import '../widgets/property_type_section.dart';
import '../widgets/furnishing_type_section.dart';
import '../widgets/filter_chip_section.dart';
import '../widgets/amenities_section.dart';
import '../widgets/area_section.dart';
import '../widgets/listed_by_section.dart';
import '../widgets/developer_section.dart';
import '../widgets/apply_button.dart';
import '../../../providers/property_provider.dart';
import '../../../data/models/property.dart';
import '../../../data/models/property_filter_model.dart';

class FilterBottomSheet extends ConsumerStatefulWidget {
  /// Optional: pass the current visible property list so the Apply button
  /// shows the correct matching count. If omitted, falls back to the global
  /// [propertyNotifierProvider] cache (works on the home/list screens).
  final List<Property>? properties;

  const FilterBottomSheet({super.key, this.properties});

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  bool _isAdvancedExpanded = false;

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(propertyFilterProvider);
    final notifier = ref.read(propertyFilterProvider.notifier);
    // Use caller-supplied list when available (e.g. search results screen);
    // fall back to the global cache used by the home screen.
    final allProperties =
        widget.properties ?? ref.watch(propertyNotifierProvider).all;

    final int propertyCount = _calculateCount(filters, allProperties);

    const activeColor = Color(0xFF7B2FF7);
    const borderColor = Color(0xFFE5E7EB);
    const textDark = Color(0xFF1A1A2E);

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.95,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 10),
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    notifier.clearFilters();
                  },
                  child: const Text(
                    'Reset All',
                    style: TextStyle(
                      color: activeColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Searching in city banner
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 16),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //     children: [
          //       Text(
          //         'Searching in ${filters.selectedCity}',
          //         style: const TextStyle(
          //           fontSize: 13,
          //           fontWeight: FontWeight.w600,
          //           color: Color(0xFF6B7280),
          //         ),
          //       ),
          //       GestureDetector(
          //         onTap: () => _showChangeCityDialog(context),
          //         child: const Text(
          //           'Change City >',
          //           style: TextStyle(
          //             fontSize: 13,
          //             fontWeight: FontWeight.w700,
          //             color: activeColor,
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          const SizedBox(height: 12),
          const Divider(color: borderColor, height: 1),

          // Filter scrollable contents
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Applied Filters Chips Row
                  _buildAppliedChips(filters, notifier),
                  const SizedBox(height: 18),

                  // I'm Looking To Section
                  const Text(
                    "I'm Looking To",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D2939),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children:
                        [
                          ('Buy', '🏠'),
                          ('Rent', '🔑'),
                          ('Commercial', '🏢'),
                          ('Land/Plots', '🌿'),
                          ('Commercial Lands', '🏗️'),
                          ('Pg/Co-living', '🛋️'),
                          ('Villas', '🏡'),
                          ('Bungalows', '🏘️'),
                          ('Lease', '📋'),
                        ].map((record) {
                          final intent = record.$1;
                          final icon = record.$2;
                          final isSelected = filters.selectedIntent == intent;
                          return GestureDetector(
                            onTap: () => notifier.updateIntent(intent),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF7C3AED),
                                          Color(0xFF9F67FA),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: isSelected
                                    ? null
                                    : const Color(0xFFF8F8FF),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : const Color(0xFFD0D5DD),
                                  width: 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF7C3AED,
                                          ).withOpacity(0.30),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    icon,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    intent,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF344054),
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Locality Section
                  // LocalitySection(
                  //   selectedLocalities: filters.selectedLocalities,
                  //   onLocalityAdded: notifier.addLocality,
                  //   onLocalityRemoved: notifier.removeLocality,
                  // ),
                  const SizedBox(height: 24),

                  // Budget Section
                  BudgetSection(
                    minBudget: filters.minBudget,
                    maxBudget: filters.maxBudget,
                    onBudgetChanged: notifier.updateBudget,
                  ),
                  const SizedBox(height: 24),

                  // BHK Section
                  BhkSection(
                    selectedBhk: filters.selectedBhk,
                    onBhkToggled: notifier.toggleBhk,
                  ),
                  const SizedBox(height: 24),

                  // Furnishing Type Section
                  FurnishingTypeSection(
                    selectedFurnishing: filters.selectedFurnishing,
                    onFurnishingToggled: notifier.toggleFurnishing,
                  ),
                  const SizedBox(height: 24),

                  // Advanced Filters Accordion
                  _buildAdvancedAccordion(filters, notifier),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Sticky Bottom Apply Button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: ApplyButton(
              count: propertyCount,
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppliedChips(
    PropertyFilterState filters,
    PropertyFilterNotifier notifier,
  ) {
    final chips = <Widget>[];

    for (final loc in filters.selectedLocalities) {
      chips.add(_appliedChip(loc, () => notifier.removeLocality(loc)));
    }
    for (final bhk in filters.selectedBhk) {
      chips.add(_appliedChip(bhk, () => notifier.toggleBhk(bhk)));
    }
    for (final pt in filters.selectedPropertyTypes) {
      chips.add(_appliedChip(pt, () => notifier.togglePropertyType(pt)));
    }
    for (final pt in filters.selectedFurnishing) {
      chips.add(_appliedChip(pt, () => notifier.toggleFurnishing(pt)));
    }
    if (filters.verifiedOnly) {
      chips.add(
        _appliedChip('Verified Only', () => notifier.toggleVerifiedOnly(false)),
      );
    }
    if (filters.imagesOnly) {
      chips.add(
        _appliedChip('Images Only', () => notifier.toggleImagesOnly(false)),
      );
    }
    if (filters.minArea > 0.0 || filters.maxArea < 5000.0) {
      final label =
          '${filters.minArea.toInt()} - ${filters.maxArea.toInt()} Sqft';
      chips.add(_appliedChip(label, () => notifier.updateArea(0.0, 5000.0)));
    }
    for (final pt in filters.selectedLeaseTypes) {
      chips.add(_appliedChip(pt, () => notifier.toggleLeaseType(pt)));
    }
    for (final pt in filters.selectedBathrooms) {
      chips.add(_appliedChip(pt, () => notifier.toggleBathroom(pt)));
    }
    for (final pt in filters.selectedAge) {
      chips.add(_appliedChip(pt, () => notifier.toggleAge(pt)));
    }
    for (final pt in filters.selectedAdded) {
      chips.add(_appliedChip(pt, () => notifier.toggleAdded(pt)));
    }
    for (final pt in filters.selectedAvailable) {
      chips.add(_appliedChip(pt, () => notifier.toggleAvailable(pt)));
    }
    for (final pt in filters.selectedPowerBackup) {
      chips.add(_appliedChip(pt, () => notifier.togglePowerBackup(pt)));
    }
    for (final pt in filters.selectedAmenities) {
      chips.add(_appliedChip(pt, () => notifier.toggleAmenity(pt)));
    }

    if (filters.minBudget > 0.0 || filters.maxBudget < 20.0) {
      final label =
          '₹${filters.minBudget.toStringAsFixed(1)}Cr - ₹${filters.maxBudget.toStringAsFixed(1)}Cr';
      chips.add(_appliedChip(label, () => notifier.updateBudget(0.0, 20.0)));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Applied Filters',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: chips),
      ],
    );
  }

  Widget _appliedChip(String label, VoidCallback onDelete) {
    const activeColor = Color(0xFF7B2FF7);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F5FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: activeColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: activeColor,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: activeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedAccordion(
    PropertyFilterState filters,
    PropertyFilterNotifier notifier,
  ) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isAdvancedExpanded = !_isAdvancedExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Advanced Filters',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D2939),
                  ),
                ),
                Icon(
                  _isAdvancedExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFF667085),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // View Verified properties only
                // Row(
                //   children: [
                //     const Expanded(
                //       child: Text(
                //         'View Verified properties only',
                //         style: TextStyle(
                //           fontSize: 14,
                //           fontWeight: FontWeight.w600,
                //           color: Color(0xFF344054),
                //         ),
                //       ),
                //     ),
                //     Checkbox(
                //       value: filters.verifiedOnly,
                //       onChanged: (v) => notifier.toggleVerifiedOnly(v ?? false),
                //       activeColor: const Color(0xFF7B2FF7),
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(4),
                //       ),
                //     ),
                //   ],
                // ),
                // const SizedBox(height: 12),

                // View Properties with images only
                // Row(
                //   children: [
                //     const Expanded(
                //       child: Text(
                //         'View Properties with images only',
                //         style: TextStyle(
                //           fontSize: 14,
                //           fontWeight: FontWeight.w600,
                //           color: Color(0xFF344054),
                //         ),
                //       ),
                //     ),
                //     Checkbox(
                //       value: filters.imagesOnly,
                //       onChanged: (v) => notifier.toggleImagesOnly(v ?? false),
                //       activeColor: const Color(0xFF7B2FF7),
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(4),
                //       ),
                //     ),
                //   ],
                // ),
                const SizedBox(height: 24),

                PropertyTypeSection(
                  selectedTypes: filters.selectedPropertyTypes,
                  onTypeToggled: notifier.togglePropertyType,
                ),
                const SizedBox(height: 24),

                AreaSection(
                  minArea: filters.minArea,
                  maxArea: filters.maxArea,
                  onAreaChanged: notifier.updateArea,
                ),
                const SizedBox(height: 24),

                FilterChipSection(
                  title: 'Lease Type',
                  options: const ['Family', 'Company', 'Bachelor'],
                  selectedOptions: filters.selectedLeaseTypes,
                  onOptionToggled: notifier.toggleLeaseType,
                ),
                const SizedBox(height: 24),

                FilterChipSection(
                  title: 'Bathrooms',
                  options: const ['1+', '2+', '3+', '4+'],
                  selectedOptions: filters.selectedBathrooms,
                  onOptionToggled: notifier.toggleBathroom,
                ),
                const SizedBox(height: 24),

                FilterChipSection(
                  title: 'Age of Property',
                  options: const [
                    'Less than 1 year',
                    'Less than 3 years',
                    'Less than 5 years',
                    'Less than 10 years',
                  ],
                  selectedOptions: filters.selectedAge,
                  onOptionToggled: notifier.toggleAge,
                ),
                const SizedBox(height: 24),

                FilterChipSection(
                  title: 'Added',
                  options: const [
                    'Yesterday',
                    'Last 3 days',
                    'Last week',
                    'Last month',
                  ],
                  selectedOptions: filters.selectedAdded,
                  onOptionToggled: notifier.toggleAdded,
                ),
                const SizedBox(height: 24),

                FilterChipSection(
                  title: 'Available',
                  options: const [
                    'Within a week',
                    'Within 15 days',
                    'Within a month',
                    'After a month',
                  ],
                  selectedOptions: filters.selectedAvailable,
                  onOptionToggled: notifier.toggleAvailable,
                ),
                const SizedBox(height: 24),

                // FilterChipSection(
                //   title: 'Power Backup',
                //   options: const ['Partial', 'Full'],
                //   selectedOptions: filters.selectedPowerBackup,
                //   onOptionToggled: notifier.togglePowerBackup,
                // ),
                // const SizedBox(height: 24),
                AmenitiesSection(
                  selectedAmenities: filters.selectedAmenities,
                  onAmenityToggled: notifier.toggleAmenity,
                ),
                const SizedBox(height: 24),

                // ListedBySection(
                //   selectedListedBy: filters.selectedListedBy,
                //   selectedConstructionStatus:
                //       filters.selectedConstructionStatus,
                //   onListedByToggled: notifier.toggleListedBy,
                //   onConstructionStatusToggled:
                //       notifier.toggleConstructionStatus,
                // ),
                // const SizedBox(height: 24),

                // DeveloperSection(
                //   selectedDevelopers: filters.selectedDevelopers,
                //   onDeveloperToggled: notifier.toggleDeveloper,
                // ),
              ],
            ),
          ),
          crossFadeState: _isAdvancedExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }

  int _calculateCount(PropertyFilterState filter, List<Property> all) {
    if (all.isEmpty) return 0; // no data yet — show 0 instead of fake number
    return all.where((p) {
      // Empty intent = show all types (consistent with search results screen)
      if (filter.selectedIntent.isNotEmpty) {
        final pt = p.type.toLowerCase();
        if (filter.selectedIntent == 'Buy' && pt != 'buy' && pt != 'sale') {
          return false;
        }
        if (filter.selectedIntent == 'Rent' && pt != 'rent') return false;
        if (filter.selectedIntent == 'Commercial' &&
            !p.propertyKind.toLowerCase().contains('commercial') &&
            !p.name.toLowerCase().contains('office')) {
          return false;
        }
      }

      if (filter.selectedLocalities.isNotEmpty) {
        bool localityMatch = false;
        for (final loc in filter.selectedLocalities) {
          if (p.location.toLowerCase().contains(loc.toLowerCase())) {
            localityMatch = true;
            break;
          }
        }
        if (!localityMatch) return false;
      }
      if (filter.selectedBhk.isNotEmpty) {
        bool bhkMatch = false;
        final nameClean = p.name.toLowerCase().replaceAll(' ', '');
        final kindClean = p.propertyKind.toLowerCase().replaceAll(' ', '');
        for (final bhk in filter.selectedBhk) {
          final bhkClean = bhk.toLowerCase().replaceAll(' ', '');
          if (nameClean.contains(bhkClean) || kindClean.contains(bhkClean)) {
            bhkMatch = true;
            break;
          }
        }
        if (!bhkMatch) return false;
      }
      if (filter.selectedPropertyTypes.isNotEmpty &&
          p.propertyKind.isNotEmpty &&
          p.propertyKind != 'null') {
        bool typeMatch = false;
        for (final type in filter.selectedPropertyTypes) {
          if (p.propertyKind.toLowerCase().contains(type.toLowerCase()) ||
              p.name.toLowerCase().contains(type.toLowerCase())) {
            typeMatch = true;
            break;
          }
        }
        if (!typeMatch) return false;
      }
      final priceCr = p.price / 10000000.0;
      if (priceCr < filter.minBudget ||
          (filter.maxBudget < 20.0 && priceCr > filter.maxBudget)) {
        return false;
      }

      if (filter.verifiedOnly &&
          !p.description.toLowerCase().contains('verified'))
        return false;

      if (filter.imagesOnly && p.images.isEmpty) return false;

      if (filter.minArea > 0.0 || filter.maxArea < 5000.0) {
        final area = p.area ?? 0.0;
        if (area < filter.minArea ||
            (filter.maxArea < 5000.0 && area > filter.maxArea)) {
          return false;
        }
      }

      if (filter.selectedFurnishing.isNotEmpty && p.description.isNotEmpty) {
        bool furnMatch = false;
        for (final f in filter.selectedFurnishing) {
          if (p.description.toLowerCase().contains(f.toLowerCase()))
            furnMatch = true;
        }
        if (!furnMatch) return false;
      }

      if (filter.selectedAmenities.isNotEmpty && p.amenities.isNotEmpty) {
        bool amenMatch = false;
        for (final a in filter.selectedAmenities) {
          for (final pa in p.amenities) {
            if (pa.toLowerCase().contains(a.toLowerCase())) {
              amenMatch = true;
              break;
            }
          }
        }
        if (!amenMatch) return false;
      }

      if (filter.selectedBathrooms.isNotEmpty &&
          p.bathrooms != null &&
          p.bathrooms! > 0) {
        bool bathMatch = false;
        final baths = p.bathrooms!;
        for (final b in filter.selectedBathrooms) {
          if (b == '1+' && baths >= 1) bathMatch = true;
          if (b == '2+' && baths >= 2) bathMatch = true;
          if (b == '3+' && baths >= 3) bathMatch = true;
          if (b == '4+' && baths >= 4) bathMatch = true;
        }
        if (!bathMatch) return false;
      }

      if (filter.selectedAdded.isNotEmpty && p.createdAt != null) {
        bool addedMatch = false;
        final now = DateTime.now();
        final diff = now.difference(p.createdAt!);
        for (final a in filter.selectedAdded) {
          if (a == 'Yesterday' && diff.inDays <= 1) addedMatch = true;
          if (a == 'Last 3 days' && diff.inDays <= 3) addedMatch = true;
          if (a == 'Last week' && diff.inDays <= 7) addedMatch = true;
          if (a == 'Last month' && diff.inDays <= 30) addedMatch = true;
        }
        if (!addedMatch) return false;
      }

      if (filter.selectedLeaseTypes.isNotEmpty && p.description.isNotEmpty) {
        bool leaseMatch = false;
        for (final l in filter.selectedLeaseTypes) {
          if (p.description.toLowerCase().contains(l.toLowerCase()))
            leaseMatch = true;
        }
        if (!leaseMatch) return false;
      }
      return true;
    }).length;
  }
}
