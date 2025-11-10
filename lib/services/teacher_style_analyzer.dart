import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/document_analysis.dart';
import '../models/teacher_style_profile.dart';
import '../models/test.dart';
import 'gemini_ai_service.dart';
import 'firestore_service.dart';

class TeacherStyleAnalyzer {
  final GeminiAIService _aiService = GeminiAIService();
  final FirestoreService _firestoreService = FirestoreService();

  /// 1. HER BELGE YÜKLENDİĞİNDE - Öğretmen stili için detaylı analiz
  Future<DocumentAnalysis> analyzeDocumentForTeacherStyle({
    String? filePath, // For mobile
    Uint8List? fileBytes, // For web
    String? fileName, // For web (to get extension)
    required String courseName,
    required String documentTitle,
    required String teacherName,
    required String documentId,
  }) async {
    try {
      print('🎓 Öğretmen stili analizi: $documentTitle');
      
      Uint8List bytes;
      String extension;
      
      if (kIsWeb) {
        // Web platform
        if (fileBytes == null) throw 'Web platformunda fileBytes gerekli';
        bytes = fileBytes;
        extension = fileName?.split('.').last.toLowerCase() ?? 'jpg';
      } else {
        // Mobile platform
        if (filePath == null) throw 'Mobil platformda filePath gerekli';
        final file = File(filePath);
        if (!await file.exists()) throw 'Dosya bulunamadı';
        bytes = await file.readAsBytes();
        extension = filePath.split('.').last.toLowerCase();
      }
      
      String mimeType;
      if (extension == 'pdf') {
        mimeType = 'application/pdf';
      } else if (['jpg', 'jpeg'].contains(extension)) {
        mimeType = 'image/jpeg';
      } else if (extension == 'png') {
        mimeType = 'image/png';
      } else {
        mimeType = 'image/jpeg';
      }

      final prompt = '''
🎓 SEN BİR EĞİTİM ANALİZCİSİSİN

GÖREV: Bu belgeyi DETAYLI analiz et! BELGEYE ODAKLAN ve BELGEDE YAZANLARI ANALİZ ET!

BELGE: $documentTitle
DERS: $courseName
ÖĞRETMEN: $teacherName

⚠️ ÇOK ÖNEMLİ: Belgede GÖRDÜĞÜN her şeyi analiz et! Belgedeki metinleri, soruları, örnekleri, formülleri, görselleri detaylı incele!

1️⃣ BELGE TİPİ: ders_notu/ödev_kağıdı/sınav_kağıdı/çalışma_föyü/kitap_sayfası

2️⃣ BELGE İÇERİĞİ ANALİZİ (BELGEDE NE VAR?):
- Ana konu (belgede yazılan)
- Alt konular (belgede geçen tüm konular)
- Derinlik: yüzeysel/orta/derinlemesine
- Belgedeki önemli formüller/kurallar (varsa)
- Belgedeki örnekler/uygulamalar (varsa)
- Belgedeki vurgular/önemli notlar (varsa)

3️⃣ SORU ANALİZİ (BELGEDEKİ HER SORUYU DETAYLI ANALİZ ET!):
Belgede gördüğün HER soru için şunları belirt:
{
  "questionNumber": 1,
  "type": "hesaplama", // tanım/hesaplama/problem_çözme/analiz/sentez/karşılaştırma
  "difficulty": "kolay", // kolay/orta/zor
  "topic": "Çarpım Tablosu", // Belgede hangi konuyla ilgili?
  "pageNumber": 1,
  "fullQuestionText": "Belgede yazılan sorunun TAM METNİ", // SORUNUN TAMAMINI YAZ!
  "questionContext": "Sorunun belgedeki bağlamı (hangi konu bölümünde, ne amaçla sorulmuş)",
  "requiredKnowledge": ["Bu soruyu çözmek için gereken bilgiler"],
  "solutionMethod": "Sorunun çözüm yöntemi (varsa belgede yazılan)",
  "relatedConcepts": ["Bu soruyla ilişkili kavramlar"],
  "preview": "Kısa özet"
}

⚠️ ÖNEMLİ: Eğer belgede soru varsa, sorunun TAM METNİNİ "fullQuestionText" alanına yaz! Sorunun çözümü varsa onu da belirt!

4️⃣ BELGEYE ÖZEL ÖĞRETMEN STİLİ:
{
  "emphasizedTopics": ["Belgede vurgulanan konular"],
  "preferredQuestionTypes": ["Belgede görülen soru tipleri"],
  "difficultyPreference": "Belgedeki soruların zorluk dağılımı",
  "usesVisuals": false, // Belgede görsel/şema var mı?
  "usesRealLifeExamples": true, // Belgede gerçek hayat örneği var mı?
  "focusOnMemorization": false, // Belge ezbere mi odaklı?
  "teachingApproach": "Belgeden çıkarılan öğretim yaklaşımı",
  "keyPointsFromDocument": ["Belgede özellikle vurgulanan noktalar"],
  "additionalNotes": "Belgeye özel notlar"
}

5️⃣ BELGEDEKİ SORULARA GÖRE SINAV TAHMİNİ:
{
  "likelyQuestionCount": 5, // Belgedeki soru sayısına göre
  "confidence": 0.8,
  "reasoning": "Belgedeki sorulara dayalı açıklama",
  "expectedQuestionTypes": ["Belgede görülen soru tipleri"],
  "expectedTopics": ["Belgede işlenen konular"]
}

JSON ÇIKTI (sadece JSON, başka metin yok):
{
  "documentType": "ödev_kağıdı",
  "mainTopic": "Çarpım Tablosu",
  "subTopics": ["2'ler", "5'ler"],
  "topicDepth": "orta",
  "questions": [...], // Her soru için fullQuestionText dahil TÜM detaylar
  "teacherStyleInsights": {...},
  "examPredictionHints": {...}
}
''';

      final response = await _aiService.model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart(mimeType, bytes),
        ])
      ]).timeout(Duration(seconds: 60));
      
      final text = response.text;
      if (text == null || text.isEmpty) throw 'AI boş yanıt';
      
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch == null) throw 'JSON bulunamadı';
      
      final jsonData = json.decode(jsonMatch.group(0)!);
      
      final analysis = DocumentAnalysis(
        documentId: documentId,
        documentTitle: documentTitle,
        documentType: jsonData['documentType'] ?? 'ders_notu',
        mainTopic: jsonData['mainTopic'] ?? '',
        subTopics: List<String>.from(jsonData['subTopics'] ?? []),
        topicDepth: jsonData['topicDepth'] ?? 'orta',
        questions: (jsonData['questions'] as List?)
            ?.map((q) => QuestionAnalysis.fromMap(q))
            .toList() ?? [],
        teacherStyleInsights: TeacherStyleInsights.fromMap(
            jsonData['teacherStyleInsights'] ?? {}),
        examPredictionHints: ExamPredictionHints.fromMap(
            jsonData['examPredictionHints'] ?? {}),
        analyzedAt: DateTime.now(),
      );
      
      print('✅ Analiz tamamlandı: ${analysis.questions.length} soru');
      return analysis;
      
    } catch (e) {
      print('❌ Belge analiz hatası: $e');
      rethrow;
    }
  }

  /// 2. ÖĞRETMEN PROFİLİ OLUŞTUR
  Future<TeacherStyleProfile?> buildTeacherProfile({
    required String courseId,
    required String studentId,
    required String courseName,
    required String teacherName,
  }) async {
    try {
      print('🎯 Öğretmen profili oluşturuluyor...');
      
      // Get all materials
      final materials = await _firestoreService
          .getCourseMaterials(courseId)
          .first;
      
      if (materials.length < 3) {
        print('⚠️ En az 3 belge gerekli. Şu an: ${materials.length}');
        return null;
      }

      // Parse AI analyses from materials
      Map<String, int> questionTypes = {};
      Map<String, TopicAnalysis> topics = {};
      Map<String, int> difficulties = {};
      List<QuestionSource> allSources = [];
      int totalQuestions = 0;

      for (var material in materials) {
        if (material.aiAnalysis == null || material.aiAnalysis!.isEmpty) {
          print('⚠️ Materyal analizi eksik: ${material.title}');
          continue;
        }

        try {
          // Parse the AI analysis JSON
          final analysisData = json.decode(material.aiAnalysis!);
          
          // Extract main topic
          final mainTopic = analysisData['mainTopic'] ?? 'Bilinmeyen Konu';
          
          // Update or create topic analysis
          if (!topics.containsKey(mainTopic)) {
            topics[mainTopic] = TopicAnalysis(
              topicName: mainTopic,
              questionCount: 0,
              averageDifficulty: 0.0,
              subTopics: [],
              sourceDocuments: [],
              examProbability: 0.0,
              teacherEmphasis: 0.0,
            );
          }
          topics[mainTopic]!.questionCount++;
          
          // Extract sub topics
          final subTopics = analysisData['subTopics'] as List?;
          if (subTopics != null) {
            for (var subTopic in subTopics) {
              final topicName = subTopic.toString();
              if (!topics[mainTopic]!.subTopics.contains(topicName)) {
                topics[mainTopic]!.subTopics.add(topicName);
              }
            }
          }
          
          // Add document reference to topic
          topics[mainTopic]!.sourceDocuments.add(DocumentReference(
            documentId: material.id,
            documentTitle: material.title,
            pages: [],
            questionCount: 0,
            difficultyLevel: analysisData['topicDepth'] ?? 'orta',
          ));
          
          // Extract questions
          final questions = analysisData['questions'] as List?;
          if (questions != null) {
            for (var q in questions) {
              totalQuestions++;
              topics[mainTopic]!.questionCount++;
              
              // Count question types
              final type = q['type'] ?? 'diğer';
              questionTypes[type] = (questionTypes[type] ?? 0) + 1;
              
              // Count difficulties
              final difficulty = q['difficulty'] ?? 'orta';
              difficulties[difficulty] = (difficulties[difficulty] ?? 0) + 1;
              
              // Add to sources
              allSources.add(QuestionSource(
                documentId: material.id,
                documentTitle: material.title,
                questionType: type,
                topic: q['topic'] ?? mainTopic,
                difficulty: difficulty,
                pageNumber: q['pageNumber'] ?? 0,
                questionPreview: q['preview'] ?? '',
              ));
              
              // Update document question count
              topics[mainTopic]!.sourceDocuments.last.questionCount++;
            }
          }
          
          print('✅ ${material.title}: ${questions?.length ?? 0} soru');
        } catch (e) {
          print('⚠️ Analiz parse hatası (${material.title}): $e');
        }
      }

      // Calculate average difficulty and exam probability for topics
      for (var topic in topics.values) {
        if (topic.questionCount > 0 && totalQuestions > 0) {
          topic.examProbability = (topic.questionCount / totalQuestions).clamp(0.0, 1.0);
          topic.teacherEmphasis = topic.examProbability;
        }
      }

      // Get completed tests for additional analysis
      final tests = await _firestoreService.getTests(studentId, courseId);
      final completedTests = tests.where((t) => t.isCompleted).toList();
      
      print('📊 İstatistikler:');
      print('   - Toplam Soru: $totalQuestions');
      print('   - Soru Tipleri: ${questionTypes.length}');
      print('   - Konular: ${topics.length}');
      print('   - Tamamlanan Test: ${completedTests.length}');

      // Generate teacher personality with AI
      final personalityPrompt = '''
Bir öğretmen profili oluştur:

DERS: $courseName
ÖĞRETMEN: $teacherName
ANALİZ EDİLEN BELGE: ${materials.length}
TOPLAM SORU: $totalQuestions

SORU TİPİ DAĞILIMI: ${questionTypes.toString()}
KONU DAĞILIMI: ${topics.keys.toList().toString()}
ZORLUK DAĞILIMI: ${difficulties.toString()}

GÖREV: Bu verilere dayanarak öğretmenin öğretim stilini 2-3 cümlede açıkla.
Sadece açıklamayı ver, JSON veya başka format olmasın.
''';

      String teacherPersonality = '';
      try {
        final response = await _aiService.model.generateContent([
          Content.text(personalityPrompt)
        ]);
        teacherPersonality = response.text ?? 'Öğretmen profili ${materials.length} belgeden oluşturuldu.';
      } catch (e) {
        print('⚠️ Kişilik metni oluşturulamadı: $e');
        teacherPersonality = 'Bu öğretmen ${materials.length} belgede toplam $totalQuestions soru sormuş. ${questionTypes.keys.take(2).join(" ve ")} tipi sorular tercih ediyor.';
      }

      // Build exam prediction with PredictedQuestion objects
      final predictedQuestionsMap = <String, PredictedQuestion>{};
      final sortedTopics = topics.entries.toList()
        ..sort((a, b) => b.value.questionCount.compareTo(a.value.questionCount));
      
      for (var entry in sortedTopics.take(5)) {
        predictedQuestionsMap[entry.key] = PredictedQuestion(
          topic: entry.key,
          predictedQuestionCount: (entry.value.questionCount * 0.8).round(),
          confidence: entry.value.examProbability,
          reasoning: 'Bu konu ${entry.value.questionCount} soruda işlenmiş.',
        );
      }

      final examPrediction = ExamPrediction(
        predictedQuestions: predictedQuestionsMap,
        criticalTopics: sortedTopics
            .take(3)
            .map((e) => e.key)
            .toList(),
        possibleTopics: topics.keys.toList(),
        unlikelyTopics: [],
        reasoning: sortedTopics.isNotEmpty 
            ? 'Öğretmen ${sortedTopics.first.key} konusuna daha fazla odaklanıyor.' 
            : 'Öğretmen profili oluşturuldu.',
        overallConfidence: totalQuestions >= 20 ? 0.85 : 0.60,
      );

      final profile = TeacherStyleProfile(
        id: '${courseId}_profile',
        teacherName: teacherName,
        courseName: courseName,
        studentId: studentId,
        questionTypeDistribution: questionTypes,
        topicDistribution: topics,
        difficultyDistribution: difficulties,
        questionSources: allSources,
        totalDocumentsAnalyzed: materials.length,
        totalQuestionsFound: totalQuestions,
        lastUpdated: DateTime.now(),
        teacherPersonality: teacherPersonality,
        examPrediction: examPrediction,
      );
      
      print('✅ Profil oluşturuldu!');
      return profile;
      
    } catch (e) {
      print('❌ Profil hatası: $e');
      return null;
    }
  }

  /// 3. GERÇEK SINAV SİMÜLASYONU
  Future<List<Question>> generateRealisticExam({
    required TeacherStyleProfile teacherProfile,
    required int questionCount,
  }) async {
    try {
      print('📝 Gerçekçi sınav oluşturuluyor...');

      final prompt = '''
🎯 GERÇEK SINAV SİMÜLASYONU

ÖĞRETMEN: ${teacherProfile.teacherName}
DERS: ${teacherProfile.courseName}
ANALİZ EDİLEN BELGE: ${teacherProfile.totalDocumentsAnalyzed}

KİŞİLİK: "${teacherProfile.teacherPersonality}"

GÖREV: Bu öğretmenin GERÇEK sınavında çıkacak $questionCount soru hazırla!

JSON ÇIKTI:
{
  "questions": [
    {
      "question": "Soru metni?",
      "options": ["A", "B", "C", "D"],
      "correctAnswerIndex": 0,
      "explanation": "Detaylı açıklama..."
    }
  ]
}
''';

      final response = await _aiService.model.generateContent([
        Content.text(prompt)
      ]);
      
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response.text ?? '');
      if (jsonMatch == null) throw 'JSON bulunamadı';
      
      final examData = json.decode(jsonMatch.group(0)!);
      
      final questions = <Question>[];
      for (var q in examData['questions']) {
        questions.add(Question(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          question: q['question'],
          options: List<String>.from(q['options']),
          correctAnswerIndex: q['correctAnswerIndex'],
          explanation: q['explanation'],
        ));
      }
      
      print('✅ ${questions.length} soru oluşturuldu!');
      return questions;
      
    } catch (e) {
      print('❌ Sınav hatası: $e');
      rethrow;
    }
  }
}