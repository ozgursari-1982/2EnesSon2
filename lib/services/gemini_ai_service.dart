import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/test.dart';
import '../models/material_analysis_result.dart';
import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';

// PHASE 1.3: Helper class for material with ID
class MaterialWithId {
  final String id;
  final String title;
  final String analysis;

  MaterialWithId({
    required this.id,
    required this.title,
    required this.analysis,
  });
}

class GeminiAIService {
  late GenerativeModel _model;
  GenerativeModel get model => _model; // Public getter
  final Uuid _uuid = const Uuid();
  
  // API key'i buraya ekleyin veya environment variable olarak kullanın
  static const String _apiKey = 'AIzaSyDTbMcxi7Cl0_IFq1XGCUsu818HTlOIDOI';

  GeminiAIService() {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash', // Çalışan model!
      apiKey: _apiKey,
    );
  }

  // Analyze study material with REAL FILE CONTENT (Vision API)
  Future<String> analyzeStudyMaterialWithFile({
    required String filePath,
    required String courseName,
    required String title,
    String? description,
  }) async {
    try {
      print('🔍 Dosya analiz ediliyor: $filePath');
      
      final file = File(filePath);
      if (!await file.exists()) {
        throw 'Dosya bulunamadı: $filePath';
      }

      final bytes = await file.readAsBytes();
      
      // Dosya uzantısını kontrol et
      final extension = filePath.split('.').last.toLowerCase();
      String mimeType;
      
      if (extension == 'pdf') {
        mimeType = 'application/pdf';
      } else if (['jpg', 'jpeg'].contains(extension)) {
        mimeType = 'image/jpeg';
      } else if (extension == 'png') {
        mimeType = 'image/png';
      } else if (extension == 'webp') {
        mimeType = 'image/webp';
      } else if (extension == 'gif') {
        mimeType = 'image/gif';
      } else if (extension == 'bmp') {
        mimeType = 'image/bmp';
      } else if (['heic', 'heif'].contains(extension)) {
        mimeType = 'image/heic';
      } else {
        throw 'Desteklenmeyen dosya formatı: $extension. Desteklenen formatlar: JPG, PNG, WEBP, GIF, BMP, HEIC, PDF';
      }

      final prompt = '''
Sen bir $courseName öğretmenisin. 

ÖĞRENCİNİN YÜKLEME BİLGİLERİ:
- Başlık: $title
${description != null && description.isNotEmpty ? '- Açıklama: $description' : ''}
- Ders: $courseName

ÇOK ÖNEMLİ: Yukarıdaki bilgiler sadece öğrencinin ne yüklediğini söylüyor. 
ASIL GÖREVİN: Aşağıdaki GERÇEK DOSYA İÇERİĞİNİ detaylı analiz et!

GERÇEK İÇERİĞE GÖRE analiz yap:

📚 ANA KONULAR:
[Dosyada GÖRDÜKLERİNE göre, hangi konular işlenmiş? 3-5 madde]

💡 ÖNEMLİ KAVRAMLAR:
[Dosyada YAZANLARA göre, anahtar kavramlar neler? 3-5 madde]

⚠️ DİKKAT EDİLMESİ GEREKENLER:
[Dosyada VURGULANMIŞsa, önemli noktalar - 3-4 madde]

📊 İÇERİK DETAYI:
[Dosyada ne tür içerik var? Notlar mı, çözümler mi, formüller mi? Açıkla]

📝 ÇALIŞMA ÖNERİLERİ:
[Bu içeriğe GÖRE nasıl çalışmalı? 2-3 spesifik öneri]

✅ SINAV HAZIRLIĞI:
[Bu içerikten NASIL sorular sorulabilir? Örnek tipleri ver]

UYARI: Eğer başlık ile dosya içeriği farklıysa, DOSYA İÇERİĞİNİ önceliklendir ve bunu belirt!

Türkçe, net ve öğrenci dostu bir dille yaz.
''';

      // Vision model ile analiz (resim/pdf desteği)
      final response = await _model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart(mimeType, bytes),
        ])
      ]).timeout(
        const Duration(seconds: 60), // PDF/resim için daha uzun süre
        onTimeout: () => throw 'AI yanıt süresi aşıldı (60 saniye). Dosya çok büyük olabilir.',
      );
      
      final text = response.text;
      if (text == null || text.isEmpty) {
        throw 'AI boş yanıt döndü';
      }
      
      print('✅ Dosya başarıyla analiz edildi');
      return text;
      
    } catch (e) {
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('429') || errorMessage.contains('quota') || errorMessage.contains('rate limit')) {
        print('❌ AI Kota Aşıldı Hatası (429): $e');
        throw 'AI kota aşıldı. Lütfen daha sonra tekrar deneyin.';
      } else {
        print('❌ AI Dosya Analiz Hatası: $e');
        rethrow;
      }
    }
  }

  // PHASE 1.2: Analyze study material with STRUCTURED JSON OUTPUT
  // This method returns structured data instead of free text
  Future<MaterialAnalysisResult> analyzeStudyMaterialStructured({
    required String filePath,
    required String courseName,
    required String title,
    String? description,
  }) async {
    try {
      print('🔍 Dosya yapılandırılmış analiz ediliyor: $filePath');
      
      final file = File(filePath);
      if (!await file.exists()) {
        throw 'Dosya bulunamadı: $filePath';
      }

      final bytes = await file.readAsBytes();
      
      // Dosya uzantısını kontrol et
      final extension = filePath.split('.').last.toLowerCase();
      String mimeType;
      
      if (extension == 'pdf') {
        mimeType = 'application/pdf';
      } else if (['jpg', 'jpeg'].contains(extension)) {
        mimeType = 'image/jpeg';
      } else if (extension == 'png') {
        mimeType = 'image/png';
      } else if (extension == 'webp') {
        mimeType = 'image/webp';
      } else if (extension == 'gif') {
        mimeType = 'image/gif';
      } else if (extension == 'bmp') {
        mimeType = 'image/bmp';
      } else if (['heic', 'heif'].contains(extension)) {
        mimeType = 'image/heic';
      } else {
        throw 'Desteklenmeyen dosya formatı: $extension';
      }

      final prompt = '''
Sen bir $courseName öğretmenisin. 

ÖĞRENCİNİN YÜKLEME BİLGİLERİ:
- Başlık: $title
${description != null && description.isNotEmpty ? '- Açıklama: $description' : ''}
- Ders: $courseName

ÇOK ÖNEMLİ: Yukarıdaki bilgiler sadece öğrencinin ne yüklediğini söylüyor. 
ASIL GÖREVİN: Aşağıdaki GERÇEK DOSYA İÇERİĞİNİ detaylı analiz et!

Çıktı formatı (SADECE JSON, başka metin yok):
{
  "mainTopics": ["Konu 1", "Konu 2", "Konu 3"],
  "keyConcepts": ["Kavram 1", "Kavram 2", "Kavram 3"],
  "importantPoints": ["Önemli nokta 1", "Önemli nokta 2"],
  "contentType": "ödev_kağıdı",
  "contentDetail": "Dosyada ne tür içerik var? Notlar mı, çözümler mi, formüller mi? Detaylı açıkla.",
  "studyRecommendations": [
    "Bu içeriğe göre çalışma önerisi 1",
    "Bu içeriğe göre çalışma önerisi 2"
  ],
  "examPreparation": {
    "questionTypes": ["Hesaplama", "Problem Çözme", "Tanım"],
    "difficulty": "orta",
    "estimatedQuestions": 5
  }
}

KURALLAR:
- mainTopics: Dosyada gördüğün ana konular (3-5 madde)
- keyConcepts: Dosyada yazılan anahtar kavramlar (3-5 madde)
- importantPoints: Dosyada vurgulanan önemli noktalar (2-4 madde)
- contentType: "ders_notu", "ödev_kağıdı", "sınav_kağıdı", "çalışma_föyü" veya "kitap_sayfası"
- contentDetail: İçeriğin detaylı açıklaması
- studyRecommendations: Bu içeriğe özel çalışma önerileri (2-3 madde)
- examPreparation.questionTypes: Bu içerikten ne tür sorular sorulabilir
- examPreparation.difficulty: "kolay", "orta" veya "zor"
- examPreparation.estimatedQuestions: Sınavda kaç soru çıkabilir (tahmini)

UYARI: Eğer başlık ile dosya içeriği farklıysa, DOSYA İÇERİĞİNİ önceliklendir ve bunu contentDetail'de belirt!
''';

      // Vision model ile analiz
      final response = await _model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart(mimeType, bytes),
        ])
      ]).timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw 'AI yanıt süresi aşıldı (60 saniye). Dosya çok büyük olabilir.',
      );
      
      final text = response.text;
      if (text == null || text.isEmpty) {
        throw 'AI boş yanıt döndü';
      }
      
      // JSON parse et
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch == null) {
        throw 'JSON bulunamadı. AI yanıtı: ${text.substring(0, text.length > 100 ? 100 : text.length)}...';
      }
      
      final jsonString = jsonMatch.group(0)!;
      final jsonData = json.decode(jsonString);
      
      print('✅ Dosya başarıyla yapılandırılmış analiz edildi');
      return MaterialAnalysisResult.fromJson(jsonData);
      
    } catch (e) {
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('429') || errorMessage.contains('quota') || errorMessage.contains('rate limit')) {
        print('❌ AI Kota Aşıldı Hatası (429): $e');
        throw 'AI kota aşıldı. Lütfen daha sonra tekrar deneyin.';
      } else {
        print('❌ AI Yapılandırılmış Analiz Hatası: $e');
        rethrow;
      }
    }
  }

  // Validate question data before creating Question object
  bool _validateQuestion(Map<String, dynamic> q) {
    // 1. Temel alan kontrolleri - Required fields must exist and not be empty
    if (q['question']?.toString().isEmpty ?? true) {
      print('⚠️ Validasyon hatası: Soru metni boş');
      return false;
    }
    if (q['explanation']?.toString().isEmpty ?? true) {
      print('⚠️ Validasyon hatası: Açıklama boş');
      return false;
    }
    
    // 2. Şık sayısı kontrolü - Must have exactly 4 options
    final options = q['options'] as List?;
    if (options == null || options.length != 4) {
      print('⚠️ Validasyon hatası: Şık sayısı ${options?.length ?? 0} (4 olmalı)');
      return false;
    }
    
    // 3. Doğru cevap indeksi kontrolü - Must be valid
    final correctIndex = q['correctAnswerIndex'];
    if (correctIndex == null || correctIndex is! int || correctIndex < 0 || correctIndex >= 4) {
      print('⚠️ Validasyon hatası: Geçersiz doğru cevap indeksi: $correctIndex');
      return false;
    }
    
    // 4. Şık benzersizliği - Options must be unique
    final uniqueOptions = options.toSet();
    if (uniqueOptions.length != 4) {
      print('⚠️ Validasyon hatası: Şıklar benzersiz değil');
      return false;
    }
    
    // 5. Minimum uzunluk kontrolü - Question must be at least 10 characters
    if (q['question'].toString().length < 10) {
      print('⚠️ Validasyon hatası: Soru çok kısa (min 10 karakter)');
      return false;
    }
    
    // 6. Options minimum length - Each option should have some content
    for (var option in options) {
      if (option.toString().trim().isEmpty) {
        print('⚠️ Validasyon hatası: Boş şık');
        return false;
      }
    }
    
    return true;
  }

  // Generate test questions based on materials
  Future<List<Question>> generateTest({
    required String courseName,
    required List<String> materialAnalyses,
    required int questionCount,
    String difficulty = 'orta',
  }) async {
    try {
      final prompt = '''
Sen bir $courseName öğretmenisin. 

ÇOK ÖNEMLİ: Aşağıda öğrencinin GERÇEK DOSYALARDAN yapılmış AI ANALİZLERİ var.
Bu analizler, öğrencinin yüklediği gerçek notların, ödevlerin içeriğinden çıkarılmıştır.

ÖĞRENCİNİN GERÇEK ÇALIŞMA İÇERİKLERİ:
${materialAnalyses.join('\n\n━━━━━━━━━━━━━━━━━━━━━━━━\n\n')}

GÖREV: Yukarıdaki GERÇEK İÇERİKLERDEN $questionCount adet özgün soru oluştur!

KURALLAR:
❌ Genel bilgi soruları YASAK
❌ Hazır kalıp sorular YASAK  
✅ Öğrencinin yüklediği içeriğe ÖZEL sorular oluştur
✅ Analizlerdeki spesifik konulardan sor
✅ İçerikte geçen kavramları kullan

Zorluk: $difficulty
Format: Çoktan seçmeli (4 şık)

ÖRNEKLENDİRME:
Eğer analizde "toplama işlemi" geçiyorsa, toplamadan sor.
Eğer analizde "notolar" geçiyorsa, notolardan sor.
Eğer analizde "fiil çekimi" geçiyorsa, fiil çekiminden sor.

Çıktı formatı (sadece JSON, başka metin yok):
{
  "questions": [
    {
      "question": "Öğrencinin çalıştığı içeriğe ÖZEL soru?",
      "options": ["Şık A", "Şık B", "Şık C", "Şık D"],
      "correctAnswerIndex": 0,
      "explanation": "DETAYLI AÇIKLAMA! 3 bölüm: 1) Doğru cevap neden doğru? Kavramı açıkla. 2) Yanlış şıklar neden yanlış? 3) Öğrencinin yüklediği hangi materyalden bu soru geldi? Bu konuyu nasıl çalışmalı?"
    }
  ]
}

AÇIKLAMA ÖRNEĞİ:
"✅ Doğru Cevap: [X] çünkü [kavram açıklaması]. Yüklediğin notta [spesifik detay] yazıyordu. 

❌ Diğer Şıklar: [Y] yanlış çünkü [neden]. [Z] da hatalı çünkü [neden].

📚 Bu Konu: Bu soru, yüklediğin '[materyal başlığı]' notundan geldi. [Spesifik öneri] çalışarak pekiştirebilirsin."
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '';
      
      // JSON'ı parse et
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);
      if (jsonMatch == null) {
        throw 'Geçerli bir JSON yanıtı alınamadı';
      }
      
      final jsonString = jsonMatch.group(0)!;
      final data = json.decode(jsonString);
      
      // PHASE 1.1: Add validation - filter valid questions only
      final List<Question> validQuestions = [];
      final List<String> invalidQuestions = [];
      
      for (var q in data['questions']) {
        if (_validateQuestion(q)) {
          validQuestions.add(Question(
            id: _uuid.v4(),
            question: q['question'],
            options: List<String>.from(q['options']),
            correctAnswerIndex: q['correctAnswerIndex'],
            explanation: q['explanation'],
          ));
        } else {
          invalidQuestions.add(q['question']?.toString() ?? 'Bilinmeyen soru');
          print('⚠️ Geçersiz soru atlandı: ${q['question']}');
        }
      }
      
      // Check if we have enough valid questions (at least 80% of requested)
      if (validQuestions.length < questionCount * 0.8) {
        throw '''
Yeterli kaliteli soru üretilemedi.
İstenen: $questionCount
Geçerli: ${validQuestions.length}
Geçersiz: ${invalidQuestions.length}
Lütfen tekrar deneyin veya farklı materyaller ekleyin.''';
      }
      
      print('✅ ${validQuestions.length} geçerli soru oluşturuldu');
      if (invalidQuestions.isNotEmpty) {
        print('⚠️ ${invalidQuestions.length} geçersiz soru atlandı');
      }
      
      return validQuestions;
    } catch (e) {
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('429') || errorMessage.contains('quota') || errorMessage.contains('rate limit')) {
        print('❌ AI Kota Aşıldı Hatası (429): $e');
        throw 'AI kota aşıldı. Lütfen daha sonra tekrar deneyin.';
      } else {
        print('❌ Test oluşturulurken AI hatası: $e');
        rethrow;
      }
    }
  }

  // PHASE 1.3: Generate test with material reference tracking
  // This version tracks which material each question came from
  Future<List<Question>> generateTestWithTracking({
    required String courseName,
    required List<MaterialWithId> materials,
    required int questionCount,
    String difficulty = 'orta',
  }) async {
    try {
      // Create material map with IDs
      final materialMap = <String, MaterialWithId>{};
      for (int i = 0; i < materials.length; i++) {
        materialMap['MAT_$i'] = materials[i];
      }

      // Build prompt with material IDs
      final materialsText = materials.asMap().entries.map((e) {
        return '''
[MAT_${e.key}] "${e.value.title}"
${e.value.analysis}
''';
      }).join('\n━━━━━━━━━━━━━━━━━━━━━━━━\n');

      final prompt = '''
Sen bir $courseName öğretmenisin. 

ÇOK ÖNEMLİ: Aşağıda öğrencinin GERÇEK DOSYALARDAN yapılmış AI ANALİZLERİ var.

MATERYALLER:
$materialsText

GÖREV: Yukarıdaki GERÇEK İÇERİKLERDEN $questionCount adet özgün soru oluştur!

Her soru için "sourceMaterialId" ve "topic" döndür:
{
  "questions": [
    {
      "question": "Soru metni?",
      "options": ["Şık A", "Şık B", "Şık C", "Şık D"],
      "correctAnswerIndex": 0,
      "explanation": "Detaylı açıklama...",
      "sourceMaterialId": "MAT_0",
      "topic": "Konu Adı"
    }
  ]
}

KURALLAR:
❌ Genel bilgi soruları YASAK
✅ Öğrencinin yüklediği içeriğe ÖZEL sorular oluştur
✅ sourceMaterialId: Sorunun hangi materyalden geldiği (MAT_0, MAT_1, vs.)
✅ topic: Sorunun hangi konuyla ilgili olduğu (örn: "Toplama İşlemi", "Fiil Çekimi")

Zorluk: $difficulty
Format: Çoktan seçmeli (4 şık)
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '';
      
      // JSON parse
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);
      if (jsonMatch == null) {
        throw 'Geçerli bir JSON yanıtı alınamadı';
      }
      
      final jsonString = jsonMatch.group(0)!;
      final data = json.decode(jsonString);
      
      // Process with validation and material tracking
      final List<Question> validQuestions = [];
      final List<String> invalidQuestions = [];
      
      for (var q in data['questions']) {
        if (_validateQuestion(q)) {
          // Get material info
          final materialId = q['sourceMaterialId']?.toString() ?? '';
          final material = materialMap[materialId];
          
          validQuestions.add(Question(
            id: _uuid.v4(),
            question: q['question'],
            options: List<String>.from(q['options']),
            correctAnswerIndex: q['correctAnswerIndex'],
            explanation: q['explanation'],
            sourceMaterialId: material?.id,
            sourceMaterialTitle: material?.title,
            topic: q['topic'],
          ));
        } else {
          invalidQuestions.add(q['question']?.toString() ?? 'Bilinmeyen soru');
        }
      }
      
      // Check threshold
      if (validQuestions.length < questionCount * 0.8) {
        throw '''
Yeterli kaliteli soru üretilemedi.
İstenen: $questionCount
Geçerli: ${validQuestions.length}
Geçersiz: ${invalidQuestions.length}''';
      }
      
      print('✅ ${validQuestions.length} soru oluşturuldu (materyal takipli)');
      return validQuestions;
      
    } catch (e) {
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('429') || errorMessage.contains('quota') || errorMessage.contains('rate limit')) {
        print('❌ AI Kota Aşıldı Hatası (429): $e');
        throw 'AI kota aşıldı. Lütfen daha sonra tekrar deneyin.';
      } else {
        print('❌ Test oluşturulurken AI hatası: $e');
        rethrow;
      }
    }
  }

  // Analyze student's test performance
  Future<String> analyzeTestPerformance({
    required List<Test> completedTests,
    required DateTime examDate,
  }) async {
    try {
      final daysUntilExam = examDate.difference(DateTime.now()).inDays;
      final totalTests = completedTests.length;
      final averageScore = completedTests.isEmpty
          ? 0.0
          : completedTests.map((t) => t.score ?? 0).reduce((a, b) => a + b) / totalTests;

      final prompt = '''
Bir öğrencinin sınav hazırlığını analiz et:

- Sınava kalan gün: $daysUntilExam gün
- Çözülen test sayısı: $totalTests
- Ortalama başarı oranı: ${averageScore.toStringAsFixed(1)}%
- Test detayları:
${completedTests.map((t) => '  * ${t.title}: ${t.score?.toStringAsFixed(1)}%').join('\n')}

Lütfen öğrenciye:
1. Mevcut hazırlık durumu hakkında genel bir değerlendirme
2. Güçlü ve zayıf yönleri
3. Sınava kadar yapılması gerekenler
4. Motivasyon arttırıcı öneriler

Türkçe ve destekleyici bir dille yaz.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Analiz yapılamadı.';
    } catch (e) {
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('429') || errorMessage.contains('quota') || errorMessage.contains('rate limit')) {
        print('❌ AI Kota Aşıldı Hatası (429): $e');
        throw 'AI kota aşıldı. Lütfen daha sonra tekrar deneyin.';
      } else {
        print('❌ Performans analizi sırasında AI hatası: $e');
        throw 'Performans analizi sırasında hata oluştu: $e';
      }
    }
  }

  // Get study recommendations
  Future<String> getStudyRecommendations({
    required String courseName,
    required List<String> weakTopics,
    required int daysUntilExam,
  }) async {
    try {
      final prompt = '''
$courseName dersi için öğrenciye çalışma planı hazırla:

Zayıf olduğu konular:
${weakTopics.map((t) => '- $t').join('\n')}

Sınava kalan gün: $daysUntilExam gün

Lütfen:
1. Günlük çalışma planı öner
2. Her zayıf konu için çalışma stratejisi ver
3. Pratik yapma önerileri sun
4. Motivasyonu yüksek tut

Türkçe ve uygulanabilir öneriler ver.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Öneri oluşturulamadı.';
    } catch (e) {
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('429') || errorMessage.contains('quota') || errorMessage.contains('rate limit')) {
        print('❌ AI Kota Aşıldı Hatası (429): $e');
        throw 'AI kota aşıldı. Lütfen daha sonra tekrar deneyin.';
      } else {
        print('❌ Öneri oluşturulurken AI hatası: $e');
        throw 'Öneriler oluşturulurken hata oluştu: $e';
      }
    }
  }

  // Kişiselleştirilmiş durum analizi
  Future<String> generatePersonalizedAnalysis({
    required Map<String, double> courseAverages,
    required Map<String, int> courseTestCounts,
    required Map<String, DateTime?> courseExamDates,
    required int totalMaterials,
    Map<String, dynamic>? studentProfile, // Yeni: Öğrenci profil bilgileri
  }) async {
    try {
      // En yakın sınavı bul
      DateTime? closestExam;
      String? closestExamCourse;
      for (var entry in courseExamDates.entries) {
        if (entry.value != null) {
          if (closestExam == null || entry.value!.isBefore(closestExam)) {
            closestExam = entry.value;
            closestExamCourse = entry.key;
          }
        }
      }

      // Zayıf dersler (<%60)
      final weakCourses = courseAverages.entries
          .where((e) => e.value < 60 && e.value > 0)
          .map((e) => '${e.key} (%${e.value.toStringAsFixed(0)})')
          .toList();

      // Güçlü dersler (>%70)
      final strongCourses = courseAverages.entries
          .where((e) => e.value >= 70)
          .map((e) => '${e.key} (%${e.value.toStringAsFixed(0)})')
          .toList();

      final daysUntilExam = closestExam != null 
          ? closestExam.difference(DateTime.now()).inDays 
          : 30;

      // Profil bilgilerini al
      final grade = studentProfile?['grade'];
      final schoolName = studentProfile?['schoolName'] ?? '';
      final learningStyle = studentProfile?['learningStyle'] ?? '';
      final studyGoals = studentProfile?['studyGoals'] ?? '';
      final notes = studentProfile?['notes'] ?? '';
      final favoriteCourses = studentProfile?['favoriteCourses'] != null
          ? List<String>.from(studentProfile!['favoriteCourses'])
          : <String>[];
      final difficultCourses = studentProfile?['difficultCourses'] != null
          ? List<String>.from(studentProfile!['difficultCourses'])
          : <String>[];

      // Profil bilgisi var mı?
      final hasProfileInfo = grade != null || 
          favoriteCourses.isNotEmpty || 
          difficultCourses.isNotEmpty ||
          learningStyle.isNotEmpty;

      final prompt = '''
Sen bir yapay zeka öğretmensin. Öğrencinin GERÇEK durumunu analiz edip KENDİNİ TANITARAK kişiselleştirilmiş öneriler vereceksin:

📊 ÖĞRENCİNİN GERÇEK BİLGİLERİ:
${grade != null ? '- Sınıf: $grade. Sınıf' : ''}
${schoolName.isNotEmpty ? '- Okul: $schoolName' : ''}
${learningStyle.isNotEmpty ? '- Öğrenme Stili: $learningStyle' : ''}
${studyGoals.isNotEmpty ? '- Hedefleri: $studyGoals' : ''}
${notes.isNotEmpty ? '- Ek Notlar: $notes' : ''}
${favoriteCourses.isNotEmpty ? '- Sevdiği Dersler: ${favoriteCourses.join(', ')}' : ''}
${difficultCourses.isNotEmpty ? '- Zorlandığı Dersler: ${difficultCourses.join(', ')}' : ''}

📊 DERS PERFORMANSI:
- Toplam ${courseAverages.length} ders takip ediliyor
- $totalMaterials materyal yüklendi
- En yakın sınav: ${closestExamCourse ?? 'Belirtilmemiş'} (${daysUntilExam} gün sonra)
- Test Sonuçlarına Göre Güçlü: ${strongCourses.isEmpty ? 'Henüz yok' : strongCourses.join(', ')}
- Test Sonuçlarına Göre Zayıf: ${weakCourses.isEmpty ? 'Henüz yok' : weakCourses.join(', ')}

${!hasProfileInfo ? '⚠️ NOT: Öğrenci henüz profil bilgilerini doldurmamış! Ona Profil > Hesap Bilgileri kısmını doldurmasını önermeni unutma!' : ''}

🎯 GÖREVİN:
Aşağıdaki formatta, KENDİNİ ÖN PLANA ÇIKARAN bir analiz yap:

👋 MERHABA!
[Kendini tanıt! "Ben senin yapay zeka öğretmenim" de. Öğrencinin durumunu özetle. 2-3 cümle]

🤖 BEN SANA NASIL YARDIMCI OLABİLİRİM:
• Okulda gördüğün ders notlarını, ödevlerini, fotoğraflarını bana yükle
• Ben senin çalışma tarzını analiz ederim
• Sana özel sorular hazırlarım
• Cevaplarına göre konuları tekrar anlatırım
• Eksik olduğun konularda seni desteklerim
${learningStyle.isNotEmpty ? '• Senin öğrenme stiline uygun ($learningStyle) içerikler hazırlarım' : ''}
[3-5 madde, "ben", "sana", "senin için" kelimelerini kullan]

${!hasProfileInfo ? '''
🎯 İLK ÖNCE:
Profil > Hesap Bilgileri kısmından:
• Hangi sınıfta olduğunu
• Sevdiğin ve zorlandığın dersleri
• Öğrenme stilini (görsel/işitsel/okuma-yazma/kinestetik)
• Hedeflerini
Bana söyle! Böylece sana DAHA KİŞİSEL öneriler sunabilirim!
''' : ''}

⏰ SINAV DURUMUN:
[Sınava kaç gün kaldı? Acil mi? Hangi tempoda çalışmalı? "Seninle birlikte..." şeklinde yaz. 2-3 cümle]

📚 ÖNCE BUNLARA ODAKLAN:
[Hangi derslere öncelik? ÖĞRENCİNİN ZORLANDIĞI DERSLER ve TEST SONUÇLARINA GÖRE ZAYIF OLDUĞU DERSLERİ dikkate al!
"Bana şu dersten materyal yükle..." şeklinde direktif ver. 3 madde]

💡 BUGÜN BENİMLE NE YAPALIM:
[Somut eylem planı. ${learningStyle.isNotEmpty ? 'Öğrenme stiline ($learningStyle) uygun öneriler ver!' : ''}
"Şimdi git ve...", "Sonra bana yükle...", "Ben sana test hazırlayacağım" gibi. 3 madde]

🎯 BU HAFTA PLANIN (BENİM YARDIMIMla):
[Bir haftalık plan. ${studyGoals.isNotEmpty ? 'Hedeflerini ($studyGoals) dikkate al!' : ''}
"Her gün bana X materyal yükle", "Her gün benim hazırladığım Y test çöz" gibi. 2-3 madde]

💪 MOTİVASYON:
[Kısa, güçlü mesaj. ${studyGoals.isNotEmpty ? 'Hedefine atıfta bulun!' : ''} "Ben yanındayım", "Birlikte başaracağız" tarzında]

ÖNEMLİ: 
- KENDİNİ sürekli hatırlat! "Ben", "Bana", "Benimle", "Benim için" kelimelerini kullan!
- Direktif ver: "Yükle", "Çöz", "Bana göster" gibi
- SPESIFIK ders isimleri ve sayılar kullan!
- ÖĞRENCİNİN GERÇEK profil bilgilerini (sevdiği/zorlandığı dersler, öğrenme stili, hedefler) mutlaka kullan!
- Öğrenciyle direkt konuş, samimi ol!
Türkçe yaz, emojiler kullan.
''';

      final response = await _model.generateContent([Content.text(prompt)]).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw 'Timeout',
      );

      return response.text ?? 'Kişiselleştirilmiş analiz yapılamadı.';
    } catch (e) {
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('429') || errorMessage.contains('quota') || errorMessage.contains('rate limit')) {
        print('❌ AI Kota Aşıldı Hatası (429): $e');
        throw 'AI kota aşıldı. Lütfen daha sonra tekrar deneyin.';
      } else {
        print('❌ Kişiselleştirilmiş AI analizi hatası: $e');
        rethrow;
      }
    }
  }
}

