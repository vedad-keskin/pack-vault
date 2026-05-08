import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pack_vault/firebase_options.dart';
import 'package:pack_vault/core/theme/app_theme.dart';
import 'package:pack_vault/services/auth_service.dart';
import 'package:pack_vault/services/collection_service.dart';
import 'package:pack_vault/features/auth/login_screen.dart';
import 'package:pack_vault/features/album/album_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (e) {
    debugPrint('Firebase init failed: $e');
    debugPrint('Run: flutterfire configure --project=YOUR_PROJECT_ID');
  }

  runApp(PackVaultApp(firebaseReady: firebaseReady));
}

class PackVaultApp extends StatelessWidget {
  final bool firebaseReady;
  const PackVaultApp({super.key, required this.firebaseReady});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => CollectionService()),
      ],
      child: MaterialApp(
        title: 'Pack Vault',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: firebaseReady
            ? Consumer<AuthService>(
                builder: (context, auth, _) {
                  if (auth.isLoggedIn) {
                    // Start listening if returning from backgrounded app
                    final collection = context.read<CollectionService>();
                    if (collection.isLoading) {
                      collection.startListening(auth.uid);
                    }
                    return const AlbumScreen();
                  }
                  return const LoginScreen();
                },
              )
            : const _FirebaseErrorScreen(),
      ),
    );
  }
}

/// Shown when Firebase is not configured yet.
class _FirebaseErrorScreen extends StatelessWidget {
  const _FirebaseErrorScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: Colors.white38),
              const SizedBox(height: 24),
              Text(
                'Firebase Not Configured',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Run the following command to set up Firebase:\n\n'
                'flutterfire configure --project=YOUR_PROJECT_ID\n\n'
                'Then rebuild the app.',
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
