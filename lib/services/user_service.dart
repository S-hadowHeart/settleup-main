import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/app_user.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  Stream<AppUser?> watchUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return AppUser.fromMap(snap.id, snap.data()!);
    });
  }

  Future<void> createUser(AppUser user) {
    return _db.collection('users').doc(user.id).set(user.toMap());
  }

  Future<void> updateEmoji(String uid, String emoji) {
    return _db.collection('users').doc(uid).update({'emoji': emoji});
  }

  Future<void> updateName(String uid, String name) {
    return _db.collection('users').doc(uid).update({'name': name});
  }

  Future<String> uploadAvatar(String uid, File file) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('avatars')
        .child('$uid.jpg');

    await ref.putFile(file);
    final url = await ref.getDownloadURL();
    await _db.collection('users').doc(uid).update({'avatarUrl': url});
    return url;
  }
}
