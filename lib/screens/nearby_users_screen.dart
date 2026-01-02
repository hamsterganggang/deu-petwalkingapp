import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/theme_data.dart';
import '../providers/social_provider.dart';
import '../models/user_model.dart';

/// Nearby Users Screen - 반경 1km 내 산책 중인 사용자
class NearbyUsersScreen extends StatefulWidget {
  const NearbyUsersScreen({super.key});

  @override
  State<NearbyUsersScreen> createState() => _NearbyUsersScreenState();
}

class _NearbyUsersScreenState extends State<NearbyUsersScreen> {
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });
      
      if (mounted) {
        final socialProvider = Provider.of<SocialProvider>(context, listen: false);
        await socialProvider.getNearbyUsers(
          position.latitude,
          position.longitude,
          1.0, // 1km 반경
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('위치를 가져올 수 없습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주변 사용자'),
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Consumer<SocialProvider>(
              builder: (context, socialProvider, _) {
                if (socialProvider.isLoading) {
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
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: nearbyUsers.length,
                  itemBuilder: (context, index) {
                    return _buildUserCard(nearbyUsers[index]);
                  },
                );
              },
            ),
    );
  }

  Widget _buildUserCard(UserModel user) {
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
            // TODO: 사용자 프로필 보기
          },
          icon: const Icon(Icons.chevron_right),
          color: AppTheme.textBody,
        ),
      ),
    );
  }
}

