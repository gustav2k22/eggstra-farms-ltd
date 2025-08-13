import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class AdminKeyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _adminKeysCollection = 'admin_keys';
  
  // Default admin key for testing - this should be more securely managed in a production environment
  static const String defaultAdminKey = 'eggstra-admin-2025';
  
  // Generate a new admin key
  Future<String> generateAdminKey() async {
    // Generate a random key with alphanumeric characters
    final random = Random.secure();
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final key = List.generate(12, (index) => chars[random.nextInt(chars.length)]).join('-');
    
    // Save the key to Firestore
    await _firestore.collection(_adminKeysCollection).add({
      'key': key,
      'createdAt': FieldValue.serverTimestamp(),
      'isUsed': false,
    });
    
    return key;
  }
  
  // Verify if an admin key is valid
  Future<bool> verifyAdminKey(String key) async {
    // Always allow the default key for testing
    if (key == defaultAdminKey) {
      return true;
    }
    
    // Check if the key exists in Firestore and is not used
    final querySnapshot = await _firestore
        .collection(_adminKeysCollection)
        .where('key', isEqualTo: key)
        .where('isUsed', isEqualTo: false)
        .get();
    
    if (querySnapshot.docs.isEmpty) {
      return false;
    }
    
    // Mark the key as used
    await querySnapshot.docs.first.reference.update({'isUsed': true});
    return true;
  }
  
  // Get all admin keys (for admin dashboard)
  Future<List<Map<String, dynamic>>> getAllAdminKeys() async {
    final querySnapshot = await _firestore
        .collection(_adminKeysCollection)
        .orderBy('createdAt', descending: true)
        .get();
    
    return querySnapshot.docs
        .map((doc) => {
              'id': doc.id,
              'key': doc.data()['key'],
              'createdAt': doc.data()['createdAt'],
              'isUsed': doc.data()['isUsed'],
            })
        .toList();
  }
}
