import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

import 'member_repository.dart';
import 'session_repository.dart';

enum AttendanceStatus { hadir, telat, alpha, izin, sakit }

class AttendanceRecord {
  const AttendanceRecord({
    required this.memberId,
    required this.status,
    this.photoUrl,
    this.storagePath,
    this.localPhotoPath,
    this.lateMinutes = 0,
  });

  final String memberId;
  final AttendanceStatus status;
  final String? photoUrl;
  final String? storagePath;
  final String? localPhotoPath;
  final int lateMinutes;

  bool get photoTaken =>
      (photoUrl != null && photoUrl!.isNotEmpty) ||
      (localPhotoPath != null && localPhotoPath!.isNotEmpty);

  factory AttendanceRecord.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};

    return AttendanceRecord(
      memberId: snapshot.id,
      status: attendanceStatusFromName(data['status'] as String?),
      photoUrl: data['photoUrl'] as String?,
      storagePath: data['storagePath'] as String?,
      localPhotoPath: data['localPhotoPath'] as String?,
      lateMinutes: (data['lateMinutes'] as num?)?.toInt() ?? 0,
    );
  }
}

class SelfieUpload {
  const SelfieUpload({required this.downloadUrl, required this.storagePath});

  final String downloadUrl;
  final String storagePath;
}

AttendanceStatus attendanceStatusFromName(String? value) {
  return AttendanceStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => AttendanceStatus.alpha,
  );
}

class AttendanceRepository {
  AttendanceRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> _attendance({
    required String teamId,
    required String sessionId,
  }) {
    return _firestore
        .collection('teams')
        .doc(teamId)
        .collection('sessions')
        .doc(sessionId)
        .collection('attendance');
  }

  Stream<Map<String, AttendanceRecord>> watchAttendanceRecords({
    required String teamId,
    required String sessionId,
  }) {
    return _attendance(teamId: teamId, sessionId: sessionId).snapshots().map((
      snapshot,
    ) {
      return {
        for (final doc in snapshot.docs)
          doc.id: AttendanceRecord.fromSnapshot(doc),
      };
    });
  }

  Future<void> saveAttendance({
    required String teamId,
    required TeamSession session,
    required TeamMember member,
    required AttendanceStatus status,
    int lateMinutes = 0,
    String? photoUrl,
    String? storagePath,
    String? localPhotoPath,
  }) async {
    final data = <String, dynamic>{
      'memberId': member.id,
      'memberName': member.name,
      'voiceType': member.voiceType,
      'angkatan': member.angkatan,
      'sessionId': session.id,
      'sessionLabel': session.dayDate,
      'sessionLocation': session.location,
      'status': status.name,
      'lateMinutes': lateMinutes,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (photoUrl != null && photoUrl.isNotEmpty) {
      data['photoUrl'] = photoUrl;
      data['localPhotoPath'] = FieldValue.delete();
    }
    if (storagePath != null && storagePath.isNotEmpty) {
      data['storagePath'] = storagePath;
    }
    if (localPhotoPath != null && localPhotoPath.isNotEmpty) {
      data['localPhotoPath'] = localPhotoPath;
      data['photoUrl'] = FieldValue.delete();
      data['storagePath'] = FieldValue.delete();
    }
    if (status == AttendanceStatus.hadir || status == AttendanceStatus.telat) {
      data['checkedAt'] = FieldValue.serverTimestamp();
    }

    await _attendance(
      teamId: teamId,
      sessionId: session.id,
    ).doc(member.id).set(data, SetOptions(merge: true));
  }

  Future<void> deleteAttendance({
    required String teamId,
    required String sessionId,
    required String memberId,
  }) async {
    await _attendance(
      teamId: teamId,
      sessionId: sessionId,
    ).doc(memberId).delete();
  }

  Future<SelfieUpload> uploadSelfie({
    required String teamId,
    required String sessionId,
    required String memberId,
    required File file,
  }) async {
    final storagePath = 'attendance_selfies/$teamId/$sessionId/$memberId.jpg';
    final ref = _storage.ref(storagePath);

    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));

    return SelfieUpload(
      downloadUrl: await ref.getDownloadURL(),
      storagePath: storagePath,
    );
  }

  Future<String> saveSelfieLocally({
    required String teamId,
    required String sessionId,
    required String memberId,
    required File file,
  }) async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final selfieDirectory = Directory(
      '${appDirectory.path}/attendance_selfies/$teamId/$sessionId',
    );

    if (!await selfieDirectory.exists()) {
      await selfieDirectory.create(recursive: true);
    }

    final savedFile = File('${selfieDirectory.path}/$memberId.jpg');
    await file.copy(savedFile.path);
    return savedFile.path;
  }
}
