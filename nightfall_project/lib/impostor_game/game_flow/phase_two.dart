import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightfall_project/services/language_service.dart';
import 'package:provider/provider.dart';
import 'package:nightfall_project/base_components/pixel_starfield_background.dart';
import 'package:nightfall_project/base_components/pixel_button.dart';
import 'package:nightfall_project/impostor_game/game_flow/phase_three.dart';
import 'package:nightfall_project/impostor_game/offline_db/category_service.dart';
import 'package:nightfall_project/impostor_game/offline_db/player_service.dart';
import 'package:nightfall_project/impostor_game/offline_db/words_service.dart';
import 'dart:math';

class PhaseTwoScreen extends StatefulWidget {
  final List<Player> players;
  final Category category;
  final Word word;
  final String impostorId;

  const PhaseTwoScreen({
    super.key,
    required this.players,
    required this.category,
    required this.word,
    required this.impostorId,
  });

  @override
  State<PhaseTwoScreen> createState() => _PhaseTwoScreenState();
}

class _PhaseTwoScreenState extends State<PhaseTwoScreen> {
  bool _showInstructions = true;
  Player? _selectedSuspect;
  late Player _startingPlayer;

  @override
  void initState() {
    super.initState();
    _startingPlayer = widget.players[Random().nextInt(widget.players.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const PixelStarfieldBackground(),
          SafeArea(
            child: _showInstructions ? _buildInstructions() : _buildVoting(),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    final languageService = context.read<LanguageService>();
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            languageService.translate('discussion_time'),
            style: GoogleFonts.pressStart2p(
              color: const Color(0xFFE63946),
              fontSize: 22,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1B263B).withOpacity(0.9),
              border: Border.all(color: const Color(0xFF415A77), width: 4),
            ),
            child: Column(
              children: [
                _buildInstructionShot("1", languageService.translate('inst_1')),
                const SizedBox(height: 24),
                _buildInstructionShot("2", languageService.translate('inst_2')),
                const SizedBox(height: 24),
                _buildInstructionShot("3", languageService.translate('inst_3')),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE63946).withOpacity(0.1),
              border: Border.all(color: const Color(0xFFE63946), width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Color(0xFFFFD700), size: 24),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languageService.translate('starting_player_label'),
                      style: GoogleFonts.pressStart2p(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _startingPlayer.name.toUpperCase(),
                      style: GoogleFonts.pressStart2p(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          PixelButton(
            label: languageService.translate('start_voting_button'),
            color: const Color(0xFF52B788),
            onPressed: () {
              setState(() {
                _showInstructions = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionShot(String num, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(color: Color(0xFFE0E1DD)),
          child: Center(
            child: Text(
              num,
              style: GoogleFonts.pressStart2p(
                color: Colors.black,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.vt323(color: Colors.white, fontSize: 24),
          ),
        ),
      ],
    );
  }

  Widget _buildVoting() {
    final languageService = context.read<LanguageService>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            languageService.translate('who_is_impostor'),
            style: GoogleFonts.pressStart2p(
              color: const Color(0xFFE0E1DD),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),

        // Drop Zone
        Center(
          child: DragTarget<Player>(
            onWillAccept: (data) => data != null,
            onAccept: (player) {
              setState(() {
                _selectedSuspect = player;
              });
            },
            builder: (context, candidateData, rejectedData) {
              final isHovering = candidateData.isNotEmpty;
              return Container(
                width: 200,
                height: 150,
                decoration: BoxDecoration(
                  color: isHovering
                      ? Colors.red.withOpacity(0.2)
                      : Colors.black.withOpacity(0.5),
                  border: Border.all(
                    color: _selectedSuspect != null
                        ? const Color(0xFFE63946)
                        : Colors.white24,
                    width: 4,
                    style: _selectedSuspect != null
                        ? BorderStyle.solid
                        : BorderStyle.none,
                  ),
                ),
                child: Center(
                  child: _selectedSuspect == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.touch_app,
                              color: Colors.white24,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              languageService.translate('drag_suspect_here'),
                              style: GoogleFonts.vt323(
                                color: Colors.white24,
                                fontSize: 18,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.gavel,
                              color: Color(0xFFE63946),
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedSuspect!.name.toUpperCase(),
                              style: GoogleFonts.pressStart2p(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 24),

        // Players List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: widget.players.length,
            itemBuilder: (context, index) {
              final player = widget.players[index];
              final isSelected = _selectedSuspect?.id == player.id;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSuspect = player;
                    });
                  },
                  child: LongPressDraggable<Player>(
                    data: player,
                    feedback: Material(
                      color: Colors.transparent,
                      child: _buildPlayerCard(player, true),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: _buildPlayerCard(player, false),
                    ),
                    child: _buildPlayerCard(
                      player,
                      false,
                      isSelected: isSelected,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Action Button
        if (_selectedSuspect != null)
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: PixelButton(
              label: languageService.translate('reveal_impostor_button'),
              color: const Color(0xFFE63946),
              soundPath: 'audio/impostor/gavel_hit.mp3',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PhaseThreeScreen(
                      votedPlayerId: _selectedSuspect!.id,
                      impostorId: widget.impostorId,
                      players: widget.players,
                      category: widget.category,
                      word: widget.word,
                    ),
                  ),
                );
              },
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              languageService.translate('vote_instruction'),
              style: GoogleFonts.vt323(color: Colors.white54, fontSize: 20),
            ),
          ),
      ],
    );
  }

  Widget _buildPlayerCard(
    Player player,
    bool isFeedback, {
    bool isSelected = false,
  }) {
    return Container(
      width: isFeedback ? 250 : double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF3D0C02).withOpacity(0.9)
            : const Color(0xFF1B263B).withOpacity(0.9),
        border: Border.all(
          color: isSelected ? const Color(0xFFE63946) : const Color(0xFF415A77),
          width: 3,
        ),
      ),
      child: Center(
        child: Text(
          player.name,
          style: GoogleFonts.vt323(
            color: Colors.white,
            fontSize: 28,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
