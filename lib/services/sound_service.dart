// lib/services/sound_service.dart

import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static Future<void> playSound(String soundFile) async {
    await _audioPlayer.stop();
    try {
      await _audioPlayer.play(AssetSource('audio/$soundFile'));
    } catch (e) {
      // Hata olursa konsola yazdır (üretim kodunda bu da kaldırılabilir)
      // print("Ses çalınırken hata oluştu: $e");
    }
  }
}