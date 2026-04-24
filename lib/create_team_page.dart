import 'package:flutter/material.dart';

import 'app_entry_shell.dart';

class CreateTeamPage extends StatefulWidget {
  const CreateTeamPage({super.key, this.initialTeamName});

  final String? initialTeamName;

  @override
  State<CreateTeamPage> createState() => _CreateTeamPageState();
}

class _CreateTeamPageState extends State<CreateTeamPage> {
  late final TextEditingController _teamNameController;

  bool get _isEditing => widget.initialTeamName != null;

  @override
  void initState() {
    super.initState();
    _teamNameController = TextEditingController(
      text: widget.initialTeamName ?? '',
    );
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    super.dispose();
  }

  void _submitTeam() {
    final teamName = _teamNameController.text.trim();
    if (teamName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a team name.'),
          duration: Duration(milliseconds: 900),
        ),
      );
      return;
    }
    Navigator.pop(context, teamName);
  }

  @override
  Widget build(BuildContext context) {
    return AppEntryShell(
      heroTitle: _isEditing ? 'Edit team' : 'Create a new team',
      heroSubtitle: _isEditing
          ? 'Update the choir team name used across attendance records.'
          : 'Set up a choir team so attendance and sessions stay organized.',
      leading: AppEntryHeaderButton(
        icon: Icons.arrow_back_rounded,
        tooltip: 'Back',
        onTap: () => Navigator.pop(context),
      ),
      bodyBuilder: (context, constraints, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppEntrySectionHeader(
                    title: 'Team Details',
                    subtitle: 'Choose a clear name your choir will recognize.',
                  ),
                  const SizedBox(height: 24),
                  AppEntryTextField(
                    label: 'Team Name',
                    controller: _teamNameController,
                    hint: 'Enter team name',
                    prefixIcon: Icons.groups_rounded,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2EAFE)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFF10316B),
                          size: 18,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Choose a short, memorable name so the team is easy to find later.',
                            style: TextStyle(
                              color: Color(0xFF6C7B9A),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: 24),
                  AppEntryPrimaryButton(
                    label: _isEditing ? 'Save Team' : 'Create Team',
                    icon: Icons.check_rounded,
                    onTap: _submitTeam,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
