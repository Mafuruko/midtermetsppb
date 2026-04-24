import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_motion.dart';
import 'app_session.dart';
import 'login_page.dart';
import 'members_page.dart';
import 'notification_service.dart';
import 'select_teams_page.dart';
import 'sessions_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, this.teamName});

  final String? teamName;

  String _currentUserName() {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final emailName = user?.email?.split('@').first.trim();
    if (emailName != null && emailName.isNotEmpty) {
      return emailName;
    }

    return 'User';
  }

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Log out?'),
          content: const Text('You will return to the login page.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10316B),
                foregroundColor: Colors.white,
              ),
              child: const Text('LOG OUT'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !context.mounted) return;

    AppSession.clearTeam();
    await NotificationService.instance.clearAllSessionReminders();
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  void _openSelectTeams(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const SelectTeamsPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(16, 49, 107, 0.08),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      teamName ?? AppSession.currentTeamName,
                      style: const TextStyle(
                        color: Color(0xFF10316B),
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _handleLogout(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF5F8FF),
                        ),
                        child: const Icon(
                          Icons.logout,
                          color: Color(0xFFE92E2E),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SoftFadeIn(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dashboard',
                        style: TextStyle(
                          color: Color(0xFF10316B),
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Welcome Back, ${_currentUserName()}',
                        style: const TextStyle(
                          color: Color(0xFF4C5B8A),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.95,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _DashboardCard(
                            title: 'Members',
                            subtitle: 'Manage Choir Members',
                            icon: Icons.group,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MembersPage(),
                                ),
                              );
                            },
                          ),
                          _DashboardCard(
                            title: 'Sessions',
                            subtitle: 'Practice Sessions',
                            icon: Icons.event_note,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SessionsPage(),
                                ),
                              );
                            },
                          ),
                          _DashboardCard(
                            title: 'Attendance',
                            subtitle: 'Record Attendance',
                            icon: Icons.checklist,
                            onTap: () =>
                                Navigator.pushNamed(context, '/attendance'),
                          ),
                          _DashboardCard(
                            title: 'Recap',
                            subtitle: 'Monthly Reports',
                            icon: Icons.bar_chart,
                            onTap: () => Navigator.pushNamed(context, '/recap'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SwitchTeamCard(
                        currentTeamName: teamName ?? AppSession.currentTeamName,
                        onTap: () => _openSelectTeams(context),
                      ),
                    ],
                  ),
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
                _NavItem(
                  label: 'Recap',
                  icon: Icons.bar_chart,
                  active: false,
                  onTap: () => Navigator.pushNamed(context, '/recap'),
                ),
                _NavItem(
                  label: 'Members',
                  icon: Icons.group,
                  active: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MembersPage(),
                      ),
                    );
                  },
                ),
                _NavItem(
                  label: 'Home',
                  icon: Icons.home,
                  active: true,
                  onTap: () {},
                ),
                _NavItem(
                  label: 'Attendance',
                  icon: Icons.checklist,
                  active: false,
                  onTap: () => Navigator.pushNamed(context, '/attendance'),
                ),
                _NavItem(
                  label: 'Sessions',
                  icon: Icons.event_note,
                  active: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SessionsPage(),
                      ),
                    );
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

class _SwitchTeamCard extends StatelessWidget {
  const _SwitchTeamCard({required this.currentTeamName, required this.onTap});

  final String currentTeamName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2EAFE)),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(16, 49, 107, 0.05),
                blurRadius: 14,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  color: Color(0xFF10316B),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Other Team',
                      style: TextStyle(
                        color: Color(0xFF10316B),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentTeamName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6C7B9A),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFF8A99C6),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF10316B), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(16, 49, 107, 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF0FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF10316B), size: 24),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF10316B),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF5F6F9F),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
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
    return GestureDetector(
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
              color: active ? const Color(0xFF10316B) : const Color(0xFF8A99C6),
            ),
          ),
        ],
      ),
    );
  }
}
