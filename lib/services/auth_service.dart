import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _fire = FirebaseFirestore.instance;

  Stream<User?> get authState => _auth.authStateChanges();

  Future<User?> signIn(String email, String password) async {
    final res = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return res.user;
  }

  Future<User?> signUp(String email, String password) async {
    final res = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = res.user!.uid;

    await _fire.collection('users').doc(uid).set({
      'name': email.split('@')[0],
      'email': email,
      'emoji': '🙂',
      'avatarUrl': null,
    });

    return res.user;
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> updatePassword(String newPassword) =>
      _auth.currentUser!.updatePassword(newPassword);
}
