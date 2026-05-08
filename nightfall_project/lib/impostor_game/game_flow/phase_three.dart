import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightfall_project/services/language_service.dart';
import 'package:provider/provider.dart';
import 'package:nightfall_project/base_components/pixel_starfield_background.dart';
import 'package:nightfall_project/base_components/pixel_button.dart';
import 'package:nightfall_project/impostor_game/offline_db/category_service.dart';
import 'package:nightfall_project/impostor_game/offline_db/player_service.dart';
import 'package:nightfall_project/impostor_game/offline_db/words_service.dart';
import 'dart:async';

class PhaseThreeScreen extends StatefulWidget {
  final String votedPlayerId;
  final String impostorId;
  final List<Player> players;
  final Category category;
  final Word word;

  const PhaseThreeScreen({
    super.key,
    required this.votedPlayerId,
    required this.impostorId,
    required this.players,
    required this.category,
    required this.word,
  });

  @override
  State<PhaseThreeScreen> createState() => _PhaseThreeScreenState();
}

class _PhaseThreeScreenState extends State<PhaseThreeScreen> {
  final PlayerService _playerService = PlayerService();
  bool _isRevealDone = false;
  late Player _votedPlayer;
  late Player _realImpostor;
  bool _impostorWon = false;
  String _typedVerdict = "";
  Timer? _typewriterTimer;

  bool _showRealImpostor = false;
  String _typedImpostorName = "";
  Timer? _impostorTimer;

  @override
  void initState() {
    super.initState();
    _votedPlayer = widget.players.firstWhere(
      (p) => p.id == widget.votedPlayerId,
    );
    _realImpostor = widget.players.firstWhere((p) => p.id == widget.impostorId);
    _impostorWon = widget.votedPlayerId != widget.impostorId;

    // Logic: If impostor escaped, give them 1 point
    if (_impostorWon) {
      _applyPoints();
    }

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isRevealDone = true;
        });
        _startTypewriter();
      }
    });
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _impostorTimer?.cancel();
    super.dispose();
  }

  void _startTypewriter() {
    final languageService = context.read<LanguageService>();
    final fullText = _impostorWon
        ? languageService.translate('verdict_innocent')
        : languageService.translate('verdict_impostor');
    int index = 0;

    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 50), (
      timer,
    ) {
      if (index < fullText.length) {
        setState(() {
          _typedVerdict += fullText[index];
        });
        index++;
      } else {
        timer.cancel();
        if (_impostorWon) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              _startImpostorReveal();
            }
          });
        }
      }
    });
  }

  void _startImpostorReveal() {
    setState(() {
      _showRealImpostor = true;
    });

    final fullText = _realImpostor.name.toUpperCase();
    int index = 0;

    _impostorTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (index < fullText.length) {
        setState(() {
          _typedImpostorName += fullText[index];
        });
        index++;
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _applyPoints() async {
    final players = await _playerService.loadPlayers();
    final updatedPlayers = players.map((p) {
      if (p.id == widget.impostorId) {
        return Player(id: p.id, name: p.name, points: p.points + 1);
      }
      return p;
    }).toList();
    await _playerService.savePlayers(updatedPlayers);
  }

  @override
  Widget build(BuildContext context) {
    final languageService = context.watch<LanguageService>();
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            const PixelStarfieldBackground(),
            SafeArea(
              child: SingleChildScrollView(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Text(
                          languageService.translate('verdict_title'),
                          style: GoogleFonts.pressStart2p(
                            color: Colors.white,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildVerdictCard(),
                        if (_showRealImpostor) ...[
                          const SizedBox(height: 20),
                          _buildRealImpostorCard(),
                        ],
                        const SizedBox(height: 20),
                        if (_isRevealDone &&
                            (!_impostorWon ||
                                _typedImpostorName.length ==
                                    _realImpostor.name.length)) ...[
                          _buildWordCard(),
                          const SizedBox(height: 16),
                          _buildResultText(),
                          const SizedBox(height: 20),
                          PixelButton(
                            label: languageService.translate('back_to_menu'),
                            color: const Color(0xFF415A77),
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).popUntil(ModalRoute.withName('/impostor_game'));
                            },
                          ),
                        ],
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerdictCard() {
    final languageService = context.read<LanguageService>();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: _isRevealDone
            ? (_impostorWon ? const Color(0xFF3D0C02) : const Color(0xFF1B4332))
            : const Color(0xFF1B263B),
        border: Border.all(
          color: _isRevealDone
              ? (_impostorWon
                    ? const Color(0xFFE63946)
                    : const Color(0xFF52B788))
              : const Color(0xFF415A77),
          width: 6,
        ),
      ),
      child: Column(
        children: [
          Text(
            languageService.translate('voted_as_impostor'),
            style: GoogleFonts.vt323(color: Colors.white70, fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            _votedPlayer.name.toUpperCase(),
            style: GoogleFonts.pressStart2p(color: Colors.white, fontSize: 20),
          ),
          const SizedBox(height: 12),
          if (_isRevealDone) ...[
            const Icon(Icons.arrow_downward, color: Colors.white54, size: 32),
            const SizedBox(height: 12),
            Text(
              _typedVerdict,
              style: GoogleFonts.vt323(
                color: _impostorWon
                    ? const Color(0xFFFFBA08)
                    : Colors.greenAccent,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ] else
            const CircularProgressIndicator(color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildRealImpostorCard() {
    final languageService = context.read<LanguageService>();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF3D0C02),
        border: Border.all(color: const Color(0xFFE63946), width: 4),
      ),
      child: Column(
        children: [
          Text(
            languageService.translate('real_impostor_was'),
            style: GoogleFonts.vt323(color: Colors.white70, fontSize: 20),
          ),
          const SizedBox(height: 12),
          Text(
            _typedImpostorName,
            style: GoogleFonts.pressStart2p(
              color: const Color(0xFFE63946),
              fontSize: 22,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWordCard() {
    final languageService = context.read<LanguageService>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            languageService.translate('secret_word'),
            style: GoogleFonts.pressStart2p(color: Colors.white38, fontSize: 9),
          ),
          const SizedBox(height: 6),
          Text(
            widget.word.name.toUpperCase(),
            style: GoogleFonts.vt323(
              color: const Color(0xFF4CC9F0),
              fontSize: 22,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResultText() {
    final languageService = context.read<LanguageService>();
    return Column(
      children: [
        if (_impostorWon) ...[
          Text(
            languageService.translate('impostor_escaped'),
            style: GoogleFonts.pressStart2p(
              color: const Color(0xFFE63946),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            "${languageService.translate('point_to')} ${_realImpostor.name.toUpperCase()}",
            style: GoogleFonts.pressStart2p(
              color: const Color(0xFFFFBA08),
              fontSize: 12,
            ),
          ),
        ] else ...[
          Text(
            languageService.translate('innocents_win'),
            style: GoogleFonts.pressStart2p(
              color: const Color(0xFF52B788),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            languageService.translate('caught_impostor'),
            style: GoogleFonts.vt323(color: Colors.white70, fontSize: 22),
          ),
        ],
      ],
    );
  }
}
