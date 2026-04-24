import 'package:cloud_firestore/cloud_firestore.dart';

class AppTeam {
  const AppTeam({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.memberUids,
  });

  final String id;
  final String name;
  final String ownerUid;
  final List<String> memberUids;

  bool isOwner(String uid) => ownerUid == uid;

  factory AppTeam.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    final memberUids = (data['memberUids'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList();

    return AppTeam(
      id: snapshot.id,
      name: (data['name'] as String? ?? 'Untitled Team').trim(),
      ownerUid: data['ownerUid'] as String? ?? '',
      memberUids: memberUids,
    );
  }
}

class TeamRepository {
  TeamRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _teams =>
      _firestore.collection('teams');

  Stream<List<AppTeam>> watchUserTeams(String uid) {
    return _teams.where('memberUids', arrayContains: uid).snapshots().map((
      snapshot,
    ) {
      final teams = snapshot.docs.map(AppTeam.fromSnapshot).toList();
      teams.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return teams;
    });
  }

  Future<void> createTeam({
    required String name,
    required String ownerUid,
  }) async {
    final trimmedName = name.trim();
    await _teams.add({
      'name': trimmedName,
      'nameLower': trimmedName.toLowerCase(),
      'ownerUid': ownerUid,
      'memberUids': [ownerUid],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateTeam({
    required String teamId,
    required String name,
  }) async {
    final trimmedName = name.trim();
    await _teams.doc(teamId).update({
      'name': trimmedName,
      'nameLower': trimmedName.toLowerCase(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteTeam(String teamId) async {
    await _teams.doc(teamId).delete();
  }
}
