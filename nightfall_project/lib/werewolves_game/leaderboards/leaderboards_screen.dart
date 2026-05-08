import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightfall_project/base_components/pixel_starfield_background.dart';
import 'package:nightfall_project/base_components/pixel_button.dart';
import 'package:nightfall_project/werewolves_game/offline_db/player_service.dart';
import 'package:nightfall_project/werewolves_game/offline_db/player_analytics_service.dart';
import 'package:nightfall_project/werewolves_game/leaderboards/player_analytics_screen.dart';
import 'package:nightfall_project/services/language_service.dart';
import 'package:nightfall_project/services/live_session_service.dart';
import 'package:provider/provider.dart';

class WerewolfLeaderboardsScreen extends StatefulWidget {
  const WerewolfLeaderboardsScreen({super.key});

  @override
  State<WerewolfLeaderboardsScreen> createState() =>
      _WerewolfLeaderboardsScreenState();
}

class _WerewolfLeaderboardsScreenState
    extends State<WerewolfLeaderboardsScreen> {
  final WerewolfPlayerService _playerService = WerewolfPlayerService();
  List<WerewolfPlayer> _players = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final players = await _playerService.loadPlayers();

    // Sort by points descending
    players.sort((a, b) => b.points.compareTo(a.points));

    if (mounted) {
      setState(() {
        _players = players;
      });
    }
  }

  Future<void> _showResetConfirmation() async {
    final languageService = context.read<LanguageService>();
    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1B2A),
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Color(0xFF778DA9), width: 4),
        ),
        title: Text(
          languageService.translate('reset_points_q'),
          style: GoogleFonts.pressStart2p(
            color: const Color(0xFFE0E1DD),
            fontSize: 16,
          ),
        ),
        content: Text(
          languageService.translate('reset_undo_warn'),
          style: GoogleFonts.vt323(color: Colors.white70, fontSize: 18),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  languageService.translate('cancel_button'),
                  style: GoogleFonts.pressStart2p(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              PixelButton(
                label: languageService.translate('reset_button'),
                color: Colors.redAccent.withOpacity(0.8),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirm == true) {
      final liveSession = context.read<LiveSessionService>();
      if (liveSession.hasSession) {
        await liveSession.deleteSession();
      }
      final updatedPlayers = await _playerService.resetPlayersPoints(_players);
      await PlayerAnalyticsService().clearAllAnalytics();
      if (mounted) {
        setState(() {
          _players = updatedPlayers;
        });
      }
    }
  }

  Future<void> _handleGoLive() async {
    final liveSession = context.read<LiveSessionService>();
    await liveSession.createSession();

    final allAnalytics = await PlayerAnalyticsService().loadAllAnalytics();
    await liveSession.syncLeaderboard(_players, allAnalytics);
  }

  Future<void> _handleStopLive() async {
    final languageService = context.read<LanguageService>();
    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1B2A),
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Color(0xFF778DA9), width: 4),
        ),
        title: Text(
          languageService.translate('live_confirm_stop'),
          style: GoogleFonts.pressStart2p(
            color: const Color(0xFFE0E1DD),
            fontSize: 14,
          ),
        ),
        content: Text(
          languageService.translate('live_stop_warn'),
          style: GoogleFonts.vt323(color: Colors.white70, fontSize: 18),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  languageService.translate('cancel_button'),
                  style: GoogleFonts.pressStart2p(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              PixelButton(
                label: languageService.translate('stop_live'),
                color: Colors.redAccent.withOpacity(0.8),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirm == true) {
      await context.read<LiveSessionService>().deleteSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageService = context.watch<LanguageService>();
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const PixelStarfieldBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Header
                  Row(
                    children: [
                      PixelButton(
                        label: languageService.translate('back'),
                        color: const Color(0xFF415A77),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Center(
                          child: Text(
                            languageService.translate('leaderboards_title'),
                            style: GoogleFonts.pressStart2p(
                              color: const Color(0xFFE0E1DD),
                              fontSize: 14,
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
                      const SizedBox(width: 2),
                      PixelButton(
                        label: languageService.translate('reset_button'),
                        color: Colors.redAccent.withOpacity(0.7),
                        onPressed: _showResetConfirmation,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Live Session Controls
                  Consumer<LiveSessionService>(
                    builder: (context, liveSession, _) {
                      if (liveSession.hasSession) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF52B788).withOpacity(0.1),
                            border: Border.all(
                              color: const Color(0xFF52B788),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: liveSession.isSyncing
                                              ? Colors.amber
                                              : const Color(0xFF52B788),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        languageService.translate('live_code_label'),
                                        style: GoogleFonts.vt323(
                                          color: Colors.white54,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(
                                        text: liveSession.sessionCode!,
                                      ));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${liveSession.sessionCode} copied!',
                                            style: GoogleFonts.vt323(fontSize: 18),
                                          ),
                                          duration: const Duration(seconds: 1),
                                          backgroundColor: const Color(0xFF415A77),
                                        ),
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        Text(
                                          liveSession.sessionCode!,
                                          style: GoogleFonts.pressStart2p(
                                            color: const Color(0xFF52B788),
                                            fontSize: 18,
                                            letterSpacing: 4,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.copy,
                                          color: Color(0xFF52B788),
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              PixelButton(
                                label: languageService.translate('stop_live'),
                                color: Colors.redAccent.withOpacity(0.7),
                                onPressed: _handleStopLive,
                              ),
                            ],
                          ),
                        );
                      }
                      return SizedBox(
                        width: double.infinity,
                        child: PixelButton(
                          label: languageService.translate('go_live'),
                          color: const Color(0xFF52B788).withOpacity(0.8),
                          onPressed: _players.isEmpty ? null : _handleGoLive,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Main Content
                  Expanded(
                    child: Container(
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
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1B2A).withOpacity(0.95),
                            border: Border.all(
                              color: Colors.black.withOpacity(0.8),
                              width: 4,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                width: double.infinity,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Color(0xFF778DA9),
                                      width: 4,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  languageService.translate(
                                    'top_players_title',
                                  ),
                                  style: GoogleFonts.vt323(
                                    color: Colors.white70,
                                    fontSize: 24,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: _players.isEmpty
                                    ? Center(
                                        child: Text(
                                          languageService.translate(
                                            'no_players_found',
                                          ),
                                          style: GoogleFonts.vt323(
                                            color: Colors.white54,
                                            fontSize: 24,
                                          ),
                                        ),
                                      )
                                    : ListView.separated(
                                        padding: const EdgeInsets.all(16),
                                        itemCount: _players.length,
                                        separatorBuilder: (ctx, i) =>
                                            const SizedBox(height: 12),
                                        itemBuilder: (context, index) {
                                          final player = _players[index];
                                          final rank = index + 1;
                                          Color rankColor = Colors.white;

                                          if (rank == 1)
                                            rankColor = const Color(
                                              0xFFFFD700,
                                            ); // Gold
                                          else if (rank == 2)
                                            rankColor = const Color(
                                              0xFFC0C0C0,
                                            ); // Silver
                                          else if (rank == 3)
                                            rankColor = const Color(
                                              0xFFCD7F32,
                                            ); // Bronze

                                          return GestureDetector(
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      PlayerAnalyticsScreen(
                                                        player: player,
                                                      ),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(
                                                  0.5,
                                                ),
                                                border: Border.all(
                                                  color: const Color(0xFF415A77),
                                                  width: 2,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Text(
                                                    "$rank.",
                                                    style: GoogleFonts.vt323(
                                                      color: rankColor,
                                                      fontSize: 28,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: Text(
                                                      player.name,
                                                      style: GoogleFonts.vt323(
                                                        color: Colors.white,
                                                        fontSize: 28,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    "${player.points}",
                                                    style: GoogleFonts.vt323(
                                                      color: rankColor,
                                                      fontSize: 28,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    "pts",
                                                    style: GoogleFonts.vt323(
                                                      color: Colors.white54,
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Icon(
                                                    Icons.chevron_right,
                                                    color: Color(0xFF778DA9),
                                                    size: 24,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
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
