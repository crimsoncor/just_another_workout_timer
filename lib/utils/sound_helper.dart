import 'package:flutter/services.dart';
import 'package:prefs/prefs.dart';
import 'package:audioplayers/audioplayers.dart';

// ignore: avoid_classes_with_only_static_members
class SoundHelper {
  static late AudioPlayer _beepLowPlayer;
  static late AudioPlayer _beepHighPlayer;
  static late AudioPlayer _tickPlayer;

  static bool useSound = false;

  static Future<void> loadSounds() async {
    await _loadSounds();
    useSound = Prefs.getString('sound') == 'beep';
  }

  static Future<void> _loadSounds() async {

    // Default AssetCache prepends "assets" to all media paths
    _beepLowPlayer = await _loadSound("beep_low.wav");
    _beepHighPlayer = await _loadSound("beep_high.wav");
    _tickPlayer = await _loadSound("tick.wav");
  }

  static Future<AudioPlayer> _loadSound(String path) async {
    var _player = AudioPlayer();
    await _player.setPlayerMode(PlayerMode.lowLatency);
    await _player.setReleaseMode(ReleaseMode.stop);

    await _player.setSourceDeviceFile(path);
    return _player;
  }

  static void playBeepLow() {
    if (useSound) _beepLowPlayer.resume();
  }

  static void playBeepHigh() {
    if (useSound) _beepHighPlayer.resume();
  }

  static void playBeepTick() {
    if (Prefs.getBool('ticks')) _tickPlayer.resume;
  }

  static void playDouble() {
    if (useSound) {
      _beepLowPlayer.resume();
      Future.delayed(const Duration(milliseconds: 200))
          .then((value) => _beepLowPlayer.resume());
    }
  }

  static void playTriple() {
    if (useSound) {
      _beepHighPlayer.resume();
      Future.delayed(const Duration(milliseconds: 150))
          .then((value) => _beepHighPlayer.resume())
          .then(
            (value) => Future.delayed(const Duration(milliseconds: 150))
                .then((value) => _beepHighPlayer.resume()),
          );
    }
  }

  // TODO does this need to be called somewhere?
  static void dispose() async {
    await _beepHighPlayer.dispose();
    await _beepLowPlayer.dispose();
    await _tickPlayer.dispose();
  }
}
