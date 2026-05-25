import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/favorites_provider.dart';
import 'providers/auth_provider.dart';
import 'routes/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: PropertyCustomerApp()));
}

class PropertyCustomerApp extends ConsumerStatefulWidget {
  const PropertyCustomerApp({super.key});

  @override
  ConsumerState<PropertyCustomerApp> createState() => _PropertyCustomerAppState();
}

class _PropertyCustomerAppState extends ConsumerState<PropertyCustomerApp> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(favoritesProvider.notifier).load();
    });

    ref.listenManual(authProvider, (prev, next) {
      final prevToken = prev?.user?.token;
      final nextToken = next.user?.token;
      final tokenChanged = (prevToken ?? '') != (nextToken ?? '');
      if (tokenChanged) {
        ref.read(favoritesProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
