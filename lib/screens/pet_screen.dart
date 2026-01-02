import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_data.dart';
import '../utils/confirm_dialog.dart';
import '../providers/pet_provider.dart';
import '../providers/auth_provider.dart';
import '../models/pet_model.dart';
import 'pet_register_screen.dart';

/// Pet Management Screen
class PetScreen extends StatefulWidget {
  const PetScreen({super.key});

  @override
  State<PetScreen> createState() => _PetScreenState();
}

class _PetScreenState extends State<PetScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPets();
    });
  }

  void _loadPets() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final petProvider = Provider.of<PetProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      petProvider.loadPets(authProvider.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('반려동물'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PetRegisterScreen(),
                ),
              ).then((_) => _loadPets());
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Consumer<PetProvider>(
        builder: (context, petProvider, _) {
          if (petProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (petProvider.pets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pets,
                    size: 64,
                    color: AppTheme.textBody.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '등록된 반려동물이 없습니다',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textBody,
                        ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PetRegisterScreen(),
                        ),
                      ).then((_) => _loadPets());
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('반려동물 등록하기'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: petProvider.pets.length,
            itemBuilder: (context, index) {
              final pet = petProvider.pets[index];
              return _buildPetCard(pet, petProvider);
            },
          );
        },
      ),
    );
  }

  Widget _buildPetCard(PetModel pet, PetProvider petProvider) {
    return Card(
      elevation: AppTheme.cardElevation,
      shadowColor: AppTheme.cardShadowColor,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 35,
          backgroundColor: AppTheme.secondaryMint,
          backgroundImage: pet.photoUrl != null
              ? NetworkImage(pet.photoUrl!)
              : null,
          child: pet.photoUrl == null
              ? Icon(
                  Icons.pets,
                  size: 35,
                  color: AppTheme.primaryGreen,
                )
              : null,
        ),
        title: Row(
          children: [
            Text(
              pet.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (pet.isPrimary) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '대표',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Paperlogy',
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            if (pet.breed != null)
              Text(
                '품종: ${pet.breed}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            if (pet.gender != null)
              Text(
                '성별: ${pet.gender == 'male' ? '수컷' : pet.gender == 'female' ? '암컷' : '알 수 없음'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            if (pet.weight != null)
              Text(
                '체중: ${pet.weight!.toStringAsFixed(1)} kg',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            if (pet.birthDate != null)
              Text(
                '생년월일: ${_formatDate(pet.birthDate!)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            if (pet.isNeutered != null)
              Text(
                '중성화: ${pet.isNeutered! ? "완료" : "미완료"}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text('대표로 설정'),
              onTap: () async {
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                await Future.delayed(
                  const Duration(milliseconds: 100),
                );
                if (navigator.mounted) {
                  final success = await petProvider.setPrimaryPet(pet.petId, pet.ownerId);
                  if (navigator.mounted) {
                    if (success) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('대표 반려동물로 설정되었습니다.'),
                          backgroundColor: AppTheme.primaryGreen,
                        ),
                      );
                    } else {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(petProvider.error ?? '설정에 실패했습니다.'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  }
                }
              },
            ),
            PopupMenuItem(
              child: const Text('수정'),
              onTap: () {
                final navigator = Navigator.of(context);
                Future.delayed(
                  const Duration(milliseconds: 100),
                  () {
                    if (navigator.mounted) {
                      navigator.push(
                        MaterialPageRoute(
                          builder: (context) => PetRegisterScreen(pet: pet),
                        ),
                      ).then((_) {
                        if (navigator.mounted) {
                          _loadPets();
                        }
                      });
                    }
                  },
                );
              },
            ),
            PopupMenuItem(
              child: const Text(
                '삭제',
                style: TextStyle(
                  color: Colors.red,
                  fontFamily: 'Paperlogy',
                ),
              ),
              onTap: () {
                Future.delayed(
                  const Duration(milliseconds: 100),
                  () {
                    _showDeleteDialog(pet, petProvider);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(PetModel pet, PetProvider petProvider) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: '반려동물 삭제',
      message: '${pet.name}을(를) 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
      confirmText: '삭제',
      isDestructive: true,
    );

    if (!confirmed || !mounted) return;

    try {
      final success = await petProvider.deletePet(pet.petId);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('반려동물이 삭제되었습니다.'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(petProvider.error ?? '삭제에 실패했습니다.'),
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
            content: Text('삭제 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}

