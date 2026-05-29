import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/property_filter_provider.dart';
import '../widgets/budget_section.dart';
import '../widgets/apply_button.dart';
import '../../../providers/property_provider.dart';
import '../../../data/models/property.dart';
import '../../../data/models/property_filter_model.dart';

class BudgetBottomSheet extends ConsumerWidget {
  const BudgetBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(propertyFilterProvider);
    final notifier = ref.read(propertyFilterProvider.notifier);
    final allProperties = ref.watch(propertyNotifierProvider).all;

    int propertyCount = _calculateCount(filters, allProperties);

    const borderColor = Color(0xFFE5E7EB);

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.40,
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
              color: borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Budget Section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              child: BudgetSection(
                minBudget: filters.minBudget,
                maxBudget: filters.maxBudget,
                onBudgetChanged: notifier.updateBudget,
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

  int _calculateCount(PropertyFilterState filter, List<Property> all) {
    if (all.isEmpty) return 36;
    return all.where((p) {
      if (filter.selectedIntent == 'Buy' && p.type != 'buy') return false;
      if (filter.selectedIntent == 'Rent' && p.type != 'rent') return false;
      if (filter.selectedCity.isNotEmpty && !p.location.toLowerCase().contains(filter.selectedCity.toLowerCase())) {
        return false;
      }
      final priceCr = p.price / 10000000.0;
      if (priceCr < filter.minBudget || (filter.maxBudget < 20.0 && priceCr > filter.maxBudget)) {
        return false;
      }
      return true;
    }).length;
  }
}
