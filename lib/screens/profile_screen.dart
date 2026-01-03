import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/theme_data.dart';
import '../utils/confirm_dialog.dart';
import '../providers/auth_provider.dart';
import '../providers/walk_provider.dart';
import '../models/walk_model.dart';
import '../services/storage_service.dart';
import 'login_screen.dart';
import 'follow_list_screen.dart';
import 'walk_detail_screen.dart';
import 'main_screen.dart';

/// Profile Screen
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _introController = TextEditingController();
  bool _isEditing = false;
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();
  final StorageService _storageService = FirebaseStorageService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final walkProvider = Provider.of<WalkProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      _nicknameController.text = authProvider.user?.nickname ?? '';
      _introController.text = authProvider.user?.intro ?? '';
      walkProvider.loadWalks(authProvider.user!.uid);
      // 사용자 정보 새로고침 (팔로워/팔로잉 수 동기화)
      authProvider.loadUserInfo();
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null && mounted) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(content: Text('이미지 선택에 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null && mounted) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(content: Text('사진 촬영에 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) return;

    String? photoUrl = authProvider.user!.photoUrl;
    
    // 사진 업로드
    if (_selectedImage != null) {
      try {
        photoUrl = await _storageService.uploadUserPhoto(
          authProvider.user!.uid,
          _selectedImage!,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('사진 업로드에 실패했습니다: $e')),
          );
        }
        return;
      }
    }

    final updatedUser = authProvider.user!.copyWith(
      nickname: _nicknameController.text.isEmpty
          ? null
          : _nicknameController.text,
      intro: _introController.text.isEmpty ? null : _introController.text,
      photoUrl: photoUrl,
    );

    final success = await authProvider.updateUserInfo(updatedUser);
    if (success && mounted) {
      setState(() {
        _isEditing = false;
        _selectedImage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필이 저장되었습니다.')),
      );
    } else if (mounted && authProvider.error != null) {
      // 에러 메시지 표시 (닉네임 변경 제한 등)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error!),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _introController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필'),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _saveProfile,
              child: Text(
                '저장',
                style: const TextStyle(
                  color: AppTheme.primaryGreen,
                  fontFamily: 'Paperlogy',
                ),
              ),
            )
          else ...[
            IconButton(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              icon: const Icon(Icons.edit),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Text('로그아웃'),
                      onTap: () {
                        final navigator = Navigator.of(context);
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        Future.delayed(
                          const Duration(milliseconds: 100),
                          () async {
                            if (!navigator.mounted) return;
                            
                            final confirmed = await ConfirmDialog.show(
                              context: navigator.context,
                              title: '로그아웃',
                              message: '로그아웃 하시겠습니까?',
                              confirmText: '로그아웃',
                            );

                            if (!confirmed || !navigator.mounted) return;

                            try {
                              await authProvider.signOut();
                              if (navigator.mounted) {
                                navigator.pushReplacement(
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                );
                              }
                            } catch (e) {
                              if (navigator.mounted) {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text('로그아웃 중 오류가 발생했습니다: $e'),
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
          ],
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;
          if (user == null) {
            return const Center(
              child: Text('로그인이 필요합니다.'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile Photo
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppTheme.secondaryMint,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : (user.photoUrl != null ? NetworkImage(user.photoUrl!) : null) as ImageProvider?,
                      child: (_selectedImage == null && user.photoUrl == null)
                          ? Icon(
                              Icons.person,
                              size: 60,
                              color: AppTheme.primaryGreen,
                            )
                          : null,
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: PopupMenuButton<String>(
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: AppTheme.primaryGreen,
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          onSelected: (value) async {
                            if (value == 'gallery') {
                              await _pickImage();
                            } else if (value == 'camera') {
                              await _takePhoto();
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'gallery',
                              child: Row(
                                children: [
                                  Icon(Icons.photo_library),
                                  SizedBox(width: 8),
                                  Text('갤러리에서 선택'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'camera',
                              child: Row(
                                children: [
                                  Icon(Icons.camera_alt),
                                  SizedBox(width: 8),
                                  Text('사진 촬영'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Nickname
                if (_isEditing)
                  TextField(
                    controller: _nicknameController,
                    decoration: InputDecoration(
                      labelText: '닉네임',
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
                  )
                else
                  Text(
                    user.nickname ?? '닉네임 없음',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                const SizedBox(height: 16),

                // Intro
                if (_isEditing)
                  TextField(
                    controller: _introController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: '소개',
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
                  )
                else if (user.intro != null && user.intro!.isNotEmpty)
                  Text(
                    user.intro!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),

                const SizedBox(height: 32),

                // Location Privacy Switch
                Card(
                  elevation: AppTheme.cardElevation,
                  shadowColor: AppTheme.cardShadowColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  ),
                  child: SwitchListTile(
                    title: const Text('위치 정보 공개'),
                    subtitle: const Text('다른 사용자에게 내 위치를 공개합니다'),
                    value: user.isLocationPublic,
                    onChanged: (value) async {
                      final updatedUser = user.copyWith(
                        isLocationPublic: value,
                      );
                      await authProvider.updateUserInfo(updatedUser);
                    },
                    activeThumbColor: AppTheme.primaryGreen,
                    activeTrackColor: AppTheme.primaryGreen.withValues(alpha: 0.5),
                  ),
                ),

                const SizedBox(height: 32),

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
                          onTap: () async {
                            // 팔로워 목록 화면으로 이동
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FollowListScreen(
                                  userId: user.uid,
                                  isFollowers: true,
                                ),
                              ),
                            );
                            // 돌아왔을 때 사용자 정보 새로고침
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            await authProvider.loadUserInfo();
                            setState(() {});
                          },
                          child: Column(
                            children: [
                              Text(
                                '${user.followerCount}',
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
                          onTap: () async {
                            // 팔로잉 목록 화면으로 이동
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FollowListScreen(
                                  userId: user.uid,
                                  isFollowers: false,
                                ),
                              ),
                            );
                            // 돌아왔을 때 사용자 정보 새로고침
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            await authProvider.loadUserInfo();
                            setState(() {});
                          },
                          child: Column(
                            children: [
                              Text(
                                '${user.followingCount}',
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

                const SizedBox(height: 32),

                // My Walks List
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '내 산책 기록',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Consumer<WalkProvider>(
                  builder: (context, walkProvider, _) {
                    // 현재 사용자의 산책만 필터링
                    final myWalks = walkProvider.walks.where((walk) => walk.userId == user.uid).toList();

                    if (myWalks.isEmpty) {
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
                                '아직 산책 기록이 없습니다',
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
                      itemCount: myWalks.length,
                      itemBuilder: (context, index) {
                        return _buildWalkItem(myWalks[index]);
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Build Walk Item
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
