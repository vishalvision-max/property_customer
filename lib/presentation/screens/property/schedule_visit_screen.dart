import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/property_provider.dart';
import '../../../providers/app_providers.dart';
import '../../../data/models/property.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/primary_button.dart';

class ScheduleVisitScreen extends ConsumerStatefulWidget {
  final String propertyId;
  const ScheduleVisitScreen({super.key, required this.propertyId});

  @override
  ConsumerState<ScheduleVisitScreen> createState() =>
      _ScheduleVisitScreenState();
}

class _ScheduleVisitScreenState extends ConsumerState<ScheduleVisitScreen> {
  DateTime? _date;
  String? _slot;
  bool _submitting = false;

  static const _slots = <String>[
    '09:00 AM',
    '11:00 AM',
    '01:00 PM',
    '03:00 PM',
    '05:00 PM',
    '07:00 PM',
  ];

  bool get _valid => _date != null && _slot != null;

  String _formatIndianPrice(int price, String type) {
    if (type == 'rent') {
      if (price >= 100000) {
        double lakhs = price / 100000.0;
        return '₹${lakhs.toStringAsFixed(lakhs % 1 == 0 ? 0 : 1)} L/mo';
      }
      String priceStr = price.toString();
      if (priceStr.length > 3) {
        priceStr = priceStr.replaceAllMapped(
          RegExp(r'(\d+?)(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
      }
      return '₹$priceStr /mo';
    } else {
      if (price >= 10000000) {
        double crores = price / 10000000.0;
        return '₹${crores.toStringAsFixed(crores % 1 == 0 ? 0 : 2)} Cr';
      } else if (price >= 100000) {
        double lakhs = price / 100000.0;
        return '₹${lakhs.toStringAsFixed(lakhs % 1 == 0 ? 0 : 1)} Lakh';
      }
      return '₹$price';
    }
  }

  String _getCleanTitle(Property property) {
    String typeStr = 'Property';
    if (property.categoryName != null && property.categoryName!.isNotEmpty) {
      typeStr = property.categoryName!;
    } else if (property.name.toLowerCase().contains('apartment')) {
      typeStr = 'Apartment';
    } else if (property.name.toLowerCase().contains('villa')) {
      typeStr = 'Villa';
    }

    if (property.bhk != null && property.bhk! > 0) {
      return '${property.bhk} BHK $typeStr';
    }
    return typeStr;
  }

  @override
  Widget build(BuildContext context) {
    final property = ref
        .watch(propertyNotifierProvider.notifier)
        .getById(widget.propertyId);
    final fmt = DateFormat('EEE, MMM d, yyyy');

    String imageUrl =
        'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=900&q=80&auto=format&fit=crop';
    if (property != null) {
      if (property.images.isNotEmpty) {
        imageUrl = property.images.first;
      } else {
        final asyncImages = ref.watch(propertyImagesProvider(property.id));
        if (asyncImages.hasValue && asyncImages.value!.isNotEmpty) {
          imageUrl = asyncImages.value!.first;
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Schedule a Visit',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (property != null) ...[
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: Colors.grey[300]),
                      errorWidget: (context, url, error) =>
                          Container(color: Colors.grey[300]),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.8),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatIndianPrice(property.price, property.type),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getCleanTitle(property),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.white70,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  property.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8000).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          property.type.toUpperCase() == 'SALE'
                              ? 'FOR SALE'
                              : 'FOR RENT',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              'Select Date & Time',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: const Color(0xFF1D2939),
              ),
            ),
            const SizedBox(height: 12),
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Preferred Date',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF344054),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final errorColor = Theme.of(context).colorScheme.error;
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: now.add(const Duration(days: 1)),
                        firstDate: DateTime(
                          now.year,
                          now.month,
                          now.day,
                        ).add(const Duration(days: 1)),
                        lastDate: now.add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFFFF8000),
                                onPrimary: Colors.white,
                                onSurface: Color(0xFF1D2939),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (!mounted) return;
                      if (picked == null) return;
                      if (picked.isBefore(
                        DateTime(now.year, now.month, now.day + 1),
                      )) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: const Text('Cannot pick a past date'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: errorColor,
                          ),
                        );
                        return;
                      }
                      setState(() => _date = picked);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFEAECF0),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_rounded,
                            color: Color(0xFFFF8000),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _date == null
                                  ? 'Choose a future date'
                                  : fmt.format(_date!),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: _date == null
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                color: _date == null
                                    ? const Color(0xFF98A2B3)
                                    : const Color(0xFF1D2939),
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF98A2B3),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Preferred Time Slot',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF344054),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final s in _slots)
                        ChoiceChip(
                          label: Text(s),
                          selected: _slot == s,
                          onSelected: (_) => setState(() => _slot = s),
                          selectedColor: const Color(
                            0xFFFF8000,
                          ).withValues(alpha: 0.1),
                          labelStyle: TextStyle(
                            color: _slot == s
                                ? const Color(0xFFFF8000)
                                : const Color(0xFF344054),
                            fontWeight: _slot == s
                                ? FontWeight.w800
                                : FontWeight.w600,
                            fontSize: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: _slot == s
                                  ? const Color(0xFFFF8000)
                                  : const Color(0xFFEAECF0),
                              width: _slot == s ? 1.5 : 1,
                            ),
                          ),
                          backgroundColor: Colors.white,
                          showCheckmark: false,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Confirm Schedule',
              isLoading: _submitting,
              onPressed: _valid
                  ? () async {
                      final router = GoRouter.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      final errorColor = Theme.of(context).colorScheme.error;
                      final authState = ref.read(authProvider);
                      final user = authState.user;

                      if (user == null || user.token.isEmpty) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Please login to schedule a visit',
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: errorColor,
                          ),
                        );
                        return;
                      }

                      setState(() => _submitting = true);
                      try {
                        final formattedDate = DateFormat(
                          'yyyy-MM-dd',
                        ).format(_date!);
                        final timeParsed = DateFormat('hh:mm a').parse(_slot!);
                        final formattedTime = DateFormat(
                          'HH:mm',
                        ).format(timeParsed);

                        await ref
                            .read(propertyNotifierProvider.notifier)
                            .scheduleVisit(
                              token: user.token,
                              propertyId: widget.propertyId,
                              userId: user.id,
                              date: formattedDate,
                              time: formattedTime,
                            );

                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Visit scheduled successfully for ${fmt.format(_date!)} at $_slot!',
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: const Color(0xFF039855),
                          ),
                        );
                        router.pop();
                      } catch (e) {
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceFirst('Exception: ', ''),
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: errorColor,
                          ),
                        );
                      } finally {
                        if (mounted) setState(() => _submitting = false);
                      }
                    }
                  : null,
              leading: const Icon(Icons.event_available_rounded, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
