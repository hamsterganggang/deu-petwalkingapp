import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_data.dart';
import '../utils/confirm_dialog.dart';
import '../providers/social_provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

/// Follow List Screen - 팔로워/팔로잉 목록
class FollowListScreen extends StatefulWidget {
  final String userId;
  final bool isFollowers; // true: 팔로워, false: 팔로잉

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.isFollowers,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadList();
    });
  }

  void _loadList() {
    final socialProvider = Provider.of<SocialProvider>(context, listen: false);
    if (widget.isFollowers) {
      socialProvider.loadFollowers(widget.userId);
    } else {
      socialProvider.loadFollowing(widget.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFollowers ? '팔로워' : '팔로잉'),
      ),
      body: Consumer<SocialProvider>(
        builder: (context, socialProvider, _) {
          if (socialProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = widget.isFollowers
              ? socialProvider.followers
              : socialProvider.following;

          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: AppTheme.textBody.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.isFollowers
                        ? '팔로워가 없습니다'
                        : '팔로우한 사용자가 없습니다',
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
            itemCount: users.length,
            itemBuilder: (context, index) {
              return _buildUserCard(users[index], socialProvider);
            },
          );
        },
      ),
    );
  }

  Widget _buildUserCard(UserModel user, SocialProvider socialProvider) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;

    if (currentUser == null || currentUser.uid == user.uid) {
      return const SizedBox.shrink();
    }

    // 팔로우 상태 확인
    WidgetsBinding.instance.addPostFrameCallback((_) {
      socialProvider.checkFollowingStatus(currentUser.uid, user.uid);
    });

    final isFollowing = socialProvider.isFollowing(user.uid);

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
        subtitle: user.intro != null && user.intro!.isNotEmpty
            ? Text(
                user.intro!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textBody,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: ElevatedButton(
          onPressed: () async {
            if (!mounted) return;

            final scaffoldMessenger = ScaffoldMessenger.of(context);
            final action = isFollowing ? '언팔로우' : '팔로우';
            final confirmed = await ConfirmDialog.show(
              context: context,
              title: action,
              message: isFollowing
                  ? '${user.nickname ?? "이 사용자"}를(을) 언팔로우 하시겠습니까?'
                  : '${user.nickname ?? "이 사용자"}를(을) 팔로우 하시겠습니까?',
              confirmText: action,
            );

            if (!confirmed || !mounted) return;

            try {
              final success = isFollowing
                  ? await socialProvider.unfollowUser(currentUser.uid, user.uid)
                  : await socialProvider.followUser(currentUser.uid, user.uid);

              if (mounted) {
                if (success) {
                  // 사용자 정보 새로고침
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  await authProvider.loadUserInfo();
                  
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('$action 되었습니다.'),
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                  );
                  setState(() {});
                } else {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(socialProvider.error ?? '$action에 실패했습니다.'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            } catch (e) {
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('$action 중 오류가 발생했습니다: $e'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
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
          ),
          child: Text(isFollowing ? '언팔로우' : '팔로우'),
        ),
        onTap: () {
          // TODO: 사용자 프로필 상세 화면으로 이동
        },
      ),
    );
  }
}

