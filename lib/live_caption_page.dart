import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class LiveCaptionPage extends StatefulWidget {
  const LiveCaptionPage({super.key});

  @override
  State<LiveCaptionPage> createState() => _LiveCaptionPageState();
}

class _LiveCaptionPageState extends State<LiveCaptionPage> {
  final SpeechToText _speechToText = SpeechToText();

  bool _speechEnabled = false;
  bool _isListening = false;

  String _captionText = '';
  String _alertType = '';

  // Detected important words
  List<String> _keyTerms = [];

  String _selectedLocale = 'kn_IN';

  double _captionFontSize = 22;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  // ==========================================================
  // INITIALIZE SPEECH
  // ==========================================================

  Future<void> _initializeSpeech() async {
    final available = await _speechToText.initialize(
      onStatus: (status) {
        if (!mounted) return;

        setState(() {
          _isListening = status == 'listening';
        });
      },
      onError: (error) {
        if (!mounted) return;

        setState(() {
          _isListening = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Speech recognition error: ${error.errorMsg}'),
          ),
        );
      },
    );

    if (!mounted) return;

    setState(() {
      _speechEnabled = available;
    });
  }

  // ==========================================================
  // START LISTENING
  // ==========================================================

  Future<void> _startListening() async {
    if (!_speechEnabled) {
      await _initializeSpeech();
    }

    if (!_speechEnabled) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition is not available.')),
      );

      return;
    }

    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.dictation,
        localeId: _selectedLocale,
      ),
    );

    if (!mounted) return;

    setState(() {
      _isListening = true;
    });
  }

  // ==========================================================
  // STOP LISTENING
  // ==========================================================

  Future<void> _stopListening() async {
    await _speechToText.stop();

    if (!mounted) return;

    setState(() {
      _isListening = false;
    });
  }

  // ==========================================================
  // SPEECH RESULT
  // ==========================================================

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) return;

    final originalText = result.recognizedWords;

    final processedText = _processCaption(originalText);

    setState(() {
      _captionText = processedText;

      _detectClassroomAlert(originalText);

      _keyTerms = _extractKeyTerms(originalText);
    });
  }

  // ==========================================================
  // LIGHTWEIGHT NLP PROCESSING
  // ==========================================================

  String _processCaption(String text) {
    String processed = text.trim();

    if (processed.isEmpty) {
      return '';
    }

    // Remove repeated spaces
    processed = processed.replaceAll(RegExp(r'\s+'), ' ');

    // Capitalize first character for English.
    if (_selectedLocale == 'en_IN' && processed.isNotEmpty) {
      processed = processed[0].toUpperCase() + processed.substring(1);
    }

    // Add simple punctuation.
    if (_shouldAddQuestionMark(processed)) {
      if (!processed.endsWith('?')) {
        processed = '$processed?';
      }
    } else {
      if (!processed.endsWith('.') &&
          !processed.endsWith('!') &&
          !processed.endsWith('?')) {
        processed = '$processed.';
      }
    }

    return processed;
  }

  // ==========================================================
  // QUESTION DETECTION
  // ==========================================================

  bool _shouldAddQuestionMark(String text) {
    final lowerText = text.toLowerCase();

    final questionPatterns = [
      // English
      'what is',
      'what are',
      'what was',
      'why is',
      'why are',
      'why do',
      'why does',
      'how is',
      'how are',
      'how do',
      'how does',
      'how can',
      'where is',
      'where are',
      'when is',
      'when was',
      'who is',
      'who are',
      'can you',
      'could you',
      'do you know',
      'explain',
      'question',

      // Kannada
      'ಏನು',
      'ಏಕೆ',
      'ಹೇಗೆ',
      'ಯಾರು',
      'ಯಾವಾಗ',
      'ಎಲ್ಲಿ',
      'ಪ್ರಶ್ನೆ',

      // Hindi
      'क्या है',
      'क्या हैं',
      'क्यों',
      'कैसे',
      'कौन',
      'कब',
      'कहाँ',
      'प्रश्न',

      // Tamil
      'என்ன',
      'ஏன்',
      'எப்படி',
      'யார்',
      'எப்போது',
      'எங்கே',
      'கேள்வி',

      // Telugu
      'ఏమిటి',
      'ఏమి',
      'ఎందుకు',
      'ఎలా',
      'ఎవరు',
      'ఎప్పుడు',
      'ఎక్కడ',
      'ప్రశ్న',

      // Bengali
      'কী',
      'কেন',
      'কীভাবে',
      'কে',
      'কখন',
      'কোথায়',
      'প্রশ্ন',
    ];

    return questionPatterns.any((pattern) => lowerText.contains(pattern));
  }

  // ==========================================================
  // CLASSROOM ALERT DETECTION
  // ==========================================================

  void _detectClassroomAlert(String text) {
    final lowerText = text.toLowerCase();

    final questionPatterns = [
      // English
      'question',
      'what is',
      'what are',
      'why is',
      'why are',
      'how is',
      'how are',
      'how can',
      'where is',
      'when is',
      'who is',
      'can you',
      'explain',

      // Kannada
      'ಪ್ರಶ್ನೆ',
      'ಏನು',
      'ಏಕೆ',
      'ಹೇಗೆ',
      'ಯಾರು',
      'ಯಾವಾಗ',
      'ಎಲ್ಲಿ',
      'ಉತ್ತರ',

      // Hindi
      'प्रश्न',
      'क्या',
      'क्यों',
      'कैसे',
      'कौन',
      'कब',
      'कहाँ',
      'उत्तर',

      // Tamil
      'கேள்வி',
      'என்ன',
      'ஏன்',
      'எப்படி',
      'யார்',
      'எப்போது',
      'எங்கே',
      'பதில்',

      // Telugu
      'ప్రశ్న',
      'ఏమిటి',
      'ఎందుకు',
      'ఎలా',
      'ఎవరు',
      'ఎప్పుడు',
      'ఎక్కడ',
      'సమాధానం',

      // Bengali
      'প্রশ্ন',
      'কী',
      'কেন',
      'কীভাবে',
      'কে',
      'কখন',
      'কোথায়',
      'উত্তর',
    ];

    final homeworkPatterns = [
      // English
      'homework',
      'assignment',
      'submit',
      'submission',
      'complete',
      'project',
      'write down',
      'prepare',
      'due tomorrow',
      'finish the work',

      // Kannada
      'ಮನೆಕೆಲಸ',
      'ಅಸೈನ್‌ಮೆಂಟ್',
      'ಅಸೈನ್ಮೆಂಟ್',
      'ಸಲ್ಲಿಸಿ',
      'ಸಲ್ಲಿಸಬೇಕು',
      'ಪೂರ್ಣಗೊಳಿಸಿ',
      'ನಾಳೆ',
      'ಯೋಜನೆ',

      // Hindi
      'होमवर्क',
      'गृहकार्य',
      'असाइनमेंट',
      'जमा करें',
      'जमा',
      'पूरा करें',
      'कल',
      'प्रोजेक्ट',

      // Tamil
      'வீட்டுப்பாடம்',
      'ஹோம்வொர்க்',
      'அசைன்மென்ட்',
      'சமர்ப்பிக்க',
      'சமர்ப்பிக்கவும்',
      'முடிக்கவும்',
      'நாளை',
      'திட்டம்',

      // Telugu
      'ఇంటిపని',
      'హోంవర్క్',
      'అసైన్‌మెంట్',
      'అసైన్మెంట్',
      'సమర్పించ',
      'సమర్పించండి',
      'పూర్తి చేయండి',
      'రేపు',
      'ప్రాజెక్ట్',

      // Bengali
      'বাড়ির কাজ',
      'হোমওয়ার্ক',
      'অ্যাসাইনমেন্ট',
      'জমা দিন',
      'জমা',
      'সম্পূর্ণ করুন',
      'আগামীকাল',
      'প্রকল্প',
    ];

    final questionDetected = questionPatterns.any(
      (pattern) => lowerText.contains(pattern),
    );

    final homeworkDetected = homeworkPatterns.any(
      (pattern) => lowerText.contains(pattern),
    );

    if (homeworkDetected) {
      _alertType = 'homework';
    } else if (questionDetected) {
      _alertType = 'question';
    } else {
      _alertType = '';
    }
  }

  // ==========================================================
  // KEY TERM EXTRACTION
  // ==========================================================

  List<String> _extractKeyTerms(String text) {
    final lowerText = text.toLowerCase();

    final importantTerms = [
      // Education
      'education',
      'student',
      'teacher',
      'classroom',
      'lecture',
      'lesson',
      'exam',
      'project',
      'assignment',
      'homework',

      // Technology
      'artificial intelligence',
      'machine learning',
      'deep learning',
      'computer',
      'software',
      'hardware',
      'algorithm',
      'database',
      'internet',
      'technology',
      'python',
      'flutter',

      // Science
      'science',
      'physics',
      'chemistry',
      'biology',
      'mathematics',

      // General classroom terms
      'important',
      'definition',
      'example',
      'problem',
      'solution',
      'method',
      'process',
      'result',
      'answer',
    ];

    final detected = <String>[];

    for (final term in importantTerms) {
      if (lowerText.contains(term)) {
        detected.add(term);
      }
    }

    return detected;
  }

  // ==========================================================
  // CHANGE LANGUAGE
  // ==========================================================

  void _changeLanguage(String? value) {
    if (value == null) return;

    setState(() {
      _selectedLocale = value;
      _captionText = '';
      _alertType = '';
      _keyTerms = [];
    });
  }

  // ==========================================================
  // TEXT SIZE
  // ==========================================================

  void _decreaseTextSize() {
    if (_captionFontSize > 16) {
      setState(() {
        _captionFontSize -= 2;
      });
    }
  }

  void _resetTextSize() {
    setState(() {
      _captionFontSize = 22;
    });
  }

  void _increaseTextSize() {
    if (_captionFontSize < 36) {
      setState(() {
        _captionFontSize += 2;
      });
    }
  }

  // ==========================================================
  // CLEAR
  // ==========================================================

  void _clearCaption() {
    setState(() {
      _captionText = '';
      _alertType = '';
      _keyTerms = [];
    });
  }

  // ==========================================================
  // SAVE LECTURE
  // ==========================================================

  Future<void> _saveLecture() async {
    final lecture = _captionText.trim();

    if (lecture.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('There is no caption to save.')),
      );

      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      final savedLectures = prefs.getStringList('saved_lectures') ?? [];

      savedLectures.add(lecture);

      final saved = await prefs.setStringList('saved_lectures', savedLectures);

      if (!mounted) return;

      if (saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lecture saved successfully!')),
        );
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving lecture: $error')));
    }
  }

  // ==========================================================
  // LANGUAGE NAME
  // ==========================================================

  String _getLanguageName() {
    switch (_selectedLocale) {
      case 'kn_IN':
        return 'Kannada';

      case 'hi_IN':
        return 'Hindi';

      case 'ta_IN':
        return 'Tamil';

      case 'te_IN':
        return 'Telugu';

      case 'bn_IN':
        return 'Bengali';

      case 'en_IN':
        return 'English';

      default:
        return 'Language';
    }
  }

  // ==========================================================
  // ALERT UI
  // ==========================================================

  Widget _buildAlert() {
    if (_alertType.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_alertType == 'question') {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.orange.shade100,
          border: Border.all(color: Colors.orange, width: 2),
        ),
        child: const Row(
          children: [
            Icon(Icons.help_outline, size: 32, color: Colors.orange),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QUESTION DETECTED',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Teacher may be asking a question.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.blue.shade100,
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: const Row(
        children: [
          Icon(Icons.assignment, size: 32, color: Colors.blue),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HOMEWORK DETECTED',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 3),
                Text(
                  'Homework or assignment instruction detected.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // KEY TERMS UI
  // ==========================================================

  Widget _buildKeyTerms() {
    if (_keyTerms.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Icon(Icons.key, size: 20, color: Colors.green),

          const Text(
            'Key terms:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          ..._keyTerms.map(
            (term) =>
                Chip(label: Text(term), visualDensity: VisualDensity.compact),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _speechToText.stop();
    super.dispose();
  }

  // ==========================================================
  // UI
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'VaaniLipi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            children: [
              const Text(
                'Live Classroom Caption',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Real-time speech captions for accessible learning',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // LANGUAGE
              DropdownButtonFormField<String>(
                initialValue: _selectedLocale,

                decoration: InputDecoration(
                  labelText: 'Select Language',
                  prefixIcon: const Icon(Icons.language),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),

                items: const [
                  DropdownMenuItem(value: 'kn_IN', child: Text('Kannada')),
                  DropdownMenuItem(value: 'hi_IN', child: Text('Hindi')),
                  DropdownMenuItem(value: 'ta_IN', child: Text('Tamil')),
                  DropdownMenuItem(value: 'te_IN', child: Text('Telugu')),
                  DropdownMenuItem(value: 'bn_IN', child: Text('Bengali')),
                  DropdownMenuItem(value: 'en_IN', child: Text('English')),
                ],

                onChanged: _isListening ? null : _changeLanguage,
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.translate, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Current language: ${_getLanguageName()}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ALERT
              _buildAlert(),

              // KEY TERMS
              _buildKeyTerms(),

              // CAPTION
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),

                    color: Colors.grey.shade50,

                    border: Border.all(
                      color: _isListening ? Colors.green : Colors.blue,
                      width: 2,
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),

                  child: Center(
                    child: SingleChildScrollView(
                      child: Text(
                        _captionText.isEmpty
                            ? (_isListening
                                  ? 'Listening...\n\nSpeak now.'
                                  : 'Press Start to begin\nlive classroom captions.')
                            : _captionText,

                        textAlign: TextAlign.center,

                        style: TextStyle(
                          fontSize: _captionFontSize,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // TEXT SIZE
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Text Size:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(width: 10),

                  OutlinedButton(
                    onPressed: _decreaseTextSize,
                    child: const Text('A−', style: TextStyle(fontSize: 18)),
                  ),

                  const SizedBox(width: 8),

                  OutlinedButton(
                    onPressed: _resetTextSize,
                    child: const Text('A', style: TextStyle(fontSize: 18)),
                  ),

                  const SizedBox(width: 8),

                  OutlinedButton(
                    onPressed: _increaseTextSize,
                    child: const Text('A+', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // SAVE
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _captionText.trim().isEmpty ? null : _saveLecture,

                  icon: const Icon(Icons.save),

                  label: const Text(
                    'Save Lecture',
                    style: TextStyle(fontSize: 16),
                  ),

                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              // CLEAR
              TextButton.icon(
                onPressed: _captionText.trim().isEmpty ? null : _clearCaption,

                icon: const Icon(Icons.clear),

                label: const Text('Clear Caption'),
              ),

              // START / STOP
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isListening ? _stopListening : _startListening,

                  icon: Icon(_isListening ? Icons.stop : Icons.mic),

                  label: Text(
                    _isListening ? 'Stop Listening' : 'Start Live Caption',

                    style: const TextStyle(fontSize: 17),
                  ),

                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
