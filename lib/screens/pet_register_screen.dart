import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/theme_data.dart';
import '../utils/confirm_dialog.dart';
import '../providers/pet_provider.dart';
import '../providers/auth_provider.dart';
import '../models/pet_model.dart';
import '../services/storage_service.dart';

/// Pet Registration Screen
class PetRegisterScreen extends StatefulWidget {
  const PetRegisterScreen({super.key, this.pet});

  final PetModel? pet;

  @override
  State<PetRegisterScreen> createState() => _PetRegisterScreenState();
}

class _PetRegisterScreenState extends State<PetRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  
  String? _gender;
  DateTime? _birthDate;
  double? _weight;
  bool? _isNeutered;
  bool _isPrimary = false;
  File? _selectedImage;
  String? _photoUrl;
  final ImagePicker _imagePicker = ImagePicker();
  final StorageService _storageService = FirebaseStorageService();

  @override
  void initState() {
    super.initState();
    if (widget.pet != null) {
      _nameController.text = widget.pet!.name;
      _breedController.text = widget.pet!.breed ?? '';
      _gender = widget.pet!.gender;
      _birthDate = widget.pet!.birthDate;
      _weight = widget.pet!.weight;
      _isNeutered = widget.pet!.isNeutered;
      _isPrimary = widget.pet!.isPrimary;
      _photoUrl = widget.pet!.photoUrl;
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 선택에 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사진 촬영에 실패했습니다: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _selectWeight() async {
    final result = await showDialog<double>(
      context: context,
      builder: (context) {
        double weight = _weight ?? 5.0;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('체중 입력'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${weight.toStringAsFixed(1)} kg'),
                Slider(
                  value: weight,
                  min: 0.1,
                  max: 100.0,
                  divisions: 990,
                  label: '${weight.toStringAsFixed(1)} kg',
                  onChanged: (value) {
                    setState(() {
                      weight = value;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, weight),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      },
    );
    if (result != null) {
      setState(() {
        _weight = result;
      });
    }
  }

  Future<void> _savePet() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final petProvider = Provider.of<PetProvider>(context, listen: false);

    if (authProvider.user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다.')),
        );
      }
      return;
    }

    // 확인 모달 표시
    final isEdit = widget.pet != null;
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: isEdit ? '반려동물 수정' : '반려동물 등록',
      message: isEdit
          ? '${_nameController.text}의 정보를 수정하시겠습니까?'
          : '${_nameController.text}을(를) 등록하시겠습니까?',
      confirmText: isEdit ? '수정하기' : '등록하기',
    );

    if (!confirmed || !mounted) return;

    String? finalPhotoUrl = _photoUrl;
    
    // 사진 업로드
    if (_selectedImage != null) {
      try {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('사진을 업로드하는 중...')),
          );
        }
        final petId = widget.pet?.petId ?? 'pet_${DateTime.now().millisecondsSinceEpoch}';
        finalPhotoUrl = await _storageService.uploadPetPhoto(petId, _selectedImage!);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('사진 업로드에 실패했습니다: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }
    }

    final pet = PetModel(
      petId: widget.pet?.petId ?? 'pet_${DateTime.now().millisecondsSinceEpoch}',
      ownerId: authProvider.user!.uid,
      name: _nameController.text,
      breed: _breedController.text.isEmpty ? null : _breedController.text,
      gender: _gender,
      birthDate: _birthDate,
      weight: _weight,
      photoUrl: finalPhotoUrl,
      isNeutered: _isNeutered,
      isPrimary: _isPrimary,
    );

    try {
      final success = widget.pet != null
          ? await petProvider.updatePet(pet)
          : await petProvider.createPet(pet);

      if (!mounted) return;
      
      if (success) {
        if (_isPrimary) {
          await petProvider.setPrimaryPet(pet.petId, pet.ownerId);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.pet != null ? '반려동물 정보가 수정되었습니다.' : '반려동물이 등록되었습니다.'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(petProvider.error ?? '오류가 발생했습니다.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pet != null ? '반려동물 수정' : '반려동물 등록'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Photo
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppTheme.secondaryMint,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : (_photoUrl != null ? NetworkImage(_photoUrl!) : null) as ImageProvider?,
                      child: (_selectedImage == null && _photoUrl == null)
                          ? Icon(
                              Icons.pets,
                              size: 60,
                              color: AppTheme.primaryGreen,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.primaryGreen,
                        child: PopupMenuButton<String>(
                          icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          onSelected: (value) {
                            if (value == 'gallery') {
                              _pickImage();
                            } else if (value == 'camera') {
                              _takePhoto();
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'gallery',
                              child: Row(
                                children: [
                                  Icon(Icons.photo_library),
                                  SizedBox(width: 8),
                                  Text('갤러리에서 선택'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'camera',
                              child: Row(
                                children: [
                                  Icon(Icons.camera_alt),
                                  SizedBox(width: 8),
                                  Text('사진 촬영'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '이름 *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryGreen,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이름을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Breed
              TextFormField(
                controller: _breedController,
                decoration: InputDecoration(
                  labelText: '품종',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryGreen,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Gender
              Text(
                '성별',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Radio<String>(
                      value: 'male',
                      groupValue: _gender,
                      onChanged: (value) {
                        setState(() {
                          _gender = value;
                        });
                      },
                      activeColor: AppTheme.primaryGreen,
                    ),
                  ),
                  const Text('수컷'),
                  Expanded(
                    child: Radio<String>(
                      value: 'female',
                      groupValue: _gender,
                      onChanged: (value) {
                        setState(() {
                          _gender = value;
                        });
                      },
                      activeColor: AppTheme.primaryGreen,
                    ),
                  ),
                  const Text('암컷'),
                ],
              ),
              const SizedBox(height: 16),

              // Birth Date
              ListTile(
                title: const Text('생년월일'),
                subtitle: Text(
                  _birthDate != null
                      ? DateFormat('yyyy.MM.dd').format(_birthDate!)
                      : '선택 안 함',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDate,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(height: 16),

              // Weight
              ListTile(
                title: const Text('체중'),
                subtitle: Text(
                  _weight != null
                      ? '${_weight!.toStringAsFixed(1)} kg'
                      : '선택 안 함',
                ),
                trailing: const Icon(Icons.monitor_weight),
                onTap: _selectWeight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(height: 16),

              // Primary Pet
              SwitchListTile(
                title: const Text('대표 반려동물로 설정'),
                subtitle: const Text('홈 화면에 표시됩니다'),
                value: _isPrimary,
                onChanged: (value) {
                  setState(() {
                    _isPrimary = value;
                  });
                },
                activeThumbColor: AppTheme.primaryGreen,
                activeTrackColor: AppTheme.primaryGreen.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _savePet,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    widget.pet != null ? '수정하기' : '등록하기',
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Paperlogy',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

