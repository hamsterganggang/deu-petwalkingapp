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
import 'user_profile_screen.dart';
import 'blocked_users_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geolocator/geolocator.dart';

/// Social Screen - Instagram-style feed
class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> with SingleTickerProviderStateMixin {
  Position? _currentPosition;
  bool _isLoadingNearby = false;
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
      if (_tabController.index == 1 && _currentPosition == null) {
        _loadNearbyUsers();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPublicWalks();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('위치를 가져올 수 없습니다: $e')),
        );
      }
    }
  }

  Future<void> _loadNearbyUsers() async {
    if (_currentPosition == null) {
      await _getCurrentLocation();
    }
    
    if (_currentPosition == null) return;

    setState(() {
      _isLoadingNearby = true;
    });

    try {
      final socialProvider = Provider.of<SocialProvider>(context, listen: false);
      await socialProvider.getNearbyUsers(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        1.0, // 1km 반경
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('주변 사용자를 불러오는데 실패했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingNearby = false;
        });
      }
    }
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.textBody,
          indicatorColor: AppTheme.primaryGreen,
          tabs: const [
            Tab(text: '피드'),
            Tab(text: '주변 사용자'),
          ],
        ),
        actions: [
          if (_currentTabIndex == 0) ...[
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BlockedUsersScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.block),
              tooltip: '차단된 사용자',
            ),
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
          ] else if (_currentTabIndex == 1) ...[
            IconButton(
              onPressed: _loadNearbyUsers,
              icon: _isLoadingNearby
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              tooltip: '새로고침',
            ),
          ],
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 피드 탭
          Consumer<WalkProvider>(
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
          // 주변 사용자 탭
          _buildNearbyUsersTab(),
        ],
      ),
    );
  }

  /// Build Nearby Users Tab
  Widget _buildNearbyUsersTab() {
    return Consumer<SocialProvider>(
      builder: (context, socialProvider, _) {
        if (_isLoadingNearby) {
          return const Center(child: CircularProgressIndicator());
        }

        final nearbyUsers = socialProvider.nearbyUsers;

        if (nearbyUsers.isEmpty) {
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
                  '반경 1km 내에 산책 중인 사용자가 없습니다',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textBody,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadNearbyUsers,
                  icon: const Icon(Icons.refresh),
                  label: const Text('새로고침'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: nearbyUsers.length,
          itemBuilder: (context, index) {
            return _buildNearbyUserCard(nearbyUsers[index]);
          },
        );
      },
    );
  }

  /// Build Nearby User Card
  Widget _buildNearbyUserCard(UserModel user) {
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
          backgroundImage: user.photoUrl != null
              ? NetworkImage(user.photoUrl!)
              : null,
          child: user.photoUrl == null
              ? Icon(
                  Icons.person,
                  color: AppTheme.primaryGreen,
                  size: 30,
                )
              : null,
        ),
        title: Text(
          user.nickname ?? '닉네임 없음',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.intro != null && user.intro!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(user.intro!),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 14,
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(width: 4),
                Text(
                  '산책 중',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfileScreen(userId: user.uid),
              ),
            );
          },
          icon: const Icon(Icons.chevron_right),
          color: AppTheme.textBody,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfileScreen(userId: user.uid),
            ),
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
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserProfileScreen(userId: walk.userId),
                            ),
                          );
                        },
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
