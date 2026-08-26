import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/property_filter_provider.dart';
import '../../../providers/property_provider.dart';
import '../../../data/models/property.dart';
import '../../../data/models/property_filter_model.dart';

const _navy = Color(0xFF191D31);
const _grey = Color(0xFF666876);
const _orange = Color(0xFFFF8000);
const _orangeTint = Color(0xFFFFF1E0);

const _kPropertyTypes = [
  'Apartments',
  'Independent House',
  'Builder Floor',
  'Villa',
  'Studio',
  'Duplex',
];

class FilterBottomSheet extends ConsumerWidget {
  /// Optional: pass the current visible property list so the price-range
  /// histogram and "Set Filter" count reflect the actual result set.
  final List<Property>? properties;

  const FilterBottomSheet({super.key, this.properties});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(propertyFilterProvider);
    final notifier = ref.read(propertyFilterProvider.notifier);
    final allProperties = properties ?? ref.watch(propertyNotifierProvider).all;

    final propertyCount = _calculateCount(filters, allProperties);
    final priceBounds = _priceBounds(allProperties);

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: _orangeTint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: _navy,
                      size: 20,
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Filter',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _navy,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: notifier.clearFilters,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Reset',
                      style: TextStyle(
                        color: _orange,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Price Range',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _PriceHistogramSlider(
                    min: priceBounds.$1,
                    max: priceBounds.$2,
                    values: RangeValues(
                      (filters.minBudget * 10000000).clamp(
                        priceBounds.$1,
                        priceBounds.$2,
                      ),
                      (filters.maxBudget >= 20.0
                              ? priceBounds.$2
                              : filters.maxBudget * 10000000)
                          .clamp(priceBounds.$1, priceBounds.$2),
                    ),
                    prices: allProperties
                        .map((p) => p.price.toDouble())
                        .toList(),
                    onChanged: (v) => notifier.updateBudget(
                      v.start / 10000000,
                      v.end / 10000000,
                    ),
                  ),
                  const SizedBox(height: 28),

                  const Text(
                    'Property Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final t in _kPropertyTypes)
                        _TypePill(
                          label: t,
                          selected: filters.selectedPropertyTypes.contains(t),
                          onTap: () => notifier.togglePropertyType(t),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  const Text(
                    'Home Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _StepperRow(
                    label: 'Bedrooms',
                    value: filters.minBedrooms,
                    onChanged: notifier.setMinBedrooms,
                  ),
                  const Divider(height: 1, color: Color(0xFFF2F4F7)),
                  _StepperRow(
                    label: 'Bathrooms',
                    value: filters.minBathroomsCount,
                    onChanged: notifier.setMinBathrooms,
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Building Size',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _PlainRangeSlider(
                    min: 0,
                    max: 5000,
                    values: RangeValues(filters.minArea, filters.maxArea),
                    onChanged: (v) => notifier.updateArea(v.start, v.end),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: Material(
                color: _orange,
                borderRadius: BorderRadius.circular(27),
                child: InkWell(
                  borderRadius: BorderRadius.circular(27),
                  onTap: () => Navigator.pop(context, true),
                  child: Center(
                    child: Text(
                      propertyCount > 0
                          ? 'Set Filter ($propertyCount)'
                          : 'Set Filter',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  (double, double) _priceBounds(List<Property> all) {
    if (all.isEmpty) return (0, 20000000);
    var min = all.first.price.toDouble();
    var max = all.first.price.toDouble();
    for (final p in all) {
      if (p.price < min) min = p.price.toDouble();
      if (p.price > max) max = p.price.toDouble();
    }
    if (max <= min) max = min + 1;
    return (min, max);
  }

  int _calculateCount(PropertyFilterState filter, List<Property> all) {
    if (all.isEmpty) return 0;
    return all.where((p) {
      if (filter.selectedIntent.isNotEmpty) {
        final pt = p.type.toLowerCase();
        if (filter.selectedIntent == 'Buy' && pt != 'buy' && pt != 'sale')
          return false;
        if (filter.selectedIntent == 'Rent' && pt != 'rent') return false;
      }
      if (filter.selectedPropertyTypes.isNotEmpty) {
        final kindClean = p.propertyKind.toLowerCase();
        final nameClean = p.name.toLowerCase();
        var typeMatch = false;
        for (final type in filter.selectedPropertyTypes) {
          if (kindClean.contains(type.toLowerCase()) ||
              nameClean.contains(type.toLowerCase())) {
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
      if (filter.minArea > 0.0 || filter.maxArea < 5000.0) {
        final area = p.area ?? 0.0;
        if (area < filter.minArea ||
            (filter.maxArea < 5000.0 && area > filter.maxArea)) {
          return false;
        }
      }
      if (filter.minBedrooms > 0) {
        final bhk = p.bhk ?? p.bedrooms ?? 0;
        if (bhk < filter.minBedrooms) return false;
      }
      if (filter.minBathroomsCount > 0) {
        if ((p.bathrooms ?? 0) < filter.minBathroomsCount) return false;
      }
      return true;
    }).length;
  }
}

class _TypePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TypePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? _orange : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? _orange : const Color(0xFFECEDF0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : _navy,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  const _StepperRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: _grey,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _stepBtn(
            Icons.remove_rounded,
            () => onChanged(value > 0 ? value - 1 : 0),
          ),
          SizedBox(
            width: 32,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _navy,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _stepBtn(Icons.add_rounded, () => onChanged(value + 1)),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: _orangeTint,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: _orange, size: 18),
      ),
    );
  }
}

class _PlainRangeSlider extends StatelessWidget {
  final double min;
  final double max;
  final RangeValues values;
  final ValueChanged<RangeValues> onChanged;
  const _PlainRangeSlider({
    required this.min,
    required this.max,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safe = RangeValues(
      values.start.clamp(min, max),
      values.end.clamp(values.start.clamp(min, max), max),
    );
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _orange,
            inactiveTrackColor: _orangeTint,
            thumbColor: Colors.white,
            overlayColor: _orange.withValues(alpha: 0.12),
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 11,
              elevation: 3,
            ),
            trackHeight: 3,
          ),
          child: RangeSlider(
            min: min,
            max: max,
            values: safe,
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                safe.start.toInt().toString(),
                style: const TextStyle(
                  color: _orange,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
              Text(
                safe.end.toInt().toString(),
                style: const TextStyle(
                  color: _orange,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Range slider with a real price-distribution histogram drawn behind the
/// track, bucketed from the currently loaded properties' prices.
class _PriceHistogramSlider extends StatelessWidget {
  final double min;
  final double max;
  final RangeValues values;
  final List<double> prices;
  final ValueChanged<RangeValues> onChanged;

  const _PriceHistogramSlider({
    required this.min,
    required this.max,
    required this.values,
    required this.prices,
    required this.onChanged,
  });

  String _fmt(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(0)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(0)}K';
    return '₹${v.toInt()}';
  }

  @override
  Widget build(BuildContext context) {
    final safe = RangeValues(
      values.start.clamp(min, max),
      values.end.clamp(values.start.clamp(min, max), max),
    );
    const bins = 24;
    final counts = List<int>.filled(bins, 0);
    final span = (max - min) <= 0 ? 1 : (max - min);
    for (final price in prices) {
      final idx = (((price - min) / span) * bins).floor().clamp(0, bins - 1);
      counts[idx]++;
    }
    final maxCount = counts
        .fold<int>(0, (a, b) => a > b ? a : b)
        .clamp(1, 1 << 30);

    return Column(
      children: [
        SizedBox(
          height: 58,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final c in counts)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Container(
                      height: 6 + (c / maxCount) * 52,
                      decoration: BoxDecoration(
                        color: _orangeTint,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _orange,
            inactiveTrackColor: Colors.transparent,
            thumbColor: Colors.white,
            overlayColor: _orange.withValues(alpha: 0.12),
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 11,
              elevation: 3,
            ),
            trackHeight: 3,
          ),
          child: RangeSlider(
            min: min,
            max: max,
            values: safe,
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _fmt(safe.start),
                style: const TextStyle(
                  color: _orange,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
              Text(
                _fmt(safe.end),
                style: const TextStyle(
                  color: _orange,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
