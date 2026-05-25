import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/validators/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/lead_provider.dart';
import '../../widgets/primary_button.dart';

// Styling close to HomeScreen design tokens with a premium touch
const _kPrimary = Color(0xFF6C5CE7);
const _kBg = Color(0xFFF6F7FB);
const _kTextDark = Color(0xFF1A1A2E);
const _kTextMid = Color(0xFF6B7280);
const _kBorder = Color(0xFFE5E7EB);

class LeadCreateScreen extends ConsumerStatefulWidget {
  final String? propertyId;
  final String? type;

  const LeadCreateScreen({
    super.key,
    this.propertyId,
    this.type,
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
  late final TextEditingController _typeController;

  @override
  void initState() {
    super.initState();
    // Pre-populate read-only fields
    _propertyIdController = TextEditingController(text: widget.propertyId ?? '0');
    _typeController = TextEditingController(text: widget.type ?? 'sale');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _message.dispose();
    _propertyIdController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  String? _required(String? v, String fieldName) =>
      (v == null || v.trim().isEmpty) ? '$fieldName is required' : null;

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(leadProvider).isLoading;
    final isAuthed = ref.watch(authProvider).user != null;

    Future<void> submit() async {
      if (!(_formKey.currentState?.validate() ?? false)) {
        return;
      }
      try {
        if (!isAuthed) {
          AppSnackbar.showError(context, 'Please login to submit the lead');
          context.push('/login?from=${Uri.encodeComponent('/leads/new?property_id=${widget.propertyId}&type=${widget.type}')}');
          return;
        }

        final propertyId = int.tryParse(_propertyIdController.text.trim()) ?? 0;
        final type = _typeController.text.trim().toLowerCase();

        await ref.read(leadProvider.notifier).createBuyerLead(
              name: _name.text.trim(),
              phone: _phone.text.trim(),
              email: _email.text.trim(),
              message: _message.text.trim(),
              type: type,
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
      backgroundColor: _kBg,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: PrimaryButton(
            label: 'Submit Lead',
            isLoading: busy,
            onPressed: busy ? null : submit,
            leading: const Icon(Icons.send_rounded, color: Colors.white),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Create Buyer Lead',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: _kTextDark,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: 120,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/leadBanner.jpeg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
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
                              Colors.black.withValues(alpha: 0.10),
                              Colors.black.withValues(alpha: 0.65),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text(
                              'Inquire About Property',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isAuthed
                                  ? 'Enter your buyer inquiry details below.'
                                  : 'Login is required before submitting.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.pagePadding,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Buyer Inquiry Details',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: _kTextDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _Field(
                        controller: _name,
                        label: 'Name',
                        icon: Icons.person_outline_rounded,
                        validator: Validators.name,
                        textInputAction: TextInputAction.next,
                        enabled: !busy,
                      ),
                      const SizedBox(height: 16),
                      _Field(
                        controller: _phone,
                        label: 'Phone Number',
                        icon: Icons.phone_outlined,
                        validator: (v) => _required(v, 'Phone number'),
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        enabled: !busy,
                      ),
                      const SizedBox(height: 16),
                      _Field(
                        controller: _email,
                        label: 'Email Address',
                        icon: Icons.mail_outline_rounded,
                        validator: Validators.email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        enabled: !busy,
                      ),
                      const SizedBox(height: 16),
                      _Field(
                        controller: _message,
                        label: 'Message',
                        icon: Icons.notes_outlined,
                        validator: (v) => _required(v, 'Message'),
                        textInputAction: TextInputAction.newline,
                        enabled: !busy,
                        minLines: 3,
                        maxLines: 5,
                      ),
                      const SizedBox(height: 24),
                      const Divider(color: _kBorder, height: 1),
                      const SizedBox(height: 16),
                      const Text(
                        'Linked Property Details',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: _kTextDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _Field(
                        controller: _typeController,
                        label: 'Type',
                        icon: Icons.category_outlined,
                        enabled: false,
                        readOnly: true,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'The listing type is read-only and automatically filled from the active property details.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _kTextMid,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool enabled;
  final bool readOnly;
  final int? minLines;
  final int? maxLines;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.enabled = true,
    this.readOnly = false,
    this.minLines,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      readOnly: readOnly,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      minLines: minLines,
      maxLines: maxLines ?? 1,
      style: TextStyle(
        color: readOnly ? _kTextMid : _kTextDark,
        fontWeight: readOnly ? FontWeight.w600 : FontWeight.normal,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: readOnly ? _kTextMid.withValues(alpha: 0.7) : _kPrimary),
        filled: readOnly,
        fillColor: readOnly ? Colors.grey.withValues(alpha: 0.1) : Colors.transparent,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kPrimary, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kBorder),
        ),
      ),
    );
  }
}
