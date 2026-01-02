import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_data.dart';
import '../providers/pet_provider.dart';
import '../providers/walk_provider.dart';
import '../providers/auth_provider.dart';
import 'stats_screen.dart';
import 'main_screen.dart';

/// Home Screen
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final petProvider = Provider.of<PetProvider>(context, listen: false);
    final walkProvider = Provider.of<WalkProvider>(context, listen: false);

    if (authProvider.user != null) {
      petProvider.loadPets(authProvider.user!.uid);
      walkProvider.loadWalks(authProvider.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Walk'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Banner
            _buildTopBanner(),
            const SizedBox(height: 32),
            
            // Dashboard Card
            _buildDashboardCard(),
            const SizedBox(height: 32),
            
            // Quick Access
            _buildQuickAccess(),
          ],
        ),
      ),
    );
  }

  /// Top Banner: 반려동물 등록/대표 펫
  Widget _buildTopBanner() {
    return Consumer<PetProvider>(
      builder: (context, petProvider, _) {
        final primaryPet = petProvider.primaryPet;
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.secondaryMint,
                AppTheme.secondaryMint.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // TODO: 반려동물 관리 화면으로 이동
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            primaryPet != null
                                ? '${primaryPet.name}와 함께'
                                : '반려동물을 등록해주세요',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppTheme.textTitle,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (primaryPet != null && primaryPet.breed != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              primaryPet.breed!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textBody,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: AppTheme.primaryGreen,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Dashboard Card: 오늘의 활동
  Widget _buildDashboardCard() {
    return Consumer<WalkProvider>(
      builder: (context, walkProvider, _) {
        // 오늘의 산책 데이터 계산
        final today = DateTime.now();
        final todayWalks = walkProvider.walks.where((walk) {
          return walk.date.year == today.year &&
              walk.date.month == today.month &&
              walk.date.day == today.day;
        }).toList();

        // 오늘의 총 거리 (m)
        final totalDistance = todayWalks.fold<double>(
          0.0,
          (sum, walk) => sum + (walk.distance ?? 0.0) * 1000,
        );

        // 오늘의 총 시간 (초)
        final totalDuration = todayWalks.fold<int>(
          0,
          (sum, walk) => sum + ((walk.duration ?? 0) * 60),
        );

        // 오늘의 산책 횟수
        final walkCount = todayWalks.length;

        return Card(
          elevation: 4,
          shadowColor: Colors.green.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.backgroundWhite,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '오늘의 활동',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textTitle,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      value: totalDistance.toStringAsFixed(0),
                      unit: 'm',
                      label: '거리',
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: AppTheme.secondaryMint,
                    ),
                    _buildStatItem(
                      value: _formatDuration(totalDuration),
                      unit: '',
                      label: '시간',
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: AppTheme.secondaryMint,
                    ),
                    _buildStatItem(
                      value: walkCount.toString(),
                      unit: '회',
                      label: '횟수',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Stat Item Widget
  Widget _buildStatItem({
    required String value,
    required String unit,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textTitle,
                fontFamily: 'Paperlogy',
              ),
              children: [
                TextSpan(text: value),
                if (unit.isNotEmpty)
                  const TextSpan(
                    text: ' ',
                    style: TextStyle(fontSize: 20, fontFamily: 'Paperlogy'),
                  ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: unit,
                    style: const TextStyle(fontSize: 20, fontFamily: 'Paperlogy'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textBody,
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }

  /// Format duration in seconds to MM:SS
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Quick Access: 빠른 실행
  Widget _buildQuickAccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '빠른 실행',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textTitle,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _buildQuickAccessItem(
              icon: Icons.directions_walk,
              label: '산책 시작',
              onTap: () {
                // MainScreen의 탭 인덱스 변경
                final mainScreenState = context.findAncestorStateOfType<MainScreenState>();
                if (mainScreenState != null) {
                  mainScreenState.changeTab(2); // 산책 탭 (인덱스 2)
                }
              },
            ),
            _buildQuickAccessItem(
              icon: Icons.pets,
              label: '반려동물 관리',
              onTap: () {
                // MainScreen의 탭 인덱스 변경
                final mainScreenState = context.findAncestorStateOfType<MainScreenState>();
                if (mainScreenState != null) {
                  mainScreenState.changeTab(1); // 반려동물 탭 (인덱스 1)
                }
              },
            ),
            _buildQuickAccessItem(
              icon: Icons.bar_chart,
              label: '산책 통계',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StatsScreen(),
                  ),
                );
              },
            ),
            _buildQuickAccessItem(
              icon: Icons.people,
              label: '소셜',
              onTap: () {
                // MainScreen의 탭 인덱스 변경
                final mainScreenState = context.findAncestorStateOfType<MainScreenState>();
                if (mainScreenState != null) {
                  mainScreenState.changeTab(3); // 소셜 탭 (인덱스 3)
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  /// Quick Access Item Widget
  Widget _buildQuickAccessItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.secondaryMint,
            child: Icon(
              icon,
              color: AppTheme.primaryGreen,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textBody,
                  fontSize: 11,
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
