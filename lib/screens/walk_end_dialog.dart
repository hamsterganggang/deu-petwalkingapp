import 'package:flutter/material.dart';
import '../utils/theme_data.dart';

/// Walk End Dialog - 산책 종료 시 메모와 기분 입력
class WalkEndDialog extends StatefulWidget {
  final int duration;
  final double distance;

  const WalkEndDialog({
    super.key,
    required this.duration,
    required this.distance,
  });

  @override
  State<WalkEndDialog> createState() => _WalkEndDialogState();
}

class _WalkEndDialogState extends State<WalkEndDialog> {
  final TextEditingController _memoController = TextEditingController();
  String? _selectedMood;

  // 기분 이모지 옵션
  final List<Map<String, String>> _moodOptions = [
    {'emoji': '😊', 'label': '행복해요'},
    {'emoji': '😄', 'label': '신나요'},
    {'emoji': '😌', 'label': '평온해요'},
    {'emoji': '😴', 'label': '피곤해요'},
    {'emoji': '😎', 'label': '시원해요'},
    {'emoji': '🤗', 'label': '만족해요'},
  ];

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
                '산책 완료!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.timer, size: 16, color: AppTheme.textBody),
                  const SizedBox(width: 4),
                  Text(
                    '${(widget.duration ~/ 60)}분 ${widget.duration % 60}초',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.straighten, size: 16, color: AppTheme.textBody),
                  const SizedBox(width: 4),
                  Text(
                    widget.distance >= 1.0
                        ? '${widget.distance.toStringAsFixed(2)} km'
                        : '${(widget.distance * 1000).toStringAsFixed(0)} m',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // 기분 선택
              Text(
                '오늘 산책 기분은 어땠나요?',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _moodOptions.map((mood) {
                  final isSelected = _selectedMood == mood['emoji'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMood = mood['emoji'];
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.secondaryMint
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryGreen
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            mood['emoji']!,
                            style: const TextStyle(
                              fontSize: 24,
                              fontFamily: 'Paperlogy',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            mood['label']!,
                            style: TextStyle(
                              color: isSelected
                                  ? AppTheme.primaryGreen
                                  : AppTheme.textBody,
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
              const SizedBox(height: 24),
              
              // 메모 입력 (필수)
              TextField(
                controller: _memoController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: '메모 *',
                  hintText: '오늘 산책에 대한 생각을 남겨보세요',
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
              const SizedBox(height: 24),
              
              // 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      // 메모 필수 체크
                      if (_memoController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('메모를 입력해주세요.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      Navigator.pop(context, {
                        'memo': _memoController.text.trim(),
                        'mood': _selectedMood,
                      });
                    },
                    child: const Text('저장'),
                  ),
                ],
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

