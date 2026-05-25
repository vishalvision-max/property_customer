class Validators {
  static String? name(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Name is required';
    if (v.length < 3) return 'Name must be at least 3 characters';
    return null;
  }

  static final _emailReg = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? email(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Email is required';
    if (!_emailReg.hasMatch(v)) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    final v = (value ?? '');
    if (v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    if (!RegExp(r'\d').hasMatch(v)) return 'Password must include at least 1 number';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    final v = (value ?? '');
    if (v.isEmpty) return 'Confirm password is required';
    if (v != password) return 'Passwords do not match';
    return null;
  }
}

