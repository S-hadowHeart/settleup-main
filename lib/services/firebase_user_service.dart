import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/app_user.dart';

class FirebaseUserService {
  final _auth = FirebaseAuth.instance;
  final _fire = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  Future<AppUser> loadUser() async {
    final uid = _auth.currentUser!.uid;
    final docRef = _fire.collection('users').doc(uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      final newUser = AppUser(
        id: uid,
        name: _auth.currentUser!.email!.split('@')[0],
        email: _auth.currentUser!.email!,
        emoji: "🙂",
        avatarUrl: null,
      );

      await docRef.set(newUser.toMap());
      return newUser;
    }

    return AppUser.fromMap(uid, doc.data()!);
  }

  Future<void> updateName(String newName) async {
    final uid = _auth.currentUser!.uid;
    await _fire.collection('users').doc(uid).update({'name': newName});
  }

  Future<void> updateEmoji(String emoji) async {
    final uid = _auth.currentUser!.uid;
    await _fire.collection('users').doc(uid).update({'emoji': emoji});
  }

  Future<String> uploadAvatar(File file) async {
    final uid = _auth.currentUser!.uid;

    final ref = _storage.ref().child("avatars/$uid.jpg");
    await ref.putFile(file);

    final url = await ref.getDownloadURL();

    await _fire.collection('users').doc(uid).update({'avatarUrl': url});
    return url;
  }

  Future<void> changePassword(String newPass) async {
    await _auth.currentUser!.updatePassword(newPass);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
