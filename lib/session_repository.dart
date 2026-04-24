import 'package:cloud_firestore/cloud_firestore.dart';

class TeamSession {
  const TeamSession({
    required this.id,
    required this.dayDate,
    required this.location,
    required this.activity,
    required this.startTime,
    required this.endTime,
  });

  final String id;
  final String dayDate;
  final String location;
  final String activity;
  final String startTime;
  final String endTime;

  factory TeamSession.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};

    return TeamSession(
      id: snapshot.id,
      dayDate: data['dayDate'] as String? ?? '',
      location: data['location'] as String? ?? '',
      activity: data['activity'] as String? ?? '',
      startTime: data['startTime'] as String? ?? '',
      endTime: data['endTime'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'dayDate': dayDate,
      'location': location,
      'activity': activity,
      'startTime': startTime,
      'endTime': endTime,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class SessionRepository {
  SessionRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _sessions(String teamId) {
    return _firestore.collection('teams').doc(teamId).collection('sessions');
  }

  Stream<List<TeamSession>> watchTeamSessions(String teamId) {
    return _sessions(
      teamId,
    ).orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map(TeamSession.fromSnapshot).toList();
    });
  }

  Future<List<TeamSession>> fetchTeamSessions(String teamId) async {
    final snapshot = await _sessions(
      teamId,
    ).orderBy('createdAt', descending: true).get();
    return snapshot.docs.map(TeamSession.fromSnapshot).toList();
  }

  Future<TeamSession> createSession({
    required String teamId,
    required TeamSession session,
  }) async {
    final document = _sessions(teamId).doc();
    final savedSession = TeamSession(
      id: document.id,
      dayDate: session.dayDate,
      location: session.location,
      activity: session.activity,
      startTime: session.startTime,
      endTime: session.endTime,
    );

    await document.set({
      ...savedSession.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return savedSession;
  }

  Future<void> updateSession({
    required String teamId,
    required TeamSession session,
  }) async {
    await _sessions(teamId).doc(session.id).update(session.toFirestore());
  }

  Future<void> deleteSession({
    required String teamId,
    required String sessionId,
  }) async {
    await _sessions(teamId).doc(sessionId).delete();
  }
}
