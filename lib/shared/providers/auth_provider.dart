import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/firebase_service.dart';
import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService.instance;
  
  AuthState _authState = AuthState.initial;
  UserModel? _user;
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  AuthState get authState => _authState;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _authState == AuthState.authenticated && _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isCustomer => _user?.isCustomer ?? false;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    _firebaseService.authStateChanges.listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        await _loadUserData(firebaseUser.uid);
      } else {
        await _clearUserData();
      }
    });
  }

  Future<void> _loadUserData(String userId) async {
    try {
      _setLoading(true);
      
      final userDoc = await _firebaseService.usersCollection.doc(userId).get();
      
      if (userDoc.exists) {
        _user = UserModel.fromFirestore(userDoc);
        _authState = AuthState.authenticated;
        
        // Save user data locally
        await _saveUserDataLocally();
        
        // Set analytics user properties
        await _firebaseService.setUserId(userId);
        await _firebaseService.setUserProperty(name: 'user_role', value: _user!.role);
        
        _errorMessage = null;
      } else {
        // User document doesn't exist, create it
        await _createUserDocument(userId);
      }
    } catch (e) {
      _errorMessage = 'Failed to load user data: $e';
      _authState = AuthState.error;
      debugPrint('Error loading user data: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _createUserDocument(String userId) async {
    try {
      final firebaseUser = _firebaseService.currentUser;
      if (firebaseUser == null) return;

      final newUser = UserModel(
        id: userId,
        email: firebaseUser.email ?? '',
        firstName: firebaseUser.displayName?.split(' ').first ?? '',
        lastName: firebaseUser.displayName?.split(' ').skip(1).join(' ') ?? '',
        role: AppConstants.customerRole,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firebaseService.usersCollection.doc(userId).set(newUser.toMap());
      _user = newUser;
      _authState = AuthState.authenticated;
      
      await _saveUserDataLocally();
      
      // Log registration event
      await _firebaseService.logEvent(
        name: 'user_created',
        parameters: {'user_id': userId, 'user_role': newUser.role},
      );
      
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to create user profile: $e';
      _authState = AuthState.error;
      debugPrint('Error creating user document: $e');
    }
  }

  Future<void> _clearUserData() async {
    _user = null;
    _authState = AuthState.unauthenticated;
    _errorMessage = null;
    
    // Clear local data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userDataKey);
    await prefs.remove(AppConstants.userTokenKey);
    
    notifyListeners();
  }

  Future<void> _saveUserDataLocally() async {
    if (_user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userDataKey, _user!.toMap().toString());
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _authState = AuthState.error;
    _setLoading(false);
  }

  // Authentication methods
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await _firebaseService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      debugPrint('Sign in error: $e');
      return false;
    }
  }

  // Signup method that handles both customer and admin registration
  Future<bool> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String role = 'customer',
  }) async {
    return await createUserWithEmailAndPassword(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      role: role, // Pass the role to the creation method
    );
  }

  Future<bool> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String role = AppConstants.customerRole, // Add role parameter with default value
  }) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      final credential = await _firebaseService.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName('$firstName $lastName');
        
        // Create user document with additional info
        final newUser = UserModel(
          id: credential.user!.uid,
          email: email,
          firstName: firstName,
          lastName: lastName,
          phoneNumber: phoneNumber,
          role: role, // Use the provided role
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firebaseService.usersCollection
            .doc(credential.user!.uid)
            .set(newUser.toMap());

        return true;
      }
      
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      debugPrint('Registration error: $e');
      return false;
    }
  }

  Future<bool> signOut() async {
    try {
      _setLoading(true);
      await _firebaseService.signOut();
      return true;
    } catch (e) {
      _setError('Failed to sign out. Please try again.');
      debugPrint('Sign out error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendPasswordResetEmail({required String email}) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await _firebaseService.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      debugPrint('Password reset error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? address,
    String? city,
    String? region,
    String? profileImageUrl,
  }) async {
    if (_user == null) return false;

    try {
      _setLoading(true);
      _errorMessage = null;

      final updatedUser = _user!.copyWith(
        firstName: firstName ?? _user!.firstName,
        lastName: lastName ?? _user!.lastName,
        phoneNumber: phoneNumber ?? _user!.phoneNumber,
        address: address ?? _user!.address,
        city: city ?? _user!.city,
        region: region ?? _user!.region,
        profileImageUrl: profileImageUrl ?? _user!.profileImageUrl,
        updatedAt: DateTime.now(),
      );

      await _firebaseService.usersCollection
          .doc(_user!.id)
          .update(updatedUser.toMap());

      _user = updatedUser;
      await _saveUserDataLocally();
      
      // Log profile update event
      await _firebaseService.logEvent(
        name: 'profile_updated',
        parameters: {'user_id': _user!.id},
      );

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update profile. Please try again.');
      debugPrint('Profile update error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> uploadProfileImage(String imagePath) async {
    if (_user == null) return false;

    try {
      _setLoading(true);
      _errorMessage = null;

      // Upload image to Firebase Storage
      final imageUrl = await _firebaseService.uploadFile(
        path: '${AppConstants.userAvatarsPath}/${_user!.id}',
        file: imagePath,
        contentType: 'image/jpeg',
      );

      // Update user document
      final updatedUser = _user!.copyWith(
        profileImageUrl: imageUrl,
        updatedAt: DateTime.now(),
      );

      await _firebaseService.usersCollection
          .doc(_user!.id)
          .update({'profileImageUrl': imageUrl, 'updatedAt': Timestamp.now()});

      _user = updatedUser;
      await _saveUserDataLocally();
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to upload profile image. Please try again.');
      debugPrint('Profile image upload error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshUser() async {
    if (_firebaseService.currentUser != null) {
      await _loadUserData(_firebaseService.currentUser!.uid);
    }
  }

  void clearError() {
    _errorMessage = null;
    if (_authState == AuthState.error) {
      _authState = _user != null ? AuthState.authenticated : AuthState.unauthenticated;
    }
    notifyListeners();
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return e.message ?? 'An unexpected error occurred.';
    }
  }

  // No need to override dispose() as the parent implementation is sufficient
}
