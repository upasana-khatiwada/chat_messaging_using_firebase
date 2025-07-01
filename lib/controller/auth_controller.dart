import 'package:chat_messaging_firebase/model/users.dart';
import 'package:chat_messaging_firebase/utils/consts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Convert Firebase User to custom Users model
  Users? _userFromFirebaseUser(User? user) {
    return user != null
        ? Users(
            uid: user.uid,
            name: user.displayName ?? 'User',
            email: user.email,
            image: user.photoURL ?? dummyProfile,
          )
        : null;
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<Users?> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }

  Future<void> _registerUserInFirestore(User user, {String? username}) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': username ?? user.displayName ?? 'User',
        'email': user.email,
        'profileImage': user.photoURL ?? dummyProfile,
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('User ${user.uid} registered in Firestore');
    } catch (e) {
      debugPrint('Error registering user in Firestore: $e');
    }
  }

  // Sign in with email and password
  Future<Users?> signInWithEmailAndPassword(String email, String password) async {
    try {
      debugPrint('Attempting to sign in with email: $email');
      
      // Validate inputs
      if (email.trim().isEmpty || password.isEmpty) {
        throw 'Email and password cannot be empty';
      }
      
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      debugPrint('Sign-in successful for user: ${result.user?.uid}');
      
      if (result.user != null) {
        // Update user online status without blocking the sign-in process
        _registerUserInFirestore(result.user!).catchError((error) {
          debugPrint('Non-critical error updating user in Firestore: $error');
        });
        
        return _userFromFirebaseUser(result.user);
      } else {
        throw 'Sign-in failed: No user returned';
      }
      
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException - Code: ${e.code}, Message: ${e.message}');
      throw _getAuthException(e);
    } catch (e) {
      debugPrint('Unexpected sign-in error: $e');
      throw e.toString().contains('Email and password cannot be empty') 
          ? e.toString() 
          : 'An unexpected error occurred during sign-in';
    }
  }

  // Sign up with email and password - MODIFIED to accept username
  Future<Users?> signUpWithEmailAndPassword(String email, String password, {String? username}) async {
    try {
      debugPrint('Attempting to create account with email: $email');
      
      // Validate inputs
      if (email.trim().isEmpty || password.isEmpty) {
        throw 'Email and password cannot be empty';
      }
      
      if (password.length < 6) {
        throw 'Password must be at least 6 characters long';
      }
      
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      debugPrint('Account created successfully for user: ${result.user?.uid}');
      
      if (result.user != null) {
        // Register user in Firestore with username
        await _registerUserInFirestore(result.user!, username: username);
        return _userFromFirebaseUser(result.user);
      } else {
        throw 'Account creation failed: No user returned';
      }
      
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during sign-up: Code: ${e.code}, Message: ${e.message}');
      throw _getAuthException(e);
    } catch (e) {
      debugPrint('Unexpected sign-up error: $e');
      if (e.toString().contains('Email and password cannot be empty') ||
          e.toString().contains('Password must be at least 6 characters')) {
        throw e.toString();
      }
      throw 'An unexpected error occurred during account creation';
    }
  }

  // Reset password
  Future<void> resetPass(String email) async {
    try {
      if (email.trim().isEmpty) {
        throw 'Email cannot be empty';
      }
      
      debugPrint('Sending password reset email to: $email');
      await _auth.sendPasswordResetEmail(email: email.trim());
      debugPrint('Password reset email sent successfully');
    } on FirebaseAuthException catch (e) {
      debugPrint('Password reset error: ${e.code} - ${e.message}');
      throw _getAuthException(e);
    } catch (e) {
      debugPrint('Unexpected password reset error: $e');
      if (e.toString().contains('Email cannot be empty')) {
        throw e.toString();
      }
      throw 'An unexpected error occurred while sending reset email';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      if (currentUser != null) {
        // Update user offline status
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'isOnline': false,
          'lastSeen': FieldValue.serverTimestamp(),
        }).catchError((error) {
          debugPrint('Error updating offline status: $error');
          // Don't throw, continue with sign out
        });
      }
      
      await _auth.signOut();
      debugPrint('User signed out successfully');
    } catch (e) {
      debugPrint('Sign-out error: $e');
      // Even if there's an error, try to sign out from Firebase Auth
      try {
        await _auth.signOut();
      } catch (finalError) {
        debugPrint('Final sign-out attempt failed: $finalError');
        throw 'Failed to sign out completely';
      }
    }
  }

  // Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  // Get user-friendly error messages
  String _getAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email address';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-credential':
        return 'Invalid email or password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password';
      case 'invalid-email':
        return 'Invalid email address format';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection';
      case 'internal-error':
        return 'Internal server error. Please try again later';
      case 'credential-already-in-use':
        return 'This credential is already associated with a different user account';
      case 'requires-recent-login':
        return 'Please sign out and sign in again to perform this action';
      default:
        debugPrint('Unhandled auth error code: ${e.code}');
        return e.message ?? 'An authentication error occurred';
    }
  }

  // Method to refresh user token (useful for long-running apps)
  Future<void> refreshUserToken() async {
    try {
      if (currentUser != null) {
        await currentUser!.getIdToken(true);
        debugPrint('User token refreshed');
      }
    } catch (e) {
      debugPrint('Error refreshing user token: $e');
    }
  }
}