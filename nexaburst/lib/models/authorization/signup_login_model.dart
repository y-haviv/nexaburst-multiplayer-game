// nexaburst/lib/models/authorization/signup_login_model.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/model_view/user_data_view_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexaburst/models/structures/user_model.dart';

/// Manages user sign‑up and login via Firebase Auth and Firestore.
class SignupLoginModel {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Registers a new user with [email], [username], [password], [language], and [age].
  ///
  /// - Creates a Firebase Auth account.
  /// - Saves user profile to Firestore under `users/{uid}`.
  ///
  /// Returns `true` on success, or `false` on failure.
  Future<bool> signUp(
    /// User’s email address for authentication.
    String email,

    /// Desired display name to store in Firestore.
    String username,

    /// Password for the new account.
    String password,

    /// Preferred language code (e.g. 'en', 'he').
    String language,

    /// User’s age in years.
    int age,
  ) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      //if(userCredential.user == null) return false;
      await _db.collection("users").doc(userCredential.user?.uid).set({
        "id": userCredential.user!.uid, // Store UID explicitly
        "username": username,
        "email": email,
        "language": language,
        "age": age,
        "avatar": PicPaths.defaultAvatarPath,
        "wins": 0, // Default wins to 0
      });

      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        debugPrint("Error: This email is already in use.");
      } else {
        debugPrint("Error: ${e.message}");
      }
      return false;
    } catch (e) {
      debugPrint("Unexpected error: ${e.toString()}");
      return false;
    }
  }

  /// Authenticates an existing user with [email] and [password].
  ///
  /// On success, fetches the user’s Firestore profile and caches it locally.
  /// Returns `true` if login and data retrieval succeed, otherwise `false`.
  Future<bool> login(
    /// Email address of the user.
    String email,

    /// Password for the user’s account.
    String password,
  ) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // After successful login, fetch user data from Firestore and save locally
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(_auth.currentUser!.uid)
          .get();
      if (userDoc.exists) {
        UserModel user = UserModel.fromMap(userDoc.data()!);
        await UserData.instance.setUser(user);
      }

      return true; // Success
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }
}
