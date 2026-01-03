import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/theme_data.dart';
import '../providers/walk_provider.dart';
import '../providers/auth_provider.dart';
import '../models/walk_model.dart';

/// Stats Screen - Weekly walk distance chart
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWalks();
    });
  }

  void _loadWalks() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final walkProvider = Provider.of<WalkProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      walkProvider.loadWalks(authProvider.user!.uid);
    }
  }

  /// Get weekly walk data
  List<double> _getWeeklyData(List<WalkModel> walks) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    final weeklyData = List<double>.filled(7, 0.0);
    
    for (var walk in walks) {
      final walkDate = walk.date;
      if (walkDate.isAfter(weekStart.subtract(const Duration(days: 1)))) {
        final dayIndex = walkDate.weekday - 1;
        if (dayIndex >= 0 && dayIndex < 7) {
          weeklyData[dayIndex] += walk.distance ?? 0.0;
        }
      }
    }
    
    return weeklyData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('산책 통계'),
      ),
      body: Consumer<WalkProvider>(
        builder: (context, walkProvider, _) {
          final weeklyData = _getWeeklyData(walkProvider.walks);
          final maxDistance = weeklyData.isEmpty
              ? 1.0
              : weeklyData.reduce((a, b) => a > b ? a : b);

          // Calculate totals
          final totalDistance = walkProvider.walks.fold<double>(
            0.0,
            (sum, walk) => sum + (walk.distance ?? 0.0),
          );
          final totalDuration = walkProvider.walks.fold<int>(
            0,
            (sum, walk) => sum + (walk.duration ?? 0),
          );
          final totalWalks = walkProvider.walks.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        icon: Icons.straighten,
                        value: totalDistance >= 1.0
                            ? '${totalDistance.toStringAsFixed(1)} km'
                            : '${(totalDistance * 1000).toStringAsFixed(0)} m',
                        label: '총 거리',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        icon: Icons.timer,
                        value: '${(totalDuration ~/ 60)}분',
                        label: '총 시간',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSummaryCard(
                  icon: Icons.directions_walk,
                  value: '$totalWalks회',
                  label: '총 산책',
                  fullWidth: true,
                ),
                
                const SizedBox(height: 32),
                
                // Tab Bar for Weekly/Monthly
                Text(
                  '산책 통계',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),
                DefaultTabController(
                  length: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TabBar(
                        labelColor: AppTheme.primaryGreen,
                        unselectedLabelColor: AppTheme.textBody,
                        indicatorColor: AppTheme.primaryGreen,
                        tabs: const [
                          Tab(text: '이번 주'),
                          Tab(text: '이번 달'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 300,
                        child: TabBarView(
                          children: [
                            // Weekly Chart
                            _buildWeeklyChart(weeklyData, maxDistance),
                            // Monthly Chart
                            _buildMonthlyChart(walkProvider.walks),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Build Summary Card
  Widget _buildSummaryCard({
    required IconData icon,
    required String value,
    required String label,
    bool fullWidth = false,
  }) {
    return Card(
      elevation: AppTheme.cardElevation,
      shadowColor: AppTheme.cardShadowColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: fullWidth ? double.infinity : null,
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.secondaryMint,
              child: Icon(
                icon,
                color: AppTheme.primaryGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textTitle,
                        ),
                  ),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textBody,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get monthly walk data
  List<double> _getMonthlyData(List<WalkModel> walks) {
    final now = DateTime.now();
    
    final monthlyData = List<double>.filled(now.day, 0.0);
    
    for (var walk in walks) {
      final walkDate = walk.date;
      if (walkDate.year == now.year && walkDate.month == now.month) {
        final dayIndex = walkDate.day - 1;
        if (dayIndex >= 0 && dayIndex < monthlyData.length) {
          monthlyData[dayIndex] += walk.distance ?? 0.0;
        }
      }
    }
    
    return monthlyData;
  }

  /// Build Weekly Chart
  Widget _buildWeeklyChart(List<double> weeklyData, double maxDistance) {
    return Card(
      elevation: AppTheme.cardElevation,
      shadowColor: AppTheme.cardShadowColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxDistance > 0 ? maxDistance * 1.2 : 5.0,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipPadding: const EdgeInsets.all(8),
                getTooltipColor: (group) => AppTheme.primaryGreen,
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    const days = ['월', '화', '수', '목', '금', '토', '일'];
                    if (value.toInt() >= 0 && value.toInt() < 7) {
                      return Text(
                        days[value.toInt()],
                        style: const TextStyle(
                          color: AppTheme.textBody,
                          fontSize: 12,
                          fontFamily: 'Paperlogy',
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const Text('');
                    return Text(
                      value.toStringAsFixed(1),
                      style: const TextStyle(
                        color: AppTheme.textBody,
                        fontSize: 10,
                        fontFamily: 'Paperlogy',
                      ),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.secondaryMint,
                  width: 1,
                ),
                left: BorderSide(
                  color: AppTheme.secondaryMint,
                  width: 1,
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxDistance > 0 ? maxDistance / 5 : 1.0,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: AppTheme.secondaryMint.withValues(alpha: 0.3),
                  strokeWidth: 1,
                );
              },
            ),
            barGroups: weeklyData.asMap().entries.map((entry) {
              final index = entry.key;
              final value = entry.value;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: value,
                    color: _getGradientColor(value, maxDistance),
                    width: 20,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// Build Monthly Chart
  Widget _buildMonthlyChart(List<WalkModel> walks) {
    final monthlyData = _getMonthlyData(walks);
    final maxDistance = monthlyData.isEmpty
        ? 1.0
        : monthlyData.reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: AppTheme.cardElevation,
      shadowColor: AppTheme.cardShadowColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxDistance > 0 ? maxDistance * 1.2 : 5.0,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipPadding: const EdgeInsets.all(8),
                getTooltipColor: (group) => AppTheme.primaryGreen,
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final day = value.toInt() + 1;
                    if (day % 5 == 0 || day == 1) {
                      return Text(
                        '$day일',
                        style: const TextStyle(
                          color: AppTheme.textBody,
                          fontSize: 10,
                          fontFamily: 'Paperlogy',
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const Text('');
                    return Text(
                      value.toStringAsFixed(1),
                      style: const TextStyle(
                        color: AppTheme.textBody,
                        fontSize: 10,
                        fontFamily: 'Paperlogy',
                      ),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.secondaryMint,
                  width: 1,
                ),
                left: BorderSide(
                  color: AppTheme.secondaryMint,
                  width: 1,
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxDistance > 0 ? maxDistance / 5 : 1.0,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: AppTheme.secondaryMint.withValues(alpha: 0.3),
                  strokeWidth: 1,
                );
              },
            ),
            barGroups: monthlyData.asMap().entries.map((entry) {
              final index = entry.key;
              final value = entry.value;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: value,
                    color: _getGradientColor(value, maxDistance),
                    width: 8,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// Get gradient color based on value
  Color _getGradientColor(double value, double maxValue) {
    if (maxValue == 0) return AppTheme.primaryGreen;
    final ratio = value / maxValue;
    
    // Green gradient from light to vivid
    if (ratio < 0.3) {
      return AppTheme.secondaryMint;
    } else if (ratio < 0.6) {
      return AppTheme.primaryGreenAlt;
    } else {
      return AppTheme.primaryGreen;
    }
  }
}

