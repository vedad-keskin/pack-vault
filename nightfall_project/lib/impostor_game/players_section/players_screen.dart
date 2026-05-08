import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightfall_project/base_components/pixel_starfield_background.dart';
import 'package:nightfall_project/base_components/pixel_button.dart';
import 'package:nightfall_project/impostor_game/offline_db/player_service.dart';
import 'package:nightfall_project/services/language_service.dart';
import 'package:provider/provider.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final PlayerService _playerService = PlayerService();
  List<Player> _players = [];
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    final players = await _playerService.loadPlayers();
    setState(() {
      _players = players;
    });
  }

  Future<void> _addPlayer() async {
    final playerName = _nameController.text.trim();
    if (playerName.isEmpty) return;

    if (playerName.length > 20) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Name cannot exceed 20 characters!',
              style: GoogleFonts.vt323(fontSize: 20),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    // Check for duplicate names (case-insensitive)
    final newName = playerName.toLowerCase();
    final isDuplicate = _players.any(
      (player) => player.name.toLowerCase() == newName,
    );

    if (isDuplicate) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Player "$playerName" already exists!',
              style: GoogleFonts.vt323(fontSize: 20),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    try {
      final updated = await _playerService.addPlayer(
        _players,
        playerName,
      );
      setState(() {
        _players = updated;
        _nameController.clear();
      });
    } catch (e) {
      debugPrint('Error adding player: $e');
    }
  }

  Future<void> _removePlayer(String id) async {
    try {
      final updated = await _playerService.removePlayer(_players, id);
      setState(() {
        _players = updated;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: GoogleFonts.vt323(fontSize: 20),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageService = context.watch<LanguageService>();
    return Scaffold(
      backgroundColor: Colors.black, // Fallback
      body: Stack(
        children: [
          const PixelStarfieldBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Header Section
                  Row(
                    children: [
                      PixelButton(
                        label: languageService.translate('back'),
                        color: const Color(0xFF415A77),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Center(
                          child: Text(
                            languageService.translate('players_title'),
                            style: GoogleFonts.pressStart2p(
                              color: const Color(0xFFE0E1DD),
                              fontSize: 24,
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
                  const SizedBox(height: 24),

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
                              // Add Player Input
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          border: Border.all(
                                            color: const Color(0xFF778DA9),
                                          ),
                                        ),
                                        child: TextField(
                                          controller: _nameController,
                                          style: GoogleFonts.vt323(
                                            color: Colors.white,
                                            fontSize: 24,
                                          ),
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            hintText: languageService.translate(
                                              'enter_name_hint',
                                            ),
                                            hintStyle: GoogleFonts.vt323(
                                              color: Colors.white54,
                                              fontSize: 24,
                                            ),
                                          ),
                                          onSubmitted: (_) => _addPlayer(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    PixelButton(
                                      label: languageService.translate(
                                        'add_button',
                                      ),
                                      color: const Color(0xFF415A77),
                                      onPressed: _addPlayer,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                height: 4,
                                color: const Color(0xFF778DA9),
                              ),
                              // Players List
                              Expanded(
                                child: ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _players.length,
                                  separatorBuilder: (ctx, i) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final player = _players[index];
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF1B263B,
                                        ).withOpacity(0.8),
                                        border: Border.all(
                                          color: const Color(0xFF415A77),
                                          width: 2,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              player.name,
                                              style: GoogleFonts.vt323(
                                                color: Colors.white,
                                                fontSize: 28,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.blueAccent,
                                            ),
                                            onPressed: () =>
                                                _editPlayer(player),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.redAccent,
                                            ),
                                            onPressed: _players.length > 1
                                                ? () => _removePlayer(player.id)
                                                : null,
                                          ),
                                        ],
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

  Future<void> _editPlayer(Player player) async {
    final languageService = context.read<LanguageService>();
    final editController = TextEditingController(text: player.name);
    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF778DA9),
              border: Border.all(color: const Color(0xFFE0E1DD), width: 4),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF0D1B2A),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    languageService.translate('edit_name_title'),
                    style: GoogleFonts.pressStart2p(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      border: Border.all(color: const Color(0xFF778DA9)),
                    ),
                    child: TextField(
                      controller: editController,
                      style: GoogleFonts.vt323(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: languageService.translate('enter_name_hint'),
                        hintStyle: GoogleFonts.vt323(
                          color: Colors.white54,
                          fontSize: 24,
                        ),
                      ),
                      autofocus: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: PixelButton(
                          label: languageService.translate('cancel_button'),
                          color: Colors.redAccent.withOpacity(0.8),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: PixelButton(
                          label: languageService.translate('save_button'),
                          color: const Color(0xFF415A77),
                          onPressed: () async {
                            final newName = editController.text.trim();
                            if (newName.isNotEmpty) {
                              if (newName.length > 20) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Name cannot exceed 20 characters!',
                                      style: GoogleFonts.vt323(fontSize: 20),
                                    ),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                                return;
                              }

                              final isDuplicate = _players.any(
                                (p) => p.id != player.id && p.name.toLowerCase() == newName.toLowerCase(),
                              );

                              if (isDuplicate) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Player "$newName" already exists!',
                                      style: GoogleFonts.vt323(fontSize: 20),
                                    ),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                                return;
                              }

                              try {
                                final updated = await _playerService
                                    .updatePlayer(
                                      _players,
                                      player.id,
                                      newName,
                                    );
                                setState(() {
                                  _players = updated;
                                });
                                if (context.mounted)
                                  Navigator.of(context).pop();
                              } catch (e) {
                                debugPrint('Error updating player: $e');
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
