import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_data.dart';
import '../providers/pet_provider.dart';
import '../models/pet_model.dart';

/// Pet Select Dialog - 반려동물 선택 다이얼로그
class PetSelectDialog extends StatelessWidget {
  const PetSelectDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PetProvider>(
      builder: (context, petProvider, _) {
        final pets = petProvider.pets;

        if (pets.isEmpty) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            ),
            title: const Text('반려동물 없음'),
            content: const Text('먼저 반려동물을 등록해주세요.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          );
        }

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '반려동물 선택',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...pets.map((pet) {
                            return _buildPetItem(context, pet);
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false), // '선택 안함'은 false 반환
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textBody,
                            side: const BorderSide(color: AppTheme.textBody, width: 1),
                          ),
                          child: const Text('선택 안함'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, null), // '취소'는 null 반환
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red, width: 1),
                          ),
                          child: const Text('취소'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPetItem(BuildContext context, PetModel pet) {
    return Card(
      elevation: AppTheme.cardElevation,
      shadowColor: AppTheme.cardShadowColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: AppTheme.secondaryMint,
          backgroundImage: pet.photoUrl != null
              ? NetworkImage(pet.photoUrl!)
              : null,
          child: pet.photoUrl == null
              ? Icon(
                  Icons.pets,
                  color: AppTheme.primaryGreen,
                  size: 30,
                )
              : null,
        ),
        title: Row(
          children: [
            Text(
              pet.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (pet.isPrimary) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: pet.breed != null
            ? Text(
                pet.breed!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textBody,
                    ),
              )
            : null,
        trailing: Icon(
          Icons.chevron_right,
          color: AppTheme.textBody,
        ),
        onTap: () => Navigator.pop(context, pet),
      ),
    );
  }
}

