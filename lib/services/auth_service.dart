import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<Map<String, dynamic>> signUp({
    required String name,
    required String email,
    required String password,
    required String cnic,
  }) async {
    try {
      // Create user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name in Firebase Auth
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(name.trim());
      }

      // Create user profile in Firestore
      if (userCredential.user != null) {
        try {
          UserModel userModel = UserModel(
            uid: userCredential.user!.uid,
            email: email.trim(),
            cnic: cnic.trim(),
            displayName: name.trim(),
            createdAt: DateTime.now(),
          );

          await _firestoreService.createUserProfile(userModel);
        } catch (firestoreError) {
          // If Firestore fails, still return success since Auth worked
          print('Firestore error: $firestoreError');
          return {
            'success': true,
            'message': 'Account created successfully',
            'user': userCredential.user,
          };
        }
      }

      return {
        'success': true,
        'message': 'Account created successfully',
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          message = 'An account already exists for that email.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        default:
          message = 'An error occurred. Please try again.';
      }
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      print('Unexpected error in signUp: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  // Sign in with email and password
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      return {
        'success': true,
        'message': 'Signed in successfully',
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found for that email.';
          break;
        case 'wrong-password':
          message = 'Wrong password provided.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        case 'user-disabled':
          message = 'This user account has been disabled.';
          break;
        case 'invalid-credential':
          message = 'Invalid email or password.';
          break;
        default:
          message = 'An error occurred. Please try again.';
      }
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred.',
      };
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Error signing out');
    }
  }

  // Reset password
  Future<Map<String, dynamic>> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return {
        'success': true,
        'message': 'Password reset email sent. Check your inbox.',
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found for that email.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        default:
          message = 'An error occurred. Please try again.';
      }
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred.',
      };
    }
  }

  // Delete account
  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final uid = _auth.currentUser?.uid;
      
      // Delete user profile from Firestore first
      if (uid != null) {
        await _firestoreService.deleteUserProfile(uid);
      }
      
      // Then delete auth account
      await _auth.currentUser?.delete();
      
      return {
        'success': true,
        'message': 'Account deleted successfully',
      };
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'requires-recent-login') {
        message = 'Please log in again before deleting your account.';
      } else {
        message = 'An error occurred. Please try again.';
      }
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred.',
      };
    }
  }

  // Get current user profile from Firestore
  Future<UserModel?> getCurrentUserProfile() async {
    try {
      if (_auth.currentUser != null) {
        return await _firestoreService.getUserProfile(_auth.currentUser!.uid);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting user profile: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    try {
      if (_auth.currentUser != null) {
        await _firestoreService.updateUserProfile(_auth.currentUser!.uid, updates);
      }
    } catch (e) {
      throw Exception('Error updating user profile: $e');
    }
  }
}
