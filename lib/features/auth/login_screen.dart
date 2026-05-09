import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pack_vault/core/constants/app_constants.dart';
import 'package:pack_vault/services/auth_service.dart';
import 'package:pack_vault/features/auth/widgets/stadium_intro.dart';
import 'package:pack_vault/features/auth/widgets/login_form.dart';
import 'package:pack_vault/features/auth/register_screen.dart';
import 'package:pack_vault/features/albums/album_select_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _navigateToAlbum(BuildContext context) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, a, b) => const AlbumSelectScreen(),
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

  void _navigateToRegister(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, a, b) => const RegisterScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
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
                    // Logo
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.firePrimary.withValues(
                              alpha: 0.15,
                            ),
                            blurRadius: 30,
                            spreadRadius: 4,
                          ),
                          BoxShadow(
                            color: AppColors.goalGold.withValues(alpha: 0.08),
                            blurRadius: 50,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/logo.png',
                          width: 130,
                          height: 130,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Login form (login only — no register)
                    Consumer<AuthService>(
                      builder: (context, auth, _) {
                        return LoginForm(
                          isLoading: auth.isLoading,
                          error: auth.error,
                          onSubmit: (username, password) async {
                            // Admin backdoor → register screen
                            if (username == 'admin' && password == 'admin') {
                              auth.clearError();
                              if (context.mounted) {
                                _navigateToRegister(context);
                              }
                              return false;
                            }

                            final success = await auth.login(
                              username,
                              password,
                            );
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
