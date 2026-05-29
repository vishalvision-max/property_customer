import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/property_provider.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/primary_button.dart';

class ScheduleVisitScreen extends ConsumerStatefulWidget {
  final String propertyId;
  const ScheduleVisitScreen({super.key, required this.propertyId});

  @override
  ConsumerState<ScheduleVisitScreen> createState() => _ScheduleVisitScreenState();
}

class _ScheduleVisitScreenState extends ConsumerState<ScheduleVisitScreen> {
  DateTime? _date;
  String? _slot;
  bool _submitting = false;

  static const _slots = <String>['09:00 AM', '11:00 AM', '01:00 PM', '03:00 PM', '05:00 PM', '07:00 PM'];

  bool get _valid => _date != null && _slot != null;

  @override
  Widget build(BuildContext context) {
    final property = ref.watch(propertyNotifierProvider.notifier).getById(widget.propertyId);
    final fmt = DateFormat('EEE, MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Visit')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            if (property != null)
              GlassContainer(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.home_work_outlined),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(property.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 2),
                          Text(property.location, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select date', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_rounded),
                    title: Text(_date == null ? 'Choose a date' : fmt.format(_date!)),
                    subtitle: const Text('Future dates only'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final errorColor = Theme.of(context).colorScheme.error;
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: now.add(const Duration(days: 1)),
                        firstDate: DateTime(now.year, now.month, now.day).add(const Duration(days: 1)),
                        lastDate: now.add(const Duration(days: 365)),
                      );
                      if (!mounted) return;
                      if (picked == null) return;
                      if (picked.isBefore(DateTime(now.year, now.month, now.day + 1))) {
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
                  ),
                  const SizedBox(height: 10),
                  Text('Time slot', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final s in _slots)
                        ChoiceChip(
                          label: Text(s),
                          selected: _slot == s,
                          onSelected: (_) => setState(() => _slot = s),
                        ),
                    ],
                  ),
                  if (_slot == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text('Please select a time slot', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            PrimaryButton(
              label: 'Confirm visit',
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
                            content: const Text('Please login to schedule a visit'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: errorColor,
                          ),
                        );
                        return;
                      }

                      setState(() => _submitting = true);
                      try {
                        final formattedDate = DateFormat('yyyy-MM-dd').format(_date!);
                        // Convert '09:00 AM' format to 'HH:mm' for backend
                        final timeParsed = DateFormat('hh:mm a').parse(_slot!);
                        final formattedTime = DateFormat('HH:mm').format(timeParsed);

                        await ref.read(propertyNotifierProvider.notifier).scheduleVisit(
                          token: user.token,
                          propertyId: widget.propertyId,
                          userId: user.id,
                          date: formattedDate,
                          time: formattedTime,
                        );

                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Visit scheduled for ${fmt.format(_date!)} at $_slot'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        router.pop();
                      } catch (e) {
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Failed to schedule visit. Please try again.'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: errorColor,
                          ),
                        );
                      } finally {
                        if (mounted) setState(() => _submitting = false);
                      }
                    }
                  : null,
              leading: const Icon(Icons.check_circle_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
