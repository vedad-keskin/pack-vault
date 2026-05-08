import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nightfall_project/services/sound_settings_service.dart';

class PixelSoundButton extends StatefulWidget {
  const PixelSoundButton({super.key});

  @override
  State<PixelSoundButton> createState() => _PixelSoundButtonState();
}

class _PixelSoundButtonState extends State<PixelSoundButton> {
  bool _isPressed = false;
  DateTime? _pressStartTime;

  @override
  Widget build(BuildContext context) {
    final soundSettings = context.watch<SoundSettingsService>();

    return GestureDetector(
      onTapDown: (_) => setState(() {
        _isPressed = true;
        _pressStartTime = DateTime.now();
      }),
      onTapUp: (_) async {
        final pressDuration = DateTime.now().difference(_pressStartTime!);
        const minPressDuration = Duration(milliseconds: 100);

        if (pressDuration < minPressDuration) {
          await Future.delayed(minPressDuration - pressDuration);
        }

        if (mounted) {
          setState(() => _isPressed = false);
          soundSettings.toggleMute();
        }
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          boxShadow: [
            if (!_isPressed)
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                offset: const Offset(6, 6),
                blurRadius: 0,
              ),
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: BoxDecoration(
            color: _isPressed
                ? const Color(0xFF415A77)
                : const Color(0xFF1B263B),
            border: Border.all(
              color: _isPressed
                  ? const Color(0xFF778DA9)
                  : const Color(0xFF415A77),
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              // Top Highlight Loophole Effect
              if (!_isPressed)
                Positioned(
                  top: 2,
                  left: 2,
                  right: 2,
                  height: 2,
                  child: Container(color: Colors.white10),
                ),
              Center(
                child: Icon(
                  soundSettings.isMuted ? Icons.volume_off : Icons.volume_up,
                  color: const Color(0xFFE0E1DD),
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
