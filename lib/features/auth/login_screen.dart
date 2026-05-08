import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pack_vault/core/constants/app_constants.dart';
import 'package:pack_vault/services/auth_service.dart';
import 'package:pack_vault/services/collection_service.dart';
import 'package:pack_vault/features/auth/widgets/stadium_intro.dart';
import 'package:pack_vault/features/auth/widgets/login_form.dart';
import 'package:pack_vault/features/album/album_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _navigateToAlbum(BuildContext context) {
    final auth = context.read<AuthService>();
    final collection = context.read<CollectionService>();
    collection.startListening(auth.uid);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, a, b) => const AlbumScreen(),
        transitionsBuilder: (_, animation, a2, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Animated stadium background
          const Positioned.fill(child: StadiumIntro()),

          // Vignette overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.3),
                  radius: 1.2,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo area
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.pitchGreenLight,
                            AppColors.pitchGreen,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.pitchGreenGlow.withValues(alpha: 0.3),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.sports_soccer,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'PACK VAULT',
                      style: GoogleFonts.orbitron(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        shadows: [
                          Shadow(
                            color:
                                AppColors.pitchGreenGlow.withValues(alpha: 0.4),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sticker Album Collection Tracker',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 44),

                    // Login form
                    Consumer<AuthService>(
                      builder: (context, auth, _) {
                        return LoginForm(
                          isLoading: auth.isLoading,
                          error: auth.error,
                          onSubmit: (username, password) async {
                            final success =
                                await auth.loginOrRegister(username, password);
                            if (success && context.mounted) {
                              _navigateToAlbum(context);
                            }
                            return success;
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
