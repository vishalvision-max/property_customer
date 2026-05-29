import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/property_filter_provider.dart';
import '../widgets/bhk_section.dart';
import '../widgets/budget_section.dart';
import '../widgets/property_type_section.dart';
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
                  Row(
                    children: ['Buy', 'Rent', 'Commercial'].map((intent) {
                      final isSelected = filters.selectedIntent == intent;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () => notifier.updateIntent(intent),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFF9F5FF)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? activeColor : borderColor,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  intent,
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
                              ),
                            ),
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

                  // Property Type Section
                  PropertyTypeSection(
                    selectedTypes: filters.selectedPropertyTypes,
                    onTypeToggled: notifier.togglePropertyType,
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
                  'Show advanced filters',
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
                ListedBySection(
                  selectedListedBy: filters.selectedListedBy,
                  selectedConstructionStatus:
                      filters.selectedConstructionStatus,
                  onListedByToggled: notifier.toggleListedBy,
                  onConstructionStatusToggled:
                      notifier.toggleConstructionStatus,
                ),
                const SizedBox(height: 24),
                DeveloperSection(
                  selectedDevelopers: filters.selectedDevelopers,
                  onDeveloperToggled: notifier.toggleDeveloper,
                ),
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
        if (filter.selectedIntent == 'Buy' &&
            p.type != 'buy' &&
            p.type != 'sale') return false;
        if (filter.selectedIntent == 'Rent' && p.type != 'rent') return false;
        if (filter.selectedIntent == 'Commercial' &&
            !p.propertyKind.toLowerCase().contains('commercial') &&
            !p.name.toLowerCase().contains('office')) {
          return false;
        }
      }
      if (filter.selectedCity.isNotEmpty &&
          !p.location.toLowerCase().contains(
            filter.selectedCity.toLowerCase(),
          )) {
        return false;
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
        for (final bhk in filter.selectedBhk) {
          final bhkClean = bhk.toLowerCase().replaceAll(' ', '');
          final nameClean = p.name.toLowerCase().replaceAll(' ', '');
          final kindClean = p.propertyKind.toLowerCase().replaceAll(' ', '');
          if (nameClean.contains(bhkClean) || kindClean.contains(bhkClean)) {
            bhkMatch = true;
            break;
          }
        }
        if (!bhkMatch) return false;
      }
      if (filter.selectedPropertyTypes.isNotEmpty) {
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
      return true;
    }).length;
  }
}
