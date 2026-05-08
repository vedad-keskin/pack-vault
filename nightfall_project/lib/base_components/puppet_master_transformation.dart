import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightfall_project/services/language_service.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:nightfall_project/werewolves_game/offline_db/role_service.dart';
import 'package:nightfall_project/base_components/pixel_button.dart';
import 'package:nightfall_project/services/sound_settings_service.dart';
import 'package:nightfall_project/base_components/gambler_bet_dialog.dart';

class PuppetMasterTransformationDialog extends StatefulWidget {
  final String playerName;
  final WerewolfRole targetRole;
  final GamblerBet? gamblerBet;

  const PuppetMasterTransformationDialog({
    super.key,
    required this.playerName,
    required this.targetRole,
    this.gamblerBet,
  });

  @override
  State<PuppetMasterTransformationDialog> createState() =>
      _PuppetMasterTransformationDialogState();
}

class _PuppetMasterTransformationDialogState
    extends State<PuppetMasterTransformationDialog>
    with TickerProviderStateMixin {
  late AnimationController _glitchController;
  late AnimationController _morphController;
  late AnimationController _shakeController;
  late AnimationController _particleController;

  bool _isStarted = false;
  int _stage = 0; // 0: Ready, 1: Morphing, 2: Final
  String _typedText = "";
  Timer? _typeTimer;

  @override
  void initState() {
    super.initState();
    _glitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..repeat();

    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  void _beginTransformation() async {
    setState(() {
      _isStarted = true;
      _stage = 1;
    });

    final soundService = context.read<SoundSettingsService>();
    soundService.stopAll();

    if (!soundService.isMuted) {
      try {
        await soundService.playGlobal(
          'audio/werewolves/puppet_master_transformation.mp3',
          loop: false,
        );
      } catch (e) {
        debugPrint('Error playing transformation sound: $e');
      }
    }

    final lang = context.read<LanguageService>();
    await _type(lang.translate('puppet_master_transforming'));

    // Sequence:
    // 1. Start Shaking
    _shakeController.repeat(reverse: true);

    // 2. Start Morphing (Cross-fade + scale + blur transition)
    await _morphController.forward();

    _shakeController.stop();

    if (!mounted) return;
    setState(() => _stage = 2);

    String roleName = lang.translate(widget.targetRole.translationKey);
    String text2 = lang
        .translate('puppet_master_new_role')
        .replaceAll('{role}', roleName.toUpperCase());
    await _type(text2);

    // Puppet Master Edge Case: Gambler Bet
    if (widget.targetRole.id == 15 && widget.gamblerBet != null) {
      await Future.delayed(const Duration(milliseconds: 500));
      String allianceKey = '';
      switch (widget.gamblerBet!) {
        case GamblerBet.village:
          allianceKey = lang.translate('gambler_bet_village');
          break;
        case GamblerBet.werewolves:
          allianceKey = lang.translate('gambler_bet_werewolves');
          break;
        case GamblerBet.specials:
          allianceKey = lang.translate('gambler_bet_specials');
          break;
      }

      String betInfo = lang
          .translate('puppet_master_gambler_bet_info')
          .replaceAll('{alliance}', allianceKey);
      await _type(betInfo);
    }
  }

  Future<void> _type(String text) async {
    _typedText = "";
    Completer completer = Completer();
    int idx = 0;
    _typeTimer?.cancel();
    _typeTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (idx < text.length) {
        if (mounted) {
          setState(() {
            _typedText += text[idx];
          });
        }
        idx++;
      } else {
        timer.cancel();
        completer.complete();
      }
    });
    return completer.future;
  }

  @override
  void dispose() {
    _glitchController.dispose();
    _morphController.dispose();
    _shakeController.dispose();
    _particleController.dispose();
    _typeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageService>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Mystical Atmosphere
          if (_isStarted)
            AnimatedBuilder(
              animation: _morphController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Color.lerp(
                          const Color(0xFF7209B7).withOpacity(0.3),
                          const Color(
                            0xFFFFD700,
                          ).withOpacity(0.2), // Gold spark
                          _morphController.value,
                        )!,
                        Colors.black,
                      ],
                      radius: 0.7 + (_morphController.value * 0.5),
                    ),
                  ),
                );
              },
            ),

          // Particle Effects (Floating Souls)
          if (_isStarted)
            ...List.generate(15, (index) => _buildParticle(index)),

          // Main Morphing Visual
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _shakeController,
                _morphController,
                _glitchController,
              ]),
              builder: (context, child) {
                double shakeX =
                    (math.Random().nextDouble() - 0.5) *
                    10 *
                    _shakeController.value;
                double shakeY =
                    (math.Random().nextDouble() - 0.5) *
                    10 *
                    _shakeController.value;

                // Morph stage: 0.0 -> 0.4 (Fade out PM), 0.3 -> 0.7 (Glow peak), 0.6 -> 1.0 (Fade in New)
                double pmOpacity = (1.0 - (_morphController.value * 1.5)).clamp(
                  0.0,
                  1.0,
                );
                double roleOpacity = ((_morphController.value - 0.5) * 2.0)
                    .clamp(0.0, 1.0);
                double glowIntensity = math.sin(
                  _morphController.value * math.pi,
                );

                return Transform.translate(
                  offset: Offset(shakeX, shakeY),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Magical Aura behind the morph
                      Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        height: MediaQuery.of(context).size.width * 0.9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF7209B7,
                              ).withOpacity(glowIntensity * 0.5),
                              blurRadius: 100 * glowIntensity,
                              spreadRadius: 20 * glowIntensity,
                            ),
                          ],
                        ),
                      ),

                      // Puppet Master (The Old Presence)
                      if (pmOpacity > 0)
                        Opacity(
                          opacity: pmOpacity,
                          child: Transform.scale(
                            scale: 1.0 + (_morphController.value * 0.2),
                            child: _buildGlitchyImage(
                              'assets/images/werewolves/Puppet Master.png',
                              scale: 0.95,
                            ),
                          ),
                        ),

                      // The New Role (The Emerging Identity)
                      if (roleOpacity > 0)
                        Opacity(
                          opacity: roleOpacity,
                          child: Transform.scale(
                            scale: 1.2 - ((1.0 - roleOpacity) * 0.2),
                            child: Image.asset(
                              widget.targetRole.imagePath,
                              width: MediaQuery.of(context).size.width * 0.9,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                      // Magical Glitch Bars (only during active morph)
                      if (_morphController.value > 0.1 &&
                          _morphController.value < 0.9)
                        ...List.generate(3, (index) => _buildGlitchBar()),
                    ],
                  ),
                );
              },
            ),
          ),

          // UI Overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                children: [
                  // Redesigned Top Title (Royal/Medieval Scroll Style)
                  _buildMedievalTitle(lang),

                  const Spacer(),

                  // Bottom Dialogue Box
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.85),
                      border: Border.all(
                        color:
                            _stage == 2 &&
                                widget.targetRole.id == 15 &&
                                widget.gamblerBet != null
                            ? const Color(0xFFFFD700) // Gold for Gambler reveal
                            : const Color(0xFF7209B7),
                        width: 4,
                      ),
                      borderRadius: BorderRadius.circular(0),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (_stage == 2 &&
                                          widget.targetRole.id == 15 &&
                                          widget.gamblerBet != null
                                      ? const Color(0xFFFFD700)
                                      : const Color(0xFF7209B7))
                                  .withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_isStarted) ...[
                          Text(
                            lang.translate('puppet_master_desc'),
                            style: GoogleFonts.vt323(
                              color: Colors.white,
                              fontSize: 22,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF7209B7,
                                  ).withOpacity(0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: PixelButton(
                              label: lang
                                  .translate('puppet_master_unleash')
                                  .toUpperCase(),
                              color: const Color(0xFF7209B7),
                              onPressed: _beginTransformation,
                            ),
                          ),
                        ] else ...[
                          Text(
                            _typedText,
                            style:
                                _typedText.contains(
                                      lang.translate('gambler_name'),
                                    ) ||
                                    _typedText.contains(' inherited') ||
                                    _typedText.contains('Naslijedili')
                                ? GoogleFonts.pressStart2p(
                                    color: const Color(0xFFFFD700),
                                    fontSize: 14,
                                    height: 1.6,
                                  )
                                : GoogleFonts.vt323(
                                    color: Colors.white,
                                    fontSize: 26,
                                  ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          if (_stage == 2)
                            SizedBox(
                              width: double.infinity,
                              child: PixelButton(
                                label: lang
                                    .translate('proceed_button')
                                    .toUpperCase(),
                                color:
                                    widget.targetRole.id == 15 &&
                                        widget.gamblerBet != null
                                    ? const Color(0xFFB8860B)
                                    : const Color(0xFF7209B7),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            )
                          else
                            _buildEvolvingIndicator(),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedievalTitle(LanguageService lang) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(
                color: const Color(0xFF7209B7).withOpacity(0.5),
                width: 2,
              ),
            ),
          ),
          child: Column(
            children: [
              Text(
                lang.translate('puppet_master_name').toUpperCase(),
                style: GoogleFonts.pressStart2p(
                  color: const Color(0xFF9D4EDD),
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                lang.translate('puppet_master_ritual').toUpperCase(),
                style: GoogleFonts.vt323(
                  color: Colors.white38,
                  fontSize: 16,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEvolvingIndicator() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            double op =
                math.sin(
                      (_particleController.value * math.pi * 2) + (i * 1.5),
                    ) *
                    0.5 +
                0.5;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF7209B7).withOpacity(op),
                shape: BoxShape.rectangle,
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildParticle(int index) {
    final random = math.Random(index);
    final startX = random.nextDouble() * 400;
    final startY = random.nextDouble() * 800;

    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        double move = _particleController.value * 100;
        return Positioned(
          left: startX + math.sin(_particleController.value * 2 * math.pi) * 20,
          top: startY - move,
          child: Opacity(
            opacity: 1.0 - _particleController.value,
            child: Container(
              width: 4,
              height: 4,
              color: const Color(0xFF7209B7),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlitchyImage(String path, {double scale = 1.0}) {
    return AnimatedBuilder(
      animation: _glitchController,
      builder: (context, child) {
        bool showCyan = math.Random().nextDouble() > 0.9;
        bool showPurple = math.Random().nextDouble() > 0.9;

        return Stack(
          alignment: Alignment.center,
          children: [
            if (showCyan)
              Transform.translate(
                offset: const Offset(-8, 0),
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Colors.cyan,
                    BlendMode.modulate,
                  ),
                  child: Image.asset(
                    path,
                    width: MediaQuery.of(context).size.width * 0.85 * scale,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            if (showPurple)
              Transform.translate(
                offset: const Offset(8, 0),
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF7209B7),
                    BlendMode.modulate,
                  ),
                  child: Image.asset(
                    path,
                    width: MediaQuery.of(context).size.width * 0.85 * scale,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            Image.asset(
              path,
              width: MediaQuery.of(context).size.width * 0.85 * scale,
              fit: BoxFit.contain,
              color: _stage == 1
                  ? Colors.white.withOpacity(
                      0.5 + (0.5 * _morphController.value),
                    )
                  : null,
              colorBlendMode: _stage == 1 ? BlendMode.modulate : null,
            ),
          ],
        );
      },
    );
  }

  Widget _buildGlitchBar() {
    final random = math.Random();
    return Positioned(
      top: random.nextDouble() * MediaQuery.of(context).size.height,
      left: 0,
      right: 0,
      child: Container(
        height: 2,
        color: const Color(0xFF7209B7).withOpacity(0.4),
      ),
    );
  }
}
