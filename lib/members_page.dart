import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app_session.dart';
import 'app_empty_state.dart';
import 'app_motion.dart';
import 'member_repository.dart';
import 'select_teams_page.dart';

const List<String> soundTypes = [
  'Soprano 1',
  'Soprano 2',
  'Alto 1',
  'Alto 2',
  'Tenor 1',
  'Tenor 2',
  'Bass 1',
  'Bass 2',
];

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  final _memberRepository = MemberRepository();

  String? get _teamId => AppSession.currentTeamId;

  Future<void> _openMemberForm({TeamMember? member}) async {
    final teamId = _teamId;
    if (teamId == null) {
      _showNoTeamMessage();
      return;
    }

    final result = await Navigator.push<TeamMember?>(
      context,
      MaterialPageRoute(builder: (context) => MemberFormPage(member: member)),
    );

    if (result == null) return;

    try {
      if (member == null) {
        await _memberRepository.createMember(teamId: teamId, member: result);
      } else {
        await _memberRepository.updateMember(teamId: teamId, member: result);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            member == null
                ? 'Added "${result.name}"'
                : 'Updated "${result.name}"',
          ),
          duration: const Duration(milliseconds: 900),
        ),
      );
    } on FirebaseException catch (error) {
      _showFirestoreError(error);
    }
  }

  Future<void> _confirmDelete(TeamMember member) async {
    final teamId = _teamId;
    if (teamId == null) {
      _showNoTeamMessage();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete member?'),
          content: Text('${member.name} will be removed from this team.'),
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
      await _memberRepository.deleteMember(teamId: teamId, memberId: member.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "${member.name}"'),
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
        'Firestore menolak akses members. Cek rules teams/{teamId}/members.',
      'unavailable' => 'Firestore sedang tidak tersedia. Coba lagi nanti.',
      _ => error.message ?? 'Member gagal diproses.',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 2200),
      ),
    );
  }

  Widget _buildMemberCard(TeamMember member) {
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF0FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.music_note, color: Color(0xFF10316B)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF10316B),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _InfoChip(label: member.voiceType),
                    const SizedBox(width: 8),
                    _InfoChip(
                      label: member.angkatan,
                      background: const Color(0xFFF3E6A8),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        member.phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
          const SizedBox(width: 8),
          Column(
            children: [
              Tooltip(
                message: 'Edit member',
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _openMemberForm(member: member),
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
                message: 'Delete member',
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _confirmDelete(member),
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
                        'Members',
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
                      message: 'Add member',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => _openMemberForm(member: null),
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
                            'Select a team first so its members can be managed.',
                        actionLabel: 'Select Team',
                        onAction: () => Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SelectTeamsPage(),
                          ),
                          (route) => false,
                        ),
                      )
                    : StreamBuilder<List<TeamMember>>(
                        stream: _memberRepository.watchTeamMembers(teamId),
                        builder: (context, snapshot) {
                          final members = snapshot.data ?? const <TeamMember>[];
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
                              title: 'Members unavailable',
                              message:
                                  'Firestore could not load members for this team. Check database rules and connection.',
                              actionLabel: 'Try Again',
                              onAction: () => setState(() {}),
                            );
                          }

                          if (members.isEmpty) {
                            return AppEmptyStateView(
                              icon: Icons.group_outlined,
                              title: 'No members yet',
                              message:
                                  'Add choir members for ${AppSession.currentTeamName} so attendance and recap can be used properly.',
                              actionLabel: 'Add Member',
                              onAction: () => _openMemberForm(member: null),
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                            child: ListView.separated(
                              itemCount: members.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                return _buildMemberCard(members[index]);
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
                  onTap: () {
                    Navigator.pushNamed(context, '/recap');
                  },
                ),
                _BottomNavItem(
                  label: 'Members',
                  icon: Icons.group,
                  active: true,
                  onTap: () {},
                ),
                _BottomNavItem(
                  label: 'Home',
                  icon: Icons.home,
                  active: false,
                  onTap: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/dashboard',
                      (route) => route.isFirst,
                    );
                  },
                ),
                _BottomNavItem(
                  label: 'Attendance',
                  icon: Icons.checklist,
                  active: false,
                  onTap: () {
                    Navigator.pushNamed(context, '/attendance');
                  },
                ),
                _BottomNavItem(
                  label: 'Sessions',
                  icon: Icons.event_note,
                  active: false,
                  onTap: () {
                    Navigator.pushNamed(context, '/sessions');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MemberField extends StatelessWidget {
  const _MemberField({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

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
          keyboardType: keyboardType,
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

class MemberFormPage extends StatefulWidget {
  const MemberFormPage({super.key, this.member});

  final TeamMember? member;

  @override
  State<MemberFormPage> createState() => _MemberFormPageState();
}

class _MemberFormPageState extends State<MemberFormPage> {
  late final TextEditingController _nameController;
  late String _selectedVoiceType;
  late final TextEditingController _angkatanController;
  late final TextEditingController _phoneController;

  String get _initialName => widget.member?.name ?? '';
  String get _initialVoiceType => widget.member?.voiceType ?? soundTypes.first;
  String get _initialAngkatan => widget.member?.angkatan ?? '';
  String get _initialPhone => widget.member?.phone ?? '';

  bool get _hasChanges {
    return _nameController.text.trim() != _initialName ||
        _selectedVoiceType != _initialVoiceType ||
        _angkatanController.text.trim() != _initialAngkatan ||
        _phoneController.text.trim() != _initialPhone;
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member?.name ?? '');
    _selectedVoiceType = soundTypes.contains(widget.member?.voiceType)
        ? widget.member!.voiceType
        : soundTypes.first;
    _angkatanController = TextEditingController(
      text: widget.member?.angkatan ?? '',
    );
    _phoneController = TextEditingController(text: widget.member?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _angkatanController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveMember() {
    final name = _nameController.text.trim();
    final voiceType = _selectedVoiceType;
    final angkatan = _angkatanController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || voiceType.isEmpty || angkatan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name, Sound Type, and Angkatan are required.'),
          duration: Duration(milliseconds: 900),
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      TeamMember(
        id: widget.member?.id ?? '',
        name: name,
        voiceType: voiceType,
        angkatan: angkatan,
        phone: phone,
      ),
    );
  }

  Future<bool> _confirmDiscardChanges() async {
    if (!_hasChanges) return true;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text('Your changes have not been saved yet.'),
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
    final isEditing = widget.member != null;
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
                          isEditing ? 'Edit Member' : 'Add Member',
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
                              _MemberField(
                                label: 'Name',
                                controller: _nameController,
                                hint: 'Sarah Johnson',
                              ),
                              const SizedBox(height: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Sound Type',
                                    style: TextStyle(
                                      color: Color(0xFF10316B),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedVoiceType,
                                    decoration: InputDecoration(
                                      hintText: 'Select sound type',
                                      hintStyle: const TextStyle(
                                        color: Color(0xFF8A99C6),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 14,
                                          ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                          color: Color(0xFFBCC9F0),
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                          color: Color(0xFF10316B),
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    items: soundTypes
                                        .map(
                                          (type) => DropdownMenuItem(
                                            value: type,
                                            child: Text(type),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _selectedVoiceType = value;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _MemberField(
                                label: 'Angkatan',
                                controller: _angkatanController,
                                hint: 'LA 24',
                              ),
                              const SizedBox(height: 16),
                              _MemberField(
                                label: 'Phone',
                                controller: _phoneController,
                                hint: '555-0101',
                                keyboardType: TextInputType.phone,
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
                                      onPressed: _saveMember,
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    this.background = const Color(0xFFEAF0FF),
  });

  final String label;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF10316B),
          fontSize: 12,
          fontWeight: FontWeight.w700,
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
