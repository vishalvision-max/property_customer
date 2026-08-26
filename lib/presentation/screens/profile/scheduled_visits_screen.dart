import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../providers/scheduled_visits_provider.dart';
import '../../../data/models/scheduled_visit.dart';

const _kPrimary = Color(0xFFFF8000);
const _kBg = Color(0xFFF9FAFB);
const _kTextDark = Color(0xFF1F2937);
const _kTextMid = Color(0xFF6B7280);

class ScheduledVisitsScreen extends ConsumerStatefulWidget {
  const ScheduledVisitsScreen({super.key});

  @override
  ConsumerState<ScheduledVisitsScreen> createState() =>
      _ScheduledVisitsScreenState();
}

class _ScheduledVisitsScreenState extends ConsumerState<ScheduledVisitsScreen> {
  bool _isUpcoming = true;

  @override
  Widget build(BuildContext context) {
    final visitsAsync = ref.watch(scheduledVisitsNotifierProvider);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'My Scheduled Visits',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: visitsAsync.when(
              data: (visits) {
                if (visits.isEmpty) {
                  return const Center(
                    child: Text('No scheduled visits found.'),
                  );
                }

                final sortedVisits = List<ScheduledVisit>.from(visits)
                  ..sort((a, b) {
                    final da =
                        DateTime.tryParse(
                          '${a.scheduledDate} ${a.scheduledTime}',
                        ) ??
                        DateTime.tryParse(a.scheduledDate) ??
                        DateTime(1970);
                    final db =
                        DateTime.tryParse(
                          '${b.scheduledDate} ${b.scheduledTime}',
                        ) ??
                        DateTime.tryParse(b.scheduledDate) ??
                        DateTime(1970);
                    return db.compareTo(da);
                  });

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: sortedVisits.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return _VisitCard(visit: sortedVisits[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) =>
                  Center(child: Text('Error loading visits')),
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

  (Color bg, Color fg, String text) _statusConfig(String st) {
    final status = st.toLowerCase();
    if (status == 'confirmed')
      return (const Color(0xFFD1FAE5), const Color(0xFF059669), 'Confirmed');
    if (status == 'pending')
      return (const Color(0xFFFEF3C7), const Color(0xFFD97706), 'Pending');
    if (status == 'scheduled')
      return (const Color(0xFFE0F2FE), const Color(0xFF0284C7), 'Scheduled');
    return (Colors.grey[200]!, Colors.grey[700]!, status.toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    final conf = _statusConfig(
      visit.status.isEmpty ? 'scheduled' : visit.status,
    );

    DateTime? date;
    try {
      date = DateTime.parse(visit.scheduledDate);
    } catch (_) {}

    final dayStr = date != null ? DateFormat('dd').format(date) : '11';
    final monthStr = date != null
        ? DateFormat('MMM').format(date).toUpperCase()
        : 'JUN';

    final p = visit.property;
    final cat = p?.categoryName ?? '';
    final kind = p?.propertyKind ?? '';
    final title = cat.isNotEmpty ? cat : (kind.isNotEmpty ? kind : 'Property');
    final location = visit.property?.location ?? 'Sector 5, Panchkula';
    String timeStr = visit.scheduledTime.isNotEmpty
        ? visit.scheduledTime
        : '11:00 AM';
    if (!timeStr.toLowerCase().contains('am') &&
        !timeStr.toLowerCase().contains('pm')) {
      try {
        final parsedTime = DateFormat('HH:mm:ss').parse(timeStr);
        timeStr = DateFormat('hh:mm a').format(parsedTime);
      } catch (_) {
        try {
          final parsedTime = DateFormat('HH:mm').parse(timeStr);
          timeStr = DateFormat('hh:mm a').format(parsedTime);
        } catch (_) {}
      }
    }

    return GestureDetector(
      onTap: () {
        if (visit.propertyId.isNotEmpty) {
          context.push('/property/${visit.propertyId}');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Column
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: _kPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  dayStr,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _kTextDark,
                  ),
                ),
                Text(
                  monthStr,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kTextMid,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Details Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _kTextDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location,
                    style: const TextStyle(fontSize: 12, color: _kTextMid),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _kTextDark,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: conf.$1,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          conf.$3,
                          style: TextStyle(
                            color: conf.$2,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            side: const BorderSide(color: _kPrimary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Reschedule',
                            style: TextStyle(
                              color: _kPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final phone = visit.property?.ownerPhone;
                            if (phone != null && phone.isNotEmpty) {
                              final uri = Uri.parse('tel:$phone');
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            backgroundColor: _kPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Call Agent',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
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
