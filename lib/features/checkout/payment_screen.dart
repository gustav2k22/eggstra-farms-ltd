import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/payment_service.dart';
import '../../shared/providers/cart_provider.dart';
import '../../shared/models/cart_model.dart';
import '../../shared/providers/order_provider.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/loading_overlay.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> deliveryAddress;
  final String? notes;

  const PaymentScreen({
    super.key,
    required this.deliveryAddress,
    this.notes,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  final PaymentService _paymentService = PaymentService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  PaymentMethod _selectedPaymentMethod = PaymentMethod.mobileMoneyMTN;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _errors = {};
  bool _isProcessing = false;
  bool _paymentSuccess = false;
  PaymentResult? _paymentResult;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeControllers();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  void _initializeControllers() {
    _controllers['phoneNumber'] = TextEditingController();
    _controllers['cardNumber'] = TextEditingController();
    _controllers['expiryDate'] = TextEditingController();
    _controllers['cvv'] = TextEditingController();
    _controllers['cardholderName'] = TextEditingController();
    _controllers['accountNumber'] = TextEditingController();
    _controllers['bankName'] = TextEditingController();
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: _paymentSuccess ? _buildSuccessScreen() : _buildPaymentForm(),
    );
  }

  Widget _buildPaymentForm() {
    return Consumer3<CartProvider, OrderProvider, AuthProvider>(
      builder: (context, cartProvider, orderProvider, authProvider, child) {
        return LoadingOverlay(
          isLoading: _isProcessing,
          message: 'Processing payment...',
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOrderSummary(cartProvider),
                    const SizedBox(height: 24),
                    _buildPaymentMethodSelection(),
                    const SizedBox(height: 24),
                    _buildPaymentDetails(),
                    const SizedBox(height: 32),
                    _buildPaymentButton(cartProvider, orderProvider, authProvider),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderSummary(CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Subtotal', 'GHS ${cartProvider.subtotal.toStringAsFixed(2)}'),
          _buildSummaryRow('Tax', 'GHS ${cartProvider.tax.toStringAsFixed(2)}'),
          _buildSummaryRow('Delivery Fee', 'GHS ${cartProvider.deliveryFee.toStringAsFixed(2)}'),
          if (cartProvider.discount > 0)
            _buildSummaryRow('Discount', '-GHS ${cartProvider.discount.toStringAsFixed(2)}', isDiscount: true),
          const Divider(height: 24),
          _buildSummaryRow(
            'Total',
            'GHS ${cartProvider.total.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isDiscount ? AppColors.success : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...PaymentMethod.values.map((method) => _buildPaymentMethodTile(method)),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(PaymentMethod method) {
    final isSelected = _selectedPaymentMethod == method;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
          _errors.clear();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 26) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.inputBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              _paymentService.getPaymentMethodIcon(method),
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _paymentService.getPaymentMethodDisplayName(method),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ..._buildPaymentFields(),
        ],
      ),
    );
  }

  List<Widget> _buildPaymentFields() {
    switch (_selectedPaymentMethod) {
      case PaymentMethod.mobileMoneyMTN:
      case PaymentMethod.mobileMoneyVodafone:
      case PaymentMethod.mobileMoneyAirtelTigo:
        return [
          CustomTextField(
            controller: _controllers['phoneNumber']!,
            label: 'Phone Number',
            hint: 'Enter your mobile money number',
            keyboardType: TextInputType.phone,
            errorText: _errors['phoneNumber'],
            prefixIcon: Icons.phone,
          ),
        ];

      case PaymentMethod.creditCard:
      case PaymentMethod.debitCard:
        return [
          CustomTextField(
            controller: _controllers['cardNumber']!,
            label: 'Card Number',
            hint: '1234 5678 9012 3456',
            keyboardType: TextInputType.number,
            errorText: _errors['cardNumber'],
            prefixIcon: Icons.credit_card,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _controllers['expiryDate']!,
                  label: 'Expiry Date',
                  hint: 'MM/YY',
                  keyboardType: TextInputType.number,
                  errorText: _errors['expiryDate'],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  controller: _controllers['cvv']!,
                  label: 'CVV',
                  hint: '123',
                  keyboardType: TextInputType.number,
                  errorText: _errors['cvv'],
                  obscureText: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _controllers['cardholderName']!,
            label: 'Cardholder Name',
            hint: 'Enter name on card',
            errorText: _errors['cardholderName'],
            prefixIcon: Icons.person,
          ),
        ];

      case PaymentMethod.bankTransfer:
        return [
          CustomTextField(
            controller: _controllers['accountNumber']!,
            label: 'Account Number',
            hint: 'Enter your account number',
            keyboardType: TextInputType.number,
            errorText: _errors['accountNumber'],
            prefixIcon: Icons.account_balance,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _controllers['bankName']!,
            label: 'Bank Name',
            hint: 'Select your bank',
            errorText: _errors['bankName'],
            prefixIcon: Icons.business,
          ),
        ];

      case PaymentMethod.cashOnDelivery:
        return [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You will pay cash when your order is delivered.',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ];
    }
  }

  Widget _buildPaymentButton(CartProvider cartProvider, OrderProvider orderProvider, AuthProvider authProvider) {
    return CustomButton(
      text: _selectedPaymentMethod == PaymentMethod.cashOnDelivery
          ? 'Place Order'
          : 'Pay GHS ${cartProvider.total.toStringAsFixed(2)}',
      onPressed: () => _processPayment(cartProvider, orderProvider, authProvider),
      isLoading: _isProcessing,
      variant: ButtonVariant.primary,
    );
  }

  Future<void> _processPayment(CartProvider cartProvider, OrderProvider orderProvider, AuthProvider authProvider) async {
    if (!_validatePaymentDetails()) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final user = authProvider.user;
      if (user == null) {
        _showErrorDialog('Please log in to continue');
        return;
      }

      // Create order first
      final orderId = await orderProvider.placeOrder(
        userId: user.id,
        cart: cartProvider.cart ?? CartModel(
          id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
          userId: user.id,
          items: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        deliveryAddress: widget.deliveryAddress,
        paymentMethod: _paymentService.getPaymentMethodDisplayName(_selectedPaymentMethod),
        notes: widget.notes,
      );

      if (orderId == null) {
        _showErrorDialog('Failed to create order. Please try again.');
        return;
      }

      // Process payment (simulation)
      final paymentDetails = _getPaymentDetails();
      final paymentResult = await _paymentService.processPayment(
        orderId: orderId,
        amount: cartProvider.total,
        paymentMethod: _selectedPaymentMethod,
        paymentDetails: paymentDetails,
      );

      setState(() {
        _paymentResult = paymentResult;
        _paymentSuccess = paymentResult.status == PaymentStatus.success;
      });

      if (_paymentSuccess) {
        // Update payment status in order
        await orderProvider.updatePaymentStatus(orderId, 'paid');
        
        // Clear cart
        await cartProvider.clearCart();
        
        // Show success animation
        _showSuccessAnimation();
      } else {
        _showErrorDialog(_paymentResult!.message);
      }

    } catch (e) {
      _showErrorDialog('Payment processing failed. Please try again.');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  bool _validatePaymentDetails() {
    _errors.clear();
    final paymentDetails = _getPaymentDetails();
    
    if (!_paymentService.validatePaymentDetails(_selectedPaymentMethod, paymentDetails)) {
      switch (_selectedPaymentMethod) {
        case PaymentMethod.mobileMoneyMTN:
        case PaymentMethod.mobileMoneyVodafone:
        case PaymentMethod.mobileMoneyAirtelTigo:
          if (_controllers['phoneNumber']!.text.isEmpty) {
            _errors['phoneNumber'] = 'Phone number is required';
          }
          break;
        case PaymentMethod.creditCard:
        case PaymentMethod.debitCard:
          if (_controllers['cardNumber']!.text.isEmpty) {
            _errors['cardNumber'] = 'Card number is required';
          }
          if (_controllers['expiryDate']!.text.isEmpty) {
            _errors['expiryDate'] = 'Expiry date is required';
          }
          if (_controllers['cvv']!.text.isEmpty) {
            _errors['cvv'] = 'CVV is required';
          }
          if (_controllers['cardholderName']!.text.isEmpty) {
            _errors['cardholderName'] = 'Cardholder name is required';
          }
          break;
        case PaymentMethod.bankTransfer:
          if (_controllers['accountNumber']!.text.isEmpty) {
            _errors['accountNumber'] = 'Account number is required';
          }
          if (_controllers['bankName']!.text.isEmpty) {
            _errors['bankName'] = 'Bank name is required';
          }
          break;
        case PaymentMethod.cashOnDelivery:
          break;
      }
      
      setState(() {});
      return false;
    }
    
    return true;
  }

  Map<String, dynamic> _getPaymentDetails() {
    switch (_selectedPaymentMethod) {
      case PaymentMethod.mobileMoneyMTN:
      case PaymentMethod.mobileMoneyVodafone:
      case PaymentMethod.mobileMoneyAirtelTigo:
        return {'phoneNumber': _controllers['phoneNumber']!.text};
      case PaymentMethod.creditCard:
      case PaymentMethod.debitCard:
        return {
          'cardNumber': _controllers['cardNumber']!.text,
          'expiryDate': _controllers['expiryDate']!.text,
          'cvv': _controllers['cvv']!.text,
          'cardholderName': _controllers['cardholderName']!.text,
        };
      case PaymentMethod.bankTransfer:
        return {
          'accountNumber': _controllers['accountNumber']!.text,
          'bankName': _controllers['bankName']!.text,
        };
      case PaymentMethod.cashOnDelivery:
        return {};
    }
  }

  void _showSuccessAnimation() {
    _animationController.reset();
    _animationController.forward();
  }

  void _showErrorDialog(String message) {
    // Only show dialog if widget is still mounted
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _fadeAnimation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Payment Successful!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _paymentResult?.message ?? 'Your order has been placed successfully.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (_paymentResult != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Transaction ID',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _paymentResult!.transactionId,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              CustomButton(
                text: 'Continue Shopping',
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                variant: ButtonVariant.primary,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'View Orders',
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  // Navigate to orders screen
                },
                variant: ButtonVariant.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
