import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/models/order_model.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/widgets/custom_button.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isLoading = false;
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Pending', 'Processing', 'Delivered', 'Cancelled'];
  
  // Mock order data - replace with real data from Firestore
  final List<OrderModel> _mockOrders = [
    OrderModel(
      id: 'order_001',
      userId: 'user_123',
      orderNumber: 'ORD-001',
      items: [],
      subtotal: 45.50,
      deliveryFee: 5.00,
      tax: 1.14,
      total: 51.64,
      status: 'delivered',
      paymentStatus: 'completed',
      paymentMethod: 'Cash on Delivery',
      deliveryAddress: DeliveryAddressModel(
        fullName: 'John Doe',
        phoneNumber: '+233244123456',
        address: '123 Main Street',
        city: 'Accra',
        region: 'Greater Accra',
      ),
      orderDate: DateTime.now().subtract(const Duration(days: 2)),
      actualDeliveryDate: DateTime.now().subtract(const Duration(days: 1)),
      notes: 'Please ring the doorbell',
    ),
    OrderModel(
      id: 'order_002',
      userId: 'user_123',
      orderNumber: 'ORD-002',
      items: [],
      subtotal: 32.00,
      deliveryFee: 5.00,
      tax: 0.80,
      total: 37.80,
      status: 'processing',
      paymentStatus: 'pending',
      paymentMethod: 'Mobile Money',
      deliveryAddress: DeliveryAddressModel(
        fullName: 'Jane Smith',
        phoneNumber: '+233244789012',
        address: '456 Oak Avenue',
        city: 'Kumasi',
        region: 'Ashanti',
      ),
      orderDate: DateTime.now().subtract(const Duration(hours: 3)),
      estimatedDeliveryDate: DateTime.now().add(const Duration(hours: 2)),
    ),
    OrderModel(
      id: 'order_003',
      userId: 'user_123',
      orderNumber: 'ORD-003',
      items: [],
      subtotal: 28.75,
      deliveryFee: 5.00,
      tax: 0.72,
      total: 34.47,
      status: 'pending',
      paymentStatus: 'pending',
      paymentMethod: 'Cash on Delivery',
      deliveryAddress: DeliveryAddressModel(
        fullName: 'Michael Johnson',
        phoneNumber: '+233244345678',
        address: '789 Pine Road',
        city: 'Tamale',
        region: 'Northern',
      ),
      orderDate: DateTime.now().subtract(const Duration(minutes: 30)),
      estimatedDeliveryDate: DateTime.now().add(const Duration(hours: 4)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<OrderModel> get _filteredOrders {
    if (_selectedFilter == 'All') {
      return _mockOrders;
    }
    
    return _mockOrders.where((order) {
      switch (_selectedFilter) {
        case 'Pending':
          return order.status == 'pending';
        case 'Processing':
          return order.status == 'processing';
        case 'Delivered':
          return order.status == 'delivered';
        case 'Cancelled':
          return order.status == 'cancelled';
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Order History'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return LoadingOverlay(
            isLoading: _isLoading,
            child: Column(
              children: [
                // Filter Section
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filterOptions.map((filter) {
                          final isSelected = _selectedFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(filter),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedFilter = filter;
                                });
                              },
                              selectedColor: AppColors.primary.withValues(alpha: 51),
                              checkmarkColor: AppColors.primary,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                
                // Orders List
                Expanded(
                  child: _filteredOrders.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _refreshOrders,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredOrders.length,
                            itemBuilder: (context, index) {
                              return SlideTransition(
                                position: _slideAnimation,
                                child: FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: _buildOrderCard(_filteredOrders[index]),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: AppColors.textSecondary.withValues(alpha: 128),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == 'All' ? 'No orders yet' : 'No ${_selectedFilter.toLowerCase()} orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary.withValues(alpha: 179),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == 'All' 
                  ? 'Start shopping to see your orders here'
                  : 'Try adjusting your filter',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withValues(alpha: 128),
              ),
              textAlign: TextAlign.center,
            ),
            if (_selectedFilter == 'All') ...[
              const SizedBox(height: 24),
              CustomButton(
                text: 'Start Shopping',
                onPressed: () => context.go('/home'),
                backgroundColor: AppColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.id.substring(order.id.length - 6).toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(order.orderDate),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              _buildStatusBadge(order.status),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Order Items Preview
          if (order.items.isNotEmpty) ...[
            Text(
              '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: order.items.take(3).length,
                itemBuilder: (context, index) {
                  final item = order.items[index];
                  return Container(
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: item.productImageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.image_not_supported,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (order.items.length > 3)
              Text(
                '+${order.items.length - 3} more items',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            const SizedBox(height: 16),
          ],
          
          // Order Details
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailItem(
                      icon: Icons.payment,
                      label: 'Payment',
                      value: order.paymentMethod,
                    ),
                    const SizedBox(height: 8),
                    _buildDetailItem(
                      icon: Icons.location_on,
                      label: 'Delivery',
                      value: '${order.deliveryAddress.city}, ${order.deliveryAddress.region}',
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'GHS ${order.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _viewOrderDetails(order),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                  child: const Text('View Details'),
                ),
              ),
              const SizedBox(width: 12),
              if (order.status.toLowerCase() == 'delivered')
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _reorderItems(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reorder'),
                  ),
                )
              else if (order.status.toLowerCase() == 'pending')
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _cancelOrder(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Cancel'),
                  ),
                )
              else
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _trackOrder(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Track Order'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    String text;
    
    switch (status) {
      case 'pending':
        backgroundColor = AppColors.warning.withValues(alpha: 0.1);
        textColor = AppColors.warning;
        text = 'PENDING';
        break;
      case 'processing':
        backgroundColor = AppColors.info.withValues(alpha: 0.1);
        textColor = AppColors.info;
        text = 'PROCESSING';
        break;
      case 'delivered':
        backgroundColor = AppColors.success.withValues(alpha: 0.1);
        textColor = AppColors.success;
        text = 'DELIVERED';
        break;
      case 'cancelled':
        backgroundColor = AppColors.error.withValues(alpha: 0.1);
        textColor = AppColors.error;
        text = 'CANCELLED';
        break;
      default:
        backgroundColor = AppColors.gray200;
        textColor = AppColors.textSecondary;
        text = status.toUpperCase();
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  void _viewOrderDetails(OrderModel order) {
    // TODO: Navigate to order details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order details for #${order.id.substring(order.id.length - 6).toUpperCase()}'),
      ),
    );
  }

  void _reorderItems(OrderModel order) {
    // TODO: Implement reorder functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reorder functionality coming soon!'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _trackOrder(OrderModel order) {
    // TODO: Navigate to order tracking screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tracking order #${order.id.substring(order.id.length - 6).toUpperCase()}'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _cancelOrder(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Text('Are you sure you want to cancel order #${order.id.substring(order.id.length - 6).toUpperCase()}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Order'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement order cancellation
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Order #${order.id.substring(order.id.length - 6).toUpperCase()} cancelled'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _isLoading = true;
    });
    
    // TODO: Implement order data refresh from Firestore
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _isLoading = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Orders refreshed!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
