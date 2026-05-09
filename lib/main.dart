import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pack_vault/core/theme/app_theme.dart';
import 'package:pack_vault/services/auth_service.dart';
import 'package:pack_vault/services/collection_service.dart';
import 'package:pack_vault/features/splash/pack_vault_splash.dart';
import 'package:pack_vault/features/auth/login_screen.dart';
import 'package:pack_vault/features/albums/album_select_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PackVaultApp());
}

class PackVaultApp extends StatelessWidget {
  const PackVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => CollectionService()),
      ],
      child: MaterialApp(
        title: 'Stickr',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: PackVaultSplash(
          nextBuilder: (firebaseReady) {
            return _HomeRouter(firebaseReady: firebaseReady);
          },
        ),
      ),
    );
  }
}

/// Routes to AlbumSelectScreen if logged in, LoginScreen if not.
class _HomeRouter extends StatelessWidget {
  final bool firebaseReady;
  const _HomeRouter({required this.firebaseReady});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        if (auth.isLoggedIn) {
          return const AlbumSelectScreen();
        }
        if (!firebaseReady) {
          return const _OfflineNoSessionScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

/// Shown when offline and no cached login session exists.
class _OfflineNoSessionScreen extends StatelessWidget {
  const _OfflineNoSessionScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 64, color: Colors.white38),
              const SizedBox(height: 24),
              Text(
                'No Internet Connection',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Connect to the internet to login for the first time.\n'
                'After that, the app works fully offline!',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
