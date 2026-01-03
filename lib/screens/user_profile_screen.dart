import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_data.dart';
import '../providers/auth_provider.dart';
import '../providers/walk_provider.dart';
import '../providers/social_provider.dart';
import '../models/user_model.dart';
import '../models/walk_model.dart';
import '../services/user_service.dart';
import 'walk_detail_screen.dart';
import 'follow_list_screen.dart';

/// User Profile Screen - 다른 사용자 프로필 화면
class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userService = FirebaseUserService();
      final user = await userService.getUserInfo(widget.userId);
      
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
        
        // 사용자의 산책 기록 로드
        if (user != null) {
          final walkProvider = Provider.of<WalkProvider>(context, listen: false);
          await walkProvider.loadWalks(widget.userId);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('사용자 정보를 불러오는데 실패했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    final isOwnProfile = currentUser?.uid == widget.userId;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('사용자 프로필'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('사용자 프로필'),
        ),
        body: const Center(
          child: Text('사용자를 찾을 수 없습니다.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_user!.nickname ?? '사용자'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Photo
            CircleAvatar(
              radius: 60,
              backgroundColor: AppTheme.secondaryMint,
              backgroundImage: _user!.photoUrl != null
                  ? NetworkImage(_user!.photoUrl!)
                  : null,
              child: _user!.photoUrl == null
                  ? Icon(
                      Icons.person,
                      size: 60,
                      color: AppTheme.primaryGreen,
                    )
                  : null,
            ),
            const SizedBox(height: 16),

            // Nickname
            Text(
              _user!.nickname ?? '닉네임 없음',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),

            // Intro
            if (_user!.intro != null && _user!.intro!.isNotEmpty)
              Text(
                _user!.intro!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),

            // Follower/Following Stats
            Card(
              elevation: AppTheme.cardElevation,
              shadowColor: AppTheme.cardShadowColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FollowListScreen(
                              userId: widget.userId,
                              isFollowers: true,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Text(
                            '${_user!.followerCount}',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryGreen,
                                ),
                          ),
                          Text(
                            '팔로워',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textBody,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppTheme.secondaryMint,
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FollowListScreen(
                              userId: widget.userId,
                              isFollowers: false,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Text(
                            '${_user!.followingCount}',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryGreen,
                                ),
                          ),
                          Text(
                            '팔로잉',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textBody,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Follow/Unfollow Button (자신의 프로필이 아닌 경우)
            if (!isOwnProfile && currentUser != null)
              Consumer<SocialProvider>(
                builder: (context, socialProvider, _) {
                  final isFollowing = socialProvider.isFollowing(widget.userId);
                  
                  // 팔로우 상태 확인
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    socialProvider.checkFollowingStatus(currentUser.uid, widget.userId);
                  });

                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final success = isFollowing
                            ? await socialProvider.unfollowUser(currentUser.uid, widget.userId)
                            : await socialProvider.followUser(currentUser.uid, widget.userId);
                        
                        if (mounted) {
                          if (success) {
                            // 사용자 정보 새로고침
                            await authProvider.loadUserInfo();
                            await _loadUserData();
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isFollowing ? '언팔로우 되었습니다.' : '팔로우 되었습니다.'),
                                backgroundColor: AppTheme.primaryGreen,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFollowing
                            ? Colors.grey.shade300
                            : AppTheme.primaryGreen,
                        foregroundColor: isFollowing ? AppTheme.textBody : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(isFollowing ? '언팔로우' : '팔로우'),
                    ),
                  );
                },
              ),

            const SizedBox(height: 32),

            // 산책 기록
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '산책 기록',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Consumer<WalkProvider>(
              builder: (context, walkProvider, _) {
                final userWalks = walkProvider.walks
                    .where((walk) => walk.userId == widget.userId && walk.isPublic)
                    .toList();

                if (userWalks.isEmpty) {
                  return Card(
                    elevation: AppTheme.cardElevation,
                    shadowColor: AppTheme.cardShadowColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.directions_walk,
                            size: 48,
                            color: AppTheme.textBody.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '공개된 산책 기록이 없습니다',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppTheme.textBody,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: userWalks.length,
                  itemBuilder: (context, index) {
                    return _buildWalkItem(userWalks[index]);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalkItem(WalkModel walk) {
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
          child: Icon(
            Icons.directions_walk,
            color: AppTheme.primaryGreen,
          ),
        ),
        title: Text(
          _formatDate(walk.date),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                if (walk.distance != null) ...[
                  Icon(Icons.straighten, size: 16, color: AppTheme.textBody),
                  const SizedBox(width: 4),
                  Text(
                    '${walk.distance!.toStringAsFixed(2)} km',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (walk.duration != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.timer, size: 16, color: AppTheme.textBody),
                  const SizedBox(width: 4),
                  Text(
                    '${walk.duration}분',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
            if (walk.memo != null && walk.memo!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                walk.memo!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textBody,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppTheme.textBody,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WalkDetailScreen(walk: walk),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}

