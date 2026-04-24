import 'package:cloud_firestore/cloud_firestore.dart';

import 'attendance_repository.dart';
import 'member_repository.dart';
import 'session_repository.dart';

class RecapMember {
  const RecapMember({
    required this.name,
    required this.present,
    required this.late,
    required this.alpha,
    required this.sick,
    required this.permission,
  });

  final String name;
  final int present;
  final int late;
  final int alpha;
  final int sick;
  final int permission;

  int get attended => present + late;
}

class RecapMonthOption {
  const RecapMonthOption({required this.key, required this.label});

  final String key;
  final String label;
}

class RecapData {
  const RecapData({
    required this.months,
    required this.selectedMonth,
    required this.members,
    required this.totalSessions,
  });

  final List<RecapMonthOption> months;
  final RecapMonthOption? selectedMonth;
  final List<RecapMember> members;
  final int totalSessions;

  int get averageAttendance {
    if (members.isEmpty || totalSessions == 0) return 0;

    final totalRate = members.fold<double>(
      0,
      (total, member) => total + (member.attended / totalSessions),
    );
    return ((totalRate / members.length) * 100).round();
  }

  bool get hasRecap => members.isNotEmpty && totalSessions > 0;
}

class _RecapSession {
  const _RecapSession({required this.session, required this.month});

  final TeamSession session;
  final RecapMonthOption month;
}

class RecapRepository {
  RecapRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _members(String teamId) {
    return _firestore.collection('teams').doc(teamId).collection('members');
  }

  CollectionReference<Map<String, dynamic>> _sessions(String teamId) {
    return _firestore.collection('teams').doc(teamId).collection('sessions');
  }

  CollectionReference<Map<String, dynamic>> _attendance({
    required String teamId,
    required String sessionId,
  }) {
    return _sessions(teamId).doc(sessionId).collection('attendance');
  }

  Future<RecapData> loadMonthlyRecap({
    required String teamId,
    String? monthKey,
  }) async {
    final results = await Future.wait([
      _members(teamId).get(),
      _sessions(teamId).get(),
    ]);

    final memberSnapshot = results[0];
    final sessionSnapshot = results[1];

    final members = memberSnapshot.docs.map(TeamMember.fromSnapshot).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final sessions =
        sessionSnapshot.docs
            .map(TeamSession.fromSnapshot)
            .where((session) => session.dayDate.trim().isNotEmpty)
            .map((session) {
              return _RecapSession(
                session: session,
                month: _monthFromSession(session),
              );
            })
            .toList()
          ..sort((a, b) {
            final aDate = _parseSessionDate(a.session.dayDate);
            final bDate = _parseSessionDate(b.session.dayDate);
            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1;
            if (bDate == null) return -1;
            return bDate.compareTo(aDate);
          });

    final months = _uniqueMonths(sessions);
    final selectedMonth = _selectMonth(months, monthKey);
    if (selectedMonth == null) {
      return RecapData(
        months: months,
        selectedMonth: null,
        members: members
            .map(
              (member) => RecapMember(
                name: member.name,
                present: 0,
                late: 0,
                alpha: 0,
                sick: 0,
                permission: 0,
              ),
            )
            .toList(),
        totalSessions: 0,
      );
    }

    final selectedSessions = sessions
        .where((session) => session.month.key == selectedMonth.key)
        .toList();
    final attendanceSnapshots = await Future.wait(
      selectedSessions.map(
        (session) =>
            _attendance(teamId: teamId, sessionId: session.session.id).get(),
      ),
    );

    final recordsBySession = <String, Map<String, AttendanceRecord>>{};
    for (var index = 0; index < selectedSessions.length; index++) {
      recordsBySession[selectedSessions[index].session.id] = {
        for (final doc in attendanceSnapshots[index].docs)
          doc.id: AttendanceRecord.fromSnapshot(doc),
      };
    }

    return RecapData(
      months: months,
      selectedMonth: selectedMonth,
      members: members.map((member) {
        var present = 0;
        var late = 0;
        var alpha = 0;
        var sick = 0;
        var permission = 0;

        for (final session in selectedSessions) {
          final record = recordsBySession[session.session.id]?[member.id];
          switch (record?.status ?? AttendanceStatus.alpha) {
            case AttendanceStatus.hadir:
              present++;
              break;
            case AttendanceStatus.telat:
              late++;
              break;
            case AttendanceStatus.alpha:
              alpha++;
              break;
            case AttendanceStatus.sakit:
              sick++;
              break;
            case AttendanceStatus.izin:
              permission++;
              break;
          }
        }

        return RecapMember(
          name: member.name,
          present: present,
          late: late,
          alpha: alpha,
          sick: sick,
          permission: permission,
        );
      }).toList(),
      totalSessions: selectedSessions.length,
    );
  }

  RecapMonthOption? _selectMonth(
    List<RecapMonthOption> months,
    String? requestedKey,
  ) {
    if (months.isEmpty) return null;
    if (requestedKey != null) {
      for (final month in months) {
        if (month.key == requestedKey) return month;
      }
    }
    return months.first;
  }

  List<RecapMonthOption> _uniqueMonths(List<_RecapSession> sessions) {
    final monthByKey = <String, RecapMonthOption>{};
    for (final session in sessions) {
      monthByKey.putIfAbsent(session.month.key, () => session.month);
    }

    final months = monthByKey.values.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return months;
  }

  RecapMonthOption _monthFromSession(TeamSession session) {
    final date = _parseSessionDate(session.dayDate);
    final now = DateTime.now();
    final year = date?.year ?? now.year;
    final month = date?.month ?? now.month;
    final paddedMonth = month.toString().padLeft(2, '0');

    return RecapMonthOption(
      key: '$year-$paddedMonth',
      label: '${_monthNames[month] ?? _monthNames[now.month]!} $year',
    );
  }

  DateTime? _parseSessionDate(String dayDate) {
    final dateParts = dayDate.split(', ');
    final monthDay = dateParts.length == 2
        ? dateParts[1].trim().split(' ')
        : const <String>[];

    if (monthDay.length != 2) return null;

    final month = _monthNumbers[monthDay[0]];
    final day = int.tryParse(monthDay[1]);
    if (month == null || day == null) return null;

    final now = DateTime.now();
    return DateTime(now.year, month, day);
  }
}

const _monthNumbers = {
  'Jan': 1,
  'Feb': 2,
  'Mar': 3,
  'Apr': 4,
  'May': 5,
  'Jun': 6,
  'Jul': 7,
  'Aug': 8,
  'Sep': 9,
  'Oct': 10,
  'Nov': 11,
  'Dec': 12,
};

const _monthNames = {
  1: 'January',
  2: 'February',
  3: 'March',
  4: 'April',
  5: 'May',
  6: 'June',
  7: 'July',
  8: 'August',
  9: 'September',
  10: 'October',
  11: 'November',
  12: 'December',
};
