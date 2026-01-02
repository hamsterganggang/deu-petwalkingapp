import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/confirm_dialog.dart';

/// Storage Service Interface
abstract class StorageService {
  Future<String> uploadUserPhoto(String userId, File imageFile);
  Future<String> uploadPetPhoto(String petId, File imageFile);
  Future<String> uploadWalkPhoto(String walkId, File imageFile);
  Future<void> deletePhoto(String photoUrl);
}

/// Firebase Storage Service
class FirebaseStorageService implements StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Future<String> uploadUserPhoto(String userId, File imageFile) async {
    try {
      ErrorLogger.logSuccess('프로필 사진 업로드 시작: $userId');
      final ref = _storage.ref().child('users/$userId/profile.jpg');
      await ref.putFile(imageFile);
      final url = await ref.getDownloadURL();
      ErrorLogger.logSuccess('프로필 사진 업로드 완료: $url');
      return url;
    } catch (e, stackTrace) {
      ErrorLogger.logFirebaseError('프로필 사진 업로드', e);
      ErrorLogger.logError('uploadUserPhoto', e, stackTrace);
      throw Exception('프로필 사진 업로드에 실패했습니다: $e');
    }
  }

  @override
  Future<String> uploadPetPhoto(String petId, File imageFile) async {
    try {
      ErrorLogger.logSuccess('반려동물 사진 업로드 시작: $petId');
      final ref = _storage.ref().child('pets/$petId/profile.jpg');
      await ref.putFile(imageFile);
      final url = await ref.getDownloadURL();
      ErrorLogger.logSuccess('반려동물 사진 업로드 완료: $url');
      return url;
    } catch (e, stackTrace) {
      ErrorLogger.logFirebaseError('반려동물 사진 업로드', e);
      ErrorLogger.logError('uploadPetPhoto', e, stackTrace);
      throw Exception('반려동물 사진 업로드에 실패했습니다: $e');
    }
  }

  @override
  Future<String> uploadWalkPhoto(String walkId, File imageFile) async {
    try {
      ErrorLogger.logSuccess('산책 사진 업로드 시작: $walkId');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref().child('walks/$walkId/$timestamp.jpg');
      await ref.putFile(imageFile);
      final url = await ref.getDownloadURL();
      ErrorLogger.logSuccess('산책 사진 업로드 완료: $url');
      return url;
    } catch (e, stackTrace) {
      ErrorLogger.logFirebaseError('산책 사진 업로드', e);
      ErrorLogger.logError('uploadWalkPhoto', e, stackTrace);
      throw Exception('산책 사진 업로드에 실패했습니다: $e');
    }
  }

  @override
  Future<void> deletePhoto(String photoUrl) async {
    try {
      ErrorLogger.logSuccess('사진 삭제 시작: $photoUrl');
      final ref = _storage.refFromURL(photoUrl);
      await ref.delete();
      ErrorLogger.logSuccess('사진 삭제 완료');
    } catch (e, stackTrace) {
      ErrorLogger.logFirebaseError('사진 삭제', e);
      ErrorLogger.logError('deletePhoto', e, stackTrace);
      throw Exception('사진 삭제에 실패했습니다: $e');
    }
  }
}

