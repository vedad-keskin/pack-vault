import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightfall_project/base_components/pixel_button.dart';
import 'package:nightfall_project/services/language_service.dart';
import 'package:nightfall_project/services/sound_settings_service.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';

class PixelRulesDialog extends StatefulWidget {
  final bool isImpostor;

  const PixelRulesDialog({super.key, required this.isImpostor});

  @override
  State<PixelRulesDialog> createState() => _PixelRulesDialogState();
}

class _PixelRulesDialogState extends State<PixelRulesDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _pageController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playPageSound() async {
    final isMuted = context.read<SoundSettingsService>().isMuted;
    if (!isMuted) {
      try {
        await _audioPlayer.play(
          AssetSource('audio/pixel_click.mp3'),
          volume: 0.5,
        );
      } catch (e) {
        // Ignore sound errors
      }
    }
  }

  List<String> _getPages(String content) {
    // Split by numbered sections: "1. ", "2. ", etc.
    // We look for double newline followed by digits and a dot OR just digits at the start.
    final sections = content.trim().split(RegExp(r'\n\n(?=\d+\.)'));
    return sections.where((s) => s.trim().isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageService>();
    final title = lang.translate(
      widget.isImpostor ? 'rules_impostor_title' : 'rules_werewolves_title',
    );
    final rawContent = lang.translate(
      widget.isImpostor ? 'rules_impostor_content' : 'rules_werewolves_content',
    );
    final pages = _getPages(rawContent);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Stack(
        children: [
          // Premium Glass Background with Blur
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1B263B).withOpacity(0.9),
                      const Color(0xFF0D1B2A).withOpacity(0.95),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF415A77).withOpacity(0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.8),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main Book Container
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Book Title Bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B263B),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.book,
                        color: Color(0xFFFCA311),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title.toUpperCase(),
                          style: GoogleFonts.pressStart2p(
                            color: const Color(0xFFE0E1DD),
                            fontSize: 13,
                            height: 1.5,
                            shadows: [
                              const Shadow(
                                color: Colors.black,
                                offset: Offset(2, 2),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Pages UI (The "Paper" feeling)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E1DD), // Creamy/Paper color
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          offset: const Offset(4, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(
                        children: [
                          // Vertical "Spine" Shadow to simulate an open book
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: 15,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withOpacity(0.2),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),

                          PageView.builder(
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() => _currentPage = index);
                              _playPageSound();
                            },
                            itemCount: pages.length,
                            itemBuilder: (context, index) {
                              return _buildPageContent(pages[index]);
                            },
                          ),

                          // Page Numbers at the bottom center of the page
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Text(
                                "- PAGE ${_currentPage + 1} OF ${pages.length} -",
                                style: GoogleFonts.pressStart2p(
                                  color: const Color(
                                    0xFF1B263B,
                                  ).withOpacity(0.5),
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Book Footer - Navigation
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: Row(
                    children: [
                      if (_currentPage > 0)
                        Expanded(
                          child: PixelButton(
                            label: lang.translate('back').toUpperCase(),
                            color: const Color(0xFF415A77),
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOutCubic,
                              );
                            },
                          ),
                        )
                      else
                        const Spacer(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _currentPage < pages.length - 1
                            ? PixelButton(
                                label: lang
                                    .translate('next_step_button')
                                    .toUpperCase(),
                                color: const Color(0xFF06D6A0),
                                onPressed: () {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeOutCubic,
                                  );
                                },
                              )
                            : PixelButton(
                                label: lang
                                    .translate('close_button')
                                    .toUpperCase(),
                                color: const Color(0xFFE63946),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Outer Gold Pixel Ornaments
          _buildPixelOrnament(top: 4, left: 4),
          _buildPixelOrnament(top: 4, right: 4, rotate: 1),
          _buildPixelOrnament(bottom: 4, left: 4, rotate: 3),
          _buildPixelOrnament(bottom: 4, right: 4, rotate: 2),

          // Close Button (X) - Layered on TOP
          Positioned(
            top: 17,
            right: 17,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE63946).withOpacity(0.2),
                    border: Border.all(
                      color: const Color(0xFFE63946).withOpacity(0.7),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(3, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Color(0xFFE63946),
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(String content) {
    final lines = content.trim().split('\n');
    if (lines.isEmpty) return const SizedBox();

    final header = lines[0];
    final bodyLines = lines.length > 1 ? lines.sublist(1) : <String>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(30, 30, 30, 45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Text(
            header,
            style: GoogleFonts.pressStart2p(
              color: const Color(
                0xFF1B263B,
              ), // Dark navy for text on cream paper
              fontSize: 14,
              height: 1.5,
              decoration: TextDecoration.underline,
            ),
          ),
          const SizedBox(height: 20),

          // Section Body
          for (var line in bodyLines)
            if (line.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (line.trim().startsWith('-'))
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0, right: 8.0),
                        child: Icon(
                          Icons.circle,
                          size: 6,
                          color: Color(0xFF415A77),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        line.trim().startsWith('-')
                            ? line.trim().substring(1).trim()
                            : line.trim(),
                        style: GoogleFonts.vt323(
                          color: const Color(0xFF1B263B).withOpacity(0.9),
                          fontSize: 21,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildPixelOrnament({
    double? top,
    double? left,
    double? right,
    double? bottom,
    int rotate = 0,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: RotatedBox(
        quarterTurns: rotate,
        child: Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFFFCA311), width: 4),
              left: BorderSide(color: Color(0xFFFCA311), width: 4),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFFCA311), width: 2),
                left: BorderSide(color: Color(0xFFFCA311), width: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
