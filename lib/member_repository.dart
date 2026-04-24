import 'package:cloud_firestore/cloud_firestore.dart';

class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    required this.voiceType,
    required this.angkatan,
    required this.phone,
  });

  final String id;
  final String name;
  final String voiceType;
  final String angkatan;
  final String phone;

  factory TeamMember.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};

    return TeamMember(
      id: snapshot.id,
      name: data['name'] as String? ?? '',
      voiceType: data['voiceType'] as String? ?? '',
      angkatan: data['angkatan'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'nameLower': name.toLowerCase(),
      'voiceType': voiceType,
      'angkatan': angkatan,
      'phone': phone,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class MemberRepository {
  MemberRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _members(String teamId) {
    return _firestore.collection('teams').doc(teamId).collection('members');
  }

  Stream<List<TeamMember>> watchTeamMembers(String teamId) {
    return _members(teamId).snapshots().map((snapshot) {
      final members = snapshot.docs.map(TeamMember.fromSnapshot).toList();
      members.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return members;
    });
  }

  Future<void> createMember({
    required String teamId,
    required TeamMember member,
  }) async {
    await _members(
      teamId,
    ).add({...member.toFirestore(), 'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> updateMember({
    required String teamId,
    required TeamMember member,
  }) async {
    await _members(teamId).doc(member.id).update(member.toFirestore());
  }

  Future<void> deleteMember({
    required String teamId,
    required String memberId,
  }) async {
    await _members(teamId).doc(memberId).delete();
  }
}
