import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:nightfall_project/base_components/pixel_starfield_background.dart';
import 'package:nightfall_project/base_components/pixel_button.dart';
import 'package:nightfall_project/base_components/pixel_heart.dart';
import 'package:nightfall_project/werewolves_game/offline_db/timer_settings_service.dart';
import 'package:nightfall_project/werewolves_game/offline_db/player_service.dart';
import 'package:nightfall_project/werewolves_game/offline_db/role_service.dart';
import 'phase_five.dart';
import 'phase_three_night.dart';
import 'package:provider/provider.dart';
import 'package:nightfall_project/services/language_service.dart';
import 'package:nightfall_project/services/sound_settings_service.dart';
import 'package:nightfall_project/base_components/puppet_master_transformation.dart';
import 'package:nightfall_project/base_components/gambler_bet_dialog.dart';

class WerewolfPhaseFourScreen extends StatefulWidget {
  final Map<String, WerewolfRole> playerRoles;
  final List<WerewolfPlayer> players;
  final List<String> deadPlayerIds; // IDs of players who are dead

  // History state passed specifically to maintain game state if we loop back to night
  final String? lastHealedId;
  final String? lastPlagueTargetId;
  final Map<String, int>? knightLives;

  // Gambler's bet from first night
  final GamblerBet? gamblerBet;

  final int dayNumber;

  // Dire Wolf: who was last silenced (passed through to next night)
  final String? lastDireWolfTargetId;

  const WerewolfPhaseFourScreen({
    super.key,
    required this.playerRoles,
    required this.players,
    required this.deadPlayerIds,
    this.lastHealedId,
    this.lastPlagueTargetId,
    this.knightLives,
    this.gamblerBet,
    this.dayNumber = 1,
    this.lastDireWolfTargetId,
  });

  @override
  State<WerewolfPhaseFourScreen> createState() =>
      _WerewolfPhaseFourScreenState();
}

class _WerewolfPhaseFourScreenState extends State<WerewolfPhaseFourScreen> {
  String? _selectedForHangingId;
  String? _selectedForRetaliationId;
  bool _isRetaliationPhase = false;
  int _secondsRemaining = 300; // 5 minutes
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadTimerDuration();
  }

  Future<void> _loadTimerDuration() async {
    final timerService = TimerSettingsService();
    final modeString = await timerService.getTimerMode();
    int duration = 300; // Default 5 minutes

    switch (modeString) {
      case 'fiveMinutes':
        duration = 300;
        break;
      case 'tenMinutes':
        duration = 600;
        break;
      case 'thirtySecondsPerPlayer':
        duration = 30 * widget.players.length;
        if (duration < 60) duration = 60;
        break;
      case 'infinity':
        duration = -1;
        break;
    }

    if (mounted) {
      setState(() {
        _secondsRemaining = duration;
      });
      _startTimer();
    }
  }

  void _startTimer() {
    if (_secondsRemaining == -1) return; // Infinity mode
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    if (_secondsRemaining == -1) return '∞';
    final minutes = (_secondsRemaining / 60).floor();
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color _getRoleColor(int roleId) {
    switch (roleId) {
      case 2: // Werewolf
      case 7: // Avenging Twin
      case 8: // Vampire
      case 18: // Dire Wolf
        return const Color(0xFFE63946); // Red
      case 6: // Twins
        return const Color(0xFF4CC9F0); // Blue
      case 3: // Doctor
        return Colors.green; // Classic Green
      case 5: // Plague Doctor
        return const Color(0xFF06D6A0); // Toxic/Emerald Green
      case 4: // Guard
        return const Color(0xFFFFD166); // Yellow
      case 10: // Drunk
        return const Color(0xFFCD9777); // Brown/Beer
      case 11: // Knight
        return const Color(0xFF9E2A2B); // Dark Red
      case 9: // Jester
        return const Color(0xFF9D4EDD); // Purple
      case 12: // Puppet Master
        return const Color(0xFF7209B7); // Indigo/Deep Purple
      case 13: // Executioner
        return const Color(0xFF6B4226); // Executioner-like Brown/Dark
      case 14: // Infected
        return const Color(0xFF8E9B97); // Sickly Green-Grey
      case 15: // Gambler
        return const Color(0xFFD4AF37); // Gold
      case 16: // Shaman
        return const Color(0xFFE8720C); // Ember orange
      case 17: // Wraith
        return const Color(0xFF6EC6CA); // Ghostly teal
      default:
        return Colors.white; // Villager etc.
    }
  }

  void _handleVote() {
    if (_isRetaliationPhase) {
      if (_selectedForRetaliationId != null) {
        _finalizeDayPhase();
      }
      return;
    }

    if (_selectedForHangingId == null) {
      _finalizeDayPhase();
      return;
    }

    final role = widget.playerRoles[_selectedForHangingId];

    // 1. Jester Check (Specific Win Condition)
    if (role?.id == 9) {
      // Jester Wins immediately if hanged
      _navigateToGameEnd("jester", widget.playerRoles);
      return;
    }

    // 2. Wraith Check (immune to hanging)
    if (role?.id == 17) {
      _selectedForHangingId = null;
      _finalizeDayPhase();
      return;
    }

    // 3. Executioner Check
    if (role?.id == 13) {
      // Only allow retaliation if there are other players alive at this point
      final remainingPlayersCount = widget.players
          .where(
            (p) =>
                !widget.deadPlayerIds.contains(p.id) &&
                p.id != _selectedForHangingId,
          )
          .length;

      if (remainingPlayersCount > 0) {
        setState(() {
          _isRetaliationPhase = true;
          _timer?.cancel(); // Stop timer during retaliation decision
        });
        return;
      }
    }

    // 3. Normal finalize if not Executioner or no one left to kill
    _finalizeDayPhase();
  }

  void _finalizeDayPhase() async {
    // 1. Compute Dead List
    List<String> nextDeadIds = List.from(widget.deadPlayerIds);
    if (_selectedForHangingId != null) {
      nextDeadIds.add(_selectedForHangingId!);
    }
    if (_isRetaliationPhase && _selectedForRetaliationId != null) {
      // Wraith immunity: Executioner's retaliation cannot kill the Wraith
      final retaliationRole = widget.playerRoles[_selectedForRetaliationId];
      if (retaliationRole?.id != 17) {
        nextDeadIds.add(_selectedForRetaliationId!);
      }
    }

    Map<String, WerewolfRole> updatedRoles = Map.from(widget.playerRoles);
    Map<String, int> updatedKnightLives = Map.from(widget.knightLives ?? {});

    // --- PRELIMINARY WIN CHECK ---
    // If the Executioner's kill results in all werewolves dead, we end now
    // so the Puppet Master doesn't transform needlessly.
    int preliminaryWerewolves = 0;
    for (final player in widget.players) {
      if (!nextDeadIds.contains(player.id)) {
        final role = widget.playerRoles[player.id];
        // Werewolf Alliance (2: Werewolf, 7: Avenging Twin, 8: Vampire, 18: Dire Wolf)
        if (role?.id == 2 || role?.id == 7 || role?.id == 8 || role?.id == 18) {
          preliminaryWerewolves++;
        }
      }
    }

    if (preliminaryWerewolves == 0) {
      // Determine if a Puppet Master is still alive to potentially transform
      bool hasPuppetMaster = widget.players.any(
        (p) =>
            !nextDeadIds.contains(p.id) && widget.playerRoles[p.id]?.id == 12,
      );

      // We end immediately ONLY if:
      // 1. It was the Executioner's retaliation kill (requested skip)
      // 2. OR there is no Puppet Master left to transform and keep the game alive.
      if (_isRetaliationPhase || !hasPuppetMaster) {
        _navigateToGameEnd("village", updatedRoles);
        return;
      }
    }
    // ----------------------------

    if (_selectedForHangingId != null) {
      final hangedRole = widget.playerRoles[_selectedForHangingId];

      // 3b. Puppet Master Transformation (happens after retaliation decision if Executioner)
      String? puppetMasterId;
      for (final player in widget.players) {
        if (!nextDeadIds.contains(player.id) &&
            widget.playerRoles[player.id]?.id == 12) {
          puppetMasterId = player.id;
          break;
        }
      }

      if (puppetMasterId != null && hangedRole != null) {
        final pmPlayer = widget.players.cast<WerewolfPlayer?>().firstWhere(
          (p) => p!.id == puppetMasterId,
          orElse: () => null,
        );
        if (pmPlayer != null) {
          context.read<SoundSettingsService>().stopAll();
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => PuppetMasterTransformationDialog(
              playerName: pmPlayer.name,
              targetRole: hangedRole,
              gamblerBet: widget.gamblerBet,
            ),
          );
        }
        updatedRoles[puppetMasterId] = hangedRole;
        if (hangedRole.id == 11) {
          updatedKnightLives[puppetMasterId] = 2;
        }
      }

      // 3c. Twin Transformation
      if (hangedRole?.id == 6) {
        for (final player in widget.players) {
          if (player.id != _selectedForHangingId &&
              !nextDeadIds.contains(player.id)) {
            final playerRole = widget.playerRoles[player.id];
            if (playerRole?.id == 6) {
              final avengingTwinRole = WerewolfRoleService().getRoleById(7);
              if (avengingTwinRole != null) {
                updatedRoles[player.id] = avengingTwinRole;
              }
              break;
            }
          }
        }
      }
    }

    // 4. Check Win Conditions (using updated roles)
    int aliveWerewolves = 0;
    int aliveVillagers = 0;

    for (final player in widget.players) {
      if (!nextDeadIds.contains(player.id)) {
        final role = updatedRoles[player.id];
        if (role != null) {
          // Werewolf Alliance (2, 7, 8, 18) count as "Bad"
          if (role.id == 2 || role.id == 7 || role.id == 8 || role.id == 18) {
            aliveWerewolves++;
          } else {
            aliveVillagers++;
          }
        }
      }
    }

    if (aliveWerewolves == 0) {
      _navigateToGameEnd("village", updatedRoles);
    } else if (aliveWerewolves >= aliveVillagers) {
      _navigateToGameEnd("werewolves", updatedRoles);
    } else if (aliveWerewolves == aliveVillagers - 1) {
      bool canPreventCasualty = false;
      for (final player in widget.players) {
        if (!nextDeadIds.contains(player.id)) {
          final role = updatedRoles[player.id];
          if (role != null) {
            if (role.id == 3 || role.id == 5) {
              canPreventCasualty = true;
              break;
            }
            if (role.id == 11 && (updatedKnightLives[player.id] ?? 0) >= 2) {
              canPreventCasualty = true;
              break;
            }
            // Wraith is immune to all kills, so werewolves could waste their kill
            if (role.id == 17) {
              canPreventCasualty = true;
              break;
            }
          }
        }
      }

      if (!canPreventCasualty) {
        _navigateToGameEnd("werewolves", updatedRoles);
      } else {
        _navigateToNextNight(nextDeadIds, updatedRoles, updatedKnightLives);
      }
    } else {
      _navigateToNextNight(nextDeadIds, updatedRoles, updatedKnightLives);
    }
  }

  void _navigateToGameEnd(
    String winningTeam,
    Map<String, WerewolfRole> playerRoles,
  ) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => WerewolfPhaseFiveScreen(
          playerRoles: playerRoles,
          players: widget.players,
          winningTeam: winningTeam,
          gamblerBet: widget.gamblerBet,
        ),
      ),
    );
  }

  void _navigateToNextNight(
    List<String> nextDeadIds,
    Map<String, WerewolfRole> updatedRoles,
    Map<String, int> updatedKnightLives,
  ) async {
    final isMuted = context.read<SoundSettingsService>().isMuted;

    if (!isMuted) {
      context.read<SoundSettingsService>().playGlobal(
        'audio/werewolves/owl_howl_night.mp3',
        loop: false,
      );
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => WerewolfPhaseThreeScreen(
            playerRoles: updatedRoles,
            players: widget.players
                .where((p) => !nextDeadIds.contains(p.id))
                .toList(),
            lastHealedId: widget.lastHealedId,
            lastPlagueTargetId: widget.lastPlagueTargetId,
            knightLives: updatedKnightLives,
            isFirstNight: false,
            gamblerBet: widget.gamblerBet,
            nightNumber: widget.dayNumber + 1,
            lastDireWolfTargetId: widget.lastDireWolfTargetId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter Alive Players for Display
    final alivePlayers = widget.players
        .where((p) => !widget.deadPlayerIds.contains(p.id))
        .toList();

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          context.read<SoundSettingsService>().stopAll();
        }
      },
      child: Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const PixelStarfieldBackground(),
          SafeArea(
            child: Column(
              children: [
                // Header - Full Width Match
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFFCA311,
                    ).withOpacity(0.2), // Day/Sun Color
                    border: const Border(
                      bottom: BorderSide(color: Color(0xFFFCA311), width: 2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        context
                            .watch<LanguageService>()
                            .translate(
                              _isRetaliationPhase
                                  ? 'executioner_retaliation_title'
                                  : 'day_phase_title',
                            )
                            .replaceAll(
                              '{number}',
                              widget.dayNumber.toString(),
                            ),
                        style: GoogleFonts.pressStart2p(
                          color: _isRetaliationPhase
                              ? const Color(0xFFE63946)
                              : const Color(0xFFFCA311),
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.watch<LanguageService>().translate(
                          _isRetaliationPhase
                              ? 'executioner_retaliation_desc'
                              : 'discuss_and_vote_instruction',
                        ),
                        style: GoogleFonts.vt323(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (!_isRetaliationPhase) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0xFFFCA311).withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                context.watch<LanguageService>().translate(
                                  'votes_needed_label',
                                ),
                                style: GoogleFonts.pressStart2p(
                                  color: Colors.white70,
                                  fontSize: 9,
                                ),
                              ),
                              const SizedBox(width: 9),
                              Text(
                                '${(alivePlayers.length / 2).floor() + 1}',
                                style: GoogleFonts.pressStart2p(
                                  color: const Color(0xFFFCA311),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Content - Alive Players Grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.8,
                        ),
                    itemCount: alivePlayers.length,
                    itemBuilder: (context, index) {
                      final player = alivePlayers[index];
                      final role = widget.playerRoles[player.id];
                      final isSelectedForHanging =
                          _selectedForHangingId == player.id;
                      final isSelectedForRetaliation =
                          _selectedForRetaliationId == player.id;
                      final isSelected = _isRetaliationPhase
                          ? isSelectedForRetaliation
                          : isSelectedForHanging;

                      // Dim players already selected for hanging during retaliation phase
                      final bool isDimmed =
                          _isRetaliationPhase && isSelectedForHanging;

                      return Opacity(
                        opacity: isDimmed ? 0.5 : 1.0,
                        child: GestureDetector(
                          onTap: isDimmed
                              ? null
                              : () {
                                  setState(() {
                                    if (_isRetaliationPhase) {
                                      if (isSelectedForRetaliation) {
                                        _selectedForRetaliationId = null;
                                      } else {
                                        _selectedForRetaliationId = player.id;
                                      }
                                    } else {
                                      if (isSelectedForHanging) {
                                        _selectedForHangingId = null;
                                      } else {
                                        _selectedForHangingId = player.id;
                                      }
                                    }
                                  });
                                },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFE63946).withOpacity(0.4)
                                  : isDimmed
                                  ? Colors.black54
                                  : const Color(0xFF1B263B),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFE63946)
                                    : isDimmed
                                    ? Colors.white10
                                    : const Color(0xFF415A77),
                                width: isSelected ? 3 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFE63946,
                                        ).withOpacity(0.6),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              children: [
                                // Image Top (Expanded)
                                Expanded(
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: role != null
                                            ? Image.asset(
                                                role.imagePath,
                                                fit: BoxFit.cover,
                                                alignment: Alignment.topCenter,
                                              )
                                            : const Center(
                                                child: Icon(
                                                  Icons.person,
                                                  color: Colors.white,
                                                  size: 40,
                                                ),
                                              ),
                                      ),
                                      if (role?.id == 11)
                                        Positioned(
                                          top: 4,
                                          left: 4,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 2,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(
                                                0.5,
                                              ),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(
                                                  0.2,
                                                ),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                PixelHeart(
                                                  isFull:
                                                      (widget.knightLives?[player
                                                              .id] ??
                                                          0) >=
                                                      1,
                                                  size: 13,
                                                ),
                                                const SizedBox(width: 4),
                                                PixelHeart(
                                                  isFull:
                                                      (widget.knightLives?[player
                                                              .id] ??
                                                          0) >=
                                                      2,
                                                  size: 13,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      if (isSelected || isSelectedForHanging)
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: TweenAnimationBuilder<double>(
                                            duration: const Duration(
                                              milliseconds: 400,
                                            ),
                                            tween: Tween(
                                              begin: 1.0,
                                              end: 1.0,
                                            ), // No animation needed if static but keeping structure
                                            builder: (context, value, child) {
                                              return Transform.scale(
                                                scale: value,
                                                child: Opacity(
                                                  opacity: value.clamp(
                                                    0.0,
                                                    1.0,
                                                  ),
                                                  child: child,
                                                ),
                                              );
                                            },
                                            child: Container(
                                              width: 30,
                                              height: 30,
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(
                                                  0.6,
                                                ),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFFE63946,
                                                  ).withOpacity(0.4),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Image.asset(
                                                isSelectedForRetaliation
                                                    ? 'assets/images/executioner_kill.png'
                                                    : 'assets/images/hanging_noose.png',
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Footer Text
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  color: Colors.black87,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        player.name,
                                        style: GoogleFonts.vt323(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (role != null)
                                        Text(
                                          context
                                              .watch<LanguageService>()
                                              .translate(role.translationKey)
                                              .toUpperCase(),
                                          style: GoogleFonts.pressStart2p(
                                            color: _getRoleColor(role.id),
                                            fontSize: 8,
                                            height: 1.5,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                if (isSelected && !_isRetaliationPhase)
                                  Text(
                                    context.watch<LanguageService>().translate(
                                      'hang_button',
                                    ),
                                    style: GoogleFonts.pressStart2p(
                                      color: Colors.redAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (isSelected && _isRetaliationPhase)
                                  Text(
                                    context
                                        .watch<LanguageService>()
                                        .translate('execute_button')
                                        .toUpperCase(),
                                    style: GoogleFonts.pressStart2p(
                                      color: Colors.redAccent,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Footer (Timer & Action) - Redesigned
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B263B),
                    border: const Border(
                      top: BorderSide(color: Color(0xFF415A77), width: 2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Timer Display
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          border: Border.all(
                            color: _secondsRemaining < 60
                                ? Colors.redAccent
                                : const Color(0xFF06D6A0),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          _formattedTime,
                          style: GoogleFonts.vt323(
                            color: _secondsRemaining < 60
                                ? Colors.redAccent
                                : Colors.greenAccent,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Buttons
                      if (!_isRetaliationPhase)
                        Expanded(
                          child: PixelButton(
                            label: context.watch<LanguageService>().translate(
                              'skip_button',
                            ),
                            color: const Color(0xFF415A77),
                            onPressed: () {
                              _selectedForHangingId = null;
                              _handleVote();
                            },
                          ),
                        ),
                      if (!_isRetaliationPhase) const SizedBox(width: 12),
                      Expanded(
                        child: PixelButton(
                          label: _isRetaliationPhase
                              ? context.watch<LanguageService>().translate(
                                  'execute_button',
                                )
                              : _selectedForHangingId == null
                              ? context.watch<LanguageService>().translate(
                                  'select_button',
                                )
                              : context.watch<LanguageService>().translate(
                                  'hang_button',
                                ),
                          color:
                              (_isRetaliationPhase
                                  ? _selectedForRetaliationId == null
                                  : _selectedForHangingId == null)
                              ? Colors.grey
                              : const Color(0xFFE63946),
                          onPressed:
                              (_isRetaliationPhase
                                  ? _selectedForRetaliationId == null
                                  : _selectedForHangingId == null)
                              ? null
                              : _handleVote,
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
    ),
    );
  }
}
