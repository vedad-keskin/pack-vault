import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightfall_project/services/language_service.dart';
import 'package:provider/provider.dart';
import 'package:nightfall_project/base_components/pixel_starfield_background.dart';
import 'package:nightfall_project/base_components/pixel_button.dart';
import 'package:nightfall_project/base_components/pixel_game_timer.dart';
import 'package:nightfall_project/werewolves_game/offline_db/timer_settings_service.dart';
import 'package:nightfall_project/werewolves_game/offline_db/player_service.dart';
import 'package:nightfall_project/werewolves_game/players_section/players_screen.dart';
import 'package:nightfall_project/werewolves_game/leaderboards/leaderboards_screen.dart';
import 'package:nightfall_project/werewolves_game/roles/roles_screen.dart';
import 'package:nightfall_project/werewolves_game/game_flow/phase_one.dart';

class WerewolfGameLayout extends StatefulWidget {
  const WerewolfGameLayout({super.key});

  @override
  State<WerewolfGameLayout> createState() => _WerewolfGameLayoutState();
}

class _WerewolfGameLayoutState extends State<WerewolfGameLayout> {
  int _playerCount = 0;
  TimerMode _timerMode = TimerMode.fiveMinutes; // Default
  final WerewolfPlayerService _playerService = WerewolfPlayerService();
  final TimerSettingsService _timerService = TimerSettingsService();

  @override
  void initState() {
    super.initState();
    _loadPlayerCount();
    _loadTimerSetting();
  }

  Future<void> _loadPlayerCount() async {
    final players = await _playerService.loadPlayers();
    if (mounted) {
      setState(() {
        _playerCount = players.length;
      });
    }
  }

  Future<void> _loadTimerSetting() async {
    final modeString = await _timerService.getTimerMode();
    TimerMode mode = TimerMode.fiveMinutes;

    switch (modeString) {
      case 'fiveMinutes':
        mode = TimerMode.fiveMinutes;
        break;
      case 'tenMinutes':
        mode = TimerMode.tenMinutes;
        break;
      case 'thirtySecondsPerPlayer':
        mode = TimerMode.thirtySecondsPerPlayer;
        break;
      case 'infinity':
        mode = TimerMode.infinity;
        break;
    }

    if (mounted) {
      setState(() {
        _timerMode = mode;
      });
    }
  }

  Future<void> _setTimerMode(TimerMode mode) async {
    String modeString = 'fiveMinutes';
    switch (mode) {
      case TimerMode.fiveMinutes:
        modeString = 'fiveMinutes';
        break;
      case TimerMode.tenMinutes:
        modeString = 'tenMinutes';
        break;
      case TimerMode.thirtySecondsPerPlayer:
        modeString = 'thirtySecondsPerPlayer';
        break;
      case TimerMode.infinity:
        modeString = 'infinity';
        break;
    }

    await _timerService.setTimerMode(modeString);
    setState(() {
      _timerMode = mode;
    });
  }

  String _getModeLabel(TimerMode mode, LanguageService languageService) {
    switch (mode) {
      case TimerMode.fiveMinutes:
        return languageService.translate('timer_5_min');
      case TimerMode.tenMinutes:
        return languageService.translate('timer_10_min');
      case TimerMode.thirtySecondsPerPlayer:
        return languageService.translate('timer_30s_p');
      case TimerMode.infinity:
        return languageService.translate('timer_infinity');
    }
  }

  Widget _buildTimerOption(TimerMode mode, LanguageService languageService) {
    final isSelected = _timerMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setTimerMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFCA311) : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFCA311)
                  : const Color(0xFF415A77),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getModeLabel(mode, languageService),
                style: GoogleFonts.pressStart2p(
                  color: isSelected ? Colors.black : Colors.white54,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTimerInfoDialog(
    BuildContext context,
    LanguageService languageService,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D1B2A),
            border: Border.all(color: const Color(0xFF778DA9), width: 4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF415A77),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF778DA9), width: 3),
                  ),
                ),
                child: Text(
                  languageService.translate('day_timer_info_title'),
                  style: GoogleFonts.pressStart2p(
                    color: const Color(0xFFE0E1DD),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    Text(
                      languageService.translate('day_timer_info_description'),
                      style: GoogleFonts.vt323(
                        color: Colors.white70,
                        fontSize: 18,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Options Title
                    Text(
                      languageService.translate('day_timer_options_title'),
                      style: GoogleFonts.pressStart2p(
                        color: const Color(0xFFFCA311),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Options List
                    _buildOptionInfo(
                      languageService.translate('day_timer_option_5min'),
                      languageService,
                    ),
                    const SizedBox(height: 8),
                    _buildOptionInfo(
                      languageService.translate('day_timer_option_10min'),
                      languageService,
                    ),
                    const SizedBox(height: 8),
                    _buildOptionInfo(
                      languageService.translate('day_timer_option_30s'),
                      languageService,
                    ),
                    const SizedBox(height: 8),
                    _buildOptionInfo(
                      languageService.translate('day_timer_option_infinity'),
                      languageService,
                    ),
                    const SizedBox(height: 20),
                    // Close button
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF415A77),
                            border: Border.all(
                              color: const Color(0xFF778DA9),
                              width: 2,
                            ),
                          ),
                          child: Text(
                            languageService.translate('close_button'),
                            style: GoogleFonts.pressStart2p(
                              color: const Color(0xFFE0E1DD),
                              fontSize: 10,
                            ),
                          ),
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

  Widget _buildOptionInfo(String text, LanguageService languageService) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6, right: 8),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(color: Color(0xFFFCA311)),
        ),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.vt323(
              color: Colors.white60,
              fontSize: 16,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageService = context.watch<LanguageService>();
    return Scaffold(
      body: Stack(
        children: [
          // Background Layer (Shared Component)
          const PixelStarfieldBackground(),

          // Foreground Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      // Layer 1: Outer Shadow/Border
                      decoration: BoxDecoration(
                        color: const Color(0xFF000000),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            offset: const Offset(8, 8),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Container(
                        // Layer 2: Metallic Frame
                        decoration: const BoxDecoration(
                          color: Color(0xFF778DA9),
                          border: Border.symmetric(
                            vertical: BorderSide(
                              color: Color(0xFF415A77),
                              width: 6,
                            ),
                            horizontal: BorderSide(
                              color: Color(0xFFE0E1DD),
                              width: 6,
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Container(
                          // Layer 3: Inner Game Area
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF0D1B2A,
                            ).withOpacity(0.95), // Deep Dark Blue
                            border: Border.all(
                              color: Colors.black.withOpacity(0.8),
                              width: 4,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Inner Header Section
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    PixelButton(
                                      label: context
                                          .watch<LanguageService>()
                                          .translate('back'),
                                      color: const Color(0xFF415A77),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Center(
                                        child: Text(
                                          context
                                              .watch<LanguageService>()
                                              .translate('werewolf_game'),
                                          style: GoogleFonts.pressStart2p(
                                            color: const Color(0xFFE0E1DD),
                                            fontSize: 16,
                                            shadows: [
                                              const Shadow(
                                                color: Colors.black,
                                                offset: Offset(4, 4),
                                              ),
                                            ],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Pixel Divider
                              Container(
                                height: 4,
                                color: const Color(0xFF778DA9),
                                margin: const EdgeInsets.only(bottom: 16),
                              ),
                              // Main Game Content
                              Expanded(
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        // Player Count Section
                                        GestureDetector(
                                          onTap: () async {
                                            await Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const WerewolfPlayersScreen(),
                                              ),
                                            );
                                            _loadPlayerCount();
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF1B263B,
                                              ).withOpacity(0.8),
                                              border: Border.all(
                                                color: const Color(0xFF415A77),
                                                width: 3,
                                              ),
                                            ),
                                            padding: const EdgeInsets.all(16),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  languageService.translate(
                                                    'players_title',
                                                  ),
                                                  style: GoogleFonts.vt323(
                                                    color: Colors.white70,
                                                    fontSize: 28,
                                                  ),
                                                ),
                                                Text(
                                                  '$_playerCount',
                                                  style: GoogleFonts.vt323(
                                                    color: Colors.white,
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        // Roles Section
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const WerewolfRolesScreen(),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF1B263B,
                                              ).withOpacity(0.8),
                                              border: Border.all(
                                                color: const Color(0xFF415A77),
                                                width: 3,
                                              ),
                                            ),
                                            padding: const EdgeInsets.all(16),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  languageService.translate(
                                                    'roles_title',
                                                  ),
                                                  style: GoogleFonts.vt323(
                                                    color: Colors.white70,
                                                    fontSize: 28,
                                                  ),
                                                ),
                                                Image.asset(
                                                  'assets/images/card.png',
                                                  width: 32,
                                                  height: 32,
                                                  fit: BoxFit.contain,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        // Leaderboards Section
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const WerewolfLeaderboardsScreen(),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF1B263B,
                                              ).withOpacity(0.8),
                                              border: Border.all(
                                                color: const Color(0xFF415A77),
                                                width: 3,
                                              ),
                                            ),
                                            padding: const EdgeInsets.all(16),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  languageService.translate(
                                                    'leaderboards_title',
                                                  ),
                                                  style: GoogleFonts.vt323(
                                                    color: Colors.white70,
                                                    fontSize: 28,
                                                  ),
                                                ),
                                                const Icon(
                                                  Icons.leaderboard,
                                                  color: Colors.white,
                                                  size: 28,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        // Timer Duration Selector
                                        Container(
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF1B263B,
                                            ).withOpacity(0.8),
                                            border: Border.all(
                                              color: const Color(0xFF415A77),
                                              width: 3,
                                            ),
                                          ),
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Header with info button
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    languageService.translate(
                                                      'day_timer',
                                                    ),
                                                    style: GoogleFonts.vt323(
                                                      color: Colors.white70,
                                                      fontSize: 20,
                                                    ),
                                                  ),
                                                  GestureDetector(
                                                    onTap: () =>
                                                        _showTimerInfoDialog(
                                                          context,
                                                          languageService,
                                                        ),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                          0xFF415A77,
                                                        ),
                                                        border: Border.all(
                                                          color: const Color(
                                                            0xFF778DA9,
                                                          ),
                                                          width: 2,
                                                        ),
                                                      ),
                                                      child: const Icon(
                                                        Icons.info_outline,
                                                        color: Color(
                                                          0xFFE0E1DD,
                                                        ),
                                                        size: 20,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              // Timer options grid
                                              Column(
                                                children: [
                                                  Row(
                                                    children: [
                                                      _buildTimerOption(
                                                        TimerMode.fiveMinutes,
                                                        languageService,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      _buildTimerOption(
                                                        TimerMode.tenMinutes,
                                                        languageService,
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      _buildTimerOption(
                                                        TimerMode
                                                            .thirtySecondsPerPlayer,
                                                        languageService,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      _buildTimerOption(
                                                        TimerMode.infinity,
                                                        languageService,
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        if (_playerCount < 5)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 8.0,
                                            ),
                                            child: Text(
                                              languageService.translate(
                                                'need_at_least_5_players',
                                              ),
                                              style: GoogleFonts.vt323(
                                                color: Colors.redAccent
                                                    .withOpacity(0.7),
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        PixelButton(
                                          label: languageService.translate(
                                            'game_on',
                                          ),
                                          color: _playerCount >= 5
                                              ? Colors.redAccent
                                              : Colors.grey,
                                          onPressed: _playerCount >= 5
                                              ? () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          const WerewolfPhaseOneScreen(),
                                                    ),
                                                  );
                                                }
                                              : null,
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
}
