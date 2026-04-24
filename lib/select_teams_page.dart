import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_empty_state.dart';
import 'app_entry_shell.dart';
import 'app_session.dart';
import 'create_team_page.dart';
import 'login_page.dart';
import 'notification_service.dart';
import 'team_repository.dart';

class SelectTeamsPage extends StatefulWidget {
  const SelectTeamsPage({super.key});

  @override
  State<SelectTeamsPage> createState() => _SelectTeamsPageState();
}

class _SelectTeamsPageState extends State<SelectTeamsPage> {
  final _teamRepository = TeamRepository();
  final _notificationService = NotificationService.instance;

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  Future<void> _openCreateTeam() async {
    final user = _currentUser;
    if (user == null) {
      _openLogin();
      return;
    }

    final newTeam = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (_) => const CreateTeamPage()),
    );

    if (!mounted || newTeam == null || newTeam.isEmpty) return;

    try {
      await _teamRepository.createTeam(name: newTeam, ownerUid: user.uid);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Created "$newTeam"'),
          duration: const Duration(milliseconds: 900),
        ),
      );
    } on FirebaseException catch (error) {
      _showError(error);
    }
  }

  Future<void> _openEditTeam(AppTeam team) async {
    final editedTeam = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateTeamPage(initialTeamName: team.name),
      ),
    );

    if (!mounted ||
        editedTeam == null ||
        editedTeam.isEmpty ||
        editedTeam == team.name) {
      return;
    }

    try {
      await _teamRepository.updateTeam(teamId: team.id, name: editedTeam);

      if (AppSession.currentTeamId == team.id) {
        AppSession.selectTeam(id: team.id, name: editedTeam);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated "$editedTeam"'),
          duration: const Duration(milliseconds: 900),
        ),
      );
    } on FirebaseException catch (error) {
      _showError(error);
    }
  }

  Future<void> _confirmDeleteTeam(AppTeam team) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete team?'),
          content: Text(
            '${team.name} will be removed with its team data references.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
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
      await _teamRepository.deleteTeam(team.id);

      if (AppSession.currentTeamId == team.id) {
        AppSession.clearTeam();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "${team.name}"'),
          duration: const Duration(milliseconds: 900),
        ),
      );
    } on FirebaseException catch (error) {
      _showError(error);
    }
  }

  Future<void> _selectTeam(AppTeam team) async {
    AppSession.selectTeam(id: team.id, name: team.name);
    try {
      await _notificationService.replaceTeamSessionReminders(
        teamId: team.id,
        teamName: team.name,
      );
    } catch (_) {}
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
  }

  void _openLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  void _showError(FirebaseException error) {
    if (!mounted) return;

    final rawMessage = error.message ?? '';
    final message = switch (error.code) {
      'permission-denied'
          when rawMessage.contains('firestore.googleapis.com') =>
        'Cloud Firestore belum aktif untuk project ini. Aktifkan Firestore Database di Firebase Console.',
      'permission-denied' =>
        'Firestore menolak akses. Cek rules untuk users dan teams.',
      'unavailable' => 'Firestore sedang tidak tersedia. Coba lagi nanti.',
      _ => rawMessage.isEmpty ? 'Team gagal diproses.' : rawMessage,
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 2200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;

    return AppEntryShell(
      heroTitle: 'Choose your team',
      heroSubtitle: 'Continue with the choir team you want to manage today.',
      bodyBuilder: (context, constraints, scrollController) {
        if (user == null) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            child: Center(
              child: AppEmptyStateCard(
                icon: Icons.lock_outline_rounded,
                title: 'Session expired',
                message: 'Please login again before selecting a team.',
                actionLabel: 'Login',
                onAction: _openLogin,
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: SizedBox(
            height: constraints.maxHeight,
            child: StreamBuilder<List<AppTeam>>(
              stream: _teamRepository.watchUserTeams(user.uid),
              builder: (context, snapshot) {
                final teams = snapshot.data ?? const <AppTeam>[];
                final isLoading =
                    snapshot.connectionState == ConnectionState.waiting;
                final hasError = snapshot.hasError;
                final errorText = snapshot.error?.toString() ?? '';
                final unavailableMessage =
                    errorText.contains('firestore.googleapis.com')
                    ? 'Cloud Firestore belum aktif untuk project ini. Aktifkan Firestore Database di Firebase Console.'
                    : 'Firestore could not load your teams. Check database rules and connection.';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppEntrySectionHeader(
                      title: 'Select Team',
                      subtitle: isLoading
                          ? 'Loading teams...'
                          : '${teams.length} ${teams.length == 1 ? 'team' : 'teams'} available',
                      trailing: Tooltip(
                        message: 'Add Team',
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: _openCreateTeam,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE2EAFE),
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color.fromRGBO(16, 49, 107, 0.05),
                                    blurRadius: 14,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: Color(0xFF10316B),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF10316B),
                              ),
                            )
                          : hasError
                          ? Center(
                              child: AppEmptyStateCard(
                                icon: Icons.cloud_off_outlined,
                                title: 'Teams unavailable',
                                message: unavailableMessage,
                                actionLabel: 'Try Again',
                                onAction: () => setState(() {}),
                              ),
                            )
                          : teams.isEmpty
                          ? Center(
                              child: AppEmptyStateCard(
                                icon: Icons.groups_2_outlined,
                                title: 'No teams yet',
                                message:
                                    'Create your first choir team to continue.',
                                actionLabel: 'Create Team',
                                onAction: _openCreateTeam,
                              ),
                            )
                          : ListView.separated(
                              itemCount: teams.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final team = teams[index];
                                final canManage = team.isOwner(user.uid);
                                return AppTeamOptionCard(
                                  title: team.name,
                                  onTap: () => _selectTeam(team),
                                  onEdit: canManage
                                      ? () => _openEditTeam(team)
                                      : null,
                                  onDelete: canManage
                                      ? () => _confirmDeleteTeam(team)
                                      : null,
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 16),
                    AppEntryTextLinkRow(
                      prompt: 'Need another team?',
                      actionLabel: 'Create one',
                      onTap: _openCreateTeam,
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
