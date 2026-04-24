import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app_session.dart';
import 'app_empty_state.dart';
import 'app_motion.dart';
import 'select_teams_page.dart';
import 'notification_service.dart';
import 'session_repository.dart';

class SessionsPage extends StatefulWidget {
  const SessionsPage({super.key});

  @override
  State<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage> {
  final _sessionRepository = SessionRepository();
  final _notificationService = NotificationService.instance;

  String? get _teamId => AppSession.currentTeamId;

  Future<void> _openSessionForm({TeamSession? session}) async {
    final teamId = _teamId;
    if (teamId == null) {
      _showNoTeamMessage();
      return;
    }

    final result = await Navigator.push<TeamSession?>(
      context,
      MaterialPageRoute(
        builder: (context) => SessionFormPage(session: session),
      ),
    );

    if (result == null) return;

    try {
      late final TeamSession savedSession;
      if (session == null) {
        savedSession = await _sessionRepository.createSession(
          teamId: teamId,
          session: result,
        );
      } else {
        savedSession = TeamSession(
          id: session.id,
          dayDate: result.dayDate,
          location: result.location,
          activity: result.activity,
          startTime: result.startTime,
          endTime: result.endTime,
        );
        await _sessionRepository.updateSession(
          teamId: teamId,
          session: savedSession,
        );
      }

      SessionReminderResult? reminderResult;
      try {
        reminderResult = await _notificationService.scheduleSessionReminder(
          teamId: teamId,
          teamName: AppSession.currentTeamName,
          session: savedSession,
        );
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _sessionSavedMessage(
              session: savedSession,
              isEditing: session != null,
              reminderResult: reminderResult,
            ),
          ),
          duration: Duration(
            milliseconds: reminderResult?.notificationsAllowed == true
                ? 2200
                : 2800,
          ),
        ),
      );
    } on FirebaseException catch (error) {
      _showFirestoreError(error);
    }
  }

  Future<void> _confirmDelete(TeamSession session) async {
    final teamId = _teamId;
    if (teamId == null) {
      _showNoTeamMessage();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete session?'),
          content: Text(
            '${session.dayDate} will be removed from the schedule.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE92E2E),
                foregroundColor: Colors.white,
              ),
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      try {
        await _notificationService.cancelSessionReminder(
          teamId: teamId,
          sessionId: session.id,
        );
      } catch (_) {}
      await _sessionRepository.deleteSession(
        teamId: teamId,
        sessionId: session.id,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "${session.dayDate}"'),
          duration: const Duration(milliseconds: 900),
        ),
      );
    } on FirebaseException catch (error) {
      _showFirestoreError(error);
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

  void _showFirestoreError(FirebaseException error) {
    if (!mounted) return;

    final message = switch (error.code) {
      'permission-denied' =>
        'Firestore menolak akses sessions. Cek rules teams/{teamId}/sessions.',
      'unavailable' => 'Firestore sedang tidak tersedia. Coba lagi nanti.',
      _ => error.message ?? 'Session gagal diproses.',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 2200),
      ),
    );
  }

  String _sessionSavedMessage({
    required TeamSession session,
    required bool isEditing,
    required SessionReminderResult? reminderResult,
  }) {
    final action = isEditing ? 'Updated' : 'Added';
    final base = '$action "${session.dayDate}".';

    if (reminderResult == null) {
      return '$base Reminder latihan belum berhasil dijadwalkan.';
    }

    if (!reminderResult.notificationsAllowed) {
      return '$base Izin notifikasi belum aktif, jadi reminder latihan belum dijadwalkan.';
    }

    if (reminderResult.sentImmediately) {
      return '$base Reminder dikirim sekarang karena waktu latihan sudah dekat.';
    }

    if (!reminderResult.reminderScheduled) {
      return '$base Waktu reminder sudah lewat, jadi tidak ada notif yang dijadwalkan.';
    }

    if (!reminderResult.preciseAlarmGranted) {
      return '$base Reminder latihan dijadwalkan, tapi tanpa exact alarm.';
    }

    return '$base Reminder latihan 30 menit sebelum mulai sudah dijadwalkan.';
  }

  Widget _buildSessionCard(TeamSession session) {
    final formattedTimeRange =
        '${session.startTime.replaceAll(':', '.')} - ${session.endTime.replaceAll(':', '.')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4EBFF)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(16, 49, 107, 0.04),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF0FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF10316B),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.dayDate,
                      style: const TextStyle(
                        color: Color(0xFF10316B),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formattedTimeRange,
                      style: const TextStyle(
                        color: Color(0xFF52627F),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFF52627F),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            session.location,
                            style: const TextStyle(
                              color: Color(0xFF52627F),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Tooltip(
                    message: 'Edit session',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _openSessionForm(session: session),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF0FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Color(0xFF10316B),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Tooltip(
                    message: 'Delete session',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _confirmDelete(session),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Color(0xFFE92E2E),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            session.activity,
            style: const TextStyle(
              color: Color(0xFF10316B),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teamId = _teamId;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: SafeArea(
        child: Column(
          children: [
            Container(
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
                        onTap: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/dashboard',
                            (route) => false,
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.arrow_back,
                            color: Color(0xFF10316B),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Sessions',
                        style: TextStyle(
                          color: Color(0xFF10316B),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: Tooltip(
                      message: 'Add session',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => _openSessionForm(session: null),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF6C43C),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SoftFadeIn(
                child: teamId == null
                    ? AppEmptyStateView(
                        icon: Icons.groups_2_outlined,
                        title: 'No team selected',
                        message:
                            'Select a team first so its sessions can be managed.',
                        actionLabel: 'Select Team',
                        onAction: () => Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SelectTeamsPage(),
                          ),
                          (route) => false,
                        ),
                      )
                    : StreamBuilder<List<TeamSession>>(
                        stream: _sessionRepository.watchTeamSessions(teamId),
                        builder: (context, snapshot) {
                          final sessions =
                              snapshot.data ?? const <TeamSession>[];
                          final isLoading =
                              snapshot.connectionState ==
                              ConnectionState.waiting;

                          if (isLoading) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF10316B),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return AppEmptyStateView(
                              icon: Icons.cloud_off_outlined,
                              title: 'Sessions unavailable',
                              message:
                                  'Firestore could not load sessions for this team. Check database rules and connection.',
                              actionLabel: 'Try Again',
                              onAction: () => setState(() {}),
                            );
                          }

                          if (sessions.isEmpty) {
                            return AppEmptyStateView(
                              icon: Icons.event_note_outlined,
                              title: 'No sessions yet',
                              message:
                                  'Create a rehearsal session for ${AppSession.currentTeamName} so attendance can be recorded on time.',
                              actionLabel: 'Add Session',
                              onAction: () => _openSessionForm(session: null),
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                            child: ListView.separated(
                              itemCount: sessions.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                return _buildSessionCard(sessions[index]);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
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
                _BottomNavItem(
                  label: 'Attendance',
                  icon: Icons.checklist,
                  active: false,
                  onTap: () => Navigator.pushNamed(context, '/attendance'),
                ),
                _BottomNavItem(
                  label: 'Sessions',
                  icon: Icons.event_note,
                  active: true,
                  onTap: () {},
                ),
              ],
            ),
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

class SessionFormPage extends StatefulWidget {
  const SessionFormPage({super.key, this.session});

  final TeamSession? session;

  @override
  State<SessionFormPage> createState() => _SessionFormPageState();
}

class _SessionFormPageState extends State<SessionFormPage> {
  late final TextEditingController _dayDateController;
  late final TextEditingController _startController;
  late final TextEditingController _endController;
  late final TextEditingController _locationController;
  late final TextEditingController _activityController;
  DateTime? _selectedDate;

  String get _initialDayDate => widget.session?.dayDate ?? '';
  String get _initialStartTime => widget.session?.startTime ?? '';
  String get _initialEndTime => widget.session?.endTime ?? '';
  String get _initialLocation => widget.session?.location ?? '';
  String get _initialActivity => widget.session?.activity ?? '';

  bool get _hasChanges {
    return _dayDateController.text.trim() != _initialDayDate ||
        _startController.text.trim() != _initialStartTime ||
        _endController.text.trim() != _initialEndTime ||
        _locationController.text.trim() != _initialLocation ||
        _activityController.text.trim() != _initialActivity;
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = _parseDayDate(widget.session?.dayDate ?? '');
    _dayDateController = TextEditingController(
      text: widget.session?.dayDate ?? '',
    );
    _startController = TextEditingController(
      text: widget.session?.startTime ?? '',
    );
    _endController = TextEditingController(text: widget.session?.endTime ?? '');
    _locationController = TextEditingController(
      text: widget.session?.location ?? '',
    );
    _activityController = TextEditingController(
      text: widget.session?.activity ?? '',
    );
  }

  @override
  void dispose() {
    _dayDateController.dispose();
    _startController.dispose();
    _endController.dispose();
    _locationController.dispose();
    _activityController.dispose();
    super.dispose();
  }

  void _saveSession() {
    final dayDate = _dayDateController.text.trim();
    final startTime = _startController.text.trim();
    final endTime = _endController.text.trim();
    final location = _locationController.text.trim();
    final activity = _activityController.text.trim();

    if (dayDate.isEmpty ||
        startTime.isEmpty ||
        endTime.isEmpty ||
        location.isEmpty ||
        activity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all session details.'),
          duration: Duration(milliseconds: 900),
        ),
      );
      return;
    }

    final start = _parseTimeOfDay(startTime);
    final end = _parseTimeOfDay(endTime);
    if (start == null ||
        end == null ||
        (end.hour * 60 + end.minute) <= (start.hour * 60 + start.minute)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End Time must be later than Start Time.'),
          duration: Duration(milliseconds: 1200),
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      TeamSession(
        id: widget.session?.id ?? '',
        dayDate: dayDate,
        location: location,
        activity: activity,
        startTime: startTime,
        endTime: endTime,
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );

    if (picked == null) return;

    setState(() {
      _selectedDate = picked;
      _dayDateController.text = _formatDayDate(picked);
    });
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final now = TimeOfDay.now();
    final initial = _parseTimeOfDay(controller.text) ?? now;
    final picked = await showTimePicker(context: context, initialTime: initial);

    if (picked == null) return;

    setState(() {
      controller.text = _formatTimeOfDay(picked);
    });
  }

  TimeOfDay? _parseTimeOfDay(String input) {
    final parts = input.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  DateTime? _parseDayDate(String input) {
    final months = {
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

    final parts = input.split(', ');
    if (parts.length != 2) return null;
    final dateParts = parts[1].split(' ');
    if (dateParts.length != 2) return null;

    final month = months[dateParts[0]];
    final day = int.tryParse(dateParts[1]);
    if (month == null || day == null) return null;

    final year = DateTime.now().year;
    return DateTime(year, month, day);
  }

  String _formatDayDate(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  Future<bool> _confirmDiscardChanges() async {
    if (!_hasChanges) return true;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text('Your session changes have not been saved yet.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('KEEP EDITING'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10316B),
                foregroundColor: Colors.white,
              ),
              child: const Text('DISCARD'),
            ),
          ],
        );
      },
    );

    return shouldDiscard ?? false;
  }

  Future<void> _handleBack() async {
    if (await _confirmDiscardChanges() && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.session != null;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FF),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 20,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(16, 49, 107, 0.08),
                      blurRadius: 16,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: Tooltip(
                        message: 'Back',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _handleBack,
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(
                              Icons.arrow_back,
                              color: Color(0xFF10316B),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          isEditing ? 'Edit Session' : 'Add Session',
                          style: const TextStyle(
                            color: Color(0xFF10316B),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 42),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 44,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _SessionField(
                                label: 'Day & Date',
                                controller: _dayDateController,
                                hint: 'Tue, Apr 14',
                                readOnly: true,
                                onTap: _pickDate,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _SessionField(
                                      label: 'Start Time',
                                      controller: _startController,
                                      hint: '18:00',
                                      readOnly: true,
                                      onTap: () => _pickTime(_startController),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: _SessionField(
                                      label: 'End Time',
                                      controller: _endController,
                                      hint: '20:00',
                                      readOnly: true,
                                      onTap: () => _pickTime(_endController),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _SessionField(
                                label: 'Location',
                                controller: _locationController,
                                hint: 'Main Hall',
                              ),
                              const SizedBox(height: 16),
                              _SessionField(
                                label: 'Activity',
                                controller: _activityController,
                                hint: 'Easter rehearsal',
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _handleBack,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFF10316B,
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFF10316B),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                      ),
                                      child: const Text('CANCEL'),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _saveSession,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF10316B,
                                        ),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                      ),
                                      child: const Text(
                                        'SAVE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionField extends StatelessWidget {
  const _SessionField({
    required this.label,
    required this.controller,
    required this.hint,
    this.readOnly = false,
    this.onTap,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF10316B),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF8A99C6)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFFBCC9F0)),
              borderRadius: BorderRadius.circular(16),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF10316B)),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }
}
