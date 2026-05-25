import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/validators/validators.dart';
import '../../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _valid = false;
  bool _obscure = true;
  bool _loginRequested = false;

  @override
  void initState() {
    super.initState();
    _email.addListener(_recompute);
    _password.addListener(_recompute);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _recompute() {
    final ok =
        Validators.email(_email.text) == null &&
        Validators.password(_password.text) == null;
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
      final loginFinished = (prev?.isLoading ?? false) && !next.isLoading;
      if (_loginRequested &&
          loginFinished &&
          next.error == null &&
          next.user != null) {
        _loginRequested = false;
        final from = GoRouterState.of(context).uri.queryParameters['from'];
        context.go((from != null && from.isNotEmpty) ? from : '/home');
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              padding: AppSpacing.pagePadding,
              children: [
                const SizedBox(height: 40),

                /// Title
                Text(
                  'Welcome back',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Sign in to your account',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                ),

                const SizedBox(height: 32),

                /// Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    onChanged: _recompute,
                    child: Column(
                      children: [
                        /// Email
                        TextFormField(
                          controller: _email,
                          decoration: _inputDecoration('Email'),
                          validator: Validators.email,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                        ),

                        const SizedBox(height: 16),

                        /// Password
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          decoration: _inputDecoration('Password').copyWith(
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: Validators.password,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) async {
                            if (!_valid || auth.isLoading) return;
                            if (!_formKey.currentState!.validate()) return;
                            _loginRequested = true;
                            await ref
                                .read(authProvider.notifier)
                                .login(
                                  email: _email.text.trim(),
                                  password: _password.text,
                                );
                          },
                        ),

                        const SizedBox(height: 12),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push('/forgot'),
                            child: const Text('Forgot password?'),
                          ),
                        ),

                        const SizedBox(height: 12),

                        /// Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _valid && !auth.isLoading
                                ? () async {
                                    if (!_formKey.currentState!.validate()) {
                                      return;
                                    }
                                    _loginRequested = true;
                                    await ref
                                        .read(authProvider.notifier)
                                        .login(
                                          email: _email.text.trim(),
                                          password: _password.text,
                                        );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: auth.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// Signup
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'New here?',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    TextButton(
                      onPressed: () => context.push('/signup'),
                      child: const Text('Create account'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF1F3F5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
