import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_snackbar.dart';
import '../../../core/validators/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/lead_provider.dart';
import '../../widgets/app_location_header.dart';
import '../../widgets/white_pill_button.dart';

const _kPrimary = Color(0xFFFF8000);
const _kTextDark = Color(0xFF1A1A2E);
const _kTextMid = Color(0xFF6B7280);
const _kBorder = Color(0xFFE5E7EB);
const _kFieldFill = Color(0xFFF2F3F5);

class LeadCreateScreen extends ConsumerStatefulWidget {
  final String? propertyId;
  final String? type;

  /// False when embedded as a persistent bottom-nav tab (Listing) — there's
  /// nothing to pop back to from a tab, so the back button is hidden.
  final bool showBackButton;

  const LeadCreateScreen({
    super.key,
    this.propertyId,
    this.type,
    this.showBackButton = true,
  });

  @override
  ConsumerState<LeadCreateScreen> createState() => _LeadCreateScreenState();
}

class _LeadCreateScreenState extends ConsumerState<LeadCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _message = TextEditingController();

  late final TextEditingController _propertyIdController;

  // User-selectable type — pre-filled from the linked property but editable
  late String _selectedType;

  static const _typeOptions = [
    ('Sale', 'sale'),
    ('Rent', 'rent'),
    ('Lease', 'lease'),
    ('PG', 'pg'),
    ('Co-Living', 'co-living'),
    ('Industrial Shed', 'industrial_shed'),
    ('Agricultural Land', 'agricultural_land'),
  ];

  @override
  void initState() {
    super.initState();
    _propertyIdController = TextEditingController(
      text: widget.propertyId ?? '0',
    );
    // Normalize the incoming type; default to 'sale'
    final incoming = (widget.type ?? 'sale').toLowerCase().trim();
    _selectedType = _typeOptions.any((o) => o.$2 == incoming)
        ? incoming
        : 'sale';
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _message.dispose();
    _propertyIdController.dispose();
    super.dispose();
  }

  String? _required(String? v, String fieldName) =>
      (v == null || v.trim().isEmpty) ? '$fieldName is required' : null;

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(leadNotifierProvider).isLoading;
    final isAuthed = ref.watch(authProvider).user != null;

    Future<void> submit() async {
      if (!(_formKey.currentState?.validate() ?? false)) {
        return;
      }
      try {
        if (!isAuthed) {
          AppSnackbar.showError(context, 'Please login to submit the lead');
          context.push(
            '/login?from=${Uri.encodeComponent('/leads/new?property_id=${widget.propertyId}&type=${widget.type}')}',
          );
          return;
        }

        final propertyId = int.tryParse(_propertyIdController.text.trim()) ?? 0;

        await ref
            .read(leadNotifierProvider.notifier)
            .createBuyerLead(
              name: _name.text.trim(),
              phone: _phone.text.trim(),
              email: _email.text.trim(),
              message: _message.text.trim(),
              type: _selectedType,
              propertyId: propertyId,
            );

        if (!context.mounted) return;
        AppSnackbar.showMessage(context, 'Lead created successfully!');
        Navigator.of(context).pop(true);
      } catch (e) {
        if (!context.mounted) return;
        final msg = e.toString().replaceFirst('Exception: ', '');
        AppSnackbar.showError(context, msg);
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
          child: WhitePillButton(
            label: 'Submit Lead',
            loading: busy,
            onTap: busy ? () {} : submit,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: AppLocationHeader()),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 260,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/icons/submit_lead_banner.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_kPrimary, Color(0xFFFFB366)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.05),
                          Colors.black.withValues(alpha: 0.70),
                        ],
                      ),
                    ),
                  ),
                  if (widget.showBackButton)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: GestureDetector(
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/home');
                          }
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.28),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'List Your Property',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isAuthed
                              ? 'Share your property details and connect with interested buyers and Seller.'
                              : 'Login is required before submitting.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                            fontSize: 13.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Property Details',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                        color: _kTextDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // ── Selectable Type Chips ──────────────────────────
                    Row(
                      children: [
                        const Icon(
                          Icons.widgets_outlined,
                          size: 18,
                          color: _kPrimary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Listing Type',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _kTextMid,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    StatefulBuilder(
                      builder: (context, setChipState) {
                        return Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: _typeOptions.map((option) {
                            final label = option.$1;
                            final value = option.$2;
                            final isSelected = _selectedType == value;
                            return GestureDetector(
                              onTap: () {
                                setChipState(() => _selectedType = value);
                                setState(() {});
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeInOut,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFFFF8000),
                                            Color(0xFFFFB366),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: isSelected ? null : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.transparent
                                        : _kBorder,
                                    width: 1.5,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xFFFF8000,
                                            ).withValues(alpha: 0.30),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSelected) ...[
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        size: 15,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? Colors.white
                                            : _kTextMid,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select the listing type for this inquiry.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _kTextMid,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: _kBorder, height: 1),
                    const SizedBox(height: 24),
                    _Field(
                      controller: _name,
                      label: 'Name',
                      hint: 'Enter your name',
                      validator: Validators.name,
                      textInputAction: TextInputAction.next,
                      enabled: !busy,
                    ),
                    const SizedBox(height: 16),
                    _Field(
                      controller: _phone,
                      label: 'Phone',
                      hint: 'Enter your phone number',
                      validator: (v) => _required(v, 'Phone number'),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      enabled: !busy,
                      maxLength: 10,
                    ),
                    const SizedBox(height: 16),
                    _Field(
                      controller: _email,
                      label: 'Email Address',
                      hint: 'Enter your email address',
                      validator: Validators.email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      enabled: !busy,
                    ),
                    const SizedBox(height: 16),
                    _Field(
                      controller: _message,
                      label: 'Message',
                      hint: 'Enter your message',
                      validator: (v) => _required(v, 'Message'),
                      textInputAction: TextInputAction.newline,
                      enabled: !busy,
                      minLines: 3,
                      maxLines: 5,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool enabled;
  final int? minLines;
  final int? maxLines;
  final int? maxLength;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.enabled = true,
    this.minLines,
    this.maxLines,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _kTextMid,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _kFieldFill,
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            validator: validator,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            minLines: minLines,
            maxLines: maxLines ?? 1,
            maxLength: maxLength,
            style: const TextStyle(
              color: _kTextDark,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: _kTextMid,
                fontWeight: FontWeight.w500,
              ),
              filled: false,
              counterText: '',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
