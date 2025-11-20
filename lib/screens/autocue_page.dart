import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flowread/models/script.dart';
import 'package:flowread/services/speech_service.dart';
import 'package:flowread/services/autocue_service.dart';
import 'package:flowread/theme.dart';

class AutocuePage extends StatefulWidget {
  final Script script;

  const AutocuePage({super.key, required this.script});

  @override
  State<AutocuePage> createState() => _AutocuePageState();
}

class _AutocuePageState extends State<AutocuePage> {
  final SpeechService _speechService = SpeechService();
  final ScrollController _scrollController = ScrollController();

  List<String> _words = [];
  int _currentWordIndex = -1;
  Set<int> _spokenWordIndices = {};
  bool _isListening = false;
  bool _isInitialized = false;
  bool _showControls = true;
  String _partialSpeech = '';
  String _lastRecognizedSpeech = '';
  double _fontSize = 24.0;

  static const double _minFontSize = 16.0;
  static const double _maxFontSize = 48.0;
  static const double _lineHeightMultiplier = 1.5;

  @override
  void initState() {
    super.initState();
    _words = AutocueService.getWords(widget.script.content);
    _initializeSpeech();
    _hideControlsTimer();

    // Hide system UI for full screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    _speechService.dispose();
    _scrollController.dispose();
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _initializeSpeech() async {
    final initialized = await _speechService.initialize();
    setState(() => _isInitialized = initialized);

    if (!initialized) {
      _showErrorDialog(
          'Speech recognition is not available. Please check microphone permissions.');
    }
  }

  void _hideControlsTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _hideControlsTimer();
    }
  }

  void _toggleListening() {
    if (!_isInitialized) return;

    if (_isListening) {
      _speechService.stopListening();
      setState(() {
        _isListening = false;
        _partialSpeech = '';
      });
    } else {
      _speechService.startListening(
        onResult: _onSpeechResult,
        onPartialResult: _onPartialSpeechResult,
      );
      setState(() => _isListening = true);
    }
  }

  void _onSpeechResult(String result) {
    setState(() {
      _lastRecognizedSpeech = result;
      _partialSpeech = '';
    });

    final matchRange = AutocueService.findBestMatchRange(_words, result);
    final startIndex = matchRange['startIndex'] ?? -1;
    final endIndex = matchRange['endIndex'] ?? -1;

    if (startIndex != -1 && endIndex != -1) {
      // Mark the matched words as spoken
      _markWordsAsSpoken(startIndex, endIndex);
      // Set current word to the next word after the spoken range
      final nextWordIndex = (endIndex + 1).clamp(0, _words.length - 1);
      _scrollToWord(nextWordIndex);
    }

    // Restart listening automatically
    if (_isInitialized && !_speechService.isListening) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _isListening) {
          _speechService.startListening(
            onResult: _onSpeechResult,
            onPartialResult: _onPartialSpeechResult,
          );
        }
      });
    }
  }

  void _onPartialSpeechResult(String result) {
    setState(() => _partialSpeech = result);
  }

  void _markWordsAsSpoken(int startIndex, int endIndex) {
    // Mark words in the range as spoken
    for (int i = startIndex; i <= endIndex; i++) {
      if (i >= 0 && i < _words.length) {
        _spokenWordIndices.add(i);
      }
    }
  }

  void _scrollToWord(int wordIndex) {
    setState(() => _currentWordIndex = wordIndex);

    final lineHeight = _fontSize * _lineHeightMultiplier;
    final targetPosition = AutocueService.calculateScrollPosition(
      wordIndex,
      _words,
      lineHeight,
    );

    _scrollController.animateTo(
      targetPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _adjustFontSize(double delta) {
    setState(() {
      _fontSize = (_fontSize + delta).clamp(_minFontSize, _maxFontSize);
    });
  }

  void _resetPosition() {
    setState(() {
      _currentWordIndex = -1;
      _spokenWordIndices.clear();
    });
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextDisplay() {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: _fontSize,
          height: _lineHeightMultiplier,
          color: Colors.white,
        ),
        children: _buildTextSpans(),
      ),
    );
  }

  List<TextSpan> _buildTextSpans() {
    final spans = <TextSpan>[];

    for (int i = 0; i < _words.length; i++) {
      final word = _words[i];
      final isCurrentWord = i == _currentWordIndex;
      final isSpokenWord = _spokenWordIndices.contains(i);
      final isUpcomingWord = !isSpokenWord && !isCurrentWord;

      Color textColor;
      Color? backgroundColor;
      FontWeight fontWeight;

      if (isCurrentWord) {
        // Current word being spoken - bright highlight
        textColor = Colors.black;
        backgroundColor = Colors.yellow.withValues(alpha: 0.9);
        fontWeight = FontWeight.bold;
      } else if (isSpokenWord) {
        // Already spoken words - dimmed
        textColor = Colors.white.withValues(alpha: 0.4);
        backgroundColor = null;
        fontWeight = FontWeight.normal;
      } else {
        // Upcoming words - normal
        textColor = Colors.white;
        backgroundColor = null;
        fontWeight = FontWeight.normal;
      }

      spans.add(TextSpan(
        text: word,
        style: TextStyle(
          color: textColor,
          backgroundColor: backgroundColor,
          fontWeight: fontWeight,
        ),
      ));

      // Add space after each word except the last
      if (i < _words.length - 1) {
        spans.add(TextSpan(
          text: ' ',
          style: TextStyle(
            color: isSpokenWord
                ? Colors.white.withValues(alpha: 0.4)
                : Colors.white,
          ),
        ));
      }
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarkModeColors.darkOnSecondary,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Main text display
            SafeArea(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: _buildTextDisplay(),
              ),
            ),

            // Controls overlay
            if (_showControls)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Top controls
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.script.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  // Progress indicator
                                  Row(
                                    children: [
                                      Expanded(
                                        child: LinearProgressIndicator(
                                          value: _words.isNotEmpty
                                              ? _spokenWordIndices.length /
                                                  _words.length
                                              : 0.0,
                                          backgroundColor: Colors.white
                                              .withValues(alpha: 0.3),
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${((_spokenWordIndices.length / _words.length) * 100).round()}%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Bottom controls
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Speech status
                            if (_partialSpeech.isNotEmpty ||
                                _lastRecognizedSpeech.isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_partialSpeech.isNotEmpty)
                                      Text(
                                        'Listening: $_partialSpeech',
                                        style: const TextStyle(
                                          color: Colors.orange,
                                          fontSize: 14,
                                        ),
                                      ),
                                    if (_lastRecognizedSpeech.isNotEmpty)
                                      Text(
                                        'Last: $_lastRecognizedSpeech',
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontSize: 14,
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                            // Control buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Font size controls
                                Column(
                                  children: [
                                    IconButton(
                                      onPressed: () => _adjustFontSize(2),
                                      icon: const Icon(Icons.text_increase,
                                          color: Colors.white),
                                    ),
                                    IconButton(
                                      onPressed: () => _adjustFontSize(-2),
                                      icon: const Icon(Icons.text_decrease,
                                          color: Colors.white),
                                    ),
                                  ],
                                ),

                                // Listen button
                                GestureDetector(
                                  onTap:
                                      _isInitialized ? _toggleListening : null,
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: _isListening
                                          ? Colors.red.withValues(alpha: 0.8)
                                          : Colors.blue.withValues(alpha: 0.8),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _isListening ? Icons.stop : Icons.mic,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                ),

                                // Reset button
                                IconButton(
                                  onPressed: _resetPosition,
                                  icon: const Icon(Icons.refresh,
                                      color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      appBar: AppBar(
        centerTitle: true,
        elevation: 4.0,
        backgroundColor: Theme.of(context).colorScheme.onSecondary,
        actions: [],
      ),
    );
  }
}
