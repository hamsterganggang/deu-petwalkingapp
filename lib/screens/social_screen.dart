import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_data.dart';
import '../providers/walk_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/social_provider.dart';
import '../models/walk_model.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'user_search_screen.dart';
import 'package:share_plus/share_plus.dart';

/// Social Screen - Instagram-style feed
class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPublicWalks();
    });
  }

  void _loadPublicWalks() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final walkProvider = Provider.of<WalkProvider>(context, listen: false);
    final socialProvider = Provider.of<SocialProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      // 차단된 사용자 목록 가져오기
      socialProvider.getBlockedIds(authProvider.user!.uid).then((blockedIds) {
        // 공개 산책 목록 로드 (차단된 사용자 제외)
        walkProvider.loadPublicWalks(excludeUserIds: blockedIds);
        
        // 좋아요 상태 확인
        Future.delayed(const Duration(seconds: 1), () {
          final publicWalks = walkProvider.walks;
          for (var walk in publicWalks) {
            socialProvider.checkLikeStatus(walk.walkId, authProvider.user!.uid);
          }
        });
      });
    }
  }

  void _shareWalk(WalkModel walk) async {
    try {
      final distanceText = walk.distance != null
          ? (walk.distance! >= 1.0
              ? '${walk.distance!.toStringAsFixed(2)}km'
              : '${(walk.distance! * 1000).toStringAsFixed(0)}m')
          : '0m';
      
      final durationText = walk.duration != null ? '${walk.duration}분' : '';
      
      final shareText = '오늘 $distanceText 산책했어요! $durationText ${walk.mood ?? ""} ${walk.memo ?? ""} #반려동물산책 #PetWalk';
      
      await Share.share(shareText);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('공유에 실패했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('소셜'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserSearchScreen(),
                ),
              );
            },
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: Consumer<WalkProvider>(
        builder: (context, walkProvider, _) {
          // 공개된 산책만 필터링
          final publicWalks = walkProvider.walks
              .where((walk) => walk.isPublic)
              .toList();

          if (publicWalks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.explore_outlined,
                    size: 64,
                    color: AppTheme.textBody.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '아직 공유된 산책이 없습니다',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textBody,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: publicWalks.length,
            itemBuilder: (context, index) {
              return _buildWalkCard(publicWalks[index]);
            },
          );
        },
      ),
    );
  }

  /// Build Walk Card (Instagram-style)
  Widget _buildWalkCard(WalkModel walk) {
    return FutureBuilder<UserModel?>(
      future: _getUserInfo(walk.userId),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final displayName = user?.nickname ?? '반려인';
        
        return Card(
          elevation: AppTheme.cardElevation,
          shadowColor: AppTheme.cardShadowColor,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header (User Info)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.secondaryMint,
                      backgroundImage: user?.photoUrl != null
                          ? NetworkImage(user!.photoUrl!)
                          : null,
                      child: user?.photoUrl == null
                          ? Icon(
                              Icons.person,
                              color: AppTheme.primaryGreen,
                              size: 20,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                      Text(
                        _formatDate(walk.date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textBody,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Map Thumbnail
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.secondaryMint,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppTheme.cardRadius),
              ),
            ),
            child: Stack(
              children: [
                // Map placeholder (실제로는 지도 위젯을 넣을 수 있음)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.map,
                        size: 48,
                        color: AppTheme.primaryGreen.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 8),
                      if (walk.distance != null)
                        Text(
                          '${walk.distance!.toStringAsFixed(2)} km',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                    ],
                  ),
                ),
                // Route overlay
                if (walk.routePoints.isNotEmpty)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.route,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${walk.routePoints.length} 포인트',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Paperlogy',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Actions (Like, Comment, Share)
          Consumer<SocialProvider>(
            builder: (context, socialProvider, _) {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final isLiked = socialProvider.isLiked(walk.walkId);
              final likeCount = socialProvider.getLikeCount(walk.walkId);
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () async {
                            if (authProvider.user == null) return;
                            
                            if (isLiked) {
                              await socialProvider.unlikeWalk(walk.walkId, authProvider.user!.uid);
                            } else {
                              await socialProvider.likeWalk(walk.walkId, authProvider.user!.uid);
                            }
                          },
                          icon: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : AppTheme.textBody,
                          ),
                        ),
                        if (likeCount > 0)
                          Text(
                            '$likeCount',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        IconButton(
                          onPressed: () {
                            // TODO: 댓글 기능
                          },
                          icon: const Icon(Icons.comment_outlined),
                          color: AppTheme.textBody,
                        ),
                        IconButton(
                          onPressed: () => _shareWalk(walk),
                          icon: const Icon(Icons.share),
                          color: AppTheme.textBody,
                        ),
                        const Spacer(),
                        if (walk.duration != null)
                          Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 16,
                                color: AppTheme.textBody,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${walk.duration}분',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textBody,
                                    ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // Mood and Memo
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (walk.mood != null && walk.mood!.isNotEmpty) ...[
                  Text(
                    walk.mood!,
                    style: const TextStyle(
                      fontSize: 24,
                      fontFamily: 'Paperlogy',
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (walk.memo != null && walk.memo!.isNotEmpty)
                  Text(
                    walk.memo!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
            ],
          ),
        );
      },
    );
  }

  Future<UserModel?> _getUserInfo(String userId) async {
    try {
      final userService = FirebaseUserService();
      return await userService.getUserInfo(userId);
    } catch (e) {
      return null;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}분 전';
      }
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    }
  }
}
