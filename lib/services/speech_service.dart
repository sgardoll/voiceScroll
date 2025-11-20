import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  
  bool get isListening => _speechToText.isListening;
  bool get isAvailable => _speechToText.isAvailable;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    // Request microphone permission
    final permission = await Permission.microphone.request();
    if (permission != PermissionStatus.granted) {
      return false;
    }

    try {
      _isInitialized = await _speechToText.initialize(
        onError: (error) => print('Speech recognition error: $error'),
        onStatus: (status) => print('Speech recognition status: $status'),
      );
      return _isInitialized;
    } catch (e) {
      print('Speech initialization error: $e');
      return false;
    }
  }

  void startListening({
    required Function(String) onResult,
    required Function(String) onPartialResult,
  }) {
    if (!_isInitialized || !_speechToText.isAvailable) return;

    _speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
        } else {
          onPartialResult(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: false,
      listenMode: ListenMode.confirmation,
    );
  }

  void stopListening() {
    if (_speechToText.isListening) {
      _speechToText.stop();
    }
  }

  void dispose() {
    _speechToText.cancel();
  }
}