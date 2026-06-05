import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/scheduled_visits_provider.dart';
import '../../widgets/property_card.dart';
import '../../../data/models/scheduled_visit.dart';

const _kPrimary = Color(0xFF6C5CE7);
const _kBg = Color(0xFFF6F8FA);
const _kTextDark = Color(0xFF1A1A2E);
const _kTextMid = Color(0xFF6B7280);
const _kBorder = Color(0xFFE5E7EB);

class ScheduledVisitsScreen extends ConsumerWidget {
  const ScheduledVisitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitsAsync = ref.watch(scheduledVisitsNotifierProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: true,
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(
                left: 20,
                bottom: 16,
                right: 20,
              ),
              title: const Text(
                'My Scheduled Visits',
                style: TextStyle(
                  color: _kTextDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_kPrimary.withValues(alpha: 0.08), Colors.white],
                  ),
                ),
              ),
            ),
          ),
          visitsAsync.when(
            data: (visits) {
              if (visits.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            size: 64,
                            color: Color(0xFFD1D5DB),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'No Scheduled Visits',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: _kTextDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'You haven\'t scheduled any property\nvisits yet. They will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _kTextMid, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final visit = visits[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _VisitCard(visit: visit),
                    );
                  }, childCount: visits.length),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Oops! Something went wrong.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _kTextDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: _kTextMid),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => ref
                            .read(scheduledVisitsNotifierProvider.notifier)
                            .refresh(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  final ScheduledVisit visit;

  const _VisitCard({required this.visit});

  (Color bg, Color fg, IconData icon) _statusConfig(String st) {
    switch (st.toLowerCase()) {
      case 'pending':
        return (
          const Color(0xFFFEF3C7),
          const Color(0xFFB45309),
          Icons.hourglass_top_rounded,
        );
      case 'confirmed':
      case 'approved':
        return (
          const Color(0xFFD1FAE5),
          const Color(0xFF059669),
          Icons.check_circle_rounded,
        );
      case 'cancelled':
      case 'rejected':
        return (
          const Color(0xFFFEE2E2),
          const Color(0xFFDC2626),
          Icons.cancel_rounded,
        );
      case 'completed':
        return (
          const Color(0xFFE0E7FF),
          const Color(0xFF4338CA),
          Icons.verified_rounded,
        );
      default:
        return (
          const Color(0xFFF3F4F6),
          const Color(0xFF4B5563),
          Icons.info_outline_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final conf = _statusConfig(visit.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kBorder, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with Date, Time, and Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [conf.$1.withValues(alpha: 0.4), Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: const Border(
                  bottom: BorderSide(color: _kBorder, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: conf.$1.withValues(alpha: 0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(Icons.event_rounded, color: conf.$2, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          visit.scheduledDate,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: _kTextDark,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          visit.scheduledTime,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kTextMid,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: conf.$1,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(conf.$3, size: 14, color: conf.$2),
                        const SizedBox(width: 4),
                        Text(
                          visit.status.isEmpty
                              ? 'UNKNOWN'
                              : visit.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: conf.$2,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Property Card Section
            if (visit.property != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Linked Property',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _kTextMid,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // We wrap PropertyCard in an AbsorbPointer or just let it be fully functional.
                    // We apply a slight border and clip so it looks neat inside our white container.
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _kBorder, width: 0.8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: PropertyCard(
                          property: visit.property!,
                          onTap: () =>
                              context.push('/property/${visit.property!.id}'),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(
                      Icons.broken_image_rounded,
                      color: _kTextMid,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Property ID: ${visit.propertyId}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _kTextMid,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
