import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/validators/validators.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/primary_button.dart';

const _kPrimary = Color(0xFF6C5CE7);
const _kBg = Color(0xFFF6F7FB);
const _kTextDark = Color(0xFF1A1A2E);
const _kBorder = Color(0xFFE5E7EB);

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _old = TextEditingController();
  final _new = TextEditingController();
  bool _obscure = true;
  bool _valid = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _old.addListener(_recompute);
    _new.addListener(_recompute);
  }

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    super.dispose();
  }

  void _recompute() {
    final ok = _old.text.trim().isNotEmpty && Validators.password(_new.text) == null;
    if (ok != _valid) setState(() => _valid = ok);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w900, color: _kTextDark)),
      ),
      body: ListView(
        padding: AppSpacing.pagePadding,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _kBorder),
            ),
            child: Form(
              key: _formKey,
              onChanged: _recompute,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Field(
                    controller: _old,
                    label: 'Old password',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscure,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Old password is required' : null,
                    enabled: !_saving,
                  ),
                  const SizedBox(height: 12),
                  _Field(
                    controller: _new,
                    label: 'New password',
                    icon: Icons.lock_reset_rounded,
                    obscureText: _obscure,
                    validator: Validators.password,
                    enabled: !_saving,
                    suffix: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    label: 'Update password',
                    isLoading: _saving,
                    onPressed: _valid ? () async {
                      if (!_formKey.currentState!.validate()) return;
                      final token = ref.read(authProvider).user?.token;
                      if (token == null || token.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login again'), behavior: SnackBarBehavior.floating));
                        return;
                      }
                      final messenger = ScaffoldMessenger.of(context);
                      setState(() => _saving = true);
                      try {
                        final message = await ref.read(ownerRepositoryProvider).updatePassword(
                          token: token.trim(),
                          currentPassword: _old.text.trim(),
                          password: _new.text.trim(),
                          passwordConfirmation: _new.text.trim(),
                        );
                        if (!mounted) return;
                        messenger.showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
                        context.go('/profile');
                      } catch (e) {
                        if (!mounted) return;
                        messenger.showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), behavior: SnackBarBehavior.floating));
                      }
                      if (!mounted) return;
                      setState(() => _saving = false);
                    } : null,
                    leading: const Icon(Icons.shield_rounded),
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

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final bool enabled;
  final String? Function(String?)? validator;
  final Widget? suffix;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    required this.obscureText,
    required this.enabled,
    this.validator,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _kPrimary),
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
