import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../utils/theme_data.dart';
import '../utils/confirm_dialog.dart';
import '../models/walk_model.dart';
import '../providers/walk_provider.dart';
import '../providers/auth_provider.dart';
import 'walk_edit_screen.dart';

/// Walk Detail Screen - 산책 상세 화면
class WalkDetailScreen extends StatelessWidget {
  final WalkModel walk;

  const WalkDetailScreen({
    super.key,
    required this.walk,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isOwner = authProvider.user?.uid == walk.userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('산책 상세'),
        actions: [
          if (isOwner) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                final navigator = Navigator.of(context);
                final walkProvider = Provider.of<WalkProvider>(context, listen: false);
                navigator.push(
                  MaterialPageRoute(
                    builder: (context) => WalkEditScreen(walk: walk),
                  ),
                ).then((_) {
                  // 수정 후 목록 새로고침
                  if (navigator.mounted && authProvider.user != null) {
                    walkProvider.loadWalks(authProvider.user!.uid);
                  }
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteDialog(context, walk),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 및 시간
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
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: AppTheme.primaryGreen),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('yyyy년 MM월 dd일').format(walk.date),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.play_circle_outline, color: AppTheme.textBody, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '시작: ${DateFormat('HH:mm').format(walk.startTime)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    if (walk.endTime != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.stop_circle_outlined, color: AppTheme.textBody, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '종료: ${DateFormat('HH:mm').format(walk.endTime!)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 거리 및 시간
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.straighten,
                    label: '거리',
                    value: walk.distance != null
                        ? (walk.distance! >= 1.0
                            ? '${walk.distance!.toStringAsFixed(2)} km'
                            : '${(walk.distance! * 1000).toStringAsFixed(0)} m')
                        : '0 m',
                    context: context,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.timer,
                    label: '시간',
                    value: walk.duration != null
                        ? '${walk.duration}분'
                        : '0분',
                    context: context,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 지도 (경로가 있는 경우)
            if (walk.routePoints.isNotEmpty)
              Card(
                elevation: AppTheme.cardElevation,
                shadowColor: AppTheme.cardShadowColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  child: SizedBox(
                    height: 300,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(
                          walk.routePoints.first.latitude,
                          walk.routePoints.first.longitude,
                        ),
                        initialZoom: 15.0,
                        minZoom: 10.0,
                        maxZoom: 19.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.deupetwalk.app',
                        ),
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: walk.routePoints
                                  .map((point) => LatLng(point.latitude, point.longitude))
                                  .toList(),
                              strokeWidth: 5.0,
                              color: AppTheme.primaryGreen,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // 기분 및 메모
            if (walk.mood != null || walk.memo != null)
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
                      if (walk.mood != null && walk.mood!.isNotEmpty) ...[
                        Text(
                          walk.mood!,
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (walk.memo != null && walk.memo!.isNotEmpty)
                        Text(
                          walk.memo!,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // 사진
            if (walk.photoUrls.isNotEmpty) ...[
              Text(
                '사진',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: walk.photoUrls.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                        child: Image.network(
                          walk.photoUrls[index],
                          width: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 200,
                              color: AppTheme.secondaryMint,
                              child: Icon(
                                Icons.broken_image,
                                color: AppTheme.textBody,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required BuildContext context,
  }) {
    return Card(
      elevation: AppTheme.cardElevation,
      shadowColor: AppTheme.cardShadowColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryGreen, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textBody,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WalkModel walk) {
    final walkProvider = Provider.of<WalkProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        ),
        title: const Text('산책 기록 삭제'),
        content: const Text('이 산책 기록을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              
              final confirmed = await ConfirmDialog.show(
                context: context,
                title: '산책 기록 삭제',
                message: '정말 삭제하시겠습니까?',
                confirmText: '삭제',
                isDestructive: true,
              );
              
              if (!confirmed || !context.mounted) return;
              
              try {
                final success = await walkProvider.deleteWalk(walk.walkId);
                if (context.mounted) {
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  
                  if (success) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('산책 기록이 삭제되었습니다.'),
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    );
                    navigator.pop(context);
                  } else {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(walkProvider.error ?? '삭제에 실패했습니다.'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('삭제 중 오류가 발생했습니다: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}

