import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:nightfall_project/services/sound_settings_service.dart';

class PixelButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final String? soundPath;
  final bool useGlobalPlayer;

  const PixelButton({
    super.key,
    required this.label,
    required this.color,
    this.onPressed,
    this.soundPath,
    this.useGlobalPlayer = false,
  });

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _isPressed = false;
  DateTime? _pressStartTime;
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playSound() async {
    if (widget.soundPath == null) return;

    final soundService = context.read<SoundSettingsService>();
    if (soundService.isMuted) return;

    if (widget.useGlobalPlayer) {
      await soundService.playGlobal(widget.soundPath!, loop: false);
    } else {
      try {
        await _audioPlayer.play(AssetSource(widget.soundPath!));
      } catch (e) {
        debugPrint('Error playing sound: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 3D effect calculation
    final double translate = _isPressed ? 4 : 0;

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
          _pressStartTime = DateTime.now();
        });
      },
      onTapUp: (_) async {
        final pressDuration = DateTime.now().difference(_pressStartTime!);
        const minPressDuration = Duration(milliseconds: 100);

        if (pressDuration < minPressDuration) {
          await Future.delayed(minPressDuration - pressDuration);
        }

        if (mounted) {
          setState(() => _isPressed = false);
          _playSound(); // Play sound on release
          widget.onPressed?.call();
        }
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: Transform.translate(
        offset: Offset(0, translate),
        child: Container(
          // Complex Button Border
          decoration: BoxDecoration(
            color: Colors.black, // Outer border color
            boxShadow: [
              if (!_isPressed)
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  offset: const Offset(4, 4),
                  blurRadius: 0,
                ),
            ],
          ),
          padding: const EdgeInsets.only(
            bottom: 4,
          ), // Bottom "3D" lip color (black here)
          child: Container(
            color: _isPressed ? widget.color.withOpacity(0.8) : widget.color,
            padding: const EdgeInsets.all(2), // Inner border width
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ), // Highlight
              ),
              // Reduced horizontal padding from 24 to 12
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Center(
                child: Text(
                  widget.label,
                  style: GoogleFonts.vt323(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      const Shadow(color: Colors.black, offset: Offset(1, 1)),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
