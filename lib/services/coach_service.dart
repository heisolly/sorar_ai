import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class CoachService with ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isListening = false;
  bool get isListening => _isListening;
  String _currentText = "";

  // Initialize
  Future<void> init() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
  }

  // Start Listening
  Future<void> startListening({required Function(String) onResult}) async {
    bool available = await _speech.initialize(
      onStatus: (status) => debugPrint('STT Status: $status'),
      onError: (errorNotification) =>
          debugPrint('STT Error: $errorNotification'),
    );

    if (available) {
      _isListening = true;
      notifyListeners();
      _speech.listen(
        onResult: (result) {
          _currentText = result.recognizedWords;
          onResult(_currentText);
        },
      );
    } else {
      debugPrint("The user has denied the use of speech recognition.");
    }
  }

  // Stop Listening
  Future<void> stopListening() async {
    await _speech.stop();
    _isListening = false;
    notifyListeners();
  }

  // Speak
  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  // Stop Speaking
  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }
}
