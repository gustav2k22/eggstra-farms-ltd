import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';

enum PaymentMethod {
  mobileMoneyMTN,
  mobileMoneyVodafone,
  mobileMoneyAirtelTigo,
  creditCard,
  debitCard,
  bankTransfer,
  cashOnDelivery,
}

enum PaymentStatus {
  pending,
  processing,
  success,
  failed,
  cancelled,
  refunded,
}

class PaymentResult {
  final String transactionId;
  final PaymentStatus status;
  final String message;
  final double amount;
  final String? errorCode;
  final DateTime timestamp;

  PaymentResult({
    required this.transactionId,
    required this.status,
    required this.message,
    required this.amount,
    this.errorCode,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'transactionId': transactionId,
      'status': status.name,
      'message': message,
      'amount': amount,
      'errorCode': errorCode,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory PaymentResult.fromMap(Map<String, dynamic> map) {
    return PaymentResult(
      transactionId: map['transactionId'] ?? '',
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PaymentStatus.failed,
      ),
      message: map['message'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      errorCode: map['errorCode'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final FirebaseService _firebaseService = FirebaseService.instance;
  final Random _random = Random();

  // Simulate payment processing
  Future<PaymentResult> processPayment({
    required String orderId,
    required double amount,
    required PaymentMethod paymentMethod,
    required Map<String, dynamic> paymentDetails,
  }) async {
    try {
      final transactionId = _generateTransactionId();
      
      // Log payment attempt
      await _firebaseService.logEvent(
        name: 'payment_initiated',
        parameters: {
          'order_id': orderId,
          'amount': amount,
          'payment_method': paymentMethod.name,
          'transaction_id': transactionId,
        },
      );

      // Simulate processing delay
      await Future.delayed(Duration(seconds: 2 + _random.nextInt(3)));

      // Simulate payment result (90% success rate)
      final isSuccess = _random.nextDouble() < 0.9;
      
      PaymentResult result;
      
      if (isSuccess) {
        result = PaymentResult(
          transactionId: transactionId,
          status: PaymentStatus.success,
          message: _getSuccessMessage(paymentMethod),
          amount: amount,
          timestamp: DateTime.now(),
        );
      } else {
        result = PaymentResult(
          transactionId: transactionId,
          status: PaymentStatus.failed,
          message: _getFailureMessage(paymentMethod),
          amount: amount,
          errorCode: _getRandomErrorCode(),
          timestamp: DateTime.now(),
        );
      }

      // Store payment result
      await _storePaymentResult(orderId, result);
      
      // Log payment result
      await _firebaseService.logEvent(
        name: 'payment_completed',
        parameters: {
          'order_id': orderId,
          'transaction_id': transactionId,
          'status': result.status.name,
          'amount': amount,
          'payment_method': paymentMethod.name,
        },
      );

      return result;
      
    } catch (e) {
      debugPrint('Payment processing error: $e');
      
      return PaymentResult(
        transactionId: _generateTransactionId(),
        status: PaymentStatus.failed,
        message: 'Payment processing failed. Please try again.',
        amount: amount,
        errorCode: 'SYSTEM_ERROR',
        timestamp: DateTime.now(),
      );
    }
  }

  // Simulate payment verification
  Future<PaymentResult?> verifyPayment(String transactionId) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      // In a real implementation, this would query the payment provider
      // For simulation, we'll check our stored results
      final doc = await _firebaseService.firestore
          .collection('payment_results')
          .doc(transactionId)
          .get();
      
      if (doc.exists) {
        return PaymentResult.fromMap(doc.data()!);
      }
      
      return null;
    } catch (e) {
      debugPrint('Payment verification error: $e');
      return null;
    }
  }

  // Simulate refund processing
  Future<PaymentResult> processRefund({
    required String originalTransactionId,
    required double refundAmount,
    required String reason,
  }) async {
    try {
      final refundTransactionId = _generateTransactionId();
      
      // Simulate processing delay
      await Future.delayed(const Duration(seconds: 2));

      // Simulate refund result (95% success rate)
      final isSuccess = _random.nextDouble() < 0.95;
      
      PaymentResult result;
      
      if (isSuccess) {
        result = PaymentResult(
          transactionId: refundTransactionId,
          status: PaymentStatus.refunded,
          message: 'Refund processed successfully. Amount will be credited within 3-5 business days.',
          amount: refundAmount,
          timestamp: DateTime.now(),
        );
      } else {
        result = PaymentResult(
          transactionId: refundTransactionId,
          status: PaymentStatus.failed,
          message: 'Refund processing failed. Please contact support.',
          amount: refundAmount,
          errorCode: 'REFUND_FAILED',
          timestamp: DateTime.now(),
        );
      }

      // Store refund result
      await _storePaymentResult(originalTransactionId, result);
      
      // Log refund
      await _firebaseService.logEvent(
        name: 'refund_processed',
        parameters: {
          'original_transaction_id': originalTransactionId,
          'refund_transaction_id': refundTransactionId,
          'amount': refundAmount,
          'status': result.status.name,
          'reason': reason,
        },
      );

      return result;
      
    } catch (e) {
      debugPrint('Refund processing error: $e');
      
      return PaymentResult(
        transactionId: _generateTransactionId(),
        status: PaymentStatus.failed,
        message: 'Refund processing failed. Please contact support.',
        amount: refundAmount,
        errorCode: 'SYSTEM_ERROR',
        timestamp: DateTime.now(),
      );
    }
  }

  // Get supported payment methods
  List<PaymentMethod> getSupportedPaymentMethods() {
    return PaymentMethod.values;
  }

  // Get payment method display name
  String getPaymentMethodDisplayName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.mobileMoneyMTN:
        return 'MTN Mobile Money';
      case PaymentMethod.mobileMoneyVodafone:
        return 'Vodafone Cash';
      case PaymentMethod.mobileMoneyAirtelTigo:
        return 'AirtelTigo Money';
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.cashOnDelivery:
        return 'Cash on Delivery';
    }
  }

  // Get payment method icon
  String getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.mobileMoneyMTN:
        return '📱';
      case PaymentMethod.mobileMoneyVodafone:
        return '📱';
      case PaymentMethod.mobileMoneyAirtelTigo:
        return '📱';
      case PaymentMethod.creditCard:
        return '💳';
      case PaymentMethod.debitCard:
        return '💳';
      case PaymentMethod.bankTransfer:
        return '🏦';
      case PaymentMethod.cashOnDelivery:
        return '💵';
    }
  }

  // Validate payment details
  bool validatePaymentDetails(PaymentMethod method, Map<String, dynamic> details) {
    switch (method) {
      case PaymentMethod.mobileMoneyMTN:
      case PaymentMethod.mobileMoneyVodafone:
      case PaymentMethod.mobileMoneyAirtelTigo:
        return details['phoneNumber'] != null && 
               details['phoneNumber'].toString().isNotEmpty;
      
      case PaymentMethod.creditCard:
      case PaymentMethod.debitCard:
        return details['cardNumber'] != null &&
               details['expiryDate'] != null &&
               details['cvv'] != null &&
               details['cardholderName'] != null;
      
      case PaymentMethod.bankTransfer:
        return details['accountNumber'] != null &&
               details['bankName'] != null;
      
      case PaymentMethod.cashOnDelivery:
        return true; // No validation needed for COD
    }
  }

  // Private helper methods
  String _generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = _random.nextInt(9999).toString().padLeft(4, '0');
    return 'TXN_$timestamp$randomSuffix';
  }

  String _getSuccessMessage(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.mobileMoneyMTN:
        return 'Payment successful via MTN Mobile Money';
      case PaymentMethod.mobileMoneyVodafone:
        return 'Payment successful via Vodafone Cash';
      case PaymentMethod.mobileMoneyAirtelTigo:
        return 'Payment successful via AirtelTigo Money';
      case PaymentMethod.creditCard:
        return 'Credit card payment processed successfully';
      case PaymentMethod.debitCard:
        return 'Debit card payment processed successfully';
      case PaymentMethod.bankTransfer:
        return 'Bank transfer initiated successfully';
      case PaymentMethod.cashOnDelivery:
        return 'Order confirmed. Pay cash on delivery';
    }
  }

  String _getFailureMessage(PaymentMethod method) {
    final messages = [
      'Insufficient funds',
      'Payment declined by provider',
      'Network timeout',
      'Invalid payment details',
      'Service temporarily unavailable',
    ];
    return messages[_random.nextInt(messages.length)];
  }

  String _getRandomErrorCode() {
    final codes = [
      'INSUFFICIENT_FUNDS',
      'PAYMENT_DECLINED',
      'NETWORK_ERROR',
      'INVALID_DETAILS',
      'SERVICE_UNAVAILABLE',
      'TIMEOUT_ERROR',
    ];
    return codes[_random.nextInt(codes.length)];
  }

  Future<void> _storePaymentResult(String orderId, PaymentResult result) async {
    try {
      await _firebaseService.firestore
          .collection('payment_results')
          .doc(result.transactionId)
          .set({
        ...result.toMap(),
        'orderId': orderId,
      });
    } catch (e) {
      debugPrint('Error storing payment result: $e');
    }
  }
}
