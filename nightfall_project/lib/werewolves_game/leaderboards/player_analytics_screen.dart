import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightfall_project/base_components/pixel_starfield_background.dart';
import 'package:nightfall_project/base_components/pixel_button.dart';
import 'package:nightfall_project/werewolves_game/offline_db/player_service.dart';
import 'package:nightfall_project/werewolves_game/offline_db/player_analytics_service.dart';
import 'package:nightfall_project/werewolves_game/offline_db/role_service.dart';
import 'package:nightfall_project/services/language_service.dart';
import 'package:provider/provider.dart';

class PlayerAnalyticsScreen extends StatefulWidget {
  final WerewolfPlayer player;

  const PlayerAnalyticsScreen({super.key, required this.player});

  @override
  State<PlayerAnalyticsScreen> createState() => _PlayerAnalyticsScreenState();
}

class _PlayerAnalyticsScreenState extends State<PlayerAnalyticsScreen> {
  final PlayerAnalyticsService _analyticsService = PlayerAnalyticsService();
  final WerewolfRoleService _roleService = WerewolfRoleService();
  List<GameRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final records = await _analyticsService.loadPlayerAnalytics(
      widget.player.id,
    );
    if (mounted) {
      setState(() {
        _records = records;
        _isLoading = false;
      });
    }
  }

  int get _totalGames => _records.length;
  int get _totalWins => _records.where((r) => r.won).length;
  int get _totalLosses => _totalGames - _totalWins;
  String get _winRate =>
      _totalGames == 0 ? '0' : ((_totalWins / _totalGames) * 100).toStringAsFixed(0);

  int _winsForAlliance(int allianceId) =>
      _records.where((r) => r.allianceId == allianceId && r.won).length;
  int _gamesForAlliance(int allianceId) =>
      _records.where((r) => r.allianceId == allianceId).length;

  Color _getAllianceColor(int allianceId) {
    switch (allianceId) {
      case 1:
        return const Color(0xFF52B788);
      case 2:
        return const Color(0xFFE63946);
      case 3:
        return const Color(0xFF9D4EDD);
      default:
        return Colors.white;
    }
  }

  Color _getRoleColor(int roleId) {
    switch (roleId) {
      case 2:
      case 7:
      case 8:
      case 18:
        return const Color(0xFFE63946);
      case 6:
        return const Color(0xFF4CC9F0);
      case 3:
        return Colors.green;
      case 5:
        return const Color(0xFF06D6A0);
      case 4:
        return const Color(0xFFFFD166);
      case 9:
        return const Color(0xFF9D4EDD);
      case 10:
        return const Color(0xFFCD9777);
      case 11:
        return const Color(0xFF9E2A2B);
      case 12:
        return const Color(0xFF7209B7);
      case 13:
        return const Color(0xFF6B4226);
      case 14:
        return const Color(0xFF8E9B97);
      case 15:
        return const Color(0xFFD4AF37);
      case 16:
        return const Color(0xFFE8720C);
      case 17:
        return const Color(0xFF6EC6CA);
      default:
        return Colors.white;
    }
  }

  Map<int, _RoleStats> _buildRoleStats() {
    final Map<int, _RoleStats> stats = {};
    for (final record in _records) {
      stats.putIfAbsent(
        record.roleId,
        () => _RoleStats(roleId: record.roleId, roleName: record.roleName),
      );
      stats[record.roleId]!.played++;
      if (record.won) stats[record.roleId]!.won++;
    }
    final sorted = stats.entries.toList()
      ..sort((a, b) => b.value.played.compareTo(a.value.played));
    return Map.fromEntries(sorted);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageService>();

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
                        label: lang.translate('back'),
                        color: const Color(0xFF415A77),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Center(
                          child: Text(
                            lang.translate('analytics_title'),
                            style: GoogleFonts.pressStart2p(
                              color: const Color(0xFFE0E1DD),
                              fontSize: 12,
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
                      const SizedBox(width: 60),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Main content
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
                          child: _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF778DA9),
                                  ),
                                )
                              : ListView(
                                  padding: const EdgeInsets.all(16),
                                  children: [
                                    _buildPlayerHeader(lang),
                                    const SizedBox(height: 16),
                                    if (_records.isEmpty)
                                      _buildEmptyState(lang)
                                    else ...[
                                      _buildOverviewStats(lang),
                                      const SizedBox(height: 20),
                                      _buildAllianceBreakdown(lang),
                                      const SizedBox(height: 20),
                                      _buildRoleHistory(lang),
                                    ],
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

  Widget _buildPlayerHeader(LanguageService lang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        border: Border.all(color: const Color(0xFF778DA9), width: 3),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.player.name,
              style: GoogleFonts.pressStart2p(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            '${widget.player.points} ${lang.translate('pts')}',
            style: GoogleFonts.vt323(
              color: const Color(0xFFFFD700),
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(LanguageService lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          lang.translate('analytics_no_games'),
          style: GoogleFonts.vt323(color: Colors.white54, fontSize: 24),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildOverviewStats(LanguageService lang) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                lang.translate('analytics_total_games'),
                '$_totalGames',
                const Color(0xFF778DA9),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                lang.translate('analytics_win_rate'),
                '$_winRate%',
                _totalGames == 0
                    ? const Color(0xFF778DA9)
                    : int.parse(_winRate) >= 50
                        ? const Color(0xFF52B788)
                        : const Color(0xFFE63946),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                lang.translate('analytics_wins'),
                '$_totalWins',
                const Color(0xFF52B788),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                lang.translate('analytics_losses'),
                '$_totalLosses',
                const Color(0xFFE63946),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        border: Border.all(color: accentColor.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.pressStart2p(
              color: accentColor,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.vt323(color: Colors.white54, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAllianceBreakdown(LanguageService lang) {
    final alliances = [
      (1, lang.translate('analytics_village_wins')),
      (2, lang.translate('analytics_werewolf_wins')),
      (3, lang.translate('analytics_special_wins')),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(lang.translate('analytics_alliance_breakdown')),
        const SizedBox(height: 12),
        ...alliances.map((a) {
          final allianceId = a.$1;
          final name = a.$2;
          final games = _gamesForAlliance(allianceId);
          final wins = _winsForAlliance(allianceId);
          final color = _getAllianceColor(allianceId);
          final pct = games == 0 ? 0 : ((wins / games) * 100).round();

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                border: Border.all(color: color.withOpacity(0.3), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 4, height: 16, color: color),
                      const SizedBox(width: 8),
                      Text(
                        name,
                        style: GoogleFonts.pressStart2p(
                          color: color,
                          fontSize: 9,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$wins/$games',
                        style: GoogleFonts.vt323(
                          color: Colors.white70,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 42,
                        child: Text(
                          '$pct%',
                          style: GoogleFonts.vt323(
                            color: color,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(0),
                    child: LinearProgressIndicator(
                      value: games == 0 ? 0 : wins / games,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        color.withOpacity(0.7),
                      ),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRoleHistory(LanguageService lang) {
    final roleStats = _buildRoleStats();
    if (roleStats.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(lang.translate('analytics_role_history')),
        const SizedBox(height: 12),
        ...roleStats.entries.map((entry) {
          final stats = entry.value;
          final role = _roleService.getRoleById(stats.roleId);
          final color = _getRoleColor(stats.roleId);
          final translatedName = role != null
              ? lang.translate(role.translationKey)
              : stats.roleName;
          final pct = stats.played == 0
              ? 0
              : ((stats.won / stats.played) * 100).round();

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                border: Border.all(color: color.withOpacity(0.3), width: 1),
              ),
              child: Row(
                children: [
                  if (role != null)
                    Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: color.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Image.asset(
                        role.imagePath,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          translatedName.toUpperCase(),
                          style: GoogleFonts.pressStart2p(
                            color: color,
                            fontSize: 8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '${lang.translate('analytics_played')}: ${stats.played}',
                              style: GoogleFonts.vt323(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${lang.translate('analytics_won')}: ${stats.won}',
                              style: GoogleFonts.vt323(
                                color: const Color(0xFF52B788),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: GoogleFonts.vt323(
                      color: pct >= 50
                          ? const Color(0xFF52B788)
                          : const Color(0xFFE63946),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 20, color: const Color(0xFF778DA9)),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.pressStart2p(
            color: const Color(0xFFE0E1DD),
            fontSize: 9,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFF778DA9).withOpacity(0.3),
          ),
        ),
      ],
    );
  }
}

class _RoleStats {
  final int roleId;
  final String roleName;
  int played = 0;
  int won = 0;

  _RoleStats({required this.roleId, required this.roleName});
}
