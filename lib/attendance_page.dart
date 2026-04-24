import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'app_empty_state.dart';
import 'app_motion.dart';
import 'app_session.dart';
import 'attendance_repository.dart';
import 'member_repository.dart';
import 'select_teams_page.dart';
import 'session_repository.dart';

class AttendanceSession {
  AttendanceSession({
    required this.id,
    required this.label,
    required this.location,
    required this.startDateTime,
    required this.endDateTime,
    required this.source,
  });

  String id;
  String label;
  String location;
  DateTime startDateTime;
  DateTime endDateTime;
  TeamSession source;

  String get startTime =>
      '${startDateTime.hour.toString().padLeft(2, '0')}:${startDateTime.minute.toString().padLeft(2, '0')}';
  String get endTime =>
      '${endDateTime.hour.toString().padLeft(2, '0')}:${endDateTime.minute.toString().padLeft(2, '0')}';

  factory AttendanceSession.fromTeamSession(TeamSession session) {
    final startDateTime = _parseSessionDateTime(
      session.dayDate,
      session.startTime,
    );
    final endDateTime = _parseSessionDateTime(session.dayDate, session.endTime);

    return AttendanceSession(
      id: session.id,
      label: session.dayDate,
      location: session.location,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      source: session,
    );
  }
}

class AttendanceMember {
  AttendanceMember({required this.source, AttendanceRecord? record})
    : status = record?.status ?? AttendanceStatus.alpha,
      photoUrl = record?.photoUrl,
      storagePath = record?.storagePath,
      localPhotoPath = record?.localPhotoPath,
      lateMinutes = record?.lateMinutes ?? 0;

  TeamMember source;
  AttendanceStatus status;
  String? photoUrl;
  String? storagePath;
  String? localPhotoPath;
  int lateMinutes;

  String get id => source.id;
  String get name => source.name;
  String get voiceType => source.voiceType;
  String get angkatan => source.angkatan;
  bool get photoTaken =>
      (photoUrl != null && photoUrl!.isNotEmpty) ||
      (localPhotoPath != null && localPhotoPath!.isNotEmpty);
}

DateTime _parseSessionDateTime(String dayDate, String time) {
  const months = {
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

  final dateParts = dayDate.split(', ');
  final monthDay = dateParts.length == 2
      ? dateParts[1].split(' ')
      : const <String>[];
  final timeParts = time.split(':');

  final month = monthDay.length == 2 ? months[monthDay[0]] : null;
  final day = monthDay.length == 2 ? int.tryParse(monthDay[1]) : null;
  final hour = timeParts.length == 2 ? int.tryParse(timeParts[0]) : null;
  final minute = timeParts.length == 2 ? int.tryParse(timeParts[1]) : null;
  final now = DateTime.now();

  return DateTime(
    now.year,
    month ?? now.month,
    day ?? now.day,
    hour ?? 0,
    minute ?? 0,
  );
}

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  static const Color _pageBg = Color(0xFFF6F8FB);
  static const Color _cardBg = Colors.white;
  static const Color _primary = Color(0xFF10316B);
  static const Color _text = Color(0xFF1F2937);
  static const Color _muted = Color(0xFF64748B);
  static const Color _border = Color(0xFFD9E2EC);

  final ImagePicker _imagePicker = ImagePicker();
  final _attendanceRepository = AttendanceRepository();
  final _memberRepository = MemberRepository();
  final _sessionRepository = SessionRepository();

  bool _sessionPanelExpanded = false;
  String _search = '';
  String? _selectedSessionId;

  String? get _teamId => AppSession.currentTeamId;

  AttendanceSession _resolveSelectedSession(List<AttendanceSession> sessions) {
    final selectedId = _selectedSessionId;
    if (selectedId != null) {
      for (final session in sessions) {
        if (session.id == selectedId) return session;
      }
    }
    return sessions.first;
  }

  void _syncSelectedSession(AttendanceSession session) {
    if (_selectedSessionId == session.id) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _selectedSessionId = session.id;
      });
    });
  }

  int _countStatus(List<AttendanceMember> members, AttendanceStatus status) {
    return members.where((member) => member.status == status).length;
  }

  List<AttendanceMember> _filteredMembers(List<AttendanceMember> members) {
    final search = _search.trim().toLowerCase();
    final filtered = members.where((member) {
      if (search.isEmpty) return true;

      return member.name.toLowerCase().contains(search) ||
          member.voiceType.toLowerCase().contains(search) ||
          member.angkatan.toLowerCase().contains(search);
    }).toList();

    filtered.sort((a, b) => a.name.compareTo(b.name));
    return filtered;
  }

  int _lateMinutesNow(AttendanceSession session) {
    final diff = DateTime.now().difference(session.startDateTime).inMinutes;
    return diff > 0 ? diff : 0;
  }

  String _lateMessage(int minutes) {
    return 'Telat $minutes menit';
  }

  String _statusLabel(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.hadir:
        return 'Hadir';
      case AttendanceStatus.telat:
        return 'Telat';
      case AttendanceStatus.alpha:
        return 'Alpha';
      case AttendanceStatus.izin:
        return 'Izin';
      case AttendanceStatus.sakit:
        return 'Sakit';
    }
  }

  String _currentStatusLabel(AttendanceMember member) {
    if (member.status == AttendanceStatus.telat) {
      return 'Hadir (${_lateMessage(member.lateMinutes)})';
    }
    return _statusLabel(member.status);
  }

  Future<bool> _confirmStatusChange(
    AttendanceMember member,
    AttendanceStatus status,
  ) async {
    final shouldAsk =
        member.status != AttendanceStatus.alpha || member.photoTaken;
    final sameAsCurrent =
        status == member.status ||
        (status == AttendanceStatus.hadir && _isPresentOrLate(member));
    if (!shouldAsk || sameAsCurrent) return true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change attendance status?'),
          content: Text(
            '${member.name} is currently ${_currentStatusLabel(member)}. Change it to ${_statusLabel(status)}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('KEEP'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('CHANGE'),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  Future<void> _setStatus(
    AttendanceSession session,
    AttendanceMember member,
    AttendanceStatus status,
  ) async {
    final teamId = _teamId;
    if (teamId == null) {
      _showNoTeamMessage();
      return;
    }

    if (status == AttendanceStatus.hadir && !member.photoTaken) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ambil foto selfie dulu sebelum menandai Hadir.'),
          duration: Duration(milliseconds: 1400),
        ),
      );
      return;
    }

    if (!await _confirmStatusChange(member, status)) return;

    final lateMinutes = status == AttendanceStatus.hadir
        ? _lateMinutesNow(session)
        : 0;
    final savedStatus = status == AttendanceStatus.hadir && lateMinutes > 0
        ? AttendanceStatus.telat
        : status;

    try {
      await _attendanceRepository.saveAttendance(
        teamId: teamId,
        session: session.source,
        member: member.source,
        status: savedStatus,
        lateMinutes: lateMinutes,
        photoUrl: member.photoUrl,
        storagePath: member.storagePath,
        localPhotoPath: member.localPhotoPath,
      );
    } on FirebaseException catch (error) {
      _showFirebaseError(error);
    }
  }

  Future<void> _takePhoto(
    AttendanceSession session,
    AttendanceMember member,
  ) async {
    final teamId = _teamId;
    if (teamId == null) {
      _showNoTeamMessage();
      return;
    }

    if (member.photoTaken) {
      final shouldReplace = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Replace selfie?'),
            content: Text(
              'A selfie for ${member.name} already exists. Replace it with a new one?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('REPLACE'),
              ),
            ],
          );
        },
      );

      if (!mounted || shouldReplace != true) return;
    }

    XFile? selfie;

    try {
      selfie = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 75,
        maxWidth: 1280,
      );
    } on PlatformException catch (error) {
      if (!mounted) return;

      final message = error.code == 'camera_access_denied'
          ? 'Izin kamera ditolak. Aktifkan permission kamera untuk aplikasi ini.'
          : 'Kamera tidak bisa dibuka. Coba cek permission kamera di HP.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(milliseconds: 2200),
        ),
      );
      return;
    }

    if (!mounted || selfie == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Menyimpan selfie...'),
        duration: Duration(milliseconds: 900),
      ),
    );

    final selfieFile = File(selfie.path);
    SelfieUpload? upload;
    String? localPhotoPath;
    FirebaseException? storageError;

    try {
      upload = await _attendanceRepository.uploadSelfie(
        teamId: teamId,
        sessionId: session.id,
        memberId: member.id,
        file: selfieFile,
      );
    } on FirebaseException catch (error) {
      storageError = error;
      try {
        localPhotoPath = await _attendanceRepository.saveSelfieLocally(
          teamId: teamId,
          sessionId: session.id,
          memberId: member.id,
          file: selfieFile,
        );
      } on FileSystemException {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Firebase Storage belum aktif dan foto juga gagal disimpan lokal.',
            ),
            duration: Duration(milliseconds: 2400),
          ),
        );
        return;
      }
    }

    try {
      final lateMinutes = _lateMinutesNow(session);
      final status = lateMinutes > 0
          ? AttendanceStatus.telat
          : AttendanceStatus.hadir;

      await _attendanceRepository.saveAttendance(
        teamId: teamId,
        session: session.source,
        member: member.source,
        status: status,
        lateMinutes: lateMinutes,
        photoUrl: upload?.downloadUrl,
        storagePath: upload?.storagePath,
        localPhotoPath: localPhotoPath,
      );

      if (!mounted) return;
      final localFallbackMessage = storageError == null
          ? null
          : ' Firebase Storage belum aktif, jadi foto disimpan lokal dulu.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lateMinutes > 0
                ? 'Selfie tersimpan. ${_lateMessage(lateMinutes)} dari jam mulai.${localFallbackMessage ?? ''}'
                : 'Selfie tersimpan. Status masuk Hadir.${localFallbackMessage ?? ''}',
          ),
          duration: Duration(milliseconds: storageError == null ? 1600 : 2800),
        ),
      );
    } on FirebaseException catch (error) {
      _showFirebaseError(error);
    }
  }

  void _showNoTeamMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please select a team first.'),
        duration: Duration(milliseconds: 1400),
      ),
    );
  }

  void _showFirebaseError(FirebaseException error) {
    if (!mounted) return;

    final message = switch (error.code) {
      'permission-denied' =>
        'Firebase menolak akses attendance/selfie. Cek Firestore dan Storage rules.',
      'object-not-found' =>
        'Selfie belum tersimpan di Storage. Pastikan Firebase Storage sudah dibuat dan rules mengizinkan upload.',
      'bucket-not-found' =>
        'Storage bucket belum ditemukan. Buat Firebase Storage bucket dulu di Firebase Console.',
      'unauthorized' =>
        'Storage menolak upload selfie. Cek rules Firebase Storage.',
      'canceled' => 'Upload selfie dibatalkan.',
      'unavailable' => 'Firebase sedang tidak tersedia. Coba lagi nanti.',
      _ =>
        error.message ?? 'Attendance gagal diproses. Kode error: ${error.code}',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 2400),
      ),
    );
  }

  Widget _buildSelfieDetailImage(AttendanceMember member) {
    final photoUrl = member.photoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return Image.network(
        photoUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const SizedBox(
            height: 360,
            child: Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox(
            height: 280,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Selfie tidak bisa dimuat. Cek koneksi atau Storage rules.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
      );
    }

    final localPhotoPath = member.localPhotoPath;
    if (localPhotoPath != null && localPhotoPath.isNotEmpty) {
      return Image.file(
        File(localPhotoPath),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox(
            height: 280,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Selfie lokal tidak ditemukan di perangkat ini.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
      );
    }

    return const SizedBox(
      height: 280,
      child: Center(child: Text('Belum ada selfie untuk anggota ini.')),
    );
  }

  void _showPhotoDetail(AttendanceSession session, AttendanceMember member) {
    final hasPhoto =
        (member.photoUrl != null && member.photoUrl!.isNotEmpty) ||
        (member.localPhotoPath != null && member.localPhotoPath!.isNotEmpty);

    if (!hasPhoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada selfie untuk anggota ini.'),
          duration: Duration(milliseconds: 1200),
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 24,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  color: const Color(0xFF10316B),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${session.label} - ${_currentStatusLabel(member)}',
                        style: const TextStyle(
                          color: Color(0xFFDCE7FF),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: InteractiveViewer(
                    child: _buildSelfieDetailImage(member),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('TUTUP'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isPresentOrLate(AttendanceMember member) {
    return member.status == AttendanceStatus.hadir ||
        member.status == AttendanceStatus.telat;
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(18, 16, 18, 16),
  }) {
    return AppEmptyStateView(
      icon: icon,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      padding: padding,
    );
  }

  Widget _buildTeamRequiredState() {
    return _buildEmptyState(
      icon: Icons.groups_2_outlined,
      title: 'No team selected',
      message: 'Select a team first so attendance can be recorded.',
      actionLabel: 'Select Team',
      onAction: () => Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SelectTeamsPage()),
        (route) => false,
      ),
    );
  }

  Widget _buildTeamAttendance(String teamId) {
    return StreamBuilder<List<TeamSession>>(
      stream: _sessionRepository.watchTeamSessions(teamId),
      builder: (context, sessionSnapshot) {
        if (sessionSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _primary),
          );
        }

        if (sessionSnapshot.hasError) {
          return _buildEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Sessions unavailable',
            message:
                'Firestore could not load sessions for this team. Check database rules and connection.',
            actionLabel: 'Try Again',
            onAction: () => setState(() {}),
          );
        }

        final sessions = (sessionSnapshot.data ?? const <TeamSession>[])
            .map(AttendanceSession.fromTeamSession)
            .toList();

        if (sessions.isEmpty) {
          return _buildEmptyState(
            icon: Icons.event_note_outlined,
            title: 'No sessions yet',
            message: 'Create a session first so attendance can be recorded.',
            actionLabel: 'Go to Sessions',
            onAction: () => Navigator.pushNamed(context, '/sessions'),
          );
        }

        final selectedSession = _resolveSelectedSession(sessions);
        _syncSelectedSession(selectedSession);

        return StreamBuilder<List<TeamMember>>(
          stream: _memberRepository.watchTeamMembers(teamId),
          builder: (context, memberSnapshot) {
            final teamMembers = memberSnapshot.data ?? const <TeamMember>[];

            if (memberSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _primary),
              );
            }

            if (memberSnapshot.hasError) {
              return _buildEmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'Members unavailable',
                message:
                    'Firestore could not load members for this team. Check database rules and connection.',
                actionLabel: 'Try Again',
                onAction: () => setState(() {}),
              );
            }

            return StreamBuilder<Map<String, AttendanceRecord>>(
              stream: _attendanceRepository.watchAttendanceRecords(
                teamId: teamId,
                sessionId: selectedSession.id,
              ),
              builder: (context, attendanceSnapshot) {
                if (attendanceSnapshot.hasError) {
                  return _buildEmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: 'Attendance unavailable',
                    message:
                        'Firestore could not load attendance for this session. Check database rules and connection.',
                    actionLabel: 'Try Again',
                    onAction: () => setState(() {}),
                  );
                }

                final records =
                    attendanceSnapshot.data ??
                    const <String, AttendanceRecord>{};
                final attendanceMembers = teamMembers
                    .map(
                      (member) => AttendanceMember(
                        source: member,
                        record: records[member.id],
                      ),
                    )
                    .toList();

                return _buildAttendanceView(
                  sessions: sessions,
                  selectedSession: selectedSession,
                  members: attendanceMembers,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAttendanceView({
    required List<AttendanceSession> sessions,
    required AttendanceSession selectedSession,
    required List<AttendanceMember> members,
  }) {
    final filteredMembers = _filteredMembers(members);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
          child: SoftFadeIn(
            child: _SessionPanel(
              selectedSession: selectedSession,
              sessions: sessions,
              hadirCount: _countStatus(members, AttendanceStatus.hadir),
              telatCount: _countStatus(members, AttendanceStatus.telat),
              alphaCount: _countStatus(members, AttendanceStatus.alpha),
              sakitCount: _countStatus(members, AttendanceStatus.sakit),
              izinCount: _countStatus(members, AttendanceStatus.izin),
              isExpanded: _sessionPanelExpanded,
              toggleExpanded: () => setState(() {
                _sessionPanelExpanded = !_sessionPanelExpanded;
              }),
              searchChanged: (value) => setState(() {
                _search = value;
              }),
              sessionChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedSessionId = value.id;
                  _search = '';
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: SoftFadeIn(
            duration: const Duration(milliseconds: 420),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: filteredMembers.isEmpty
                  ? _buildEmptyState(
                      icon: members.isEmpty
                          ? Icons.group_off_outlined
                          : Icons.search_off,
                      title: members.isEmpty
                          ? 'No members available'
                          : 'No matching member',
                      message: members.isEmpty
                          ? 'Add members first so attendance can be recorded in this session.'
                          : 'Try another name, sound type, or angkatan keyword.',
                      actionLabel: members.isEmpty ? 'Go to Members' : null,
                      onAction: members.isEmpty
                          ? () => Navigator.pushNamed(context, '/members')
                          : null,
                      padding: const EdgeInsets.all(0),
                    )
                  : ListView.separated(
                      itemCount: filteredMembers.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final member = filteredMembers[index];

                        return _MemberAttendanceCard(
                          member: member,
                          isPresentOrLate: _isPresentOrLate(member),
                          lateText: member.status == AttendanceStatus.telat
                              ? '${_lateMessage(member.lateMinutes)} dari jam mulai'
                              : null,
                          onPhotoTap: () => _takePhoto(selectedSession, member),
                          onDetailTap: member.photoTaken
                              ? () => _showPhotoDetail(selectedSession, member)
                              : null,
                          onHadirTap: () => _setStatus(
                            selectedSession,
                            member,
                            AttendanceStatus.hadir,
                          ),
                          onAlphaTap: () => _setStatus(
                            selectedSession,
                            member,
                            AttendanceStatus.alpha,
                          ),
                          onSakitTap: () => _setStatus(
                            selectedSession,
                            member,
                            AttendanceStatus.sakit,
                          ),
                          onIzinTap: () => _setStatus(
                            selectedSession,
                            member,
                            AttendanceStatus.izin,
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final teamId = _teamId;

    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: Column(
          children: [
            _AttendanceHeader(
              onBack: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/dashboard',
                (route) => false,
              ),
            ),
            Expanded(
              child: teamId == null
                  ? _buildTeamRequiredState()
                  : _buildTeamAttendance(teamId),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _AttendanceBottomNav(),
    );
  }
}

class _AttendanceHeader extends StatelessWidget {
  const _AttendanceHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(16, 49, 107, 0.08),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: Tooltip(
              message: 'Back to Home',
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onBack,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.arrow_back, color: Color(0xFF10316B)),
                ),
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Attendance',
                style: TextStyle(
                  color: Color(0xFF10316B),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _SessionPanel extends StatelessWidget {
  const _SessionPanel({
    required this.selectedSession,
    required this.sessions,
    required this.hadirCount,
    required this.telatCount,
    required this.alphaCount,
    required this.sakitCount,
    required this.izinCount,
    required this.isExpanded,
    required this.toggleExpanded,
    required this.searchChanged,
    required this.sessionChanged,
  });

  final AttendanceSession selectedSession;
  final List<AttendanceSession> sessions;
  final int hadirCount;
  final int telatCount;
  final int alphaCount;
  final int sakitCount;
  final int izinCount;
  final bool isExpanded;
  final VoidCallback toggleExpanded;
  final ValueChanged<String> searchChanged;
  final ValueChanged<AttendanceSession?> sessionChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AttendancePageState._cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5EAF0)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.06),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.event_available,
                  color: _AttendancePageState._primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${selectedSession.label} - ${selectedSession.location}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _AttendancePageState._text,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Jam mulai ${selectedSession.startTime} - selesai ${selectedSession.endTime}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _AttendancePageState._muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: isExpanded ? 'Hide details' : 'Show details',
                child: TextButton.icon(
                  onPressed: toggleExpanded,
                  icon: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                  ),
                  label: Text(isExpanded ? 'Tutup' : 'Detail'),
                  style: TextButton.styleFrom(
                    foregroundColor: _AttendancePageState._primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const SizedBox(height: 12),
                DropdownButtonFormField<AttendanceSession>(
                  initialValue: selectedSession,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: _AttendancePageState._muted,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 13,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: _AttendancePageState._border,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: _AttendancePageState._primary,
                      ),
                    ),
                  ),
                  onChanged: sessionChanged,
                  items: sessions
                      .map(
                        (session) => DropdownMenuItem(
                          value: session,
                          child: Text(
                            '${session.label} - ${session.location}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _AttendancePageState._text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatusCard(
                        label: 'Hadir',
                        value: hadirCount.toString(),
                        background: const Color(0xFFDCFCE7),
                        foreground: const Color(0xFF166534),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _StatusCard(
                        label: 'Telat',
                        value: telatCount.toString(),
                        background: const Color(0xFFFEF3C7),
                        foreground: const Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _StatusCard(
                        label: 'Alpha',
                        value: alphaCount.toString(),
                        background: const Color(0xFFFEE2E2),
                        foreground: const Color(0xFF991B1B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _StatusCard(
                        label: 'Sakit',
                        value: sakitCount.toString(),
                        background: const Color(0xFFDBEAFE),
                        foreground: const Color(0xFF1D4ED8),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _StatusCard(
                        label: 'Izin',
                        value: izinCount.toString(),
                        background: const Color(0xFFE0F2FE),
                        foreground: const Color(0xFF0369A1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: searchChanged,
                  decoration: InputDecoration(
                    hintText: 'Cari anggota',
                    hintStyle: const TextStyle(
                      color: _AttendancePageState._muted,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: _AttendancePageState._muted,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 13,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: _AttendancePageState._border,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: _AttendancePageState._primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
            sizeCurve: Curves.easeOut,
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.label,
    required this.value,
    required this.background,
    required this.foreground,
  });

  final String label;
  final String value;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: foreground,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: foreground,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberAttendanceCard extends StatelessWidget {
  const _MemberAttendanceCard({
    required this.member,
    required this.isPresentOrLate,
    required this.onPhotoTap,
    required this.onDetailTap,
    required this.onHadirTap,
    required this.onAlphaTap,
    required this.onSakitTap,
    required this.onIzinTap,
    this.lateText,
  });

  final AttendanceMember member;
  final bool isPresentOrLate;
  final String? lateText;
  final VoidCallback onPhotoTap;
  final VoidCallback? onDetailTap;
  final VoidCallback onHadirTap;
  final VoidCallback onAlphaTap;
  final VoidCallback onSakitTap;
  final VoidCallback onIzinTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AttendancePageState._cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5EAF0)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.05),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person,
                  color: _AttendancePageState._primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _AttendancePageState._text,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${member.voiceType} - ${member.angkatan}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _AttendancePageState._muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Tooltip(
                    message: member.photoTaken
                        ? 'Take selfie again'
                        : 'Take selfie',
                    child: ElevatedButton.icon(
                      onPressed: onPhotoTap,
                      icon: const Icon(Icons.camera_alt, size: 17),
                      label: Text(member.photoTaken ? 'Ulang' : 'Foto'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: member.photoTaken
                            ? _AttendancePageState._primary
                            : const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(86, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  if (onDetailTap != null) ...[
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: onDetailTap,
                      style: TextButton.styleFrom(
                        foregroundColor: _AttendancePageState._primary,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(72, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Detail',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (lateText != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 17,
                    color: Color(0xFF92400E),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lateText!,
                      style: const TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AttendanceButton(
                  label: 'Hadir',
                  selected: isPresentOrLate,
                  background: member.status == AttendanceStatus.telat
                      ? const Color(0xFFFEF3C7)
                      : const Color(0xFFDCFCE7),
                  foreground: member.status == AttendanceStatus.telat
                      ? const Color(0xFF92400E)
                      : const Color(0xFF166534),
                  active: member.photoTaken,
                  onTap: onHadirTap,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _AttendanceButton(
                  label: 'Alpha',
                  selected: member.status == AttendanceStatus.alpha,
                  background: const Color(0xFFFEE2E2),
                  foreground: const Color(0xFF991B1B),
                  onTap: onAlphaTap,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _AttendanceButton(
                  label: 'Sakit',
                  selected: member.status == AttendanceStatus.sakit,
                  background: const Color(0xFFDBEAFE),
                  foreground: const Color(0xFF1D4ED8),
                  onTap: onSakitTap,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _AttendanceButton(
                  label: 'Izin',
                  selected: member.status == AttendanceStatus.izin,
                  background: const Color(0xFFE0F2FE),
                  foreground: const Color(0xFF0369A1),
                  onTap: onIzinTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttendanceButton extends StatelessWidget {
  const _AttendanceButton({
    required this.label,
    required this.selected,
    required this.background,
    required this.foreground,
    this.active = true,
    this.onTap,
  });

  final String label;
  final bool selected;
  final bool active;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      enabled: active,
      label: label,
      child: Opacity(
        opacity: active ? 1 : 0.45,
        child: InkWell(
          onTap: active ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? background : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? foreground : _AttendancePageState._border,
              ),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? foreground : _AttendancePageState._muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AttendanceBottomNav extends StatelessWidget {
  const _AttendanceBottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(16, 49, 107, 0.08),
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _BottomNavItem(
                label: 'Recap',
                icon: Icons.bar_chart,
                active: false,
                onTap: () => Navigator.pushNamed(context, '/recap'),
              ),
              _BottomNavItem(
                label: 'Members',
                icon: Icons.group,
                active: false,
                onTap: () => Navigator.pushNamed(context, '/members'),
              ),
              _BottomNavItem(
                label: 'Home',
                icon: Icons.home,
                active: false,
                onTap: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/dashboard',
                  (route) => route.isFirst,
                ),
              ),
              const _BottomNavItem(
                label: 'Attendance',
                icon: Icons.checklist,
                active: true,
              ),
              _BottomNavItem(
                label: 'Sessions',
                icon: Icons.event_note,
                active: false,
                onTap: () => Navigator.pushNamed(context, '/sessions'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.label,
    required this.icon,
    required this.active,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: active,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedNavIconFrame(icon: icon, active: active),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: active
                      ? const Color(0xFF10316B)
                      : const Color(0xFF8A99C6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
