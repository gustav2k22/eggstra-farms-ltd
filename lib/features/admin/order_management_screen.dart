import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/order_service.dart';
import '../../shared/models/order_model.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/loading_overlay.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';
  String _selectedTimeFilter = 'All Time';
  bool _isLoading = false;
  
  // Firebase integration
  List<OrderModel> _orders = [];
  StreamSubscription<List<OrderModel>>? _ordersSubscription;
  
  final List<String> _statusOptions = [
    'All', 'Pending', 'Confirmed', 'Processing', 'Shipped', 'Delivered', 'Cancelled'
  ];
  
  final List<String> _timeFilters = [
    'All Time', 'Today', 'This Week', 'This Month', 'Last Month'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _loadOrders();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _ordersSubscription?.cancel();
    super.dispose();
  }

  void _loadOrders() {
    setState(() {
      _isLoading = true;
    });
    
    // Load orders from Firebase using OrderService
    final ordersStream = OrderService().getAllOrders();
    _ordersSubscription?.cancel();
    _ordersSubscription = ordersStream.listen(
      (orders) {
        if (mounted) {
          setState(() {
            _orders = orders;
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        debugPrint('Error loading orders: $error');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading orders: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  List<OrderModel> get _filteredOrders {
    return _orders.where((order) {
      final matchesSearch = order.id.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          order.items.any((item) => item.productName.toLowerCase().contains(_searchController.text.toLowerCase()));
      
      final matchesStatus = _selectedStatus == 'All' || order.status.toString().split('.').last == _selectedStatus.toLowerCase();
      
      bool matchesTime = true;
      final now = DateTime.now();
      switch (_selectedTimeFilter) {
        case 'Today':
          matchesTime = order.orderDate.day == now.day &&
              order.orderDate.month == now.month &&
              order.orderDate.year == now.year;
          break;
        case 'This Week':
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          matchesTime = order.orderDate.isAfter(weekStart);
          break;
        case 'This Month':
          matchesTime = order.orderDate.month == now.month &&
              order.orderDate.year == now.year;
          break;
        case 'Last Month':
          final lastMonth = DateTime(now.year, now.month - 1);
          matchesTime = order.orderDate.month == lastMonth.month &&
              order.orderDate.year == lastMonth.year;
          break;
      }
      
      return matchesSearch && matchesStatus && matchesTime;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Order Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh, color: AppColors.primary),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildSearchAndFilters(),
              _buildOrderStats(),
              Expanded(
                child: _buildOrderList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CustomTextField(
            controller: _searchController,
            label: 'Search',
            hint: 'Search orders or products...',
            prefixIcon: Icons.search,
            onChanged: (value) => setState(() {}),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  'Status',
                  _selectedStatus,
                  _statusOptions,
                  (value) => setState(() => _selectedStatus = value!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFilterDropdown(
                  'Time Period',
                  _selectedTimeFilter,
                  _timeFilters,
                  (value) => setState(() => _selectedTimeFilter = value!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> options,
    void Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.inputBorder),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.inputBackground,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(label),
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildOrderStats() {
    final filteredOrders = _filteredOrders;
    final totalOrders = filteredOrders.length;
    final totalRevenue = filteredOrders.fold<double>(0, (sum, order) => sum + order.total);
    final pendingOrders = filteredOrders.where((order) => order.status == 'pending').length;
    final deliveredOrders = filteredOrders.where((order) => order.status == 'delivered').length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 26),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Orders',
                  totalOrders.toString(),
                  Icons.shopping_bag_outlined,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Revenue',
                  'GHS ${totalRevenue.toStringAsFixed(2)}',
                  Icons.attach_money,
                  AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Pending',
                  pendingOrders.toString(),
                  Icons.pending_outlined,
                  AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Delivered',
                  deliveredOrders.toString(),
                  Icons.check_circle_outline,
                  AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 51)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    final filteredOrders = _filteredOrders;
    
    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 128),
            ),
            const SizedBox(height: 16),
            Text(
              'No orders found',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary.withValues(alpha: 179),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        return _buildOrderCard(order, index);
      },
    );
  }

  Widget _buildOrderCard(OrderModel order, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 26),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order #${order.id}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM dd, yyyy • HH:mm').format(order.orderDate),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildStatusBadge(order.status),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'GHS ${order.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        CustomButton(
                          text: 'View Details',
                          onPressed: () => _viewOrderDetails(order),
                          variant: ButtonVariant.outline,
                        ),
                      ],
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

  Widget _buildStatusBadge(String status) {
    String statusText;
    Color color;
    
    switch (status) {
      case 'pending':
        statusText = 'Pending';
        color = AppColors.warning;
        break;
      case 'confirmed':
        statusText = 'Confirmed';
        color = AppColors.info;
        break;
      case 'processing':
        statusText = 'Processing';
        color = AppColors.secondary;
        break;
      case 'shipped':
        statusText = 'Shipped';
        color = AppColors.primary;
        break;
      case 'delivered':
        statusText = 'Delivered';
        color = AppColors.success;
        break;
      case 'cancelled':
        statusText = 'Cancelled';
        color = AppColors.error;
        break;
      default:
        statusText = 'Unknown';
        color = AppColors.textSecondary;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 77)),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _viewOrderDetails(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order #${order.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total: GHS ${order.total.toStringAsFixed(2)}'),
            Text('Items: ${order.items.length}'),
            Text('Status: ${order.status.toString().split('.').last}'),
            Text('Date: ${DateFormat('MMM dd, yyyy').format(order.orderDate)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
