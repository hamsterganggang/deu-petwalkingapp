import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../utils/theme_data.dart';
import '../utils/confirm_dialog.dart';
import '../models/walk_model.dart';
import '../providers/walk_provider.dart';
import '../providers/auth_provider.dart';

/// Walk Edit Screen - 산책 기록 수정 화면
class WalkEditScreen extends StatefulWidget {
  final WalkModel walk;

  const WalkEditScreen({
    super.key,
    required this.walk,
  });

  @override
  State<WalkEditScreen> createState() => _WalkEditScreenState();
}

class _WalkEditScreenState extends State<WalkEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _memoController = TextEditingController();
  String? _selectedMood;
  bool _isPublic = true;

  // 기분 옵션
  final List<Map<String, String>> _moods = [
    {'emoji': '😊', 'label': '좋아요'},
    {'emoji': '😄', 'label': '행복해요'},
    {'emoji': '😴', 'label': '피곤해요'},
    {'emoji': '😌', 'label': '평온해요'},
    {'emoji': '🤗', 'label': '활기차요'},
    {'emoji': '😎', 'label': '시원해요'},
  ];

  @override
  void initState() {
    super.initState();
    _memoController.text = widget.walk.memo ?? '';
    _selectedMood = widget.walk.mood;
    _isPublic = widget.walk.isPublic;
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _saveWalk() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await ConfirmDialog.show(
      context: context,
      title: '산책 기록 수정',
      message: '산책 기록을 수정하시겠습니까?',
      confirmText: '수정하기',
    );

    if (!confirmed || !mounted) return;

    final walkProvider = Provider.of<WalkProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다.')),
        );
      }
      return;
    }

    try {
      final updatedWalk = widget.walk.copyWith(
        memo: _memoController.text.isEmpty ? null : _memoController.text,
        mood: _selectedMood,
        isPublic: _isPublic,
      );

      final success = await walkProvider.updateWalk(updatedWalk);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('산책 기록이 수정되었습니다.'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(walkProvider.error ?? '수정에 실패했습니다.'),
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
            content: Text('수정 중 오류가 발생했습니다: $e'),
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
        title: const Text('산책 기록 수정'),
        actions: [
          TextButton(
            onPressed: _saveWalk,
            child: Text(
              '저장',
              style: const TextStyle(
                color: AppTheme.primaryGreen,
                fontFamily: 'Paperlogy',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 산책 정보 요약
              Card(
                elevation: AppTheme.cardElevation,
                shadowColor: AppTheme.cardShadowColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('yyyy년 MM월 dd일').format(widget.walk.date),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (widget.walk.distance != null) ...[
                            Icon(Icons.straighten, size: 16, color: AppTheme.textBody),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.walk.distance!.toStringAsFixed(2)} km',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                          if (widget.walk.duration != null) ...[
                            const SizedBox(width: 16),
                            Icon(Icons.timer, size: 16, color: AppTheme.textBody),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.walk.duration}분',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 기분 선택
              Text(
                '기분',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _moods.map((mood) {
                  final isSelected = _selectedMood == mood['emoji'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMood = isSelected ? null : mood['emoji'];
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryGreen
                            : AppTheme.secondaryMint,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryGreen
                              : AppTheme.primaryGreen.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            mood['emoji']!,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            mood['label']!,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.primaryGreen,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontFamily: 'Paperlogy',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // 메모
              Text(
                '메모',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _memoController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: '산책에 대한 메모를 입력하세요',
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

              const SizedBox(height: 32),

              // 공개 설정
              Card(
                elevation: AppTheme.cardElevation,
                shadowColor: AppTheme.cardShadowColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                ),
                child: SwitchListTile(
                  title: const Text('공개 설정'),
                  subtitle: const Text('다른 사용자에게 산책 기록을 공개합니다'),
                  value: _isPublic,
                  onChanged: (value) {
                    setState(() {
                      _isPublic = value;
                    });
                  },
                  activeThumbColor: AppTheme.primaryGreen,
                  activeTrackColor: AppTheme.primaryGreen.withValues(alpha: 0.5),
                ),
              ),

              const SizedBox(height: 32),

              // 저장 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveWalk,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    '수정하기',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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

