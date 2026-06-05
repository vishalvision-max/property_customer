import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/lead_provider.dart';
import '../../widgets/error_retry.dart';
import '../../widgets/shimmer_list.dart';

const _kPrimary = Color(0xFF6C5CE7);
const _kBg = Color(0xFFF6F8FA);
const _kTextDark = Color(0xFF1A1A2E);
const _kTextMid = Color(0xFF6B7280);
const _kBorder = Color(0xFFE5E7EB);

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
      backgroundColor: _kBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: true,
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16, right: 20),
              title: const Text(
                'Property Enquiries',
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
                    colors: [
                      _kPrimary.withValues(alpha: 0.08),
                      Colors.white,
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (auth.user == null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildUnauthorizedState(context),
            )
          else
            _buildListContent(context, state),
        ],
      ),
    );
  }

  Widget _buildUnauthorizedState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withValues(alpha: 0.08),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kPrimary.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.lock_person_rounded,
                  size: 48,
                  color: _kPrimary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Authentication Required',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _kTextDark,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Please log in to view your property enquiries and track lead statuses.',
                style: TextStyle(
                  fontSize: 15,
                  color: _kTextMid,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => context.push('/login?from=/leads'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Login Now',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListContent(BuildContext context, LeadState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: ShimmerList(itemCount: 8),
        ),
      );
    }
    if (state.error != null && state.items.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
          child: ErrorRetry(
            title: 'Failed to load enquiries',
            message: state.error!,
            onRetry: () => ref.read(leadNotifierProvider.notifier).loadMyLeads(),
          ),
        ),
      );
    }
    if (state.items.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text('No inquiry found'),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final lead = state.items[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _LeadCard(
                name: lead.name,
                phone: lead.phone,
                email: lead.email,
                message: lead.message,
                city: lead.city,
                type: lead.type,
                propertyType: lead.propertyType,
                status: lead.status,
                createdAt: lead.createdAt,
                onUpdateStatus: () async {
                  final picked = await _pickStatus(context, current: lead.status);
                  if (picked == null) return;
                  try {
                    await ref
                        .read(leadNotifierProvider.notifier)
                        .updateStatus(leadId: lead.id, status: picked);
                    if (!context.mounted) return;
                    AppSnackbar.showMessage(context, 'Status updated');
                  } catch (e) {
                    if (!context.mounted) return;
                    AppSnackbar.showError(
                      context,
                      e.toString().replaceFirst('Exception: ', ''),
                    );
                  }
                },
              ),
            );
          },
          childCount: state.items.length,
        ),
      ),
    );
  }

  Future<String?> _pickStatus(BuildContext context, {required String current}) async {
    const statuses = ['assigned', 'contacted', 'converted', 'closed'];
    final cur = current.toLowerCase();
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Update Lead Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _kTextDark,
                  ),
                ),
                const SizedBox(height: 20),
                ...statuses.map((s) {
                  final selected = cur == s;
                  return InkWell(
                    onTap: () => Navigator.of(context).pop(s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: selected ? _kPrimary.withValues(alpha: 0.05) : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selected ? _kPrimary : Colors.grey.shade100,
                            ),
                            child: Icon(
                              selected ? Icons.check_rounded : Icons.label_outline_rounded,
                              size: 16,
                              color: selected ? Colors.white : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            s.toUpperCase(),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                              color: selected ? _kPrimary : _kTextDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LeadCard extends StatelessWidget {
  final String name;
  final String phone;
  final String? email;
  final String? message;
  final String city;
  final String type;
  final String propertyType;
  final String status;
  final DateTime createdAt;
  final VoidCallback onUpdateStatus;

  const _LeadCard({
    required this.name,
    required this.phone,
    this.email,
    this.message,
    required this.city,
    required this.type,
    required this.propertyType,
    required this.status,
    required this.createdAt,
    required this.onUpdateStatus,
  });

  (Color bg, Color fg, IconData icon) _statusConfig(String st) {
    switch (st.toLowerCase()) {
      case 'assigned':
        return (const Color(0xFFE0E7FF), const Color(0xFF4338CA), Icons.assignment_ind_rounded);
      case 'contacted':
        return (const Color(0xFFFEF3C7), const Color(0xFFB45309), Icons.phone_in_talk_rounded);
      case 'converted':
        return (const Color(0xFFD1FAE5), const Color(0xFF059669), Icons.verified_rounded);
      case 'closed':
        return (const Color(0xFFF3F4F6), const Color(0xFF4B5563), Icons.do_not_disturb_alt_rounded);
      default:
        return (const Color(0xFFF3F4F6), const Color(0xFF4B5563), Icons.info_outline_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final conf = _statusConfig(status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: conf.$1.withValues(alpha: 0.5),
                border: Border(
                  bottom: BorderSide(color: conf.$1, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Icon(conf.$3, size: 16, color: conf.$2),
                  const SizedBox(width: 8),
                  Text(
                    status.isEmpty ? 'UNKNOWN STATUS' : status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: conf.$2,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('MMM d, yyyy').format(createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: conf.$2.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_kPrimary, Color(0xFF9B8DF8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _kPrimary.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.isEmpty ? 'Lead' : name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: _kTextDark,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              phone,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _kTextMid,
                              ),
                            ),
                            if (email != null && email!.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  email!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: _kTextMid,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Chips for property info
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (city.trim().isNotEmpty)
                        _buildInfoChip(Icons.location_on_rounded, city),
                      if (type.trim().isNotEmpty)
                        _buildInfoChip(Icons.sell_rounded, type),
                      if (propertyType.trim().isNotEmpty)
                        _buildInfoChip(Icons.domain_rounded, propertyType),
                    ],
                  ),
                  
                  if (message != null && message!.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kPrimary.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 16, color: _kPrimary.withValues(alpha: 0.7)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              message!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: _kTextDark,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: _kBorder),
                  const SizedBox(height: 12),
                  
                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: TextButton.icon(
                      onPressed: onUpdateStatus,
                      icon: const Icon(Icons.sync_alt_rounded, size: 18),
                      label: const Text(
                        'Update Status',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: _kPrimary,
                        backgroundColor: _kPrimary.withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _kPrimary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kTextDark,
            ),
          ),
        ],
      ),
    );
  }
}
