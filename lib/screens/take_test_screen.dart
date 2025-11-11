import 'package:flutter/material.dart';
import '../models/test.dart';
import '../services/firestore_service.dart';
import '../services/gamification_service.dart';
import '../widgets/user_stats_widget.dart';
import 'test_result_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TakeTestScreen extends StatefulWidget {
  final Test test;

  const TakeTestScreen({super.key, required this.test});

  @override
  State<TakeTestScreen> createState() => _TakeTestScreenState();
}

class _TakeTestScreenState extends State<TakeTestScreen> {
  final _firestoreService = FirestoreService();
  final _gamificationService = GamificationService();
  final Map<String, int> _selectedAnswers = {};
  int _currentQuestionIndex = 0;
  bool _isSubmitting = false;
  final DateTime _testStartTime = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final question = widget.test.questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / widget.test.questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.test.title),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                '${_currentQuestionIndex + 1}/${widget.test.questions.length}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            minHeight: 8,
          ),
          // Question
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Soru ${_currentQuestionIndex + 1}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    question.question,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 32),
                  // Options
                  ...List.generate(
                    question.options.length,
                    (index) => _buildOptionCard(question.id, index, question.options[index]),
                  ),
                ],
              ),
            ),
          ),
          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (_currentQuestionIndex > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() => _currentQuestionIndex--);
                        },
                        child: const Text('Önceki'),
                      ),
                    ),
                  if (_currentQuestionIndex > 0) const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _selectedAnswers.containsKey(question.id)
                          ? () => _nextOrSubmit()
                          : null,
                      child: Text(
                        _currentQuestionIndex == widget.test.questions.length - 1
                            ? 'Testi Bitir'
                            : 'Sonraki',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(String questionId, int optionIndex, String optionText) {
    final isSelected = _selectedAnswers[questionId] == optionIndex;
    final optionLabel = String.fromCharCode(65 + optionIndex); // A, B, C, D

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isSelected
          ? Theme.of(context).primaryColor.withOpacity(0.1)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedAnswers[questionId] = optionIndex;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey[300],
                ),
                child: Center(
                  child: Text(
                    optionLabel,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  optionText,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _nextOrSubmit() {
    if (_currentQuestionIndex < widget.test.questions.length - 1) {
      setState(() => _currentQuestionIndex++);
    } else {
      _submitTest();
    }
  }

  Future<void> _submitTest() async {
    // Calculate score
    int correctAnswers = 0;
    final answers = <String, String>{};

    for (var question in widget.test.questions) {
      final selectedIndex = _selectedAnswers[question.id];
      if (selectedIndex != null) {
        answers[question.id] = selectedIndex.toString();
        if (selectedIndex == question.correctAnswerIndex) {
          correctAnswers++;
        }
      }
    }

    final score = (correctAnswers / widget.test.questions.length) * 100;
    
    // Çalışma süresini hesapla (dakika)
    final studyTimeMinutes = DateTime.now().difference(_testStartTime).inMinutes.clamp(1, 1000);

    setState(() => _isSubmitting = true);

    try {
      // Test cevaplarını kaydet
      await _firestoreService.submitTestAnswers(
        widget.test.id,
        answers,
        score,
      );

      // Gamification - Test tamamlandı
      final userId = FirebaseAuth.instance.currentUser?.uid;
      List<dynamic> unlockedAchievements = [];
      
      if (userId != null) {
        try {
          unlockedAchievements = await _gamificationService.onTestCompleted(
            userId,
            score: score,
            studyTimeMinutes: studyTimeMinutes,
          );
        } catch (e) {
          print('Gamification hatası: $e');
        }
      }

      if (mounted) {
        // Başarılar kazanıldıysa göster
        if (unlockedAchievements.isNotEmpty) {
          for (final achievement in unlockedAchievements) {
            showAchievementDialog(context, achievement);
            // Her dialog için kısa bir bekleme
            await Future.delayed(const Duration(seconds: 2));
          }
        }

        // Test sayfasını kapat ve sonuç ekranını aç
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TestResultScreen(
              test: widget.test,
              selectedAnswers: _selectedAnswers,
              correctCount: correctAnswers,
              score: score,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

}

