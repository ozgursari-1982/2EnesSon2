class DocumentAnalysis {
  String documentId;
  String documentTitle;
  String documentType; // 'ders_notu', 'ödev_kağıdı', 'sınav_kağıdı', 'çalışma_föyü', 'kitap_sayfası'
  String mainTopic;
  List<String> subTopics;
  String topicDepth; // 'yüzeysel', 'orta', 'derinlemesine'
  
  // SORU ANALİZİ
  List<QuestionAnalysis> questions;
  
  // ÖĞRETMEN STİLİ İPUÇLARI
  TeacherStyleInsights teacherStyleInsights;
  
  // SINAV TAHMİN İPUÇLARI
  ExamPredictionHints examPredictionHints;
  
  DateTime analyzedAt;

  DocumentAnalysis({
    required this.documentId,
    required this.documentTitle,
    required this.documentType,
    required this.mainTopic,
    required this.subTopics,
    required this.topicDepth,
    required this.questions,
    required this.teacherStyleInsights,
    required this.examPredictionHints,
    required this.analyzedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'documentId': documentId,
      'documentTitle': documentTitle,
      'documentType': documentType,
      'mainTopic': mainTopic,
      'subTopics': subTopics,
      'topicDepth': topicDepth,
      'questions': questions.map((e) => e.toMap()).toList(),
      'teacherStyleInsights': teacherStyleInsights.toMap(),
      'examPredictionHints': examPredictionHints.toMap(),
      'analyzedAt': analyzedAt.toIso8601String(),
    };
  }

  factory DocumentAnalysis.fromMap(Map<String, dynamic> map) {
    return DocumentAnalysis(
      documentId: map['documentId'] ?? '',
      documentTitle: map['documentTitle'] ?? '',
      documentType: map['documentType'] ?? '',
      mainTopic: map['mainTopic'] ?? '',
      subTopics: List<String>.from(map['subTopics'] ?? []),
      topicDepth: map['topicDepth'] ?? '',
      questions: (map['questions'] as List?)?.map((e) => QuestionAnalysis.fromMap(e)).toList() ?? [],
      teacherStyleInsights: TeacherStyleInsights.fromMap(map['teacherStyleInsights'] ?? {}),
      examPredictionHints: ExamPredictionHints.fromMap(map['examPredictionHints'] ?? {}),
      analyzedAt: DateTime.parse(map['analyzedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  factory DocumentAnalysis.fromJson(Map<String, dynamic> json) => DocumentAnalysis.fromMap(json);
  
  Map<String, dynamic> toJson() => toMap();
}

class QuestionAnalysis {
  int questionNumber;
  String type; // 'tanım', 'hesaplama', 'problem_çözme', 'analiz', 'sentez'
  String difficulty; // 'kolay', 'orta', 'zor'
  String topic;
  int pageNumber;
  String preview;
  
  // BELGEYE ODAKLI DETAYLI BİLGİLER
  String fullQuestionText; // Sorunun tam metni
  String questionContext; // Sorunun belgedeki bağlamı
  List<String> requiredKnowledge; // Soruyu çözmek için gereken bilgiler
  String solutionMethod; // Çözüm yöntemi (varsa)
  List<String> relatedConcepts; // İlişkili kavramlar

  QuestionAnalysis({
    required this.questionNumber,
    required this.type,
    required this.difficulty,
    required this.topic,
    required this.pageNumber,
    required this.preview,
    this.fullQuestionText = '',
    this.questionContext = '',
    this.requiredKnowledge = const [],
    this.solutionMethod = '',
    this.relatedConcepts = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'questionNumber': questionNumber,
      'type': type,
      'difficulty': difficulty,
      'topic': topic,
      'pageNumber': pageNumber,
      'preview': preview,
      'fullQuestionText': fullQuestionText,
      'questionContext': questionContext,
      'requiredKnowledge': requiredKnowledge,
      'solutionMethod': solutionMethod,
      'relatedConcepts': relatedConcepts,
    };
  }

  factory QuestionAnalysis.fromMap(Map<String, dynamic> map) {
    return QuestionAnalysis(
      questionNumber: map['questionNumber'] ?? 0,
      type: map['type'] ?? '',
      difficulty: map['difficulty'] ?? '',
      topic: map['topic'] ?? '',
      pageNumber: map['pageNumber'] ?? 0,
      preview: map['preview'] ?? '',
      fullQuestionText: map['fullQuestionText'] ?? '',
      questionContext: map['questionContext'] ?? '',
      requiredKnowledge: List<String>.from(map['requiredKnowledge'] ?? []),
      solutionMethod: map['solutionMethod'] ?? '',
      relatedConcepts: List<String>.from(map['relatedConcepts'] ?? []),
    );
  }
}

class TeacherStyleInsights {
  List<String> emphasizedTopics;
  List<String> preferredQuestionTypes;
  String difficultyPreference;
  bool usesVisuals;
  bool usesRealLifeExamples;
  bool focusOnMemorization;
  String additionalNotes;
  
  // BELGEYE ÖZEL EK BİLGİLER
  String teachingApproach; // Belgeden çıkarılan öğretim yaklaşımı
  List<String> keyPointsFromDocument; // Belgede vurgulanan önemli noktalar

  TeacherStyleInsights({
    required this.emphasizedTopics,
    required this.preferredQuestionTypes,
    required this.difficultyPreference,
    required this.usesVisuals,
    required this.usesRealLifeExamples,
    required this.focusOnMemorization,
    this.additionalNotes = '',
    this.teachingApproach = '',
    this.keyPointsFromDocument = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'emphasizedTopics': emphasizedTopics,
      'preferredQuestionTypes': preferredQuestionTypes,
      'difficultyPreference': difficultyPreference,
      'usesVisuals': usesVisuals,
      'usesRealLifeExamples': usesRealLifeExamples,
      'focusOnMemorization': focusOnMemorization,
      'additionalNotes': additionalNotes,
      'teachingApproach': teachingApproach,
      'keyPointsFromDocument': keyPointsFromDocument,
    };
  }

  factory TeacherStyleInsights.fromMap(Map<String, dynamic> map) {
    return TeacherStyleInsights(
      emphasizedTopics: List<String>.from(map['emphasizedTopics'] ?? []),
      preferredQuestionTypes: List<String>.from(map['preferredQuestionTypes'] ?? []),
      difficultyPreference: map['difficultyPreference'] ?? '',
      usesVisuals: map['usesVisuals'] ?? false,
      usesRealLifeExamples: map['usesRealLifeExamples'] ?? false,
      focusOnMemorization: map['focusOnMemorization'] ?? false,
      additionalNotes: map['additionalNotes'] ?? '',
      teachingApproach: map['teachingApproach'] ?? '',
      keyPointsFromDocument: List<String>.from(map['keyPointsFromDocument'] ?? []),
    );
  }
}

class ExamPredictionHints {
  int likelyQuestionCount;
  double confidence;
  String reasoning;
  
  // BELGEDEKİ SORULARA GÖRE EK BİLGİLER
  List<String> expectedQuestionTypes; // Belgede görülen soru tipleri
  List<String> expectedTopics; // Belgede işlenen konular

  ExamPredictionHints({
    required this.likelyQuestionCount,
    required this.confidence,
    required this.reasoning,
    this.expectedQuestionTypes = const [],
    this.expectedTopics = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'likelyQuestionCount': likelyQuestionCount,
      'confidence': confidence,
      'reasoning': reasoning,
      'expectedQuestionTypes': expectedQuestionTypes,
      'expectedTopics': expectedTopics,
    };
  }

  factory ExamPredictionHints.fromMap(Map<String, dynamic> map) {
    return ExamPredictionHints(
      likelyQuestionCount: map['likelyQuestionCount'] ?? 0,
      confidence: map['confidence']?.toDouble() ?? 0.0,
      reasoning: map['reasoning'] ?? '',
      expectedQuestionTypes: List<String>.from(map['expectedQuestionTypes'] ?? []),
      expectedTopics: List<String>.from(map['expectedTopics'] ?? []),
    );
  }
}