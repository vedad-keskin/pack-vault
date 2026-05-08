import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

class SoundSettingsService extends ChangeNotifier {
  bool _isMuted = false;
  final AudioPlayer _globalPlayer = AudioPlayer();
  String? _currentAsset;

  bool get isMuted => _isMuted;
  AudioPlayer get globalPlayer => _globalPlayer;
  String? get currentAsset => _currentAsset;

  SoundSettingsService() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isMuted = prefs.getBool('sound_muted') ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading sound settings: $e');
    }
  }

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sound_muted', _isMuted);
    } catch (e) {
      debugPrint('Error saving sound settings: $e');
    }

    if (_isMuted) {
      stopAll();
    }
  }

  void stopAll() {
    _globalPlayer.stop();
    _currentAsset = null;
  }

  Future<void> playGlobal(String assetPath, {bool loop = true}) async {
    if (isMuted) return;

    // If same asset is playing and it's a loop, don't restart (prevents "stuck" music)
    // But if it's NOT a loop (SFX/Transition), we WANT it to restart to provide feedback
    if (_currentAsset == assetPath && loop) {
      if (_globalPlayer.state != PlayerState.playing) {
        await _globalPlayer.resume();
      }
      return;
    }

    try {
      await _globalPlayer.stop();
      _currentAsset = assetPath;
      await _globalPlayer.setReleaseMode(
        loop ? ReleaseMode.loop : ReleaseMode.release,
      );
      await _globalPlayer.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('Error playing global sound ($assetPath): $e');
      _currentAsset = null;
    }
  }

  @override
  void dispose() {
    _globalPlayer.dispose();
    super.dispose();
  }

  Future<void> setMuted(bool muted) async {
    if (_isMuted == muted) return;

    _isMuted = muted;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sound_muted', muted);
    } catch (e) {
      debugPrint('Error saving sound settings: $e');
    }
  }
}
