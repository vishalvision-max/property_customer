import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/white_pill_button.dart';
import '../../../providers/auth_provider.dart';

const _navy = Color(0xFF191D31);
const _grey = Color(0xFF666876);
const _orange = Color(0xFFFF8000);
const _border = Color(0xFFE5E7EB);

class VerifyOtpArgs {
  final String phone;
  final String? autoFillOtp;

  const VerifyOtpArgs({required this.phone, this.autoFillOtp});
}

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  final String? autoFillOtp;

  const OtpScreen({super.key, required this.phone, this.autoFillOtp});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _verifying = false;
  bool _resending = false;
  Timer? _resendTimer;
  int _secondsLeft = 45;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _fillOtp(widget.autoFillOtp);
  }

  void _fillOtp(String? otp) {
    if (otp == null) return;
    final digits = otp.trim();
    for (var i = 0; i < 6; i++) {
      _controllers[i].text = i < digits.length ? digits[i] : '';
    }
    setState(() {});
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _secondsLeft = 45);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {});
  }

  Future<void> _handleVerify() async {
    if (_otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit OTP')),
      );
      return;
    }

    setState(() => _verifying = true);
    await ref
        .read(authProvider.notifier)
        .verifyOtp(phone: widget.phone, otp: _otp);
    if (!mounted) return;
    setState(() => _verifying = false);

    final authState = ref.read(authProvider);
    if (authState.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.error!.replaceFirst('Exception: ', '')),
        ),
      );
      return;
    }

    if (authState.user != null) {
      if (!mounted) return;
      final from = GoRouterState.of(context).uri.queryParameters['from'];
      context.go((from != null && from.isNotEmpty) ? from : '/home');
    }
  }

  Future<void> _handleResend() async {
    if (_secondsLeft > 0 || _resending) return;
    setState(() => _resending = true);
    final result = await ref
        .read(authProvider.notifier)
        .sendOtp(phone: widget.phone);
    if (!mounted) return;
    setState(() => _resending = false);
    if (result.otp != null) {
      _fillOtp(result.otp);
    } else {
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes.first.requestFocus();
    }
    _startResendTimer();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message ?? 'OTP resent')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/login');
                    }
                  },
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: _navy,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 8),
                AspectRatio(
                  aspectRatio: 631 / 395,
                  child: Image.asset(
                    'assets/icons/otp_illustration.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Verify Your Number',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Enter the 6-digit OTP sent to',
                  style: TextStyle(
                    color: _grey,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '+91${widget.phone}',
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/login');
                        }
                      },
                      child: const Text(
                        'Change',
                        style: TextStyle(
                          color: _orange,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 0; i < 6; i++)
                      SizedBox(
                        width: 48,
                        height: 56,
                        child: TextField(
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          autofocus: i == 0,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _navy,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _border),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: _orange,
                                width: 1.6,
                              ),
                            ),
                          ),
                          onChanged: (v) => _onDigitChanged(i, v),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: _secondsLeft > 0
                      ? Text.rich(
                          TextSpan(
                            style: const TextStyle(
                              color: _grey,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                            children: [
                              const TextSpan(text: "Didn't receive OTP? "),
                              TextSpan(
                                text:
                                    'Resend in 00:${_secondsLeft.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  color: _orange,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        )
                      : GestureDetector(
                          onTap: _handleResend,
                          child: Text(
                            _resending ? 'Sending...' : 'Resend OTP',
                            style: const TextStyle(
                              color: _orange,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 28),
                WhitePillButton(
                  label: 'Verify & Continue',
                  loading: _verifying,
                  onTap: _handleVerify,
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, color: _grey, size: 15),
                      SizedBox(width: 6),
                      Text(
                        'Your data is secure and encrypted',
                        style: TextStyle(
                          color: _grey,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
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
    );
  }
}
