import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class SoundService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;

  SoundService() {
    _init();
  }

  Future<void> _init() async {
    try {
      // Set audio mode
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.setVolume(1.0);
      _isInitialized = true;
      print('SoundService initialized successfully');
    } catch (e) {
      print('Error initializing SoundService: $e');
    }
  }

  /// Play beep sound from assets
  Future<void> playBeep() async {
    try {
      if (!_isInitialized) {
        await _init();
      }

      print('Attempting to play beep sound...');

      // Stop any currently playing sound
      await _audioPlayer.stop();

      // Play the beep sound
      await _audioPlayer.play(AssetSource('sounds/beep.mp3'));

      print('Beep sound played successfully');
    } catch (e) {
      print('Error playing beep sound: $e');
      // Try alternative method
      try {
        await _playWithSystemSound();
      } catch (e2) {
        print('Error with system sound: $e2');
      }
    }
  }

  /// Play ka-ching sound for successful transactions
  Future<void> playKaching() async {
    try {
      if (!_isInitialized) {
        await _init();
      }

      print('Attempting to play ka-ching sound...');

      // Stop any currently playing sound
      await _audioPlayer.stop();

      // Play the ka-ching sound
      await _audioPlayer.play(AssetSource('sounds/kaching.mp3'));

      print('Ka-ching sound played successfully');
    } catch (e) {
      print('Error playing ka-ching sound: $e');
      // Try alternative method
      try {
        await _playWithSystemSound();
      } catch (e2) {
        print('Error with system sound: $e2');
      }
    }
  }

  /// Alternative: Play using system channel (fallback)
  Future<void> _playWithSystemSound() async {
    try {
      await SystemSound.play(SystemSoundType.click);
      print('System sound played as fallback');
    } catch (e) {
      print('Error playing system sound: $e');
    }
  }

  /// Play beep with custom volume (0.0 to 1.0)
  Future<void> playBeepWithVolume(double volume) async {
    try {
      if (!_isInitialized) {
        await _init();
      }

      await _audioPlayer.stop();
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
      await _audioPlayer.play(AssetSource('sounds/beep.mp3'));

      print('Beep sound played with volume: $volume');
    } catch (e) {
      print('Error playing beep sound with volume: $e');
    }
  }

  /// Stop currently playing sound
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print('Error stopping sound: $e');
    }
  }

  /// Dispose audio player resources
  void dispose() {
    _audioPlayer.dispose();
    print('SoundService disposed');
  }
}
