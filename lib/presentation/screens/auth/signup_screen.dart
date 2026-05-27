import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/validators/validators.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/primary_button.dart';
import '../../../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _valid = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    for (final c in [_name, _email, _password, _confirm]) {
      c.addListener(_recompute);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _recompute() {
    final ok = Validators.name(_name.text) == null &&
        Validators.email(_email.text) == null &&
        Validators.password(_password.text) == null &&
        Validators.confirmPassword(_confirm.text, _password.text) == null;
    if (ok != _valid) setState(() => _valid = ok);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    ref.listen(authProvider, (prev, next) {
      final err = next.error;
      if (err != null && err.isNotEmpty) {
        AppSnackbar.showError(context, err.replaceFirst('Exception: ', ''));
      }
      if ((prev?.user == null) && next.user != null) {
        context.go('/home');
      }
    });

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.pagePadding,
          children: [
            Text('Create account', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Join to save favorites and schedule visits.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).hintColor)),
            const SizedBox(height: 18),
            GlassContainer(
              child: Form(
                key: _formKey,
                onChanged: _recompute,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: Validators.name,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: Validators.email,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        ),
                      ),
                      validator: Validators.password,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirm,
                      obscureText: _obscure,
                      decoration: const InputDecoration(labelText: 'Confirm Password'),
                      validator: (v) => Validators.confirmPassword(v, _password.text),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Sign up',
                      isLoading: auth.isLoading,
                      onPressed: _valid
                          ? () async {
                              if (!_formKey.currentState!.validate()) return;
                              await ref.read(authProvider.notifier).signup(
                                    name: _name.text.trim(),
                                    email: _email.text.trim(),
                                    password: _password.text,
                                    passwordConfirmation: _confirm.text,
                                  );
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Already have an account? ', style: Theme.of(context).textTheme.bodyMedium),
                TextButton(onPressed: () => context.pop(), child: const Text('Login')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

