import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRepository {
  const UserRepository();

  Future<void> upsertUserProfile(
    User user, {
    String? name,
    bool includeCreatedAt = false,
  }) async {
    final trimmedName = name?.trim();
    final authName = user.displayName?.trim();
    final resolvedName = trimmedName != null && trimmedName.isNotEmpty
        ? trimmedName
        : authName;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      if (resolvedName != null && resolvedName.isNotEmpty) 'name': resolvedName,
      'photoUrl': user.photoURL,
      'updatedAt': FieldValue.serverTimestamp(),
      if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
