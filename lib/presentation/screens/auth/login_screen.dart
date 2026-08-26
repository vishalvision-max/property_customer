import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/auth_provider.dart';
import '../../widgets/white_pill_button.dart';
import 'otp_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final phone = _phoneController.text.trim();
    final result = await ref.read(authProvider.notifier).sendOtp(phone: phone);
    if (!mounted) return;
    setState(() => _isLoading = false);

    final error = ref.read(authProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.replaceFirst('Exception: ', ''))),
      );
      return;
    }

    if (result.message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message!)));
    }

    if (!context.mounted) return;
    final from = GoRouterState.of(context).uri.queryParameters['from'];
    context.push(
      from != null && from.isNotEmpty
          ? '/verify-otp?from=${Uri.encodeComponent(from)}'
          : '/verify-otp',
      extra: VerifyOtpArgs(phone: phone, autoFillOtp: result.otp),
    );
  }

  static const _navy = Color(0xFF191D31);
  static const _grey = Color(0xFF666876);
  static const _orange = Color(0xFFFF8000);
  static const _fieldFill = Color(0xFFF2F3F5);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 0, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/onboarding');
                                }
                              },
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: _navy,
                                size: 26,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.go('/home'),
                              style: TextButton.styleFrom(
                                foregroundColor: _grey,
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text(
                                'Continue without login',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.only(right: 24),
                        child: Text.rich(
                          TextSpan(
                            style: const TextStyle(
                              color: _navy,
                              fontSize: 26,
                              height: 1.25,
                            ),
                            children: const [
                              TextSpan(
                                text: 'Welcome to Nestora\n',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              TextSpan(
                                text: "Let's Get You Closer\n",
                                style: TextStyle(fontWeight: FontWeight.w400),
                              ),
                              TextSpan(
                                text: 'To ',
                                style: TextStyle(fontWeight: FontWeight.w400),
                              ),
                              TextSpan(
                                text: 'Your Ideal Home',
                                style: TextStyle(
                                  color: _orange,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.only(right: 24),
                        child: const Text(
                          'Login or Sign up with your phone number',
                          style: TextStyle(
                            color: _grey,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                      Builder(
                        builder: (context) {
                          final screenW = MediaQuery.of(context).size.width;
                          final houseSize = screenW * 0.75;
                          return SizedBox(
                            height: houseSize,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned(
                                  left: screenW * 0.30,
                                  top: 0,
                                  width: houseSize,
                                  height: houseSize,
                                  child: Image.asset(
                                    'assets/icons/cuthouse.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      Form(
                        key: _formKey,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Phone Number',
                                style: TextStyle(
                                  color: _grey,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                decoration: BoxDecoration(
                                  color: _fieldFill,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 14,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '🇮🇳',
                                            style: TextStyle(fontSize: 20),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            '+91',
                                            style: TextStyle(
                                              color: _navy,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: _grey,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 26,
                                      color: Colors.black.withValues(
                                        alpha: 0.08,
                                      ),
                                    ),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _phoneController,
                                        keyboardType: TextInputType.phone,
                                        enabled: !_isLoading,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          LengthLimitingTextInputFormatter(10),
                                        ],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: _navy,
                                        ),
                                        decoration: const InputDecoration(
                                          hintText: 'Enter your phone number',
                                          hintStyle: TextStyle(
                                            color: _grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          filled: false,
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 14,
                                            horizontal: 14,
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Phone number is required';
                                          }
                                          if (value.length != 10) {
                                            return 'Enter a valid 10-digit number';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                "We'll send you a 6-digit OTP to verify your number",
                                style: TextStyle(
                                  color: _grey,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                child: WhitePillButton(
                  label: 'Continue',
                  loading: _isLoading,
                  onTap: _sendOtp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
