import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pack_vault/core/constants/app_constants.dart';

class LoginForm extends StatefulWidget {
  final Future<bool> Function(String username, String password, bool isRegister) onSubmit;
  final bool isLoading;
  final String? error;

  const LoginForm({
    super.key,
    required this.onSubmit,
    required this.isLoading,
    this.error,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _shakeController;
  bool _obscurePassword = true;
  bool _isRegisterMode = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) {
      _shakeController.forward(from: 0);
      return;
    }
    final success = await widget.onSubmit(
      _usernameController.text.trim(),
      _passwordController.text,
      _isRegisterMode,
    );
    if (!success && mounted) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final sineValue = _shakeController.value;
        final dx = sineValue < 1
            ? (sineValue * 10 * (sineValue < 0.5 ? 1 : -1))
            : 0.0;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: AppColors.pitchGreen.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.pitchGreen.withValues(alpha: 0.1),
              blurRadius: 30,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _isRegisterMode ? 'CREATE ACCOUNT' : 'ENTER THE PITCH',
                  key: ValueKey(_isRegisterMode),
                  style: GoogleFonts.orbitron(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 60,
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isRegisterMode
                        ? [AppColors.goalGold, AppColors.fireSecondary]
                        : [AppColors.pitchGreen, AppColors.pitchGreenGlow],
                  ),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(height: 28),

              // Username field
              TextFormField(
                controller: _usernameController,
                style: GoogleFonts.inter(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: const Icon(Icons.person_outline,
                      color: AppColors.textMuted),
                  suffixIcon: const Icon(Icons.sports_soccer,
                      color: AppColors.pitchGreenGlow, size: 20),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter a username';
                  if (v.trim().length < 3) return 'Min 3 characters';
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Password field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: GoogleFonts.inter(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: AppColors.textMuted),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter a password';
                  if (v.length < 6) return 'Min 6 characters';
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 8),

              // Error message
              if (widget.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    widget.error!,
                    style: GoogleFonts.inter(
                      color: AppColors.error,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: widget.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRegisterMode
                        ? AppColors.goalGold
                        : AppColors.pitchGreen,
                    foregroundColor: _isRegisterMode
                        ? AppColors.pitchDark
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    elevation: 8,
                    shadowColor: (_isRegisterMode
                            ? AppColors.goalGold
                            : AppColors.pitchGreen)
                        .withValues(alpha: 0.4),
                  ),
                  child: widget.isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: _isRegisterMode
                                ? AppColors.pitchDark
                                : Colors.white,
                          ),
                        )
                      : Text(
                          _isRegisterMode ? 'SIGN UP' : 'KICK OFF',
                          style: GoogleFonts.orbitron(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 2,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Toggle login/register
              GestureDetector(
                onTap: () {
                  setState(() => _isRegisterMode = !_isRegisterMode);
                },
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                    children: [
                      TextSpan(
                        text: _isRegisterMode
                            ? 'Already have an account? '
                            : 'Don\'t have an account? ',
                      ),
                      TextSpan(
                        text: _isRegisterMode ? 'Login' : 'Register',
                        style: GoogleFonts.inter(
                          color: AppColors.pitchGreenGlow,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
