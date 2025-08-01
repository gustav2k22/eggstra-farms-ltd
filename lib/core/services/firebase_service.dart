import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:eggstra_farms_ltd/firebase_options.dart';

class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();
  FirebaseService._();

  // Firebase instances
  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  FirebaseStorage get storage => FirebaseStorage.instance;
  FirebaseAnalytics get analytics => FirebaseAnalytics.instance;
  FirebaseCrashlytics get crashlytics => FirebaseCrashlytics.instance;

  // Initialize Firebase
  static Future<void> initialize() async {
    try {
      // Initialize Firebase with options from the generated firebase_options.dart file
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      
      // Configure Firestore settings
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      // Configure Crashlytics after Firebase is initialized
      if (kReleaseMode) {
        FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      }

      // Use debugPrint which is stripped in release mode or a proper logging library
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
      // Don't try to use Crashlytics if Firebase initialization failed
      // as it would cause another error
      debugPrint('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Auth methods
  User? get currentUser => auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  String? get currentUserId => currentUser?.uid;

  Stream<User?> get authStateChanges => auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await analytics.logLogin(loginMethod: 'email');
      return credential;
    } on FirebaseAuthException catch (e) {
      await crashlytics.recordError(e, null);
      throw _handleAuthException(e);
    }
  }

  // Register with email and password
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await analytics.logSignUp(signUpMethod: 'email');
      return credential;
    } on FirebaseAuthException catch (e) {
      await crashlytics.recordError(e, null);
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await auth.signOut();
      await analytics.logEvent(name: 'logout');
    } catch (e) {
      await crashlytics.recordError(e, null);
      rethrow;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      await crashlytics.recordError(e, null);
      throw _handleAuthException(e);
    }
  }

  // Update password
  Future<void> updatePassword({required String newPassword}) async {
    try {
      await currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      await crashlytics.recordError(e, null);
      throw _handleAuthException(e);
    }
  }

  // Update email
  Future<void> updateEmail({required String newEmail}) async {
    try {
      await currentUser?.verifyBeforeUpdateEmail(newEmail);
    } on FirebaseAuthException catch (e) {
      await crashlytics.recordError(e, null);
      throw _handleAuthException(e);
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      await currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      await crashlytics.recordError(e, null);
      throw _handleAuthException(e);
    }
  }

  // Firestore methods
  CollectionReference get usersCollection => firestore.collection('users');
  CollectionReference get productsCollection => firestore.collection('products');
  CollectionReference get categoriesCollection => firestore.collection('categories');
  CollectionReference get ordersCollection => firestore.collection('orders');
  CollectionReference get cartCollection => firestore.collection('cart');
  CollectionReference get reviewsCollection => firestore.collection('reviews');

  // Storage methods
  Reference getStorageRef(String path) => storage.ref().child(path);

  Future<String> uploadFile({
    required String path,
    required dynamic file,
    String? contentType,
  }) async {
    try {
      final ref = getStorageRef(path);
      final uploadTask = await ref.putData(file, SettableMetadata(
        contentType: contentType,
      ));
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      await crashlytics.recordError(e, null);
      rethrow;
    }
  }

  Future<void> deleteFile(String path) async {
    try {
      await getStorageRef(path).delete();
    } catch (e) {
      await crashlytics.recordError(e, null);
      rethrow;
    }
  }

  // Analytics methods
  Future<void> logEvent({
    required String name,
    Map<String, Object?>? parameters,
  }) async {
    try {
      await analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      await crashlytics.recordError(e, null);
    }
  }

  Future<void> setUserId(String userId) async {
    try {
      await analytics.setUserId(id: userId);
      await crashlytics.setUserIdentifier(userId);
    } catch (e) {
      await crashlytics.recordError(e, null);
    }
  }

  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    try {
      await analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      await crashlytics.recordError(e, null);
    }
  }

  // Error handling
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return e.message ?? 'An unknown error occurred.';
    }
  }

  // Batch operations
  WriteBatch batch() => firestore.batch();

  Future<void> commitBatch(WriteBatch batch) async {
    try {
      await batch.commit();
    } catch (e) {
      await crashlytics.recordError(e, null);
      rethrow;
    }
  }

  // Transaction
  Future<T> runTransaction<T>(
    TransactionHandler<T> updateFunction, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      return await firestore.runTransaction(updateFunction, timeout: timeout);
    } catch (e) {
      await crashlytics.recordError(e, null);
      rethrow;
    }
  }

  // Utility methods
  Future<bool> checkInternetConnection() async {
    try {
      await firestore.enableNetwork();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> enableOfflineMode() async {
    try {
      await firestore.disableNetwork();
    } catch (e) {
      await crashlytics.recordError(e, null);
    }
  }

  Future<void> enableOnlineMode() async {
    try {
      await firestore.enableNetwork();
    } catch (e) {
      await crashlytics.recordError(e, null);
    }
  }
}
