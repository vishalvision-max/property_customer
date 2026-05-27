import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/owner_profile_provider.dart';
import '../../widgets/primary_button.dart';

// Keep styling close to HomeScreen design tokens
const _kPrimary = Color(0xFF6C5CE7);
const _kBg = Color(0xFFF6F7FB);
const _kTextDark = Color(0xFF1A1A2E);
const _kTextMid = Color(0xFF6B7280);
const _kBorder = Color(0xFFE5E7EB);

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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final owner = ref.watch(ownerProfileProvider).profile;
    final ownerImage = owner == null ? '' : _normalizeImage(owner.imageUrl);
    final displayName = (owner?.name.trim().isNotEmpty ?? false)
        ? owner!.name.trim()
        : ((user == null || user.name.trim().isEmpty)
              ? 'Guest'
              : user.name.trim());
    final displayEmail = (owner?.email.trim().isNotEmpty ?? false)
        ? owner!.email.trim()
        : ((user == null || user.email.trim().isEmpty)
              ? '-'
              : user.email.trim());

    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            centerTitle: true,
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            title: const Text(
              'My Account',
              style: TextStyle(fontWeight: FontWeight.w900, color: _kTextDark),
            ),
            actions: [
              IconButton(
                tooltip: 'Favorites',
                onPressed: () {},
                // onPressed: () => context.push('/favorites'),
                icon: const Icon(Icons.notifications_none_outlined),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
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
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _kPrimary.withValues(alpha: 0.12),
                        border: Border.all(
                          color: _kPrimary.withValues(alpha: 0.18),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ownerImage.isEmpty
                          ? const Icon(
                              Icons.person_rounded,
                              color: _kPrimary,
                              size: 30,
                            )
                          : CachedNetworkImage(
                              imageUrl: ownerImage,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => const Icon(
                                Icons.person_rounded,
                                color: _kPrimary,
                                size: 30,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: _kTextDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            displayEmail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _kTextMid,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _QuickAction(
                                icon: Icons.support_agent_outlined,
                                label: 'My Leads',
                                onTap: () => context.push('/leads'),
                              ),
                              _QuickAction(
                                icon: Icons.favorite_border_rounded,
                                label: 'Saved',
                                onTap: () => context.push('/favorites'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.pagePadding,
              child: Container(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: _kTextDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'Edit profile',
                      isLoading: false,
                      onPressed: user == null
                          ? null
                          : () => context.push('/profile/edit'),
                      leading: const Icon(Icons.edit_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.pagePadding.copyWith(top: 0),
              child: Container(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Security',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: _kTextDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'Change password',
                      isLoading: false,
                      onPressed: user == null
                          ? null
                          : () => context.push('/profile/change-password'),
                      leading: const Icon(Icons.shield_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // SliverToBoxAdapter(child: Container(),),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: OutlinedButton.icon(
                onPressed: () async {
                  final router = GoRouter.of(context);
                  await ref.read(authProvider.notifier).logout();
                  if (!mounted) return;
                  router.go('/login');
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _kPrimary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kPrimary.withValues(alpha: 0.14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _kPrimary, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: _kTextDark,
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';

// class ProfileScreen extends StatelessWidget {
//   const ProfileScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // return
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         centerTitle: true,
//         title: Text(
//           "My Account",
//           style: TextStyle(color: Colors.black, fontSize: 20),
//         ),
//         actions: [
//           IconButton(
//             onPressed: () {},
//             icon: Icon(Icons.notifications_none_outlined, size: 20),
//           ),
//         ],
//       ),
//       backgroundColor: Colors.white,
//       body: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Column(
//           children: [
//             Container(
//               height: 100,
//               width: double.infinity,
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [
//                     Color(0xFF5B3DF5),
//                     Color(0xFF7B61FF),
//                   ],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//                 borderRadius: BorderRadius.circular(7),
//               ),
//               child: Text(
//                 "Profile Info",
//                 style: TextStyle(color: Colors.white, fontSize: 18),
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
