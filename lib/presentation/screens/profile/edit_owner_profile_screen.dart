import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/owner_profile_provider.dart';
import '../../widgets/primary_button.dart';

// Keep styling close to HomeScreen design tokens
const _kBg = Color(0xFFF6F7FB);
const _kTextDark = Color(0xFF1A1A2E);
const _kBorder = Color(0xFFE5E7EB);

class EditOwnerProfileScreen extends ConsumerStatefulWidget {
  const EditOwnerProfileScreen({super.key});

  @override
  ConsumerState<EditOwnerProfileScreen> createState() =>
      _EditOwnerProfileScreenState();
}

class _EditOwnerProfileScreenState
    extends ConsumerState<EditOwnerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final token = ref.read(authProvider).user?.token;
      if (token != null && token.trim().isNotEmpty) {
        ref
            .read(ownerProfileNotifierProvider.notifier)
            .load(token: token.trim());
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ownerState = ref.watch(ownerProfileNotifierProvider);

    ref.listen(ownerProfileNotifierProvider, (prev, next) {
      final p = next.profile;
      if (p != null) {
        if (p.name.trim().isNotEmpty && _name.text.trim().isEmpty) {
          _name.text = p.name.trim();
        }
        if (p.email.trim().isNotEmpty &&
            _email.text.trim().isEmpty &&
            !p.email.endsWith('@example.com')) {
          _email.text = p.email.trim();
        }
      }
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!.replaceFirst('Exception: ', '')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final isProfileIncomplete =
        (ownerState.profile?.name.trim().isEmpty ?? true) ||
        (ownerState.profile?.email.trim().isEmpty ?? true) ||
        (ownerState.profile?.email.endsWith('@example.com') ?? false);

    final canSubmit =
        !_saving &&
        !ownerState.isLoading &&
        _name.text.trim().isNotEmpty &&
        _email.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.w900, color: _kTextDark),
        ),
      ),
      body: ListView(
        padding: AppSpacing.pagePadding,
        children: [
          if (isProfileIncomplete)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red, Colors.red.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.priority_high_rounded,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Complete Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Update your name and email to continue.',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
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
                    'Owner Details',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: _kTextDark,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _name,
                    enabled: !_saving && !ownerState.isLoading,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Name is required'
                        : null,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _email,
                    enabled: !_saving && !ownerState.isLoading,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(v)) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Save Profile',
                    isLoading: _saving || ownerState.isLoading,
                    onPressed: canSubmit
                        ? () async {
                            if (!_formKey.currentState!.validate()) return;
                            final token = ref.read(authProvider).user?.token;
                            if (token == null || token.trim().isEmpty) return;

                            final router = GoRouter.of(context);
                            final messenger = ScaffoldMessenger.of(context);
                            setState(() => _saving = true);

                            final updated = await ref
                                .read(ownerProfileNotifierProvider.notifier)
                                .update(
                                  token: token.trim(),
                                  name: _name.text.trim(),
                                  email: _email.text.trim(),
                                );
                            if (!mounted) return;
                            setState(() => _saving = false);
                            if (updated != null) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Profile updated successfully'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              router.pop();
                            }
                          }
                        : null,
                    leading: const Icon(Icons.save_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
