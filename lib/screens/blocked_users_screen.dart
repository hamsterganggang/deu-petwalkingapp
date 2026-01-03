import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_data.dart';
import '../providers/social_provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'user_profile_screen.dart';

/// Blocked Users Screen - 차단된 사용자 목록
class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  List<UserModel> _blockedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final socialProvider = Provider.of<SocialProvider>(context, listen: false);
    
    if (authProvider.user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // 차단된 사용자 ID 목록 가져오기
      final blockedIds = await socialProvider.getBlockedIds(authProvider.user!.uid);
      
      // 차단된 사용자 정보 가져오기
      final userService = FirebaseUserService();
      final blockedUsers = <UserModel>[];
      
      for (final blockedId in blockedIds) {
        try {
          final user = await userService.getUserInfo(blockedId);
          if (user != null) {
            blockedUsers.add(user);
          }
        } catch (e) {
          // 개별 사용자 조회 실패는 무시
        }
      }

      if (mounted) {
        setState(() {
          _blockedUsers = blockedUsers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('차단된 사용자 목록을 불러오는데 실패했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _unblockUser(UserModel user) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final socialProvider = Provider.of<SocialProvider>(context, listen: false);
    
    if (authProvider.user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        ),
        title: const Text('차단 해제'),
        content: Text('${user.nickname ?? "이 사용자"}의 차단을 해제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryGreen,
            ),
            child: const Text('차단 해제'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final success = await socialProvider.unblockUser(
        authProvider.user!.uid,
        user.uid,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('차단이 해제되었습니다.'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
          _loadBlockedUsers();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(socialProvider.error ?? '차단 해제에 실패했습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('차단 해제 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('차단된 사용자'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _blockedUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.block,
                        size: 64,
                        color: AppTheme.textBody.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '차단된 사용자가 없습니다',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textBody,
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _blockedUsers.length,
                  itemBuilder: (context, index) {
                    return _buildBlockedUserCard(_blockedUsers[index]);
                  },
                ),
    );
  }

  Widget _buildBlockedUserCard(UserModel user) {
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfileScreen(userId: user.uid),
                  ),
                );
              },
              tooltip: '프로필 보기',
            ),
            IconButton(
              icon: const Icon(Icons.block),
              color: Colors.red,
              onPressed: () => _unblockUser(user),
              tooltip: '차단 해제',
            ),
          ],
        ),
      ),
    );
  }
}

