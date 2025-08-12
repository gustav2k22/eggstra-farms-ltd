import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/activity_service.dart';
import '../../core/models/activity_model.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/loading_overlay.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final Map<String, dynamic> _dashboardData = {
    'totalUsers': 0,
    'totalProducts': 0,
    'totalOrders': 0,
    'totalRevenue': 0.0,
    'todayOrders': 0,
    'pendingOrders': 0,
    'lowStockProducts': 0,
    'newUsers': 0,
  };

  final List<StreamSubscription> _subscriptions = [];
  bool _isLoading = false;
  List<ActivityModel> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));
    
    _animationController.forward();
    _loadDashboardData();
    _loadRecentActivities();
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
  
  void _loadRecentActivities() {
    final activitySubscription = ActivityService().getRecentActivitiesStream(limit: 5)
        .listen((activities) {
      if (mounted) {
        setState(() {
          _recentActivities = activities;
        });
      }
    }, onError: (error) {
      debugPrint('Error loading recent activities: $error');
    });
    
    _subscriptions.add(activitySubscription);
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load total users
      final usersSubscription = FirebaseService.instance.usersCollection
          .snapshots()
          .listen((snapshot) {
        setState(() {
          _dashboardData['totalUsers'] = snapshot.docs.length;
        });
      });
      _subscriptions.add(usersSubscription);

      // Load total products
      final productsSubscription = FirebaseService.instance.productsCollection
          .snapshots()
          .listen((snapshot) {
        setState(() {
          _dashboardData['totalProducts'] = snapshot.docs.length;
          _dashboardData['lowStockProducts'] = snapshot.docs
              .where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final stock = data['stock'] ?? 0;
                return stock < 10; // Consider low stock if less than 10
              })
              .length;
        });
      });
      _subscriptions.add(productsSubscription);

      // Load orders data
      final ordersSubscription = FirebaseService.instance.ordersCollection
          .snapshots()
          .listen((snapshot) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        double totalRevenue = 0.0;
        int todayOrders = 0;
        int pendingOrders = 0;

        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final orderDate = (data['orderDate'] as Timestamp?)?.toDate();
          final status = data['status'] as String?;
          final total = (data['total'] as num?)?.toDouble() ?? 0.0;

          // Calculate total revenue
          if (status == 'delivered' || status == 'completed') {
            totalRevenue += total;
          }

          // Count today's orders
          if (orderDate != null && orderDate.isAfter(today)) {
            todayOrders++;
          }

          // Count pending orders
          if (status == 'pending' || status == 'processing') {
            pendingOrders++;
          }
        }

        setState(() {
          _dashboardData['totalOrders'] = snapshot.docs.length;
          _dashboardData['totalRevenue'] = totalRevenue;
          _dashboardData['todayOrders'] = todayOrders;
          _dashboardData['pendingOrders'] = pendingOrders;
        });
      });
      _subscriptions.add(ordersSubscription);

      // Load new users (users created in the last 7 days)
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final newUsersSubscription = FirebaseService.instance.usersCollection
          .where('createdAt', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
          .snapshots()
          .listen((snapshot) {
        setState(() {
          _dashboardData['newUsers'] = snapshot.docs.length;
        });
      });
      _subscriptions.add(newUsersSubscription);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading dashboard data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return LoadingOverlay(
          isLoading: authProvider.isLoading,
          child: RefreshIndicator(
            onRefresh: _loadDashboardData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildWelcomeSection(authProvider.user?.firstName ?? 'Admin'),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Quick Stats
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildQuickStats(),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action Cards
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildActionCards(),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Recent Activity
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildRecentActivity(),
                    ),
                  ),
                  
                  const SizedBox(height: 100), // Bottom padding for navigation
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection(String adminName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryLight,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $adminName!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Here\'s what\'s happening at Eggstra Farms today',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildWelcomeStatItem(
                      icon: Icons.trending_up,
                      value: '${_dashboardData['todayOrders']}',
                      label: 'Today\'s Orders',
                    ),
                    const SizedBox(width: 20),
                    _buildWelcomeStatItem(
                      icon: Icons.people,
                      value: '${_dashboardData['newUsers']}',
                      label: 'New Users',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 16,
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              title: 'Total Users',
              value: _formatNumber(_dashboardData['totalUsers']),
              icon: Icons.people,
              color: AppColors.primary,
              trend: '+12%',
            ),
            _buildStatCard(
              title: 'Total Products',
              value: _formatNumber(_dashboardData['totalProducts']),
              icon: Icons.inventory_2,
              color: AppColors.secondary,
              trend: '+5%',
            ),
            _buildStatCard(
              title: 'Total Orders',
              value: _formatNumber(_dashboardData['totalOrders']),
              icon: Icons.receipt_long,
              color: AppColors.accent,
              trend: '+18%',
            ),
            _buildStatCard(
              title: 'Revenue',
              value: 'GHS ${_formatNumber(_dashboardData['totalRevenue'])}',
              icon: Icons.attach_money,
              color: AppColors.success,
              trend: '+25%',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trend,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Pending Orders',
                value: '${_dashboardData['pendingOrders']}',
                icon: Icons.pending_actions,
                color: AppColors.warning,
                onTap: () {
                  // TODO: Navigate to pending orders
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                title: 'Low Stock',
                value: '${_dashboardData['lowStockProducts']}',
                icon: Icons.warning,
                color: AppColors.error,
                onTap: () {
                  // TODO: Navigate to low stock products
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to full activity log
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _recentActivities.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.timeline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No recent activity',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: _recentActivities.asMap().entries.map((entry) {
                    final index = entry.key;
                    final activity = entry.value;
                    return _buildActivityItem(
                      icon: _getActivityIcon(activity.type),
                      title: activity.title,
                      subtitle: activity.description,
                      time: activity.timeAgo,
                      color: _getActivityColor(activity.type),
                      isLast: index == _recentActivities.length - 1,
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: isLast ? null : Border(
          bottom: BorderSide(
            color: AppColors.inputBorder.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(dynamic number) {
    if (number is int) {
      if (number >= 1000000) {
        return '${(number / 1000000).toStringAsFixed(1)}M';
      } else if (number >= 1000) {
        return '${(number / 1000).toStringAsFixed(1)}K';
      }
      return number.toString();
    } else if (number is double) {
      if (number >= 1000000) {
        return '${(number / 1000000).toStringAsFixed(1)}M';
      } else if (number >= 1000) {
        return '${(number / 1000).toStringAsFixed(1)}K';
      }
      return number.toStringAsFixed(0);
    }
    return number.toString();
  }



  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.order:
        return Icons.shopping_cart;
      case ActivityType.user:
        return Icons.person_add;
      case ActivityType.product:
        return Icons.inventory;
      case ActivityType.system:
        return Icons.settings;
    }
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.order:
        return AppColors.primary;
      case ActivityType.user:
        return AppColors.success;
      case ActivityType.product:
        return AppColors.info;
      case ActivityType.system:
        return AppColors.secondary;
    }
  }
}
