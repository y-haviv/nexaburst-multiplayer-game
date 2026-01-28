
/*
/// A helper class that continuously monitors the audio input and
/// keeps track of the latest recorded decibel level.
/// Make sure to call [init] before starting the monitor.
class AudioLoudnessMonitor {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  StreamSubscription? _levelSubscription;

  bool doNotClean = false; // Flag to prevent cleaning up the history.

  // Store volume samples with timestamps.
  final List<MapEntry<DateTime, double>> volumeHistory = [];
  DateTime? _lastSampleTime;
  static const Duration _minSampleInterval = Duration(milliseconds: 50);
  final Duration memoryDuration = Duration(seconds: 5); // e.g. 5s history

  Future<void> init() async {
    // פותחים את ה-recorder
    await _recorder.openRecorder();
    // קובעים באיזו תדירות מקבלים onProgress
    await _recorder.setSubscriptionDuration(_minSampleInterval);
  }

  Future<void> startMonitoring() async {
    // מתחילים הקלטה ב-PCM כדי לקבל decibels
    await _recorder.startRecorder(
      toStream: StreamController<Uint8List>().sink,
      codec: Codec.pcm16,                   // PCM – יאפשר decibels
      sampleRate: 16000,                    // 16 kHz
      numChannels: 1,                       // מונו
      audioSource: AudioSource.microphone,  // ממיקרופון
    );

    _levelSubscription = _recorder.onProgress!.listen((event) {
      final now = DateTime.now();
      if (_lastSampleTime == null ||
          now.difference(_lastSampleTime!) >= _minSampleInterval) {
        // כאן כבר אמור להיות dB אמיתי במקום null/0
        final dB = event.decibels ?? 0.0;
        volumeHistory.add(MapEntry(now, double.parse(dB.toStringAsFixed(1))));
        _lastSampleTime = now;

        // נקה היסטוריה ישנה
        volumeHistory.removeWhere(
          (e) => now.difference(e.key) > memoryDuration,
        );
      }
    });
  }

  Future<void> stopMonitoring() async {
    await _recorder.stopRecorder();
    await _levelSubscription?.cancel();
    volumeHistory.clear();
  }

  Future<void> close() async {
    await _recorder.closeRecorder();
  }

  /// Gets the peak volume in the last `memoryDuration`.
  /// Returns the average of the top 3 dB samples between [start] and [end].
  /// If there are fewer than 3 samples, averages whatever is available.
  /// Returns 0.0 if no samples fall in that window.
  double getPeakVolumeInWindow(DateTime start, DateTime end) {
    // 1️⃣ pick only those entries in the desired window
    final samples = volumeHistory
        .where((e) => !e.key.isBefore(start) && !e.key.isAfter(end))
        .map((e) => e.value)
        .toList();

    if (samples.isEmpty) return 0.0;

    // 2️⃣ sort descending
    samples.sort((b, a) => a.compareTo(b));

    // 3️⃣ take up to the first three
    final top = samples.take(3).toList();
    final sum = top.fold<double>(0, (acc, v) => acc + v);
    return sum / top.length;
  }

  /// Estimate the start time of the first word, given the moment you
  /// realized “a word” was spoken (detectTime).
  ///
  /// Scans `volumeHistory` backwards looking for the first jump above
  /// baseline + thresholdDb.
  DateTime estimateSpeechStart(
    DateTime detectTime, {
    double thresholdDb = 5.0,
    Duration lookback = const Duration(seconds: 2),
    int baselineSamples = 5,
  }) {
    // 1️⃣ Filter history to the window [detectTime - lookback, detectTime]
    final windowStart = detectTime.subtract(lookback);
    final window = volumeHistory
        .where((e) => e.key.isAfter(windowStart) && e.key.isBefore(detectTime))
        .toList();

    if (window.isEmpty) return detectTime.subtract(Duration(milliseconds: 500));

    // 2️⃣ Compute baseline from the earliest N samples in that window
    final baselineList = window.take(baselineSamples).map((e) => e.value);
    final baseline =
        baselineList.fold(0.0, (a, b) => a + b) / baselineList.length;

    // 3️⃣ Walk from the front of the window until we see volume ≥ baseline+threshold
    for (var entry in window) {
      if (entry.value >= baseline + thresholdDb) {
        return entry.key;
      }
    }

    // Fallback: if nothing jumps high enough, just return the first sample time
    return window.first.key;
  }
}

/// The ForbiddenWordsDetector class listens for microphone input,
/// detects forbidden words using speech-to-text, and also measures the audio
/// loudness (in decibels) so that when multiple players pick up the same word,
/// the one with the highest decibel reading (loudest) is selected.
class ForbiddenWordsDetector {
  final String roomId, playerId, lang;
  final List<String> forbiddenWords;
  final ForbiddenWordCallback onForbiddenWordDetected;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final stt.SpeechToText _speech = stt.SpeechToText();
  //final AudioLoudnessMonitor loudnessMonitor;

  // —— STATE FOR TIMED PARTIALS ——
  //final List<_TimedPartial> _partials = [];

  bool _isListening = false;
  bool _keepListening = false;
  Timer? _eventDelayTimer;

  ForbiddenWordsDetector({
    required this.roomId,
    required this.playerId,
    required this.forbiddenWords,
    required this.onForbiddenWordDetected,
    //required this.loudnessMonitor,
    required this.lang,
  });

  Future<bool> initialize() async {
    return await _speech.initialize(
      onError: (e) => debugPrint('STT error: $e'),
      onStatus: (status) async {
        debugPrint('STT status: $status');
        if (_keepListening && status != 'listening') {
          _isListening = false;
          await _speech.stop();
          Future.delayed(Duration(milliseconds: 500), startDetection);
        }
      },
    );
  }

  void startDetection() {
    if (_isListening) return;
    _isListening = true;
    _keepListening = true;
    //_partials.clear();
    //loudnessMonitor.doNotClean = false; // Prevent cleaning up the history

    _speech
        .listen(
      onResult: (result) {
        
        if (!loudnessMonitor.doNotClean)
          loudnessMonitor.doNotClean = true; // Prevent cleaning up the history
        final now = DateTime.now();

        // **1)** collect partial with timestamp
        if (!result.finalResult) {
          final words = result.recognizedWords.split(RegExp(r'\s+'));
          if (_partials.isEmpty) {
            _partials.add(_TimedPartial(
                loudnessMonitor.estimateSpeechStart(now), now, words.last));
          }
          ;
          _partials
              .add(_TimedPartial(_partials.last.EndTimeStamp, now, words.last));
          return;
        }
        bool notOrderYet = true;

        // **2)** On final: detect forbidden word
        for (var word in forbiddenWords) {
          if (result.recognizedWords.toLowerCase().contains(word)) {
            if (notOrderYet) {
              _OrderAlgo(result.recognizedWords);
              notOrderYet = false;
            }
            final finalTimeResult =
                _estimateWordTimeFromFinalResult(word, result.recognizedWords);
            final volume = loudnessMonitor.getPeakVolumeInWindow(
                finalTimeResult.StartTimeStamp, finalTimeResult.EndTimeStamp);
            debugPrint('▶ LOG: match "$word" @ $volume dB');
            _processDetectedWord(word, volume);
            break;
          }

          // **4)** cleanup for next phrase
          _partials.clear();
          loudnessMonitor.doNotClean = false;
        }
        
      },
      localeId: lang,
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        partialResults: true,
        cancelOnError: false,
        sampleRate: 44100,
      ),
      pauseFor: const Duration(milliseconds: 500),
      listenFor: const Duration(minutes: 15),
    )
        .onError((Object error, StackTrace stackTrace) {
      debugPrint('Error during speech recognition: $error');
      _isListening = false;
    });
  }

  /// Stops listening for forbidden words.
  Future<void> stopDetection() async {
    _keepListening = false;
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      _eventDelayTimer?.cancel();
      debugPrint('ForbiddenWordsDetector listening stopped.');
    }
  }



  _TimedPartial _estimateWordTimeFromFinalResult(
    String target,
    String finalText,
  ) {
    final words = finalText.split(RegExp(r'\s+'));
    // 1️⃣ find the first occurrence
    final idx = words.indexOf(target);

    // 2️⃣ error‐check & clamp
    if (_partials.isEmpty) {
      throw StateError('No partial timings recorded');
    }
    if (idx < 0) {
      // word wasn’t found (shouldn’t happen if you checked earlier)
      return _partials.first;
    }
    if (idx >= _partials.length) {
      // more final words than partials: give the last timing
      return _partials.last;
    }
    // 3️⃣ return the exact partial
    return _partials[idx];
  }

  /// Aligns the final recognized text with the recorded partials,
  /// and updates the `_partials` list with corrected timing information.
  /// This is essential because the final text may differ from the live partials,
  /// so we use a dynamic programming algorithm (like Levenshtein alignment)
  /// to match the words and adjust timings accordingly.
  void _OrderAlgo(String finalText) {
    // 1️⃣ Tokenize final result and the partials into lowercase word lists
    final finalWords = finalText
        .trim()
        .split(RegExp(r'\s+'))
        .map((w) => w.toLowerCase())
        .toList();

    // If the transcript is small, or largely unchanged, skip DP:
    if (_partials.isEmpty ||
        finalWords.length < 5 ||
        (finalWords.length - _partials.length).abs() < 2) {
      // simple one-to-one match by index
      for (int k = 0; k < finalWords.length && k < _partials.length; k++) {
        _partials[k] = _partials[k].copyWith(
          Text: finalWords[k],
        );
      }
      return;
    }

    final partialWords = _partials.map((p) => p.Text.toLowerCase()).toList();

    final int n = finalWords.length; // Final result word count
    final int m = partialWords.length; // Recorded partials word count

    // 2️⃣ Initialize a dynamic programming (DP) table for alignment
    final dp = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));

    // 3️⃣ Fill the DP table using Longest Common Subsequence (LCS) logic
    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= m; j++) {
        if (finalWords[i - 1] == partialWords[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1] + 1;
        } else {
          dp[i][j] = dp[i][j - 1] > dp[i - 1][j] ? dp[i][j - 1] : dp[i - 1][j];
        }
      }
    }

    // 4️⃣ Backtrack the table to extract the optimal alignment path
    int i = n;
    int j = m;
    final alignedPartials = List<_TimedPartial?>.filled(n, null);

    while (i > 0 && j > 0) {
      if (finalWords[i - 1] == partialWords[j - 1]) {
        // Match found: assign the partial with correct timing
        alignedPartials[i - 1] = _partials[j - 1];
        i--;
        j--;
      } else if (dp[i - 1][j] >= dp[i][j - 1]) {
        i--; // Skip a word from finalWords (insertion)
      } else {
        j--; // Skip a word from partialWords (deletion)
      }
    }

    // 5️⃣ Fill unmatched (null) entries with fallback timing from nearby partials
    for (int k = 0; k < alignedPartials.length; k++) {
      alignedPartials[k] ??= _partials.isNotEmpty
          ? _partials.last.copyWith(Text: finalWords[k])
          : _TimedPartial(DateTime.now(), DateTime.now(), finalWords[k]);
    }

    // 6️⃣ Overwrite original _partials with aligned and adjusted list
    _partials
      ..clear()
      ..addAll(alignedPartials.cast<_TimedPartial>());
  }

  /// Stops listening for forbidden words.
  Future<void> stopDetection() async {
    _keepListening = false;
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      _eventDelayTimer?.cancel();
      debugPrint('ForbiddenWordsDetector listening stopped.');
    }
  }

  /// Processes a detected forbidden word using the provided [loudness] as the intensity.
  void _processDetectedWord(String word, double loudness) async {
    debugPrint(
        'Detected forbidden word "$word" with measured loudness $loudness dB from player $playerId');
    try {
      // Save the detection event with the measured loudness value.
      bool makeUpdate = await _storeForbiddenEvent(word, loudness);
      if (makeUpdate) {
        // Wait a short delay (e.g., 3 seconds) to allow multiple events to be registered.
        _eventDelayTimer?.cancel();
        _eventDelayTimer = Timer(Duration(seconds: 3), () async {
          await _checkAndTriggerDetection(word);
        });
      }
    } catch (e) {
      debugPrint('Error processing detected forbidden word "$word": $e');
    }
  }

  /// Writes the forbidden event to Firestore under the room’s forbidden_events subcollection.
  Future<bool> _storeForbiddenEvent(String word, double loudness) async {
    try {
      debugPrint('▶ LOG: _storeForbiddenEvent ⏳ write for "$word"');
      final coll = _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('forbidden_events')
          .doc(word);

      bool makeUpdate = await _firestore.runTransaction((tx) async {
        final snap = await tx.get(coll);
        if (!snap.exists) {
          throw Exception(
              '-- forbidden_events -- $word -- document disappeared');
        }
        final data = snap.data() as Map<String, dynamic>;
        final double volume = (data['volume'] ?? 0.0) as double;
        final rawTs = data['timestamp'] as Timestamp?;
        final DateTime timestamp = rawTs?.toDate() ?? DateTime.now();

        if (volume >= loudness &&
            timestamp.isAfter(DateTime.now().subtract(Duration(seconds: 7)))) {
          debugPrint(
              '▶ LOG: ***No need to*** _storeForbiddenEvent written for "$word" detected voulum: $volume >= $loudness');
          return false;
        } else {
          tx.update(coll, {
            'playerId': playerId,
            'volume': loudness,
            'timestamp': FieldValue.serverTimestamp(),
          });
          debugPrint('▶ LOG: _storeForbiddenEvent ✅ written for "$word"');
          return true;
        }
      });

      return makeUpdate;
    } catch (e) {
      debugPrint('Error storing forbidden event for "$word": $e');
      rethrow;
    }
  }

  Future<void> _checkAndTriggerDetection(String word) async {
    try {
      final eventsColl = _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('forbidden_events')
          .doc(word);

      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(eventsColl);
        if (!snap.exists) {
          throw Exception(
              '-- forbidden_events -- $word -- document disappeared');
        }
        final data = snap.data() as Map<String, dynamic>;
        final loserPlayerId = (data['playerId'] ?? "") as String;

        if (loserPlayerId == playerId) {
          onForbiddenWordDetected(word);
          // Clean up: delete just that doc
          tx.update(eventsColl, {});
        }
      });
    } catch (e) {
      debugPrint('Error checking and triggering detection for "$word": $e');
    }
  }
  
}


class _TimedPartial {
  DateTime StartTimeStamp;
  DateTime EndTimeStamp;
  String Text;
  _TimedPartial(this.StartTimeStamp, this.EndTimeStamp, this.Text);

  _TimedPartial copyWith(
      {DateTime? StartTimeStamp, DateTime? EndTimeStamp, String? Text}) {
    return _TimedPartial(
      StartTimeStamp ?? this.StartTimeStamp,
      EndTimeStamp ?? this.EndTimeStamp,
      Text ?? this.Text,
    );
  }
}
*/