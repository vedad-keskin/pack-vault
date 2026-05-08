import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightfall_project/base_components/pixel_starfield_background.dart';
import 'package:nightfall_project/base_components/pixel_button.dart';
import 'package:nightfall_project/werewolves_game/offline_db/role_service.dart';
import 'package:nightfall_project/werewolves_game/offline_db/player_service.dart';
import 'package:nightfall_project/werewolves_game/offline_db/alliance_service.dart';
import 'package:nightfall_project/werewolves_game/offline_db/game_settings_service.dart';
import 'package:nightfall_project/werewolves_game/game_flow/phase_two.dart';
import 'package:provider/provider.dart';
import 'package:nightfall_project/services/language_service.dart';

class WerewolfPhaseOneScreen extends StatefulWidget {
  const WerewolfPhaseOneScreen({super.key});

  @override
  State<WerewolfPhaseOneScreen> createState() => _WerewolfPhaseOneScreenState();
}

class _WerewolfPhaseOneScreenState extends State<WerewolfPhaseOneScreen> {
  final WerewolfRoleService _roleService = WerewolfRoleService();
  final WerewolfPlayerService _playerService = WerewolfPlayerService();
  final WerewolfAllianceService _allianceService = WerewolfAllianceService();
  final WerewolfGameSettingsService _settingsService =
      WerewolfGameSettingsService();

  late List<WerewolfRole> _availableRoles;
  final Map<int, int> _roleCounts = {};
  int _totalPlayers = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final players = await _playerService.loadPlayers();
    final allRoles = _roleService.getRoles();
    _totalPlayers = players.length;

    // Exclude Avenging Twin (ID 7)
    _availableRoles = allRoles.where((role) => role.id != 7).toList();

    // Load saved settings
    final savedRoles = await _settingsService.loadSelectedRoles(_totalPlayers);

    setState(() {
      if (savedRoles != null) {
        // Use saved roles
        for (var role in _availableRoles) {
          _roleCounts[role.id] = savedRoles[role.id] ?? 0;
        }
      } else {
        // Generate random roles
        _generateRandomSelection();
      }
      _isLoading = false;
    });
  }

  void _generateRandomSelection() {
    // Reset
    for (var role in _availableRoles) {
      _roleCounts[role.id] = 0;
    }

    final random = Random();
    int assigned = 0;

    // 1. Mandatory Aggressor (Werewolf or Vampire)
    // We prioritize Werewolf (ID 2) for simplicity in random start
    _roleCounts[2] = 1;
    assigned++;

    // 2. Randomly fill special roles if enough space
    final specialRoles = _availableRoles
        .where((r) => r.id != 1 && r.id != 2)
        .toList();
    specialRoles.shuffle();

    for (var role in specialRoles) {
      if (assigned >= _totalPlayers - 1)
        break; // Keep room for at least one villager

      // Special rule: Twins (ID 6) need 2 slots
      if (role.id == 6) {
        if (assigned <= _totalPlayers - 3 && random.nextBool()) {
          _roleCounts[6] = 2;
          assigned += 2;
        }
      } else {
        // Others (0-1)
        if (random.nextBool()) {
          _roleCounts[role.id] = 1;
          assigned++;
        }
      }
    }

    // 3. Fill the rest with Villagers
    _roleCounts[1] = _totalPlayers - assigned;
  }

  int get _selectedRoleCount =>
      _roleCounts.values.fold(0, (sum, count) => sum + count);

  bool get _isBalanceValid {
    int werewolfAllianceCount = 0;
    int otherAllianceCount = 0;

    _roleCounts.forEach((roleId, count) {
      final role = _roleService.getRoleById(roleId);
      if (role != null) {
        if (role.allianceId == 2) {
          werewolfAllianceCount += count;
        } else {
          otherAllianceCount += count;
        }
      }
    });

    // Valid if:
    // 1. At least one predator
    // 2. Predators < Villagers + Specials
    return werewolfAllianceCount >= 1 &&
        werewolfAllianceCount < otherAllianceCount;
  }

  bool get _canProceed {
    return _selectedRoleCount == _totalPlayers && _isBalanceValid;
  }

  void _updateRoleCount(int roleId, int delta) {
    setState(() {
      final currentCount = _roleCounts[roleId] ?? 0;

      // Specialized logic for Twins (ID 6): 0 or 2
      if (roleId == 6) {
        if (delta > 0) {
          _roleCounts[6] = 2;
        } else {
          _roleCounts[6] = 0;
        }
      } else {
        // Standard logic
        int newCount = currentCount + delta;
        if (newCount < 0) return;

        // Werewolves: 1-3
        if (roleId == 2 && newCount > 3) return;

        // Others (excluding Villagers): 0-1
        if (roleId != 1 && roleId != 2 && newCount > 1) return;

        _roleCounts[roleId] = newCount;
      }

      // Save changes immediately
      _settingsService.saveSelectedRoles(_roleCounts, _totalPlayers);
    });
  }

  /// Shuffles roles and assigns them to players, re-rolling when too many
  /// players receive the same role they had in the previous game.
  ///
  /// NOTE: Anti-repeat logic was removed to keep role assignment purely random.
  Future<Map<String, WerewolfRole>> _assignRolesRandom(
    List<WerewolfPlayer> players,
  ) async {
    final random = Random.secure();

    // Flatten role counts into a list of role IDs
    final List<int> flattenedRoleIds = [];
    _roleCounts.forEach((roleId, count) {
      for (int i = 0; i < count; i++) {
        flattenedRoleIds.add(roleId);
      }
    });

    // Pure random assignment (single shuffle)
    flattenedRoleIds.shuffle(random);

    final Map<String, WerewolfRole> assignment = {};
    for (int i = 0; i < players.length; i++) {
      final role = _roleService.getRoleById(flattenedRoleIds[i]);
      if (role != null) {
        assignment[players[i].id] = role;
      }
    }

    return assignment;
  }

  Color _getAllianceColor(int allianceId) {
    switch (allianceId) {
      case 1:
        return Colors.blueAccent;
      case 2:
        return Colors.redAccent;
      case 3:
        return Colors.purpleAccent;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const PixelStarfieldBackground(),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      PixelButton(
                        label: context.watch<LanguageService>().translate(
                          'back',
                        ),
                        color: const Color(0xFF415A77),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Text(
                          context.watch<LanguageService>().translate(
                            'prepare_game_title',
                          ),
                          style: GoogleFonts.pressStart2p(
                            color: Colors.white,
                            fontSize: 18,
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
                    ],
                  ),
                ),

                // Player Info Bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  color: Colors.redAccent.withOpacity(0.2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context
                            .watch<LanguageService>()
                            .translate('players_count_label')
                            .replaceAll('{count}', '$_totalPlayers'),
                        style: GoogleFonts.vt323(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        context
                            .watch<LanguageService>()
                            .translate('selected_count_label')
                            .replaceAll('{count}', '$_selectedRoleCount'),
                        style: GoogleFonts.vt323(
                          color: _selectedRoleCount == _totalPlayers
                              ? Colors.greenAccent
                              : Colors.amberAccent,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                ),

                // Roles List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _availableRoles.length,
                    itemBuilder: (context, index) {
                      final role = _availableRoles[index];
                      final count = _roleCounts[role.id] ?? 0;
                      final isSelected = count > 0;
                      final allianceColor = _getAllianceColor(role.allianceId);

                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isSelected ? 1.0 : 0.4,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          height: 100, // Fixed height for consistent tap areas
                          decoration: BoxDecoration(
                            color: isSelected
                                ? allianceColor.withOpacity(0.15)
                                : const Color(0xFF1B263B).withOpacity(0.5),
                            border: Border.all(
                              color: isSelected
                                  ? allianceColor
                                  : const Color(0xFF415A77),
                              width: 3,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: allianceColor.withOpacity(0.3),
                                      blurRadius: 10,
                                      spreadRadius: -2,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Stack(
                            children: [
                              // Visual Content
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 12.0,
                                ),
                                child: Row(
                                  children: [
                                    // Subtle Minus Indicator (Integrated)
                                    AnimatedOpacity(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      opacity: isSelected ? 0.3 : 0.0,
                                      child: const Icon(
                                        Icons.remove,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Role Icon
                                    Container(
                                      width: 65,
                                      height: 65,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.white70
                                              : Colors.white24,
                                          width: 2,
                                        ),
                                      ),
                                      child: Image.asset(
                                        role.imagePath,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            context
                                                .watch<LanguageService>()
                                                .translate(role.translationKey)
                                                .toUpperCase(),
                                            style: GoogleFonts.pressStart2p(
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.white60,
                                              fontSize:
                                                  12, // Slightly smaller to fit everything
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _allianceService
                                                        .getAllianceById(
                                                          role.allianceId,
                                                        )
                                                        ?.translationKey !=
                                                    null
                                                ? context
                                                      .watch<LanguageService>()
                                                      .translate(
                                                        _allianceService
                                                            .getAllianceById(
                                                              role.allianceId,
                                                            )!
                                                            .translationKey,
                                                      )
                                                      .toUpperCase()
                                                : '',
                                            style: GoogleFonts.vt323(
                                              color: isSelected
                                                  ? allianceColor
                                                  : Colors.white38,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Count Display
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.white10
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.white24
                                              : Colors.transparent,
                                        ),
                                      ),
                                      child: Text(
                                        '$count',
                                        style: GoogleFonts.pressStart2p(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.white24,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 8),
                                    // Subtle Plus Indicator (Integrated)
                                    Opacity(
                                      opacity: 0.3,
                                      child: const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Interactive Areas (Huge invisible tap zones)
                              Row(
                                children: [
                                  // Decrement Area (Left 40%)
                                  Expanded(
                                    flex: 4,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () =>
                                          _updateRoleCount(role.id, -1),
                                      child: const SizedBox.expand(),
                                    ),
                                  ),
                                  // Increment Area (Right 60%)
                                  Expanded(
                                    flex: 6,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => _updateRoleCount(role.id, 1),
                                      child: const SizedBox.expand(),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Footer Validation & Proceed
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  child: Column(
                    children: [
                      if (_selectedRoleCount != _totalPlayers)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            color: Colors.black45,
                            child: Text(
                              _selectedRoleCount < _totalPlayers
                                  ? context
                                        .watch<LanguageService>()
                                        .translate('need_more_roles')
                                        .replaceAll(
                                          '{count}',
                                          '${_totalPlayers - _selectedRoleCount}',
                                        )
                                  : context
                                        .watch<LanguageService>()
                                        .translate('remove_roles')
                                        .replaceAll(
                                          '{count}',
                                          '${_selectedRoleCount - _totalPlayers}',
                                        ),
                              style: GoogleFonts.vt323(
                                color: Colors.amberAccent,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                      if (!_isBalanceValid &&
                          _selectedRoleCount == _totalPlayers)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            color: Colors.black45,
                            child: Builder(
                              builder: (context) {
                                final werewolfCount =
                                    (_roleCounts[2] ?? 0) +
                                    (_roleCounts[8] ?? 0) +
                                    (_roleCounts[18] ?? 0);
                                if (werewolfCount < 1) {
                                  return Text(
                                    context.watch<LanguageService>().translate(
                                      'need_predator',
                                    ),
                                    style: GoogleFonts.vt323(
                                      color: Colors.greenAccent,
                                      fontSize: 20,
                                    ),
                                  );
                                } else {
                                  return Text(
                                    context.watch<LanguageService>().translate(
                                      'too_many_predators',
                                    ),
                                    style: GoogleFonts.vt323(
                                      color: Colors.redAccent,
                                      fontSize: 20,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: PixelButton(
                          label: context.watch<LanguageService>().translate(
                            'proceed_button',
                          ),
                          color: _canProceed
                              ? Colors.green
                              : const Color(0xFF415A77).withOpacity(0.5),
                          onPressed: _canProceed
                              ? () async {
                                  final players = await _playerService
                                      .loadPlayers();

                                  final playerRoles =
                                      await _assignRolesRandom(players);

                                  if (mounted) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            WerewolfPhaseTwoScreen(
                                              players: players,
                                              playerRoles: playerRoles,
                                            ),
                                      ),
                                    );
                                  }
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
