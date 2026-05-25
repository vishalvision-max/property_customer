import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/validators/validators.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/primary_button.dart';
import '../../../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _valid = false;

  @override
  void initState() {
    super.initState();
    _email.addListener(() {
      final ok = Validators.email(_email.text) == null;
      if (ok != _valid) setState(() => _valid = ok);
    });
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    ref.listen(authProvider, (prev, next) {
      final err = next.error;
      if (err != null && err.isNotEmpty) {
        AppSnackbar.showError(context, err.replaceFirst('Exception: ', ''));
      } else if (prev?.isLoading == true && next.isLoading == false) {
        final msg = (next.message ?? '').trim();
        AppSnackbar.showMessage(
          context,
          msg.isNotEmpty ? msg : 'Reset link sent successfully',
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.pagePadding,
          children: [
            Text(
              'Recover your account',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your email and we’ll send a reset link.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: 18),
            GlassContainer(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: Validators.email,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Send reset link',
                      isLoading: auth.isLoading,
                      onPressed: _valid
                          ? () async {
                              if (!_formKey.currentState!.validate()) return;
                              await ref.read(authProvider.notifier).forgotPassword(email: _email.text.trim());
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
