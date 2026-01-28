// nexaburst/lib/models/server/modes/forbidden_words/forbidden_words_detector.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nexaburst/model_view/room/game/error/error_service.dart';
import 'package:nexaburst/model_view/room/game/modes/drinking/drinking_manager.dart';
import 'package:nexaburst/model_view/room/sync_manager.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:nexaburst/models/data/server/modes/forbidden_words/forbidden_words_detector_interface.dart';
import 'package:nexaburst/models/structures/errors/app_error.dart';
import 'package:nexaburst/models/structures/room_model.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_to_text.dart'; // To ensure dependency awareness.

/// Implements forbidden‐words detection by:
/// 1) Local speech‐to‐text scanning
/// 2) Writing and listening to Firestore events
/// Applies score penalties and optional drinking penalties.
class ForbiddenWordsDetector implements IForbiddenWordsDetector {
  /// Room settings, including `forbiddenWords` and `lang`.
  final Room room;

  /// Language code used for speech recognition locale.
  final String lang;

  /// Speech‐to‐text engine instance for local detection.
  final stt.SpeechToText _speech = stt.SpeechToText();

  /// List of words to detect and penalize.
  final List<String> forbiddenWords;

  /// Firestore client for writing and reading forbidden‐event documents.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Points deducted per detected forbidden word.
  final int scoreIncrement = 1; // example, deduct 1 point per forbidden word.

  /// Tracks whether local speech recognition is active.
  bool _isListening = false;

  /// Controls whether to auto‐restart recognition on interruptions.
  bool _keepListening = false;

  /// Indicates if speech engine has been successfully initialized.
  bool _initialized = false;

  /// Last recognized transcript, used to process only new text.
  String _lastTranscript = "";

  /// Broadcasts server‐side forbidden events to subscribers.
  final _forbiddenEventController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Exposes the broadcast stream for Firestore forbidden events.
  @override
  Stream<Map<String, dynamic>> get forbiddenEventStream =>
      _forbiddenEventController.stream;

  // Firestore subscription for server-side forbidden events.
  StreamSubscription<QuerySnapshot>? _firestoreSubscription;

  /// Creates detector for [room], pulling forbidden words and language.
  ForbiddenWordsDetector({required this.room})
    : forbiddenWords = room.forbiddenWords,
      lang = room.lang;

  /// Initializes the speech‐to‐text engine with error/status callbacks.
  ///
  /// Returns `true` if ready to start detection.
  @override
  Future<bool> initialize() async {
    if (_initialized) return false;
    _initialized = await _speech.initialize(
      onError: (e) {
        debugPrint('STT error (raw): $e');
        // attempt to print common error fields if present
        try {
          final map = e as dynamic;
          debugPrint(
            'STT error.msg: ${map.errorMsg ?? map.msg ?? map.message}',
          );
          debugPrint(
            'STT error.permanent: ${map.permanent ?? map.isPermanent}',
          );
        } catch (_) {}
        if (_keepListening) _restartListening();
      },
      onStatus: (status) {
        debugPrint('STT status: $status');
        if (_keepListening && (status == 'notListening' || status == 'done')) {
          _restartListening();
        }
      },
    );
    debugPrint('STT initialize returned: $_initialized');
    final locales = await _speech.locales();
    debugPrint('Available locales: ${locales.map((l) => l.localeId).toList()}');

    return _initialized;
  }

  /// Starts continuous dictation mode to detect forbidden words locally.
  @override
  void startDetection() {
    if (_isListening || !_initialized) return;
    _isListening = true;
    _keepListening = true;
    _speech.listen(
      onResult: _onSpeechResult,
      onSoundLevelChange: _onSoundLevel,
      localeId: lang,
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        partialResults:
            true, // we still receive partials but ignore them for detection
        cancelOnError: false,
      ),
      // Web implementations often ignore long windows — prefer short and restart
      pauseFor: const Duration(minutes: 10),
      listenFor: const Duration(hours: 1),
    );
  }

  /// Processes new speech transcript, scans for forbidden words,
  /// and triggers `_caseWordDetected` for each hit.
  void _onSpeechResult(SpeechRecognitionResult result) {
    final transcript = (result.recognizedWords ?? '').toLowerCase();
    debugPrint('onResult final=${result.finalResult} words="$transcript"');

    // 1) Compute the new suffix:
    String newText;
    if (transcript.startsWith(_lastTranscript)) {
      newText = transcript.substring(_lastTranscript.length).trim();
    } else {
      // If the engine restructured the text, just take everything
      newText = transcript;
    }

    if (newText.isNotEmpty) {
      debugPrint('New text to scan: "$newText"');
      // 2) Check forbidden words only in newText
      for (var word in forbiddenWords) {
        final pattern = RegExp(r'\b' + RegExp.escape(word) + r'\b');
        if (pattern.hasMatch(newText)) {
          _caseWordDetected(word).catchError((e, st) {
            debugPrint('Error in caseWordDetected: $e\n$st');
          });
          // if you only want one detection per chunk, uncomment:
          // break;
        }
      }
    }

    // 3) Remember what we've seen so far
    _lastTranscript = transcript;
  }

  /// Optional callback logging microphone sound‐level changes.
  void _onSoundLevel(double level) {
    debugPrint('Mic level: ${level.toStringAsFixed(1)} dB');
  }

  /// Stops and restarts speech recognition to maintain continuous listening.
  void _restartListening() {
    if (!_keepListening) return;
    try {
      _speech.stop();
    } catch (_) {}
    _isListening = false;
    // tiny delay, then restart
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_keepListening) startDetection();
    });
  }

  /// Stops local recognition and cancels Firestore event subscription.
  @override
  Future<void> stopDetection() async {
    _keepListening = false;
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
    // cancel the Firestore listener if you started one here
    await _firestoreSubscription?.cancel();
    _firestoreSubscription = null;
  }

  /// Handles a locally detected forbidden [word]:
  /// - Writes or updates a Firestore event doc
  /// - Deducts score in player document
  /// - Applies drinking penalty if enabled
  ///
  /// [word]: the forbidden word detected.
  Future<void> _caseWordDetected(String word) async {
    final lowerWord = word.toLowerCase();
    if (!room.forbiddenWords.contains(lowerWord)) return;

    final roomRef = _firestore.collection('rooms').doc(room.roomId);
    final playerRef = roomRef
        .collection('players')
        .doc(UserData.instance.user!.id);
    final eventDoc = roomRef.collection('forbidden_events').doc(lowerWord);

    try {
      final didClaim = await _firestore.runTransaction<bool>((tx) async {
        final snap = await tx.get(eventDoc);
        if (!snap.exists) {
          // first-ever utterance → create with server timestamp
          tx.set(eventDoc, {
            'playerName': UserData.instance.user!.username,
            'playerId': UserData.instance.user!.id,
            'timestamp': FieldValue.serverTimestamp(),
          });
          return true;
        } else {
          debugPrint(
            '⚠️ Forbidden word "$lowerWord" already exists in Firestore',
          );
        }

        // safe‐cast the stored timestamp
        final data = snap.data()!;
        final raw = data['timestamp'];
        final ts = raw is Timestamp
            ? raw.toDate()
            : raw is DateTime
            ? raw
            : DateTime.fromMillisecondsSinceEpoch(0);

        // if that server‐timestamp is < 3 seconds old, we skip
        final now = DateTime.now();
        if (now.difference(ts).inSeconds < 3) {
          debugPrint('ℹ️ Skipping "$lowerWord"; last claim was at $ts');
          return false;
        }

        // otherwise overwrite with a fresh server timestamp
        tx.update(eventDoc, {
          'playerName': UserData.instance.user!.username,
          'playerId': UserData.instance.user!.id,
          'timestamp': FieldValue.serverTimestamp(),
        });
        return true;
      });

      if (didClaim) {
        await playerRef.update({
          'total_score': FieldValue.increment(-scoreIncrement),
        });
        if (room.isDrinkingMode) {
          SyncManager.instance.playerSaidForbiddenWord(lowerWord);
        }
        debugPrint('✅ Claimed "$lowerWord" and applied penalties');
      }
    } catch (e, st) {
      debugPrint('🔥 caseWordDetected threw:\n$e\n$st');
      ErrorService.instance.report(error: ErrorType.firestore);
    }
  }

  /// Subscribes to Firestore `forbidden_events` collection,
  /// broadcasting added or modified events into `forbiddenEventStream`.
  @override
  void startListeningToForbiddenEvents() {
    try {
      // Reference to the per-word docs
      final eventsColl = _firestore
          .collection('rooms')
          .doc(room.roomId)
          .collection('forbidden_events');

      _firestoreSubscription = eventsColl.snapshots().listen(
        (QuerySnapshot snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added ||
                change.type == DocumentChangeType.modified) {
              final doc = change.doc;
              final data = doc.data() as Map<String, dynamic>;

              // Extract the forbidden word from the document ID
              final word = doc.id;
              final originPlayerId = data['playerId'] as String?;
              final playerName = data['playerName'] as String?;
              final timestamp = data['timestamp'] as Timestamp?;

              if (originPlayerId == null || originPlayerId.isEmpty) {
                debugPrint(
                  '⚠️ Invalid forbidden‐event doc: $word → missing playerId',
                );
                continue;
              }

              // Broadcast into your stream
              _forbiddenEventController.add({
                'word': word,
                'playerId': originPlayerId,
                'playerName': playerName ?? '',
                'timestamp': timestamp,
              });
              debugPrint(
                '▶ Broadcasting forbidden event for word="$word": $data',
              );
            }
          }
        },
        onError: (e, st) {
          debugPrint('❌ Error listening to forbidden_events: $e\n$st');
          ErrorService.instance.report(error: ErrorType.firestore);
        },
      );
    } catch (e) {
      debugPrint("Error listen to word event - model : $e");
      ErrorService.instance.report(error: ErrorType.firestore);
    }
  }
}
