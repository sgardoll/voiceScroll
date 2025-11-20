class AutocueService {
  static const double scrollSpeed = 50.0; // pixels per second

  /// Splits text into words and creates a mapping for scrolling positions
  static List<String> getWords(String text) {
    return text.split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => word.trim())
        .toList();
  }

  /// Finds the best match for spoken words in the script
  static int findBestMatch(List<String> scriptWords, String spokenText) {
    final match = findBestMatchRange(scriptWords, spokenText);
    return match['startIndex'] ?? -1;
  }

  /// Finds the best match range for spoken words in the script
  static Map<String, int> findBestMatchRange(List<String> scriptWords, String spokenText) {
    final spokenWords = spokenText.toLowerCase().split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => _cleanWord(word))
        .toList();

    if (spokenWords.isEmpty) return {'startIndex': -1, 'endIndex': -1, 'wordCount': 0};

    int bestMatchIndex = -1;
    int bestWordCount = 0;
    double bestScore = 0.0;

    // Look for consecutive word matches
    for (int i = 0; i <= scriptWords.length - spokenWords.length; i++) {
      double score = _calculateMatchScore(scriptWords, spokenWords, i);
      if (score > bestScore) {
        bestScore = score;
        bestMatchIndex = i;
        bestWordCount = spokenWords.length;
      }
    }

    // Consider single word matches if no consecutive match found
    if (bestScore < 0.5 && spokenWords.isNotEmpty) {
      final lastSpokenWord = spokenWords.last;
      for (int i = 0; i < scriptWords.length; i++) {
        if (_cleanWord(scriptWords[i]).contains(lastSpokenWord) ||
            lastSpokenWord.contains(_cleanWord(scriptWords[i]))) {
          return {
            'startIndex': i,
            'endIndex': i,
            'wordCount': 1,
          };
        }
      }
    }

    if (bestScore > 0.3) {
      return {
        'startIndex': bestMatchIndex,
        'endIndex': bestMatchIndex + bestWordCount - 1,
        'wordCount': bestWordCount,
      };
    }

    return {'startIndex': -1, 'endIndex': -1, 'wordCount': 0};
  }

  /// Calculates match score for consecutive words
  static double _calculateMatchScore(List<String> scriptWords, List<String> spokenWords, int startIndex) {
    int matches = 0;
    int total = spokenWords.length;

    for (int i = 0; i < spokenWords.length && (startIndex + i) < scriptWords.length; i++) {
      final scriptWord = _cleanWord(scriptWords[startIndex + i]);
      final spokenWord = spokenWords[i];

      if (scriptWord == spokenWord ||
          scriptWord.contains(spokenWord) ||
          spokenWord.contains(scriptWord) ||
          _calculateSimilarity(scriptWord, spokenWord) > 0.7) {
        matches++;
      }
    }

    return total > 0 ? matches / total : 0.0;
  }

  /// Calculates similarity between two words using simple character matching
  static double _calculateSimilarity(String word1, String word2) {
    if (word1.isEmpty || word2.isEmpty) return 0.0;
    
    final shorter = word1.length < word2.length ? word1 : word2;
    final longer = word1.length >= word2.length ? word1 : word2;
    
    int matches = 0;
    for (int i = 0; i < shorter.length; i++) {
      if (i < longer.length && shorter[i] == longer[i]) {
        matches++;
      }
    }
    
    return matches / longer.length;
  }

  /// Removes punctuation and converts to lowercase
  static String _cleanWord(String word) {
    return word.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
  }

  /// Calculates the scroll position based on word index and line height
  static double calculateScrollPosition(int wordIndex, List<String> words, double lineHeight) {
    if (wordIndex < 0 || words.isEmpty) return 0.0;
    
    // Estimate words per line (rough calculation)
    const int avgWordsPerLine = 8;
    final int lineNumber = wordIndex ~/ avgWordsPerLine;
    
    return lineNumber * lineHeight;
  }
}