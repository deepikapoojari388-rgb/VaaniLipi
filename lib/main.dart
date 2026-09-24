import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'live_caption_page.dart';

void main() {
  runApp(const VaaniLipiApp());
}

// ==========================================================
// APP
// ==========================================================

class VaaniLipiApp extends StatelessWidget {
  const VaaniLipiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VaaniLipi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

// ==========================================================
// HOME PAGE
// ==========================================================

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [
              const SizedBox(height: 30),

              const Icon(Icons.closed_caption, size: 80, color: Colors.blue),

              const SizedBox(height: 20),

              const Text(
                'Accessible Learning with Live Captions',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              Text(
                'Real-time regional-language captions '
                'for students with hearing loss.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 40),

              // LIVE CAPTION BUTTON
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LiveCaptionPage(),
                    ),
                  );
                },

                icon: const Icon(Icons.mic),

                label: const Text(
                  'Live Classroom Caption',
                  style: TextStyle(fontSize: 17),
                ),

                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

              const SizedBox(height: 15),

              // LECTURE NOTES BUTTON
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LectureNotesPage(),
                    ),
                  );
                },

                icon: const Icon(Icons.menu_book),

                label: const Text(
                  'Lecture Notes',
                  style: TextStyle(fontSize: 17),
                ),

                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

              const Spacer(),

              Text(
                'VaaniLipi • Inclusive Education',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// LECTURE NOTES PAGE
// ==========================================================

class LectureNotesPage extends StatefulWidget {
  const LectureNotesPage({super.key});

  @override
  State<LectureNotesPage> createState() => _LectureNotesPageState();
}

class _LectureNotesPageState extends State<LectureNotesPage> {
  final TextEditingController _searchController = TextEditingController();

  List<String> _allLectures = [];
  List<String> _filteredLectures = [];

  bool _isLoading = true;

  // ==========================================================
  // INITIALIZE
  // ==========================================================

  @override
  void initState() {
    super.initState();
    _loadLectures();
  }

  // ==========================================================
  // LOAD LECTURES
  // ==========================================================

  Future<void> _loadLectures() async {
    final prefs = await SharedPreferences.getInstance();

    final lectures = prefs.getStringList('saved_lectures') ?? [];

    if (!mounted) return;

    setState(() {
      _allLectures = lectures;
      _filteredLectures = lectures;
      _isLoading = false;
    });
  }

  // ==========================================================
  // SEARCH
  // ==========================================================

  void _searchLectures(String query) {
    final searchText = query.trim().toLowerCase();

    if (searchText.isEmpty) {
      setState(() {
        _filteredLectures = List.from(_allLectures);
      });

      return;
    }

    final results = _allLectures.where((lecture) {
      return lecture.toLowerCase().contains(searchText);
    }).toList();

    setState(() {
      _filteredLectures = results;
    });
  }

  // ==========================================================
  // HIGHLIGHT SEARCH KEYWORD
  // ==========================================================

  TextSpan _highlightText(String text, String query) {
    if (query.trim().isEmpty) {
      return TextSpan(
        text: text,
        style: const TextStyle(fontSize: 16, height: 1.5),
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    final spans = <TextSpan>[];

    int currentPosition = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, currentPosition);

      if (index == -1) {
        if (currentPosition < text.length) {
          spans.add(
            TextSpan(
              text: text.substring(currentPosition),
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          );
        }

        break;
      }

      // Text before match
      if (index > currentPosition) {
        spans.add(
          TextSpan(
            text: text.substring(currentPosition, index),
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        );
      }

      // Highlighted match
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.yellow,
          ),
        ),
      );

      currentPosition = index + query.length;
    }

    return TextSpan(children: spans);
  }

  // ==========================================================
  // DELETE ONE LECTURE
  // ==========================================================

  Future<void> _deleteLecture(int index) async {
    final lectureToDelete = _filteredLectures[index];

    final realIndex = _allLectures.indexOf(lectureToDelete);

    if (realIndex == -1) return;

    final prefs = await SharedPreferences.getInstance();

    _allLectures.removeAt(realIndex);

    await prefs.setStringList('saved_lectures', _allLectures);

    _searchLectures(_searchController.text);
  }

  // ==========================================================
  // DELETE ALL
  // ==========================================================

  Future<void> _deleteAllLectures() async {
    if (_allLectures.isEmpty) {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text('Delete All Notes?'),

          content: const Text('All saved lecture notes will be deleted.'),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete All'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('saved_lectures');

    if (!mounted) return;

    setState(() {
      _allLectures = [];
      _filteredLectures = [];
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('All lecture notes deleted.')));
  }

  // ==========================================================
  // REFRESH
  // ==========================================================

  Future<void> _refreshLectures() async {
    setState(() {
      _isLoading = true;
    });

    await _loadLectures();

    _searchLectures(_searchController.text);
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _searchController.dispose();
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
          'Lecture Notes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        centerTitle: true,

        actions: [
          IconButton(
            onPressed: _refreshLectures,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
          ),

          IconButton(
            onPressed: _allLectures.isEmpty ? null : _deleteAllLectures,
            tooltip: 'Delete All',
            icon: const Icon(Icons.delete_sweep),
          ),
        ],
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            children: [
              // ==================================================
              // SEARCH BOX
              // ==================================================

              TextField(
                controller: _searchController,

                onChanged: _searchLectures,

                decoration: InputDecoration(
                  hintText: 'Search lecture notes...',

                  prefixIcon: const Icon(Icons.search),

                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();

                            _searchLectures('');
                          },
                          icon: const Icon(Icons.clear),
                        )
                      : null,

                  border: const OutlineInputBorder(),

                  filled: true,

                  fillColor: Colors.grey.shade50,
                ),
              ),

              const SizedBox(height: 8),

              // SEARCH INFORMATION
              if (_searchController.text.trim().isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Matching keyword is highlighted',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),

              const SizedBox(height: 12),

              // ==================================================
              // CONTENT
              // ==================================================
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _allLectures.isEmpty
                    ? _buildEmptyState()
                    : _filteredLectures.isEmpty
                    ? _buildNoSearchResults()
                    : ListView.builder(
                        itemCount: _filteredLectures.length,

                        itemBuilder: (context, index) {
                          final lecture = _filteredLectures[index];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),

                            elevation: 2,

                            child: Padding(
                              padding: const EdgeInsets.all(16),

                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  // LECTURE NUMBER
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),

                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.blue.shade100,
                                        ),

                                        child: const Icon(
                                          Icons.menu_book,
                                          color: Colors.blue,
                                          size: 20,
                                        ),
                                      ),

                                      const SizedBox(width: 10),

                                      Expanded(
                                        child: Text(
                                          'Lecture ${index + 1}',
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),

                                      IconButton(
                                        onPressed: () {
                                          _deleteLecture(index);
                                        },

                                        tooltip: 'Delete',

                                        icon: const Icon(Icons.delete_outline),
                                      ),
                                    ],
                                  ),

                                  const Divider(),

                                  const SizedBox(height: 5),

                                  // LECTURE TEXT
                                  RichText(
                                    text: _highlightText(
                                      lecture,
                                      _searchController.text,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // EMPTY STATE
  // ==========================================================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Icon(Icons.menu_book_outlined, size: 80, color: Colors.grey.shade400),

          const SizedBox(height: 15),

          const Text(
            'No Lecture Notes',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(
            'Save a lecture from Live Classroom Caption.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // NO SEARCH RESULTS
  // ==========================================================

  Widget _buildNoSearchResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Icon(Icons.search_off, size: 70, color: Colors.grey.shade400),

          const SizedBox(height: 15),

          const Text(
            'No Matching Notes',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(
            'No lecture contains "${_searchController.text}".',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
