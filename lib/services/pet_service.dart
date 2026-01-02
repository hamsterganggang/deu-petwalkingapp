import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pet_model.dart';
import '../utils/confirm_dialog.dart';

/// Pet Service Interface
abstract class PetService {
  Future<List<PetModel>> getPets(String ownerId);
  Future<PetModel> createPet(PetModel pet);
  Future<PetModel> updatePet(PetModel pet);
  Future<void> deletePet(String petId);
  Future<void> setPrimaryPet(String petId, String ownerId);
}

/// Firebase Pet Service
class FirebasePetService implements PetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<PetModel>> getPets(String ownerId) async {
    try {
      final snapshot = await _firestore
          .collection('pets')
          .where('ownerId', isEqualTo: ownerId)
          .get();

      final pets = snapshot.docs
          .map((doc) {
            final data = doc.data();
            return PetModel.fromJson({
              'petId': doc.id,
              ...Map<String, dynamic>.from(data),
            });
          })
          .toList();
      
      ErrorLogger.logSuccess('펫 목록 조회 (${pets.length}개)');
      return pets;
    } catch (e, stackTrace) {
      ErrorLogger.logFirebaseError('펫 목록 조회', e);
      ErrorLogger.logError('getPets', e, stackTrace);
      throw Exception('펫 목록을 가져오는데 실패했습니다: $e');
    }
  }

  @override
  Future<PetModel> createPet(PetModel pet) async {
    try {
      ErrorLogger.logSuccess('펫 등록 시작: ${pet.name}');
      final docRef = await _firestore.collection('pets').add(pet.toJson());
      final createdPet = pet.copyWith(petId: docRef.id);
      ErrorLogger.logSuccess('펫 등록 완료: ${createdPet.petId}');
      return createdPet;
    } catch (e, stackTrace) {
      ErrorLogger.logFirebaseError('펫 등록', e);
      ErrorLogger.logError('createPet', e, stackTrace);
      throw Exception('펫 등록에 실패했습니다: $e');
    }
  }

  @override
  Future<PetModel> updatePet(PetModel pet) async {
    try {
      ErrorLogger.logSuccess('펫 수정 시작: ${pet.petId}');
      await _firestore.collection('pets').doc(pet.petId).update(pet.toJson());
      ErrorLogger.logSuccess('펫 수정 완료: ${pet.petId}');
      return pet;
    } catch (e, stackTrace) {
      ErrorLogger.logFirebaseError('펫 수정', e);
      ErrorLogger.logError('updatePet', e, stackTrace);
      throw Exception('펫 수정에 실패했습니다: $e');
    }
  }

  @override
  Future<void> deletePet(String petId) async {
    try {
      ErrorLogger.logSuccess('펫 삭제 시작: $petId');
      await _firestore.collection('pets').doc(petId).delete();
      ErrorLogger.logSuccess('펫 삭제 완료: $petId');
    } catch (e, stackTrace) {
      ErrorLogger.logFirebaseError('펫 삭제', e);
      ErrorLogger.logError('deletePet', e, stackTrace);
      throw Exception('펫 삭제에 실패했습니다: $e');
    }
  }

  @override
  Future<void> setPrimaryPet(String petId, String ownerId) async {
    try {
      // 모든 펫의 isPrimary를 false로 설정
      final snapshot = await _firestore
          .collection('pets')
          .where('ownerId', isEqualTo: ownerId)
          .get();

      // petId와 일치하는 문서 찾기
      final targetDoc = snapshot.docs.firstWhere(
        (doc) => doc.id == petId,
        orElse: () => throw Exception('펫을 찾을 수 없습니다: $petId'),
      );

      final batch = _firestore.batch();
      
      // 모든 펫의 isPrimary를 false로 설정
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isPrimary': false});
      }
      
      // 선택한 펫을 대표로 설정
      batch.update(targetDoc.reference, {'isPrimary': true});
      
      await batch.commit();
      ErrorLogger.logSuccess('대표 펫 설정 완료: $petId');
    } catch (e, stackTrace) {
      ErrorLogger.logFirebaseError('대표 펫 설정', e);
      ErrorLogger.logError('setPrimaryPet', e, stackTrace);
      throw Exception('대표 펫 설정에 실패했습니다: $e');
    }
  }
}

