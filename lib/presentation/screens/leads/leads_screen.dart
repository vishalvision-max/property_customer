import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/lead_provider.dart';
import '../../widgets/error_retry.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/shimmer_list.dart';

class LeadsScreen extends ConsumerStatefulWidget {
  const LeadsScreen({super.key});

  @override
  ConsumerState<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends ConsumerState<LeadsScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      final user = ref.read(authProvider).user;
      if (user != null && user.token.trim().isNotEmpty) {
        ref.read(leadNotifierProvider.notifier).loadMyLeads();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final state = ref.watch(leadNotifierProvider);

    ref.listen(authProvider, (prev, next) {
      final wasAuthed = prev?.user != null;
      final isAuthed = next.user != null;
      if (!wasAuthed && isAuthed) {
        ref.read(leadNotifierProvider.notifier).loadMyLeads(page: 1);
      }
    });

    ref.listen(leadNotifierProvider, (prev, next) {
      final err = next.error;
      if (err != null && err.trim().isNotEmpty) {
        AppSnackbar.showError(context, err);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(auth.user == null ? 'Leads' : 'My Leads'),
        actions: [
          IconButton(
            onPressed: () => context.push('/leads/new'),
            icon: const Icon(Icons.add_rounded),
            tooltip: 'New Lead',
          ),
        ],
      ),
      body: SafeArea(
        child: auth.user == null
            ? Padding(
                padding: AppSpacing.pagePadding,
                child: GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 28),
                      const SizedBox(height: 10),
                      Text(
                        'Create a lead',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'You can fill the lead form now. We’ll ask you to login before submitting.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => context.push('/leads/new'),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('New Lead'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  context.push('/login?from=/leads'),
                              child: const Text('Login'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(leadNotifierProvider.notifier).loadMyLeads(page: 1),
                child: Builder(
                  builder: (context) {
                    if (state.isLoading && state.items.isEmpty) {
                      return const ShimmerList(itemCount: 8);
                    }
                    if (state.error != null && state.items.isEmpty) {
                      return ErrorRetry(
                        title: 'Failed to load leads',
                        message: state.error!,
                        onRetry: () =>
                            ref.read(leadNotifierProvider.notifier).loadMyLeads(),
                      );
                    }
                    if (state.items.isEmpty) {
                      return const Center(child: Text('No leads yet'));
                    }
                    return ListView.separated(
                      padding: AppSpacing.pagePadding,
                      itemCount: state.items.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final lead = state.items[index];
                        return _LeadCard(
                          name: lead.name,
                          phone: lead.phone,
                          city: lead.city,
                          type: lead.type,
                          propertyType: lead.propertyType,
                          status: lead.status,
                          createdAt: lead.createdAt,
                          onUpdateStatus: () async {
                            final picked = await _pickStatus(
                              context,
                              current: lead.status,
                            );
                            if (picked == null) return;
                            try {
                              await ref
                                  .read(leadNotifierProvider.notifier)
                                  .updateStatus(
                                    leadId: lead.id,
                                    status: picked,
                                  );
                              if (!context.mounted) return;
                              AppSnackbar.showMessage(
                                context,
                                'Status updated',
                              );
                            } catch (_) {}
                          },
                        );
                      },
                    );
                  },
                ),
              ),
      ),
    );
  }

  Future<String?> _pickStatus(
    BuildContext context, {
    required String current,
  }) async {
    const statuses = ['assigned', 'contacted', 'converted', 'closed'];
    final cur = current.toLowerCase();
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text(
                  'Update status',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text('Select new status for this lead'),
              ),
              ...statuses.map((s) {
                final selected = cur == s;
                return ListTile(
                  leading: Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                  ),
                  title: Text(s),
                  onTap: () => Navigator.of(context).pop(s),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _LeadCard extends StatelessWidget {
  final String name;
  final String phone;
  final String city;
  final String type;
  final String propertyType;
  final String status;
  final DateTime createdAt;
  final VoidCallback onUpdateStatus;

  const _LeadCard({
    required this.name,
    required this.phone,
    required this.city,
    required this.type,
    required this.propertyType,
    required this.status,
    required this.createdAt,
    required this.onUpdateStatus,
  });

  Color _statusBg(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return switch (status.toLowerCase()) {
      'assigned' => cs.primaryContainer,
      'contacted' => Colors.orange.shade100,
      'converted' => Colors.green.shade100,
      'closed' => Colors.grey.shade300,
      _ => cs.surfaceContainerHighest,
    };
  }

  Color _statusFg(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return switch (status.toLowerCase()) {
      'assigned' => cs.onPrimaryContainer,
      'contacted' => Colors.orange.shade900,
      'converted' => Colors.green.shade900,
      'closed' => Colors.grey.shade800,
      _ => cs.onSurfaceVariant,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return GlassContainer(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name.isEmpty ? 'Lead' : name,
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _statusBg(context),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status.isEmpty ? 'unknown' : status,
                  style: t.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: _statusFg(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(icon: Icons.phone_rounded, text: phone),
              if (city.trim().isNotEmpty)
                _Chip(icon: Icons.location_on_rounded, text: city),
              if (type.trim().isNotEmpty)
                _Chip(icon: Icons.sell_rounded, text: type),
              if (propertyType.trim().isNotEmpty)
                _Chip(icon: Icons.home_rounded, text: propertyType),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Created ${DateFormat('MMM d, yyyy').format(createdAt)}',
                style: t.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onUpdateStatus,
                icon: const Icon(Icons.sync_alt_rounded, size: 18),
                label: const Text('Update'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Chip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
