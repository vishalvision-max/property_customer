import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_snackbar.dart';
import '../../../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  
  const OtpScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _actionRequested = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyOtp() async {
    if (!_formKey.currentState!.validate()) return;
    
    final otp = _otpController.text.trim();

    setState(() {
      _actionRequested = true;
    });

    await ref.read(authProvider.notifier).verifyOtp(
      phone: widget.phone, 
      otp: otp,
    );

    if (!mounted) return;

    setState(() {
      _actionRequested = false;
    });

    final authState = ref.read(authProvider);

    if (authState.error != null) {
      final errMsg = authState.error!.replaceFirst('Exception: ', '');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Error', style: TextStyle(color: Colors.red)),
          content: Text(errMsg),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else if (authState.user != null) {
      AppSnackbar.showMessage(context, 'Login successful!');
      
      final from = GoRouterState.of(context).uri.queryParameters['from'];
      context.go((from != null && from.isNotEmpty) ? from : '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading || _actionRequested;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          size: 70,
                          color: Color(0xFF0F172A),
                        ),
                        const SizedBox(height: 24),
                        
                        Text(
                          'Enter Verification Code',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        Text(
                          'We sent a 6-digit code to +91 ${widget.phone}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        TextFormField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          enabled: !isLoading,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'OTP',
                            prefixIcon: Icon(Icons.lock),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'OTP is required';
                            }
                            if (value.length != 6) {
                              return 'Please enter a 6-digit OTP';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _handleVerifyOtp,
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Verify & Login'),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        TextButton(
                          onPressed: isLoading ? null : () => context.pop(),
                          child: const Text('Change Phone Number'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
