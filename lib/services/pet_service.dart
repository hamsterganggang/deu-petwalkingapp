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
            // document ID를 petId로 사용 (데이터의 petId 필드는 무시)
            return PetModel.fromJson({
              ...Map<String, dynamic>.from(data),
              'petId': doc.id, // document ID를 우선 사용
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
      
      // petId가 비어있거나 임시 ID인 경우 새로운 ID 생성
      String finalPetId = pet.petId;
      if (finalPetId.isEmpty || finalPetId.startsWith('pet_')) {
        // Firestore가 자동 생성한 ID 사용
        final docRef = await _firestore.collection('pets').add(pet.toJson());
        finalPetId = docRef.id;
      } else {
        // petId를 document ID로 직접 사용
        final petData = pet.toJson();
        petData.remove('petId'); // petId는 document ID이므로 JSON에서 제거
        await _firestore.collection('pets').doc(finalPetId).set(petData);
      }
      
      final createdPet = pet.copyWith(petId: finalPetId);
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
      
      // 문서 존재 여부 확인
      final docRef = _firestore.collection('pets').doc(pet.petId);
      final docSnapshot = await docRef.get();
      
      if (!docSnapshot.exists) {
        throw Exception('펫을 찾을 수 없습니다: ${pet.petId}');
      }
      
      // petId는 document ID이므로 JSON에서 제거
      final petData = pet.toJson();
      petData.remove('petId');
      
      await docRef.update(petData);
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
      
      // 문서 존재 여부 확인
      final docRef = _firestore.collection('pets').doc(petId);
      final docSnapshot = await docRef.get();
      
      if (!docSnapshot.exists) {
        throw Exception('펫을 찾을 수 없습니다: $petId');
      }
      
      // 삭제 실행
      await docRef.delete();
      
      // 삭제 확인 (문서가 실제로 삭제되었는지 확인)
      final verifySnapshot = await docRef.get();
      if (verifySnapshot.exists) {
        throw Exception('펫 삭제에 실패했습니다. 문서가 여전히 존재합니다.');
      }
      
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

      // 빈 리스트 체크
      if (snapshot.docs.isEmpty) {
        throw Exception('펫 목록이 비어있습니다.');
      }

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

