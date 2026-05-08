import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:nightfall_project/base_components/pixel_starfield_background.dart';
import 'package:nightfall_project/base_components/pixel_button.dart';
import 'package:nightfall_project/werewolves_game/offline_db/player_service.dart';
import 'package:nightfall_project/werewolves_game/offline_db/role_service.dart';
import 'package:nightfall_project/werewolves_game/layouts/game_layout.dart';
import 'package:provider/provider.dart';
import 'package:nightfall_project/services/language_service.dart';
import 'package:nightfall_project/services/sound_settings_service.dart';
import 'package:nightfall_project/base_components/gambler_bet_dialog.dart';
import 'package:nightfall_project/werewolves_game/offline_db/player_analytics_service.dart';
import 'package:nightfall_project/services/live_session_service.dart';

class WerewolfPhaseFiveScreen extends StatefulWidget {
  final Map<String, WerewolfRole> playerRoles;
  final List<WerewolfPlayer> players;
  final String winningTeam; // 'The Werewolves', 'The Village', 'The Jester'
  final GamblerBet? gamblerBet;

  const WerewolfPhaseFiveScreen({
    super.key,
    required this.playerRoles,
    required this.players,
    required this.winningTeam,
    this.gamblerBet,
  });

  @override
  State<WerewolfPhaseFiveScreen> createState() =>
      _WerewolfPhaseFiveScreenState();
}

class _WerewolfPhaseFiveScreenState extends State<WerewolfPhaseFiveScreen> {
  final WerewolfPlayerService _playerService = WerewolfPlayerService();
  String _typedTitle = "";
  Timer? _titleTimer;
  bool _showWinners = false;
  List<WerewolfPlayer> _appPlayersUpdated = [];

  // Gambler tracking
  bool _gamblerWonBet = false;
  int _gamblerBonusPoints = 0;

  // Color scheme based on winner
  Color get _themeColor {
    final team = widget.winningTeam.toLowerCase();
    if (team.contains('werewolves')) return const Color(0xFFE63946); // Red
    if (team.contains('village')) return const Color(0xFF52B788); // Green
    if (team.contains('jester')) return const Color(0xFF9D4EDD); // Purple
    if (team.contains('specials')) return const Color(0xFF9D4EDD); // Purple
    return Colors.white;
  }

  @override
  void initState() {
    super.initState();
    _distributePoints();
    _startTypewriter();
    _playWinSound();
  }

  Future<void> _playWinSound() async {
    if (context.read<SoundSettingsService>().isMuted) return;

    String soundPath = "";
    final team = widget.winningTeam.toLowerCase();
    if (team.contains('werewolves')) {
      soundPath = 'audio/werewolves/werewolf_win.mp3';
    } else if (team.contains('village')) {
      soundPath = 'audio/werewolves/village_win.mp3';
    } else if (team.contains('jester')) {
      soundPath = 'audio/werewolves/jester_win.mp3';
    } else if (team.contains('specials')) {
      soundPath = 'audio/werewolves/jester_win.mp3';
    }

    if (soundPath.isNotEmpty) {
      context.read<SoundSettingsService>().playGlobal(soundPath, loop: false);
    }
  }

  @override
  void dispose() {
    _titleTimer?.cancel();
    // Note: We don't stop/dispose the global player here as the layout's Back button handles it
    super.dispose();
  }

  Future<void> _distributePoints() async {
    // 1. Determine Winning Alliance ID
    int winningAllianceId = -1;
    final team = widget.winningTeam.toLowerCase();
    if (team.contains('village')) winningAllianceId = 1;
    if (team.contains('werewolves')) winningAllianceId = 2;
    if (team.contains('specials')) winningAllianceId = 3;

    // 2. Check if Gambler won their bet
    bool gamblerWonBet = false;
    int gamblerBonusPoints = 0;
    if (widget.gamblerBet != null) {
      switch (widget.gamblerBet!) {
        case GamblerBet.village:
          if (team.contains('village')) {
            gamblerWonBet = true;
            gamblerBonusPoints = 1;
          }
          break;
        case GamblerBet.werewolves:
          if (team.contains('werewolves')) {
            gamblerWonBet = true;
            gamblerBonusPoints = 2;
          }
          break;
        case GamblerBet.specials:
          if (team.contains('jester') || team.contains('specials')) {
            gamblerWonBet = true;
            gamblerBonusPoints = 3;
          }
          break;
      }
    }

    // Track if gambler won for UI display
    _gamblerWonBet = gamblerWonBet;
    _gamblerBonusPoints = gamblerBonusPoints;

    // 3. Load Current Players from DB (to get current points state)
    List<WerewolfPlayer> currentDbPlayers = await _playerService.loadPlayers();

    // 4. Update Points
    List<WerewolfPlayer> updatedList = currentDbPlayers.map((dbPlayer) {
      // Find role in this game session
      final role = widget.playerRoles[dbPlayer.id];
      if (role != null) {
        int pointsToAdd = 0;

        // Special logic for Jester (individual win)
        if (team.contains('jester')) {
          if (role.id == 9) {
            pointsToAdd = role.points;
          }
        }
        // Alliance logic for standard teams
        else if (role.allianceId == winningAllianceId) {
          // Award points based on Role's point value
          pointsToAdd = role.points;
        }

        // Gambler bonus points (Gambler role ID: 15)
        if (role.id == 15 && gamblerWonBet) {
          pointsToAdd += gamblerBonusPoints;
        }

        if (pointsToAdd > 0) {
          return WerewolfPlayer(
            id: dbPlayer.id,
            name: dbPlayer.name,
            points: dbPlayer.points + pointsToAdd,
          );
        }
      }
      return dbPlayer;
    }).toList();

    // 5. Save to DB
    await _playerService.savePlayers(updatedList);

    // 6. Record analytics for each participating player
    final Map<String, GameRecord> analyticsRecords = {};
    for (final entry in widget.playerRoles.entries) {
      final playerId = entry.key;
      final role = entry.value;

      bool playerWon = false;
      int pointsEarned = 0;

      if (team.contains('jester')) {
        if (role.id == 9) {
          playerWon = true;
          pointsEarned = role.points;
        }
      } else if (role.allianceId == winningAllianceId) {
        playerWon = true;
        pointsEarned = role.points;
      }

      if (role.id == 15 && gamblerWonBet) {
        playerWon = true;
        pointsEarned += gamblerBonusPoints;
      }

      analyticsRecords[playerId] = GameRecord(
        roleId: role.id,
        roleName: role.name,
        allianceId: role.allianceId,
        winningTeam: widget.winningTeam,
        won: playerWon,
        pointsEarned: pointsEarned,
        playedAt: DateTime.now(),
      );
    }
    await PlayerAnalyticsService().recordGame(analyticsRecords);

    // Fire-and-forget live sync if session is active
    final liveSession = context.read<LiveSessionService>();
    if (liveSession.hasSession) {
      final allAnalytics = await PlayerAnalyticsService().loadAllAnalytics();
      liveSession.syncLeaderboard(updatedList, allAnalytics);
    }

    if (mounted) {
      setState(() {
        _appPlayersUpdated = updatedList;
      });
    }
  }

  void _startTypewriter() {
    final languageService = context.read<LanguageService>();
    final fullText = languageService
        .translate('win_title_${widget.winningTeam}')
        .toUpperCase();
    int index = 0;

    _titleTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (index < fullText.length) {
        setState(() {
          _typedTitle += fullText[index];
        });
        index++;
      } else {
        timer.cancel();
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _showWinners = true;
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const PixelStarfieldBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    context.watch<LanguageService>().translate(
                      'game_over_title',
                    ),
                    style: GoogleFonts.vt323(
                      color: Colors.white70,
                      fontSize: 32,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Winner Card (Animated)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.elasticOut,
                    padding: const EdgeInsets.symmetric(
                      vertical: 32,
                      horizontal: 16,
                    ),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _themeColor.withOpacity(0.1),
                      border: Border.all(color: _themeColor, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: _themeColor.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: Colors.amber,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _typedTitle,
                          style: GoogleFonts.pressStart2p(
                            color: _themeColor,
                            fontSize: 20,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Winners List & Points
                  if (_showWinners && _appPlayersUpdated.isNotEmpty) ...[
                    Text(
                      context.watch<LanguageService>().translate(
                        'points_distributed_label',
                      ),
                      style: GoogleFonts.vt323(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._buildWinnersList(),
                  ],

                  const SizedBox(height: 60),

                  // Navigation
                  if (_showWinners)
                    SizedBox(
                      width: double.infinity,
                      child: PixelButton(
                        label: context.watch<LanguageService>().translate(
                          'back_to_menu',
                        ),
                        color: const Color(0xFF415A77),
                        onPressed: () async {
                          context.read<SoundSettingsService>().stopAll();
                          if (mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const WerewolfGameLayout(),
                              ),
                              (route) => route.isFirst,
                            );
                          }
                        },
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

  List<Widget> _buildWinnersList() {
    // Determine Winning Alliance ID again for filter
    int winningAllianceId = -1;
    final team = widget.winningTeam.toLowerCase();
    if (team.contains('village')) winningAllianceId = 1;
    if (team.contains('werewolves')) winningAllianceId = 2;
    if (team.contains('specials')) winningAllianceId = 3;

    List<Widget> list = [];

    // Iterate through ALL players who participated (from database), not just survivors
    for (var dbPlayer in _appPlayersUpdated) {
      final role = widget.playerRoles[dbPlayer.id];
      if (role == null) continue;

      bool isWinner = false;
      int pointsAwarded = 0;

      if (team.contains('jester')) {
        if (role.id == 9) {
          isWinner = true;
          pointsAwarded = role.points;
        }
      } else if (role.allianceId == winningAllianceId) {
        isWinner = true;
        pointsAwarded = role.points;
      }

      // Gambler bonus (role ID 15)
      bool isGamblerWinner = false;
      if (role.id == 15 && _gamblerWonBet) {
        isGamblerWinner = true;
        pointsAwarded = _gamblerBonusPoints;
      }

      if (isWinner || isGamblerWinner) {
        list.add(
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isGamblerWinner && !isWinner
                  ? const Color(0xFFD4AF37).withOpacity(0.1)
                  : Colors.white.withOpacity(0.05),
              border: Border.all(
                color: isGamblerWinner && !isWinner
                    ? const Color(0xFFD4AF37).withOpacity(0.5)
                    : Colors.white12,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                if (isGamblerWinner)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.casino,
                      color: const Color(0xFFD4AF37),
                      size: 18,
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dbPlayer.name,
                        style: GoogleFonts.vt323(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                      if (isGamblerWinner)
                        Text(
                          context.watch<LanguageService>().translate(
                            'gambler_won_bet',
                          ),
                          style: GoogleFonts.vt323(
                            color: const Color(0xFFD4AF37),
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  "+$pointsAwarded PTS",
                  style: GoogleFonts.pressStart2p(
                    color: isGamblerWinner
                        ? const Color(0xFFD4AF37)
                        : Colors.amber,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    if (list.isEmpty) {
      list.add(
        Text(
          context.watch<LanguageService>().translate('no_points_awarded_msg'),
          style: GoogleFonts.vt323(color: Colors.white54),
        ),
      );
    }

    return list;
  }
}
