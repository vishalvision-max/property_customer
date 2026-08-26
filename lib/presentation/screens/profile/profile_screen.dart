import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/owner_profile_provider.dart';

const _navy = Color(0xFF191D31);
const _grey = Color(0xFF666876);
const _orange = Color(0xFFFF8000);
const _fieldFill = Color(0xFFF2F3F5);
const _red = Color(0xFFE0245E);

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _normalizeImage(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return v;
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    return Uri.parse(
      'https://propertysearch.visionvivante.in',
    ).resolve('/storage/$v').toString();
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature is coming soon')));
  }

  Future<void> _confirmLogout() async {
    final router = GoRouter.of(context);
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: _fieldFill,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded, color: _red, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _navy,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Are you sure you want to log out of your account?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: _grey),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: _fieldFill,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: _navy,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: _red,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Yes, Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    router.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final owner = ref.watch(ownerProfileNotifierProvider).profile;
    final ownerImage = owner == null ? '' : _normalizeImage(owner.imageUrl);
    final rawName = (owner?.name.trim().isNotEmpty ?? false)
        ? owner!.name.trim()
        : (user?.name.trim() ?? '');
    final isAutoName =
        rawName.toLowerCase().startsWith('user') &&
        RegExp(r'^user[\s_]*\d*$').hasMatch(rawName.toLowerCase());
    final displayName = isAutoName || rawName.isEmpty ? 'Guest' : rawName;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _navy,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.push('/notifications'),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: _fieldFill,
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        children: [
                          const Center(
                            child: Icon(
                              Icons.notifications_none_rounded,
                              color: _navy,
                              size: 20,
                            ),
                          ),
                          Positioned(
                            top: 9,
                            right: 10,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: _orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 130,
                      height: 130,
                      decoration: const BoxDecoration(
                        color: _fieldFill,
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ownerImage.isEmpty
                          ? const Icon(
                              Icons.person_rounded,
                              color: _grey,
                              size: 60,
                            )
                          : CachedNetworkImage(
                              imageUrl: ownerImage,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => const Icon(
                                Icons.person_rounded,
                                color: _grey,
                                size: 60,
                              ),
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: user == null
                            ? null
                            : () => context.push('/profile/edit'),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _orange,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 17,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _navy,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFFF2F4F7)),
              _ProfileTile(
                icon: Icons.calendar_month_outlined,
                title: 'My Booking',
                onTap: () => context.push('/scheduled-visits'),
              ),
              _ProfileTile(
                icon: Icons.support_agent_rounded,
                title: 'Property Enquiries',
                onTap: () => context.push('/leads'),
              ),
              const Divider(height: 1, color: Color(0xFFF2F4F7)),
              _ProfileTile(
                icon: Icons.person_outline_rounded,
                title: 'Profile',
                onTap: user == null
                    ? null
                    : () => context.push('/profile/edit'),
              ),
              _ProfileTile(
                icon: Icons.notifications_none_rounded,
                title: 'Notification',
                onTap: () => context.push('/notifications'),
              ),
              _ProfileTile(
                icon: Icons.verified_user_outlined,
                title: 'Security',
                onTap: user == null
                    ? null
                    : () => context.push('/profile/change-password'),
              ),
              _ProfileTile(
                icon: Icons.language_rounded,
                title: 'Language',
                onTap: () => _comingSoon('Language selection'),
              ),
              _ProfileTile(
                icon: Icons.info_outline_rounded,
                title: 'Help Center',
                onTap: () => _comingSoon('Help Center'),
              ),
              _ProfileTile(
                icon: Icons.group_outlined,
                title: 'Invite Friends',
                onTap: () => Share.share(
                  'Check out Nestora — find your ideal home! Download the app now.',
                ),
              ),
              _ProfileTile(
                icon: Icons.logout_rounded,
                title: 'Logout',
                isDestructive: true,
                onTap: _confirmLogout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _ProfileTile({
    required this.icon,
    required this.title,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? _red : _navy;
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15.5,
                    color: color,
                  ),
                ),
              ),
              if (!isDestructive)
                const Icon(Icons.chevron_right_rounded, color: _navy, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
