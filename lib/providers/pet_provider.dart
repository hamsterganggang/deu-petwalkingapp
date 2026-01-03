import 'package:flutter/foundation.dart';
import '../models/pet_model.dart';
import '../services/pet_service.dart';
import '../utils/confirm_dialog.dart';

/// Mock Pet Service
class MockPetService implements PetService {
  final List<PetModel> _pets = [];

  @override
  Future<List<PetModel>> getPets(String ownerId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _pets.where((pet) => pet.ownerId == ownerId).toList();
  }

  @override
  Future<PetModel> createPet(PetModel pet) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _pets.add(pet);
    return pet;
  }

  @override
  Future<PetModel> updatePet(PetModel pet) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _pets.indexWhere((p) => p.petId == pet.petId);
    if (index != -1) {
      _pets[index] = pet;
    }
    return pet;
  }

  @override
  Future<void> deletePet(String petId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _pets.removeWhere((pet) => pet.petId == petId);
  }

  @override
  Future<void> setPrimaryPet(String petId, String ownerId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    for (var pet in _pets) {
      if (pet.ownerId == ownerId) {
        final index = _pets.indexOf(pet);
        _pets[index] = pet.copyWith(
          isPrimary: pet.petId == petId,
        );
      }
    }
  }
}

/// Pet Provider (ViewModel)
class PetProvider with ChangeNotifier {
  final PetService _petService;
  List<PetModel> _pets = [];
  PetModel? _primaryPet;
  bool _isLoading = false;
  String? _error;

  PetProvider(this._petService);

  List<PetModel> get pets => _pets;
  PetModel? get primaryPet => _primaryPet;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load pets for owner
  Future<void> loadPets(String ownerId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _pets = await _petService.getPets(ownerId);
      _primaryPet = _pets.firstWhere(
        (pet) => pet.isPrimary,
        orElse: () => _pets.isNotEmpty ? _pets.first : throw StateError('No pets'),
      );

      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      ErrorLogger.logError('loadPets', e, stackTrace);
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create new pet
  Future<bool> createPet(PetModel pet) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final createdPet = await _petService.createPet(pet);
      _pets.add(createdPet);

      // 첫 번째 펫이고 isPrimary가 false일 때만 자동으로 대표 펫으로 설정
      // (사용자가 명시적으로 대표로 설정한 경우는 화면에서 처리)
      if (_pets.length == 1 && !pet.isPrimary) {
        await setPrimaryPet(createdPet.petId, createdPet.ownerId);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      ErrorLogger.logError('createPet', e, stackTrace);
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update pet
  Future<bool> updatePet(PetModel pet) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updatedPet = await _petService.updatePet(pet);
      final index = _pets.indexWhere((p) => p.petId == pet.petId);
      if (index != -1) {
        _pets[index] = updatedPet;
      }

      // 대표 펫 업데이트
      if (updatedPet.isPrimary) {
        _primaryPet = updatedPet;
      } else if (_primaryPet?.petId == updatedPet.petId) {
        _primaryPet = null;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      ErrorLogger.logError('createPet', e, stackTrace);
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete pet
  Future<bool> deletePet(String petId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _petService.deletePet(petId);
      _pets.removeWhere((pet) => pet.petId == petId);

      // 삭제된 펫이 대표 펫이었다면 첫 번째 펫을 대표로 설정
      if (_primaryPet?.petId == petId) {
        if (_pets.isNotEmpty) {
          await setPrimaryPet(_pets.first.petId, _pets.first.ownerId);
        } else {
          _primaryPet = null;
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      ErrorLogger.logError('createPet', e, stackTrace);
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Set primary pet
  Future<bool> setPrimaryPet(String petId, String ownerId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _petService.setPrimaryPet(petId, ownerId);

      // 모든 펫의 isPrimary 업데이트
      _pets = _pets.map((pet) {
        return pet.copyWith(
          isPrimary: pet.petId == petId,
        );
      }).toList();

      // 대표 펫 찾기
      try {
        _primaryPet = _pets.firstWhere(
          (pet) => pet.petId == petId,
        );
      } catch (e) {
        _primaryPet = null;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      ErrorLogger.logError('setPrimaryPet', e, stackTrace);
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

