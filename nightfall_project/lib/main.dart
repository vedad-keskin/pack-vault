import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:nightfall_project/base_components/pixel_team_dialog.dart';
import 'package:nightfall_project/base_components/pixel_dialog.dart';

import 'package:nightfall_project/base_components/pixel_rules_dialog.dart';
import 'package:nightfall_project/base_components/pixel_language_switch.dart';
import 'package:nightfall_project/impostor_game/layouts/game_layout.dart';
import 'package:nightfall_project/werewolves_game/layouts/game_layout.dart';
import 'package:nightfall_project/services/language_service.dart';
import 'package:nightfall_project/services/sound_settings_service.dart';
import 'package:nightfall_project/services/live_session_service.dart';
import 'package:nightfall_project/base_components/pixel_sound_button.dart';
import 'package:nightfall_project/base_components/pixel_swipe_indicator.dart';
import 'package:nightfall_project/base_components/nightfall_intro_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAuth.instance.signInAnonymously();

  final liveSession = LiveSessionService();
  await liveSession.loadExistingSession();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageService()),
        ChangeNotifierProvider(create: (_) => SoundSettingsService()),
        ChangeNotifierProvider.value(value: liveSession),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nightfall Project',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          surface: Colors.black,
        ),
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      home: const NightfallIntroScreen(next: SplitHomeScreen()),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplitHomeScreen extends StatefulWidget {
  const SplitHomeScreen({super.key});

  @override
  State<SplitHomeScreen> createState() => _SplitHomeScreenState();
}

class _SplitHomeScreenState extends State<SplitHomeScreen> {
  ScrollController? _scrollController;
  int _currentPage = 0; // Start on Left side (index 0)
  Timer? _easterEggTimer;

  @override
  void dispose() {
    _scrollController?.removeListener(_onScroll);
    _scrollController?.dispose();
    _easterEggTimer?.cancel();
    super.dispose();
  }

  void _showEasterEgg() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Team Credits',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const PixelTeamDialog(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  void _onScroll() {
    if (_scrollController == null || !_scrollController!.hasClients) return;
    final width = MediaQuery.of(context).size.width;
    final page = (_scrollController!.offset / width).round();
    if (page != _currentPage) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  void _scrollToPage(int page) {
    if (_scrollController != null && _scrollController!.hasClients) {
      final width = MediaQuery.of(context).size.width;
      _scrollController!.animateTo(
        page * width,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutQuart,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          if (width == 0) return const SizedBox();

          if (_scrollController == null) {
            _scrollController = ScrollController(initialScrollOffset: 0);
            _scrollController!.addListener(_onScroll);
          }

          return Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const PageScrollPhysics(),
                child: SizedBox(
                  width: width * 2,
                  height: constraints.maxHeight,
                  child: Stack(
                    children: [
                      // Background Image
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/2-split-home.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Left Side - Werewolves
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: width,
                        child: Align(
                          alignment: const Alignment(0.0, -0.6), // Move up more
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 500),
                            opacity: _currentPage == 0 ? 1.0 : 0.0,
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 500),
                              scale: _currentPage == 0 ? 1.0 : 0.8,
                              child: PixelDialog(
                                title: context
                                    .watch<LanguageService>()
                                    .translate('werewolves'),
                                color: Colors.black54, // More transparent
                                accentColor: Colors.redAccent,
                                titleFontSize: 19,
                                soundPath: 'audio/werewolves/wolf_howl.mp3',
                                useGlobalPlayer: true,
                                onPressed: () {
                                  Navigator.of(context).push(
                                    PageRouteBuilder(
                                      transitionDuration: const Duration(
                                        seconds: 2,
                                      ),
                                      reverseTransitionDuration: const Duration(
                                        seconds: 1,
                                      ),
                                      pageBuilder:
                                          (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                          ) {
                                            return const WerewolfGameLayout();
                                          },
                                      transitionsBuilder:
                                          (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                            child,
                                          ) {
                                            return FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            );
                                          },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Right Side - Impostor
                      Positioned(
                        left: width,
                        top: 0,
                        bottom: 0,
                        width: width,
                        child: Align(
                          alignment: const Alignment(0.0, -0.6), // Move up more
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 500),
                            opacity: _currentPage == 1 ? 1.0 : 0.0,
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 500),
                              scale: _currentPage == 1 ? 1.0 : 0.8,
                              child: PixelDialog(
                                title: context
                                    .watch<LanguageService>()
                                    .translate('impostor'),
                                color: const Color.fromRGBO(255, 82, 82, 0.7),
                                accentColor: Colors.black87,
                                soundPath: 'audio/impostor/mystery_mist.mp3',
                                titleFontSize: 19,
                                useGlobalPlayer: true,
                                onPressed: () {
                                  Navigator.of(context).push(
                                    PageRouteBuilder(
                                      transitionDuration: const Duration(
                                        seconds: 2,
                                      ),
                                      reverseTransitionDuration: const Duration(
                                        seconds: 1,
                                      ),
                                      pageBuilder:
                                          (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                          ) {
                                            return const ImpostorGameLayout();
                                          },
                                      settings: const RouteSettings(
                                        name: '/impostor_game',
                                      ),
                                      transitionsBuilder:
                                          (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                            child,
                                          ) {
                                            // Fade to black, then fade in new screen?
                                            // Or just a slow fade of the new screen over the old.
                                            // User asked for "transition... last 3 seconds... 3second animation"
                                            // A simple FadeTransition is cleanest and fits the "mystery" vibe.
                                            return FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            );
                                          },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Language Switch (Static)
              const Positioned(
                right: 20,
                top: 40,
                child: PixelLanguageSwitch(),
              ),
              // How to Play Button and Sound Button (Static)
              Positioned(
                left: 20,
                top: 40,
                child: Row(
                  children: [
                    PixelRulesButton(
                      onPressed: () {
                        final isImpostor = _currentPage == 1;
                        // lang not needed here as PixelRulesDialog handles it
                        showDialog(
                          context: context,
                          builder: (context) =>
                              PixelRulesDialog(isImpostor: isImpostor),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    const PixelSoundButton(),
                  ],
                ),
              ),
              // Version Info (Static)
              Positioned(
                right: 16,
                bottom: 16,
                child: GestureDetector(
                  onLongPressStart: (_) {
                    _easterEggTimer = Timer(const Duration(seconds: 1), () {
                      if (mounted) {
                        _showEasterEgg();
                      }
                    });
                  },
                  onLongPressEnd: (_) {
                    _easterEggTimer?.cancel();
                  },
                  onLongPressCancel: () {
                    _easterEggTimer?.cancel();
                  },
                  child: Text(
                    'Nightfall Project v4.6.2',
                    style: GoogleFonts.vt323(
                      color: Colors.white24,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              // Swipe Indicators
              Positioned(
                right: 10,
                top: constraints.maxHeight / 2 - 30,
                child: PixelSwipeIndicator(
                  isRight: true,
                  visible: _currentPage == 0,
                  onTap: () => _scrollToPage(1),
                ),
              ),
              Positioned(
                left: 10,
                top: constraints.maxHeight / 2 - 30,
                child: PixelSwipeIndicator(
                  isRight: false,
                  visible: _currentPage == 1,
                  onTap: () => _scrollToPage(0),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PixelRulesButton extends StatefulWidget {
  final VoidCallback onPressed;
  const PixelRulesButton({super.key, required this.onPressed});

  @override
  State<PixelRulesButton> createState() => _PixelRulesButtonState();
}

class _PixelRulesButtonState extends State<PixelRulesButton> {
  bool _isPressed = false;
  DateTime? _pressStartTime;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() {
        _isPressed = true;
        _pressStartTime = DateTime.now();
      }),
      onTapUp: (_) async {
        final pressDuration = DateTime.now().difference(_pressStartTime!);
        const minPressDuration = Duration(milliseconds: 100);

        if (pressDuration < minPressDuration) {
          await Future.delayed(minPressDuration - pressDuration);
        }

        if (mounted) {
          setState(() => _isPressed = false);
          widget.onPressed();
        }
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        width: 100, // Matching language switch width
        height: 50, // Matching language switch height
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          boxShadow: [
            if (!_isPressed)
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                offset: const Offset(6, 6),
                blurRadius: 0,
              ),
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: BoxDecoration(
            color: _isPressed
                ? const Color(0xFF415A77)
                : const Color(0xFF1B263B),
            border: Border.all(
              color: _isPressed
                  ? const Color(0xFF778DA9)
                  : const Color(0xFF415A77),
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              // Top Highlight Loophole Effect
              if (!_isPressed)
                Positioned(
                  top: 2,
                  left: 2,
                  right: 2,
                  height: 2,
                  child: Container(color: Colors.white10),
                ),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.help_center_outlined,
                      color: Color(0xFFE0E1DD),
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          context.watch<LanguageService>().translate(
                            'how_to_play',
                          ),
                          style: GoogleFonts.vt323(
                            color: const Color(0xFFE0E1DD),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
