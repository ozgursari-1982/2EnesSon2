import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  // Upload study material file (works on both mobile and web)
  Future<String> uploadStudyMaterial(dynamic file, String studentId, String courseId) async {
    try {
      String fileName;
      UploadTask uploadTask;
      final String path;
      
      if (kIsWeb) {
        // Web platform
        if (file is PlatformFile) {
          fileName = '${_uuid.v4()}_${file.name}';
          path = 'students/$studentId/courses/$courseId/materials/$fileName';
          final Reference ref = _storage.ref().child(path);
          uploadTask = ref.putData(
            file.bytes!,
            SettableMetadata(contentType: file.extension == 'pdf' 
              ? 'application/pdf' 
              : 'image/${file.extension ?? 'jpeg'}'),
          );
        } else {
          throw 'Web platformunda PlatformFile bekleniyor';
        }
      } else {
        // Mobile platform
        if (file is File) {
          fileName = '${_uuid.v4()}_${file.path.split('/').last}';
          path = 'students/$studentId/courses/$courseId/materials/$fileName';
          final Reference ref = _storage.ref().child(path);
          uploadTask = ref.putFile(file);
        } else {
          throw 'Mobil platformda File bekleniyor';
        }
      }
      
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw 'Dosya yüklenirken hata oluştu: $e';
    }
  }

  // Delete file
  Future<void> deleteFile(String fileUrl) async {
    try {
      final Reference ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      throw 'Dosya silinirken hata oluştu: $e';
    }
  }

  // Get file metadata
  Future<FullMetadata> getFileMetadata(String fileUrl) async {
    try {
      final Reference ref = _storage.refFromURL(fileUrl);
      return await ref.getMetadata();
    } catch (e) {
      throw 'Dosya bilgisi alınırken hata oluştu: $e';
    }
  }
}

