import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightfall_project/base_components/pixel_starfield_background.dart';
import 'package:nightfall_project/base_components/pixel_button.dart';
import 'package:nightfall_project/werewolves_game/offline_db/player_service.dart';
import 'package:nightfall_project/werewolves_game/offline_db/role_service.dart';
import 'phase_four_day.dart';
import 'phase_five.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import 'package:nightfall_project/services/language_service.dart';
import 'package:nightfall_project/services/sound_settings_service.dart';
import 'package:nightfall_project/base_components/guard_inspection_dialog.dart';
import 'package:nightfall_project/base_components/pixel_heart.dart';
import 'package:nightfall_project/base_components/gambler_bet_dialog.dart';
import 'package:nightfall_project/base_components/shaman_inspection_dialog.dart';

class WerewolfPhaseThreeScreen extends StatefulWidget {
  final Map<String, WerewolfRole> playerRoles;
  final List<WerewolfPlayer> players;

  // History state passed from previous nights
  final String? lastHealedId;
  final String? lastPlagueTargetId;
  final Map<String, int>? knightLives;
  // Night/Day counting
  final int nightNumber;
  final bool isFirstNight;
  // Gambler's bet (passed through if already made)
  final GamblerBet? gamblerBet;
  // Dire Wolf: who was last silenced (can't re-target + silence effect on even nights)
  final String? lastDireWolfTargetId;

  const WerewolfPhaseThreeScreen({
    super.key,
    required this.playerRoles,
    required this.players,
    this.lastHealedId,
    this.lastPlagueTargetId,
    this.knightLives,
    this.isFirstNight = false,
    this.gamblerBet,
    this.nightNumber = 1,
    this.lastDireWolfTargetId,
  });

  @override
  State<WerewolfPhaseThreeScreen> createState() =>
      _WerewolfPhaseThreeScreenState();
}

enum NightStep {
  gambler, // First night only - Gambler places bet
  werewolves, // Includes Vampire and Dire Wolf
  direWolf, // Every other night (1st, 3rd, 5th...) - silences one player
  doctor,
  guard,
  plagueDoctor,
  shaman, // Every 2nd night (2nd, 4th, 6th...) - sees true role
}

class _WerewolfPhaseThreeScreenState extends State<WerewolfPhaseThreeScreen> {
  late List<NightStep> _nightSteps;
  int _currentStepIndex = 0;

  // Night State
  String? _targetKilledId;
  String? _targetHealedId;
  String? _guardTargetId;
  String? _shamanTargetId;
  String? _direWolfSilenceTargetId;
  late Map<String, int> _knightLives;

  // Gambler state
  GamblerBet? _gamblerBet;
  bool _gamblerBetMade = false;

  // Prevents the delayed ambient music from overriding a special-dialog track
  bool _suppressAmbient = false;

  // Guards against double-tap on the action button
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    // Initialize Gambler bet from widget (if passed from previous state)
    _gamblerBet = widget.gamblerBet;
    _gamblerBetMade = widget.gamblerBet != null;

    _calculateNightSteps();
    _playAmbientNightSounds();

    // Initialize Knight Lives
    if (widget.knightLives != null) {
      _knightLives = Map.from(widget.knightLives!);
    } else {
      _knightLives = {};
      widget.playerRoles.forEach((playerId, role) {
        if (role.id == 11) {
          // Knight ID
          _knightLives[playerId] = 2; // Starts with 2 lives
        }
      });
    }

    // Show Gambler dialog on first night if it's the first step
    if (_nightSteps.isNotEmpty && _nightSteps.first == NightStep.gambler) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGamblerBetDialog();
      });
    }
  }

  Future<void> _playAmbientNightSounds() async {
    try {
      // Wait for owl howl to finish (approximately 3-4 seconds)
      await Future.delayed(const Duration(seconds: 4));

      if (!mounted || _suppressAmbient) return;
      await context.read<SoundSettingsService>().playGlobal(
        'audio/werewolves/birds_frogs_night.mp3',
        loop: true,
      );
    } catch (e) {
      debugPrint('Error playing ambient night sounds: $e');
    }
  }

  @override
  void dispose() {
    // Note: We don't stop the global player here as we want it to persist across steps,
    // but it will be stopped by the Back button in the layout if the user exits.
    super.dispose();
  }

  void _calculateNightSteps() {
    _nightSteps = [];

    // Get role IDs only from alive players
    final alivePlayerIds = widget.players.map((p) => p.id).toSet();
    final aliveRoles = widget.playerRoles.entries
        .where((entry) => alivePlayerIds.contains(entry.key))
        .map((entry) => entry.value.id)
        .toSet();

    // Determine if a player is silenced this night.
    // Silence takes effect the night AFTER the Dire Wolf acts (even nights).
    final bool isSilenceActive =
        widget.lastDireWolfTargetId != null && widget.nightNumber % 2 == 0;
    final int? silencedRoleId = isSilenceActive
        ? widget.playerRoles[widget.lastDireWolfTargetId]?.id
        : null;

    // 0. Gambler (only on first night, only if alive and bet not yet made)
    if (widget.isFirstNight && !_gamblerBetMade && aliveRoles.contains(15)) {
      _nightSteps.add(NightStep.gambler);
    }

    // 1. Werewolves/Vampire/Avenging Twin/Dire Wolf always wake up
    if (aliveRoles.contains(2) ||
        aliveRoles.contains(7) ||
        aliveRoles.contains(8) ||
        aliveRoles.contains(18)) {
      _nightSteps.add(NightStep.werewolves);
    }

    // 1b. Dire Wolf solo step (odd nights: 1st, 3rd, 5th...)
    if (aliveRoles.contains(18) && widget.nightNumber % 2 == 1) {
      _nightSteps.add(NightStep.direWolf);
    }

    // 2. Doctor (only if alive and not silenced)
    if (aliveRoles.contains(3) && silencedRoleId != 3) {
      _nightSteps.add(NightStep.doctor);
    }

    // 3. Guard (only if alive and not silenced)
    if (aliveRoles.contains(4) && silencedRoleId != 4) {
      _nightSteps.add(NightStep.guard);
    }

    // 4. Plague Doctor (only if alive and not silenced)
    if (aliveRoles.contains(5) && silencedRoleId != 5) {
      _nightSteps.add(NightStep.plagueDoctor);
    }

    // 5. Shaman (only if alive, only on even nights, and not silenced)
    if (aliveRoles.contains(16) &&
        widget.nightNumber % 2 == 0 &&
        silencedRoleId != 16) {
      _nightSteps.add(NightStep.shaman);
    }

    // Safety check if no steps (shouldn't happen in standard setup)
    if (_nightSteps.isEmpty) {
      // Auto proceed?
    }
  }

  void _showGamblerBetDialog() {
    // Find the Gambler player
    String? gamblerPlayerId;
    String gamblerPlayerName = '';
    for (final entry in widget.playerRoles.entries) {
      if (entry.value.id == 15) {
        gamblerPlayerId = entry.key;
        final player = widget.players.firstWhere(
          (p) => p.id == gamblerPlayerId,
          orElse: () => WerewolfPlayer(id: '', name: 'Gambler'),
        );
        gamblerPlayerName = player.name;
        break;
      }
    }

    if (gamblerPlayerId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GamblerBetDialog(
        playerName: gamblerPlayerName,
        onBetConfirmed: (bet) {
          Navigator.of(context).pop();
          setState(() {
            _gamblerBet = bet;
            _gamblerBetMade = true;
          });
          _nextStep();
        },
      ),
    );
  }

  NightStep get _currentStep => _nightSteps[_currentStepIndex];

  String get _stepTitle {
    final languageService = context.read<LanguageService>();
    switch (_currentStep) {
      case NightStep.gambler:
        return languageService.translate('step_gambler_title');
      case NightStep.werewolves:
        return languageService.translate('step_werewolves_title');
      case NightStep.direWolf:
        return languageService.translate('step_dire_wolf_title');
      case NightStep.doctor:
        return languageService.translate('step_doctor_title');
      case NightStep.guard:
        return languageService.translate('step_guard_title');
      case NightStep.plagueDoctor:
        return languageService.translate('step_plague_doctor_title');
      case NightStep.shaman:
        return languageService.translate('step_shaman_title');
    }
  }

  String get _stepInstruction {
    final languageService = context.read<LanguageService>();
    switch (_currentStep) {
      case NightStep.gambler:
        return languageService.translate('step_gambler_instruction');
      case NightStep.werewolves:
        return languageService.translate('step_werewolves_instruction');
      case NightStep.direWolf:
        return languageService.translate('step_dire_wolf_instruction');
      case NightStep.doctor:
        return languageService.translate('step_doctor_instruction');
      case NightStep.guard:
        return languageService.translate('step_guard_instruction');
      case NightStep.plagueDoctor:
        return languageService.translate('step_plague_doctor_instruction');
      case NightStep.shaman:
        return languageService.translate('step_shaman_instruction');
    }
  }

  Color get _stepColor {
    switch (_currentStep) {
      case NightStep.gambler:
        return const Color(0xFFD4AF37); // Gold
      case NightStep.werewolves:
        return const Color(0xFFE63946); // Red
      case NightStep.direWolf:
        return const Color(0xFF5B8FB9); // Icy blue
      case NightStep.doctor:
        return Colors.green; // Green
      case NightStep.guard:
        return const Color(0xFFFFD166); // Yellow (Shieldy)
      case NightStep.plagueDoctor:
        return const Color(0xFF06D6A0); // Greenish/Toxic
      case NightStep.shaman:
        return const Color(0xFFE8720C); // Ember orange
    }
  }

  bool get _canProceed {
    switch (_currentStep) {
      case NightStep.gambler:
        return _gamblerBetMade; // Gambler must make a bet (handled by dialog)
      case NightStep.werewolves:
        return _targetKilledId != null; // Werewolves must kill someone
      case NightStep.direWolf:
        return _direWolfSilenceTargetId != null; // Dire Wolf must silence someone
      case NightStep.doctor:
        return _targetHealedId != null; // Doctor must select someone
      case NightStep.guard:
        return _guardTargetId != null;
      case NightStep.plagueDoctor:
        return _targetHealedId != null; // Plague Doctor must select someone
      case NightStep.shaman:
        return _shamanTargetId != null; // Shaman must select someone
    }
  }

  void _handlePlayerTap(WerewolfPlayer player) {
    if (_currentStepIndex >= _nightSteps.length) return;

    final targetRole = widget.playerRoles[player.id];
    if (targetRole == null) return; // Should not happen

    setState(() {
      switch (_currentStep) {
        case NightStep.gambler:
          // Gambler step doesn't use player selection - handled by dialog
          return;

        case NightStep.werewolves:
          // Restriction: Cannot kill Werewolf Alliance
          if (targetRole.allianceId == 2) {
            return;
          }

          if (_targetKilledId == player.id) {
            _targetKilledId = null;
          } else {
            _targetKilledId = player.id;
          }
          break;

        case NightStep.direWolf:
          // Cannot silence wolves, self, or last silenced target
          if (targetRole.allianceId == 2) return;
          if (player.id == widget.lastDireWolfTargetId) return;

          if (_direWolfSilenceTargetId == player.id) {
            _direWolfSilenceTargetId = null;
          } else {
            _direWolfSilenceTargetId = player.id;
          }
          break;

        case NightStep.doctor:
          // Restriction: Cannot heal same person twice in a row
          if (player.id == widget.lastHealedId) {
            return;
          }

          if (_targetHealedId == player.id) {
            _targetHealedId = null;
          } else {
            _targetHealedId = player.id;
          }
          break;

        case NightStep.guard:
          // Toggle selection. Only one can be selected.
          if (_guardTargetId == player.id) {
            _guardTargetId = null;
          } else {
            _guardTargetId = player.id;
          }
          break;

        case NightStep.plagueDoctor:
          // Restriction: Cannot heal same person twice in a row
          if (player.id == widget.lastPlagueTargetId) {
            return;
          }

          if (_targetHealedId == player.id) {
            _targetHealedId = null;
          } else {
            _targetHealedId = player.id;
          }
          break;

        case NightStep.shaman:
          // Shaman cannot inspect himself
          if (targetRole.id == 16) {
            return;
          }

          if (_shamanTargetId == player.id) {
            _shamanTargetId = null;
          } else {
            _shamanTargetId = player.id;
          }
          break;
      }
    });
  }

  Future<void> _performGuardCheck(WerewolfPlayer player) async {
    final role = widget.playerRoles[player.id];
    bool isWerewolf = false;

    // Check Logic: Werewolf (2), Avenging Twin (7), Drunk (10), Dire Wolf (18) -> "W" (Threat)
    // Everyone else (including Vampire 8, Jester 9) -> "V" (Clear)
    if (role != null) {
      if (role.id == 2 || role.id == 7 || role.id == 10 || role.id == 18) {
        isWerewolf = true;
      }
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GuardInspectionDialog(
        playerName: player.name,
        isWerewolf: isWerewolf,
        onClose: () => Navigator.of(context).pop(),
      ),
    );

    // Auto-advance after check
    _guardTargetId = null;
    _nextStep();
  }

  Future<void> _performShamanCheck(WerewolfPlayer player) async {
    final role = widget.playerRoles[player.id];
    if (role == null) return;

    _suppressAmbient = true;
    context.read<SoundSettingsService>().stopAll();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ShamanInspectionDialog(
        playerName: player.name,
        role: role,
        onClose: () => Navigator.of(context).pop(),
      ),
    );

    _shamanTargetId = null;
    _nextStep();
  }

  // Specific state for distinct roles
  String? _doctorHealedId;
  String? _plagueDoctorTargetId;

  void _nextStep() {
    if (_isProcessing) return;
    _isProcessing = true;

    // Trigger Guard Check if target selected (Prioritize this even if it's the last step)
    if (_currentStep == NightStep.guard && _guardTargetId != null) {
      final player = widget.players.cast<WerewolfPlayer?>().firstWhere(
        (p) => p!.id == _guardTargetId,
        orElse: () => null,
      );
      if (player == null) { _isProcessing = false; return; }
      _isProcessing = false;
      _performGuardCheck(player);
      return;
    }

    // Trigger Shaman Check if target selected
    if (_currentStep == NightStep.shaman && _shamanTargetId != null) {
      final player = widget.players.cast<WerewolfPlayer?>().firstWhere(
        (p) => p!.id == _shamanTargetId,
        orElse: () => null,
      );
      if (player == null) { _isProcessing = false; return; }
      _isProcessing = false;
      _performShamanCheck(player);
      return;
    }

    if (_currentStepIndex < _nightSteps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });

      final finishedStep = _nightSteps[_currentStepIndex - 1];
      if (finishedStep == NightStep.doctor) {
        _doctorHealedId = _targetHealedId;
        _targetHealedId = null;
      }
      if (finishedStep == NightStep.plagueDoctor) {
        _plagueDoctorTargetId = _targetHealedId;
        _targetHealedId = null;
      }
      if (finishedStep == NightStep.guard) {
        _guardTargetId = null;
      }
      if (finishedStep == NightStep.shaman) {
        _shamanTargetId = null;
      }

      _isProcessing = false;
    } else {
      // End of Night - Capture last step's action
      if (_currentStep == NightStep.plagueDoctor) {
        _plagueDoctorTargetId = _targetHealedId;
      } else if (_currentStep == NightStep.doctor) {
        _doctorHealedId = _targetHealedId;
      }

      _calculateResults();
      _isProcessing = false;
    }
  }

  void _calculateResults() {
    List<String> deadPlayerIds = [];
    List<String> messages = [];
    final rng = Random();
    final lang = context.read<LanguageService>();

    // 1. Identify active targets and actions
    String? werewolfTarget = _targetKilledId;
    String? doctorTarget = _doctorHealedId;
    String? plagueTarget = _plagueDoctorTargetId;
    bool isPlagueAccident = (plagueTarget != null && rng.nextInt(3) == 0);

    // 2. Identify all players involved in an action
    final actionPlayerIds = {
      if (werewolfTarget != null) werewolfTarget,
      if (doctorTarget != null) doctorTarget,
      if (plagueTarget != null) plagueTarget,
    };

    // 3. Resolve results for each involved player
    for (final playerId in actionPlayerIds) {
      final player = widget.players.cast<WerewolfPlayer?>().firstWhere(
        (p) => p!.id == playerId,
        orElse: () => null,
      );
      if (player == null) continue;
      final role = widget.playerRoles[playerId];
      if (role == null) continue;

      final isKnight = role.id == 11;
      int currentLives = _knightLives[playerId] ?? 0;

      bool hitByWerewolves = (playerId == werewolfTarget);
      bool hitByPlagueAccident = (playerId == plagueTarget && isPlagueAccident);
      bool savedByDoctor = (playerId == doctorTarget);
      bool savedByPlagueHeal = (playerId == plagueTarget && !isPlagueAccident);

      // Wraith immunity: cannot be killed by any night action
      if (role.id == 17) {
        if (hitByWerewolves) {
          messages.add(lang.translate('wraith_immune_werewolf_msg'));
        }
        if (hitByPlagueAccident) {
          messages.add(lang.translate('wraith_immune_plague_msg'));
        }
        continue;
      }

      if (isKnight) {
        if (currentLives == 2) {
          // Rule: Hit by both on 2 lives -> Instant death
          if (hitByWerewolves && hitByPlagueAccident) {
            deadPlayerIds.add(playerId);
            _knightLives[playerId] = 0;
            messages.add(lang.translate('knight_overwhelmed_msg'));
          }
          // Rule: Hit by either on 2 lives -> Down to 1 life (Armor sacrificed)
          else if (hitByWerewolves || hitByPlagueAccident) {
            _knightLives[playerId] = 1;
            messages.add(lang.translate('knight_armor_msg'));
          }
        } else if (currentLives == 1) {
          // Rule: Hit by both on 1 life -> Can be SAVED by Doctor
          if (hitByWerewolves && hitByPlagueAccident) {
            if (savedByDoctor) {
              messages.add(
                lang
                    .translate('doctor_saved_from_both_msg')
                    .replaceAll('{name}', player.name),
              );
            } else {
              deadPlayerIds.add(playerId);
              _knightLives[playerId] = 0;
              messages.add(lang.translate('knight_overwhelmed_msg'));
            }
          }
          // Rule: Hit by one on 1 life -> Can be SAVED, but not REGENERATED
          else if (hitByWerewolves || hitByPlagueAccident) {
            if (savedByDoctor && savedByPlagueHeal) {
              if (hitByWerewolves) {
                messages.add(
                  lang
                      .translate('triple_save_from_werewolves_msg')
                      .replaceAll('{name}', player.name),
                );
              } else {
                messages.add(
                  lang
                      .translate('double_heal_msg')
                      .replaceAll('{name}', player.name),
                );
              }
            } else if (savedByDoctor || savedByPlagueHeal) {
              // Saved by one healer -> survives
              if (savedByDoctor && hitByPlagueAccident) {
                messages.add(
                  lang
                      .translate('doctor_saved_from_plague_msg')
                      .replaceAll('{name}', player.name),
                );
              } else if (savedByDoctor && hitByWerewolves) {
                messages.add(
                  lang
                      .translate('doctor_saved_msg')
                      .replaceAll('{name}', player.name),
                );
              }

              // Also report Plague Doctor's successful treatment if applicable
              if (savedByPlagueHeal) {
                if (role.id == 5) {
                  messages.add(lang.translate('plague_doctor_self_saved_msg'));
                } else {
                  messages.add(
                    lang
                        .translate('plague_doctor_saved_msg')
                        .replaceAll('{name}', player.name),
                  );
                }
              }
            } else {
              // Not saved by anyone -> Death
              deadPlayerIds.add(playerId);
              _knightLives[playerId] = 0;
              messages.add(
                lang
                    .translate('player_is_dead_label')
                    .replaceAll('{name}', player.name.toUpperCase()),
              );
            }
          }
          // Knight with 1 life NOT attacked -> nothing happens (survives)
        }
      } else {
        // NON-KNIGHT standard logic
        bool alreadyReportedDoctorSave = false;

        if (hitByWerewolves) {
          if (savedByDoctor) {
            alreadyReportedDoctorSave = true;
            if (savedByPlagueHeal) {
              messages.add(
                lang
                    .translate('double_save_from_werewolves_msg')
                    .replaceAll('{name}', player.name),
              );
            } else if (hitByPlagueAccident) {
              messages.add(
                lang
                    .translate('doctor_saved_from_both_msg')
                    .replaceAll('{name}', player.name),
              );
            } else {
              messages.add(
                lang
                    .translate('doctor_saved_msg')
                    .replaceAll('{name}', player.name),
              );
            }
          } else if (savedByPlagueHeal) {
            if (role.id == 5) {
              messages.add(lang.translate('plague_doctor_self_saved_msg'));
            } else {
              messages.add(
                lang
                    .translate('plague_doctor_saved_msg')
                    .replaceAll('{name}', player.name),
              );
            }
          } else {
            deadPlayerIds.add(playerId);
          }
        }

        if (hitByPlagueAccident && !deadPlayerIds.contains(playerId)) {
          // Doctor can save from Plague accident
          if (savedByDoctor) {
            if (!alreadyReportedDoctorSave) {
              messages.add(
                lang
                    .translate('doctor_saved_from_plague_msg')
                    .replaceAll('{name}', player.name),
              );
            }
          } else {
            deadPlayerIds.add(playerId);
            if (role.id == 5) {
              messages.add(lang.translate('plague_doctor_self_killed_msg'));
            } else {
              messages.add(
                lang
                    .translate('plague_doctor_killed_msg')
                    .replaceAll('{name}', player.name),
              );
            }
          }
        }

        // Informative message for successful Plague Doctor treatment without werewolf attack (or even with Doctor save)
        if (savedByPlagueHeal && !hitByWerewolves) {
          if (savedByDoctor) {
            messages.add(
              lang
                  .translate('double_heal_msg')
                  .replaceAll('{name}', player.name),
            );
          } else {
            if (role.id == 5) {
              messages.add(lang.translate('plague_doctor_self_treated_msg'));
            } else {
              messages.add(
                lang
                    .translate('plague_doctor_treated_msg')
                    .replaceAll('{name}', player.name),
              );
            }
          }
        }
      }
    }

    // --- INFECTED ROLE LOGIC ---
    final alivePlayerIds = widget.players.map((p) => p.id).toSet();

    // 1. Doctor Side-Effect: If Doctor heals Infected, Doctor dies.
    if (doctorTarget != null && widget.playerRoles[doctorTarget]?.id == 14) {
      String? doctorId;
      for (final entry in widget.playerRoles.entries) {
        if (entry.value.id == 3 &&
            alivePlayerIds.contains(entry.key) &&
            !deadPlayerIds.contains(entry.key)) {
          doctorId = entry.key;
          break;
        }
      }

      if (doctorId != null) {
        deadPlayerIds.add(doctorId);
        final infectedPlayer = widget.players.cast<WerewolfPlayer?>().firstWhere(
          (p) => p!.id == doctorTarget,
          orElse: () => null,
        );
        if (infectedPlayer != null) {
          messages.add(
            lang
                .translate('infected_doctor_msg')
                .replaceAll('{name}', infectedPlayer.name),
          );
        }
      }
    }

    // 2. Vampire Side-Effect: If werewolves target Infected, Vampire dies.
    if (werewolfTarget != null &&
        widget.playerRoles[werewolfTarget]?.id == 14) {
      String? vampireId;
      for (final entry in widget.playerRoles.entries) {
        if (entry.value.id == 8 &&
            alivePlayerIds.contains(entry.key) &&
            !deadPlayerIds.contains(entry.key)) {
          vampireId = entry.key;
          break;
        }
      }

      if (vampireId != null) {
        deadPlayerIds.add(vampireId);
        final infectedPlayer = widget.players.cast<WerewolfPlayer?>().firstWhere(
          (p) => p!.id == werewolfTarget,
          orElse: () => null,
        );
        if (infectedPlayer != null) {
          messages.add(
            lang
                .translate('infected_vampire_msg')
                .replaceAll('{name}', infectedPlayer.name),
          );
        }
      }
    }
    // ---------------------------

    // Show Results
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1B263B),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFF415A77), width: 4),
          borderRadius: BorderRadius.circular(0),
        ),
        title: Text(
          context.read<LanguageService>().translate('dawn_breaks_title'),
          style: GoogleFonts.pressStart2p(color: Colors.white, fontSize: 18),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (deadPlayerIds.isEmpty)
              Text(
                context.read<LanguageService>().translate('peaceful_night_msg'),
                style: GoogleFonts.vt323(color: Colors.white, fontSize: 24),
                textAlign: TextAlign.center,
              )
            else
              Column(
                children: [
                  Text(
                    context.read<LanguageService>().translate(
                      'tragedy_struck_msg',
                    ),
                    style: GoogleFonts.vt323(
                      color: Colors.redAccent,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...deadPlayerIds.map((id) {
                    final p = widget.players.cast<WerewolfPlayer?>().firstWhere(
                      (element) => element!.id == id,
                      orElse: () => null,
                    );
                    if (p == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        context
                            .read<LanguageService>()
                            .translate('player_is_dead_label')
                            .replaceAll('{name}', p.name.toUpperCase()),
                        style: GoogleFonts.pressStart2p(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }),
                ],
              ),
            if (messages.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(height: 1, color: Colors.white24),
              const SizedBox(height: 10),
              ...messages.map(
                (m) => Text(
                  m,
                  style: GoogleFonts.vt323(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
        actions: [
          Center(
            child: SizedBox(
              width: 200,
              child: PixelButton(
                label: context.read<LanguageService>().translate(
                  'start_day_button',
                ),
                color: Colors.orange,
                onPressed: () async {
                  // Play day transition sound if not muted
                  final isMuted = context.read<SoundSettingsService>().isMuted;

                  if (!isMuted) {
                    context.read<SoundSettingsService>().playGlobal(
                      'audio/werewolves/cardinal_daylight.mp3',
                      loop: false,
                    );
                  }

                  if (mounted) {
                    Navigator.of(context).pop(); // Close Dialog
                    _checkWinConditionsAndNavigate(deadPlayerIds);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _checkWinConditionsAndNavigate(List<String> deadPlayerIds) {
    // Calculate alive werewolves and villagers after night deaths
    int aliveWerewolves = 0;
    int aliveVillagers = 0;

    for (final player in widget.players) {
      if (!deadPlayerIds.contains(player.id)) {
        final role = widget.playerRoles[player.id];
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

    // Check win conditions
    if (aliveWerewolves == 0) {
      // Village Wins (Plague Doctor killed last werewolf!)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => WerewolfPhaseFiveScreen(
            playerRoles: widget.playerRoles,
            players: widget.players,
            winningTeam: 'village',
            gamblerBet: _gamblerBet,
          ),
        ),
      );
    } else if (aliveWerewolves >= aliveVillagers) {
      // Werewolves Win (rare but possible if Plague Doctor kills many villagers)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => WerewolfPhaseFiveScreen(
            playerRoles: widget.playerRoles,
            players: widget.players,
            winningTeam: 'werewolves',
            gamblerBet: _gamblerBet,
          ),
        ),
      );
    } else {
      // Game continues - go to Day Phase
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => WerewolfPhaseFourScreen(
            playerRoles: widget.playerRoles,
            players: widget.players,
            deadPlayerIds: deadPlayerIds,
            lastHealedId: _doctorHealedId,
            lastPlagueTargetId: _plagueDoctorTargetId,
            knightLives: _knightLives,
            gamblerBet: _gamblerBet,
            dayNumber: widget.nightNumber,
            lastDireWolfTargetId:
                _direWolfSilenceTargetId ?? widget.lastDireWolfTargetId,
          ),
        ),
      );
    }
  }

  Widget _buildAllianceSection(
    String title,
    Color color,
    List<WerewolfPlayer> sectionPlayers,
  ) {
    if (sectionPlayers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Container(width: 4, height: 24, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.vt323(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(height: 1, color: color.withOpacity(0.3)),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: sectionPlayers.length,
          itemBuilder: (context, index) {
            final player = sectionPlayers[index];
            final role = widget.playerRoles[player.id];

            // Determine visual state based on current step selection
            bool isSelected = false;
            bool isDisabled = false;

            // Silence indicator: show when a player's ability is being skipped this night
            final bool isSilenceActive =
                widget.lastDireWolfTargetId != null &&
                widget.nightNumber % 2 == 0;
            final bool isSilenced = isSilenceActive &&
                player.id == widget.lastDireWolfTargetId &&
                (role?.id == 3 ||
                    role?.id == 4 ||
                    role?.id == 5 ||
                    role?.id == 16);

            if (_currentStep == NightStep.werewolves) {
              if (_targetKilledId == player.id) isSelected = true;
              if (role?.allianceId == 2) isDisabled = true;
            } else if (_currentStep == NightStep.direWolf) {
              if (_direWolfSilenceTargetId == player.id) isSelected = true;
              if (role?.allianceId == 2) isDisabled = true;
              if (player.id == widget.lastDireWolfTargetId) isDisabled = true;
            } else if (_currentStep == NightStep.doctor) {
              if (_targetHealedId == player.id) isSelected = true;
              if (player.id == widget.lastHealedId) isDisabled = true;
            } else if (_currentStep == NightStep.plagueDoctor) {
              if (_targetHealedId == player.id) isSelected = true;
              if (player.id == widget.lastPlagueTargetId) isDisabled = true;
            } else if (_currentStep == NightStep.guard) {
              if (_guardTargetId == player.id) isSelected = true;
              if (role?.id == 4) isDisabled = true;
            } else if (_currentStep == NightStep.shaman) {
              if (_shamanTargetId == player.id) isSelected = true;
              if (role?.id == 16) isDisabled = true;
            }

            return GestureDetector(
              onTap: isDisabled ? null : () => _handlePlayerTap(player),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isDisabled
                      ? Colors.grey.withOpacity(0.1)
                      : isSelected
                      ? _stepColor.withOpacity(0.4)
                      : const Color(0xFF1B263B),
                  border: Border.all(
                    color: isDisabled
                        ? Colors.grey.withOpacity(0.2)
                        : isSelected
                        ? _stepColor
                        : const Color(0xFF415A77),
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _stepColor.withOpacity(0.6),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: isDisabled
                                ? const Center(
                                    child: Icon(
                                      Icons.block,
                                      color: Colors.grey,
                                      size: 32,
                                    ),
                                  )
                                : role != null
                                ? Image.asset(
                                    role.imagePath,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                  )
                                : Center(
                                    child: Icon(
                                      Icons.person,
                                      size: 40,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white60,
                                    ),
                                  ),
                          ),
                          if (!isDisabled && role?.id == 11)
                            Positioned(
                              top: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    PixelHeart(
                                      isFull:
                                          (_knightLives[player.id] ?? 0) >= 1,
                                      size: 13,
                                    ),
                                    const SizedBox(width: 4),
                                    PixelHeart(
                                      isFull:
                                          (_knightLives[player.id] ?? 0) >= 2,
                                      size: 13,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // Silence indicator overlay
                          if (isSilenced)
                            Positioned(
                              top: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  border: Border.all(
                                    color: const Color(0xFF5B8FB9),
                                    width: 1,
                                  ),
                                ),
                                child: Image.asset(
                                  'assets/images/dire_wolf_silence.png',
                                  width: 24,
                                  height: 24,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          // Action Icon Overlay
                          if (!isDisabled && isSelected)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 400),
                                tween: Tween(begin: 0.0, end: 1.0),
                                curve: Curves.elasticOut,
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: Opacity(
                                      opacity: value.clamp(0.0, 1.0),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    border: Border.all(
                                      color: _stepColor.withOpacity(0.4),
                                      width: 1,
                                    ),
                                  ),
                                  child: Image.asset(
                                    _getActionIcon() ?? '',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      color: Colors
                          .black87, // Darker background for better contrast
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            player.name,
                            style: GoogleFonts.vt323(
                              color: isDisabled ? Colors.white24 : Colors.white,
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
                                color: isDisabled
                                    ? Colors.white12
                                    : _getRoleColor(role.id),
                                fontSize: 8,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
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
      case 9: // Jester
        return const Color(0xFF9D4EDD); // Purple
      case 10: // Drunk
        return const Color(0xFFCD9777); // Brown/Beer
      case 11: // Knight
        return const Color(0xFF9E2A2B); // Dark Red
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

  String? _getActionIcon() {
    switch (_currentStep) {
      case NightStep.gambler:
        return null;
      case NightStep.werewolves:
        return 'assets/images/werewolf_kill.png';
      case NightStep.direWolf:
        return 'assets/images/dire_wolf_silence.png';
      case NightStep.doctor:
        return 'assets/images/doctor_heal.png';
      case NightStep.guard:
        return 'assets/images/guard_inspect.png';
      case NightStep.plagueDoctor:
        return 'assets/images/plague_heal.png';
      case NightStep.shaman:
        return 'assets/images/shaman_totem.png';
    }
  }

  @override
  Widget build(BuildContext context) {
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
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _stepColor.withOpacity(0.2),
                    border: Border(
                      bottom: BorderSide(color: _stepColor, width: 2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        context
                            .watch<LanguageService>()
                            .translate('night_phase_title')
                            .replaceAll(
                              '{number}',
                              widget.nightNumber.toString(),
                            ),
                        style: GoogleFonts.pressStart2p(
                          color: _stepColor,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _stepTitle,
                        style: GoogleFonts.vt323(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _stepInstruction,
                        style: GoogleFonts.vt323(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Player Sections
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildAllianceSection(
                        context.watch<LanguageService>().translate(
                          'the_pack_alliance_title',
                        ),
                        const Color(0xFFE63946),
                        widget.players.where((p) {
                          final role = widget.playerRoles[p.id];
                          return role?.allianceId == 2;
                        }).toList(),
                      ),
                      _buildAllianceSection(
                        context.watch<LanguageService>().translate(
                          'the_village_alliance_title',
                        ),
                        const Color(0xFF4CC9F0),
                        widget.players.where((p) {
                          final role = widget.playerRoles[p.id];
                          return role?.allianceId == 1;
                        }).toList(),
                      ),
                      _buildAllianceSection(
                        context.watch<LanguageService>().translate(
                          'specials_alliance_title',
                        ),
                        const Color(0xFF9D4EDD), // Purple
                        widget.players.where((p) {
                          final role = widget.playerRoles[p.id];
                          return role?.allianceId != 1 && role?.allianceId != 2;
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                // Footer Controls
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: PixelButton(
                    label: _currentStepIndex == _nightSteps.length - 1
                        ? (_currentStep == NightStep.shaman &&
                                  _shamanTargetId != null)
                              ? context.watch<LanguageService>().translate(
                                  'investigate_button',
                                )
                              : context.watch<LanguageService>().translate(
                                  'end_night_button',
                                )
                        : (_currentStep == NightStep.guard &&
                              _guardTargetId != null)
                        ? context.watch<LanguageService>().translate(
                            'investigate_button',
                          )
                        : (_currentStep == NightStep.shaman &&
                              _shamanTargetId != null)
                        ? context.watch<LanguageService>().translate(
                            'investigate_button',
                          )
                        : context.watch<LanguageService>().translate(
                            'next_step_button',
                          ),
                    color: _canProceed ? _stepColor : Colors.grey,
                    onPressed: _canProceed ? _nextStep : null,
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
