import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_data.dart';
import '../utils/confirm_dialog.dart';
import '../providers/social_provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import 'user_profile_screen.dart';

/// User Search Screen
class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers() async {
    if (_searchController.text.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final socialProvider = Provider.of<SocialProvider>(context, listen: false);
    await socialProvider.searchUsers(_searchController.text);
    
    setState(() {
      _searchResults = socialProvider.searchResults;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('사용자 검색'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '닉네임으로 검색',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchUsers();
                        },
                      )
                    : null,
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
              onChanged: (_) => _searchUsers(),
            ),
          ),

          // Search Results
          Expanded(
            child: Consumer<SocialProvider>(
              builder: (context, socialProvider, _) {
                if (socialProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
                  return Center(
                    child: Text(
                      '검색 결과가 없습니다',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textBody,
                          ),
                    ),
                  );
                }

                if (_searchResults.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 64,
                          color: AppTheme.textBody.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '닉네임을 입력하여 검색하세요',
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
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    return _buildUserCard(_searchResults[index], socialProvider);
                  },
                );
              },
            ),
          ),
        ],
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.intro != null && user.intro!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(user.intro!),
            ],
            const SizedBox(height: 4),
            Text(
              '팔로워 ${user.followerCount} · 팔로잉 ${user.followingCount}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textBody,
                  ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfileScreen(userId: user.uid),
            ),
          );
        },
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Text('차단'),
                  onTap: () {
                    final navigator = Navigator.of(context);
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    Future.delayed(
                      const Duration(milliseconds: 100),
                      () async {
                        if (!navigator.mounted) return;
                        
                        final confirmed = await ConfirmDialog.show(
                          context: navigator.context,
                          title: '사용자 차단',
                          message: '${user.nickname ?? "이 사용자"}를(을) 차단하시겠습니까?\n차단된 사용자의 산책 기록은 더 이상 보이지 않습니다.',
                          confirmText: '차단',
                          isDestructive: true,
                        );

                        if (!confirmed || !navigator.mounted) return;

                        try {
                          final success = await socialProvider.blockUser(currentUser.uid, user.uid);
                          if (navigator.mounted) {
                            if (success) {
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text('사용자를 차단했습니다.'),
                                  backgroundColor: AppTheme.primaryGreen,
                                ),
                              );
                            } else {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(socialProvider.error ?? '차단에 실패했습니다.'),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 5),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (navigator.mounted) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text('차단 중 오류가 발생했습니다: $e'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
              ],
            ),
            ElevatedButton(
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
          ],
        ),
      ),
    );
  }
}

