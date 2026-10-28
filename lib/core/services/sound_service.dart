import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';
import 'package:artavia/core/services/settings_service.dart';

/// Short chime after a transaction is saved (FR-031h).
class SoundService extends GetxService {
  static SoundService get to => Get.find();

  final _player = AudioPlayer();

  Future<void> playSuccess() async {
    if (!SettingsService.to.soundEffect) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/success.wav'),
          mode: PlayerMode.lowLatency);
    } catch (e) {
      // A missing chime must never block saving a transaction.
      Get.log('Sound playback failed: $e');
    }
  }

  @override
  void onClose() {
    _player.dispose();
    super.onClose();
  }
}
