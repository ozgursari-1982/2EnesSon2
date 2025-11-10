import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/study_material.dart';

class MaterialDetailScreen extends StatelessWidget {
  final StudyMaterial material;

  const MaterialDetailScreen({super.key, required this.material});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Materyal Detayı')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getIcon(),
                          size: 32,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                material.title,
                                style: Theme.of(context).textTheme.displaySmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(material.uploadedAt),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (material.description != null &&
                        material.description!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Açıklama:',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        material.description!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // AI Analizi
            Text(
              '🤖 AI Analizi',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 12),

            if (material.aiAnalysis == null)
              Card(
                color: Colors.orange.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Analiz Ediliyor...',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[700]!,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Materyal şu anda AI tarafından analiz ediliyor. Bu işlem 10-30 saniye sürebilir.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              _buildAnalysisSection(context),
            const SizedBox(height: 24),

            // Bilgi notu
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]!, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI analizi, yüklediğiniz materyalin içeriğini ve önemli noktalarını özetler. Bu bilgiler test oluşturmak için kullanılır.',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]!),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (material.type) {
      case StudyMaterialType.pdf:
        return Icons.picture_as_pdf;
      case StudyMaterialType.image:
        return Icons.image;
      case StudyMaterialType.note:
        return Icons.note;
      case StudyMaterialType.homework:
        return Icons.assignment;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildAnalysisSection(BuildContext context) {
    if (material.aiAnalysis == null || material.aiAnalysis!.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('AI analizi bekleniyor...'),
        ),
      );
    }

    try {
      final analysisData = json.decode(material.aiAnalysis!);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            context,
            '📚 Belge Tipi',
            analysisData['documentType'] ?? 'Bilinmiyor',
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            context,
            '📖 Ana Konu',
            analysisData['mainTopic'] ?? 'Belirtilmemiş',
          ),
          const SizedBox(height: 12),
          if (analysisData['questions'] != null)
            _buildQuestionsCard(
              context,
              List<dynamic>.from(analysisData['questions']),
            ),
          const SizedBox(height: 12),
          if (analysisData['subTopics'] != null)
            _buildTopicsCard(
              context,
              List<dynamic>.from(analysisData['subTopics']),
            ),
          const SizedBox(height: 12),
          if (analysisData['questions'] != null)
            _buildDifficultyCard(
              context,
              List<dynamic>.from(analysisData['questions']),
            ),
          const SizedBox(height: 12),
          if (analysisData['teacherStyleInsights'] != null)
            _buildTeacherInsightsCard(
              context,
              analysisData['teacherStyleInsights'],
            ),
        ],
      );
    } catch (e) {
      return Card(
        color: Colors.red.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    'Analiz Parse Hatası',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700]!,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Hata: $e', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Ham Analiz:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              SelectableText(
                material.aiAnalysis!,
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildInfoCard(BuildContext context, String title, String value) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(
          Icons.info_outline,
          color: Theme.of(context).primaryColor,
        ),
        title: Text(
          title,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        subtitle: Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionsCard(BuildContext context, List<dynamic> questions) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.quiz, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  '📝 Bulunan Sorular: ${questions.length}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...questions.map((q) {
              final questionNumber = q['questionNumber']?.toString() ?? '?';
              final preview =
                  q['preview']?.toString() ?? 'Soru $questionNumber';
              final type = q['type']?.toString() ?? 'bilinmiyor';
              final difficulty = q['difficulty']?.toString() ?? 'orta';

              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 0,
                ),
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withOpacity(0.1),
                  child: Text(
                    questionNumber,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                title: Text(
                  preview.length > 60
                      ? '${preview.substring(0, 60)}...'
                      : preview,
                  style: TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  '$type • $difficulty',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicsCard(BuildContext context, List<dynamic> subTopics) {
    if (subTopics.isEmpty) return SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.topic, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  '🎯 Konular',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: subTopics.map((topic) {
                return Chip(
                  label: Text(topic.toString(), style: TextStyle(fontSize: 13)),
                  backgroundColor: Colors.green.withOpacity(0.1),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyCard(BuildContext context, List<dynamic> questions) {
    Map<String, int> difficulties = {};
    for (var q in questions) {
      String diff = q['difficulty']?.toString() ?? 'orta';
      difficulties[diff] = (difficulties[diff] ?? 0) + 1;
    }

    if (difficulties.isEmpty) return SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.leaderboard, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  '⚖️ Zorluk Dağılımı',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...difficulties.entries.map((e) {
              MaterialColor color;
              if (e.key.toLowerCase().contains('kolay')) {
                color = Colors.green;
              } else if (e.key.toLowerCase().contains('zor')) {
                color = Colors.red;
              } else {
                color = Colors.orange;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.key.toUpperCase(),
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${e.value}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color[700] ?? color,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherInsightsCard(
    BuildContext context,
    Map<String, dynamic> insights,
  ) {
    return Card(
      elevation: 2,
      color: Colors.blue[50]!,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: Colors.blue[700]!),
                const SizedBox(width: 8),
                Text(
                  '🎓 Öğretmen Stili İçgörüleri',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (insights['emphasizedTopics'] != null) ...[
              Text(
                'Vurgulanan Konular:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                (insights['emphasizedTopics'] as List).join(', '),
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
            ],
            if (insights['preferredQuestionTypes'] != null) ...[
              Text(
                'Tercih Edilen Soru Tipleri:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                (insights['preferredQuestionTypes'] as List).join(', '),
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
            ],
            if (insights['difficultyPreference'] != null) ...[
              Text(
                'Zorluk Tercihi:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                insights['difficultyPreference'].toString(),
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
            ],
            if (insights['additionalNotes'] != null) ...[
              Text(
                'Ek Notlar:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                insights['additionalNotes'].toString(),
                style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
