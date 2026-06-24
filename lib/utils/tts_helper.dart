import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:prefs/prefs.dart';


import 'languages.dart';

class TTSVoice {
  String name;
  String locale;

  TTSVoice(this.name, this.locale);

  @override
  String toString() => '{name: $name, locale: $locale}';
}

/// handles everything related to TTS
class TTSHelper {
  static final AsyncCache _cache = AsyncCache.ephemeral();

  static late FlutterTts flutterTts;

  /// TTS is available?
  static bool available = true;

  /// enable/disable TTS output
  static bool useTTS = true;

  static bool isTalking = false;

  static bool _isInitialized = false;

  /// list of all available voices for TTS
  static List<TTSVoice> voices = [];

  static List<String> engines = [];

  static Future<void> init() async => _cache.fetch(_initWork);

  static Future<void> _initWork() async {
    if (!_isInitialized) {
      flutterTts = FlutterTts();
      flutterTts.setStartHandler(() {
        isTalking = true;
      });
      flutterTts.setCompletionHandler(() {
        isTalking = false;
      });
      _isInitialized = true;
    }

    // populate the list of available TTS voices
    try {
      List<dynamic> allVoices =
          await flutterTts.getVoices.timeout(const Duration(seconds: 1));

      engines = (await flutterTts.getEngines.timeout(const Duration(seconds: 1))
              as List<Object?>)
          .map((e) => e.toString())
          .toList(growable: false);

      var ttsEngine = Prefs.getString('tts_engine', "");
      if (ttsEngine == "") {
        ttsEngine = engines.first;
        await Prefs.setString('tts_voice', ttsEngine);
      }

      voices = allVoices.map((element) {
        Map e = element;
        var voice = TTSVoice(e["name"] ?? "", e["locale" ?? ""]);
        return voice;
      }).toList(growable: true);
      voices.retainWhere(
        (voice) => Languages.languageCodes.contains(voice.locale),
      );
    } on TimeoutException {
      _ttsUnavailable(true);
      return;
    }

    if (voices.isEmpty || engines.isEmpty) {
      _ttsUnavailable(!voices.isEmpty || !engines.isEmpty);
      return;
    }

    useTTS = Prefs.getString('sound') == 'tts';

    var ttsLang = Prefs.getString('tts_lang', 'en-US');
    if (!Languages.languageCodes.contains(ttsLang)) ttsLang = 'en-US';
    await Prefs.setString('tts_lang', ttsLang);

    var ttsVoice = Prefs.getString('tts_voice', "");
    if (ttsVoice == "") {
      ttsVoice = voices.firstWhere((voice) => voice.locale == ttsLang).name;
      await Prefs.setString('tts_voice', ttsVoice);
    }

    try {
      await flutterTts
          .setLanguage(ttsLang)
          .timeout(const Duration(seconds: 3))
          .then((_) async {
        await flutterTts.setVolume(1.0);
        await flutterTts.setVoice({"name": ttsVoice, "locale": ttsLang});
      });
    } on TimeoutException {
      await _ttsUnavailable(true);
      return;
    }
  }

  /// called when a part of the initialization fails to disable all TTS functionality
  static Future<void> _ttsUnavailable(bool canRetry) async {
    available = canRetry;
    useTTS = false;
    voices.clear();
    engines.clear();
    await Prefs.setString('sound', 'beep');
  }

  static void setLanguage(String languageCode) async {
    if (!available) return;
    Prefs.setString("tts_lang", languageCode);
    await flutterTts.setLanguage(languageCode);

    var ttsVoice =
        voices.firstWhere((voice) => voice.locale == languageCode).name;
    await Prefs.setString('tts_voice', ttsVoice);
    await flutterTts.setVoice({"name": ttsVoice, "locale": languageCode});
  }

  static void speak(String text) async {
    if (!useTTS) return;
    await flutterTts.speak(text);
  }
}
