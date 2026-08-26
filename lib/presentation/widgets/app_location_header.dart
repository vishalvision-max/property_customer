import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/location_provider.dart';
import '../screens/home/map_location_screen.dart';

const _navy = Color(0xFF191D31);
const _grey = Color(0xFF666876);
const _orange = Color(0xFFFF8000);
const _fieldFill = Color(0xFFF2F3F5);

/// Shared "Your Location" + notification-bell header shown at the top of
/// every main tab, so location context stays visible no matter which tab
/// the user is on.
class AppLocationHeader extends ConsumerWidget {
  const AppLocationHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationProvider);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MapLocationScreen()),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: _fieldFill,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: _orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Location',
                            style: TextStyle(
                              color: _grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  location.currentLabel.isEmpty ||
                                          location.currentLabel ==
                                              'Set location'
                                      ? 'Set location'
                                      : location.currentLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _navy,
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: _navy,
                                size: 18,
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
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => context.push('/notifications'),
              child: Container(
                width: 44,
                height: 44,
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
                        size: 22,
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 11,
                      child: Container(
                        width: 8,
                        height: 8,
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
      ),
    );
  }
}
