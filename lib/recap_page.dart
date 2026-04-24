import 'package:flutter/material.dart';

import 'app_empty_state.dart';
import 'app_motion.dart';
import 'app_session.dart';
import 'recap_repository.dart';
import 'select_teams_page.dart';

class RecapPage extends StatefulWidget {
  const RecapPage({super.key});

  @override
  State<RecapPage> createState() => _RecapPageState();
}

class _RecapPageState extends State<RecapPage> {
  static const Color _pageBg = Color(0xFFF4F7FF);
  static const Color _primary = Color(0xFF10316B);
  static const Color _muted = Color(0xFF8A99C6);
  static const Color _border = Color(0xFFBCC9F0);
  static const Color _warning = Color(0xFFF6C43C);
  static const Color _danger = Color(0xFFE92E2E);

  final _recapRepository = RecapRepository();

  Future<RecapData>? _recapFuture;
  String? _loadedTeamId;
  String? _selectedMonthKey;

  String? get _teamId => AppSession.currentTeamId;

  Future<RecapData> _recapForTeam(String teamId) {
    if (_loadedTeamId != teamId || _recapFuture == null) {
      _loadedTeamId = teamId;
      _recapFuture = _recapRepository.loadMonthlyRecap(
        teamId: teamId,
        monthKey: _selectedMonthKey,
      );
    }
    return _recapFuture!;
  }

  void _reloadRecap() {
    final teamId = _teamId;
    if (teamId == null) return;

    setState(() {
      _loadedTeamId = teamId;
      _recapFuture = _recapRepository.loadMonthlyRecap(
        teamId: teamId,
        monthKey: _selectedMonthKey,
      );
    });
  }

  void _changeMonth(String? monthKey) {
    final teamId = _teamId;
    if (teamId == null || monthKey == null) return;

    setState(() {
      _selectedMonthKey = monthKey;
      _loadedTeamId = teamId;
      _recapFuture = _recapRepository.loadMonthlyRecap(
        teamId: teamId,
        monthKey: monthKey,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final teamId = _teamId;

    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: Column(
          children: [
            _RecapHeader(
              onBack: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/dashboard',
                (route) => false,
              ),
            ),
            Expanded(
              child: SoftFadeIn(
                child: teamId == null
                    ? _buildTeamRequiredState()
                    : FutureBuilder<RecapData>(
                        future: _recapForTeam(teamId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(color: _primary),
                            );
                          }

                          if (snapshot.hasError) {
                            return AppEmptyStateView(
                              icon: Icons.cloud_off_outlined,
                              title: 'Recap unavailable',
                              message:
                                  'Firestore could not load recap data. Check database rules and connection.',
                              actionLabel: 'Try Again',
                              onAction: _reloadRecap,
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                16,
                                18,
                                16,
                              ),
                            );
                          }

                          final recap = snapshot.data;
                          if (recap == null || !recap.hasRecap) {
                            return AppEmptyStateView(
                              icon: Icons.bar_chart_outlined,
                              title: 'No recap data yet',
                              message:
                                  'Create members, sessions, and attendance records first so monthly recap can be calculated.',
                              actionLabel: 'Refresh',
                              onAction: _reloadRecap,
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                16,
                                18,
                                16,
                              ),
                            );
                          }

                          return RefreshIndicator(
                            color: _primary,
                            onRefresh: () async {
                              final refreshed = _recapRepository
                                  .loadMonthlyRecap(
                                    teamId: teamId,
                                    monthKey: recap.selectedMonth?.key,
                                  );
                              setState(() {
                                _selectedMonthKey = recap.selectedMonth?.key;
                                _recapFuture = refreshed;
                              });
                              await refreshed;
                            },
                            child: _buildRecapContent(recap),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _RecapBottomNav(),
    );
  }

  Widget _buildTeamRequiredState() {
    return AppEmptyStateView(
      icon: Icons.groups_2_outlined,
      title: 'No team selected',
      message: 'Select a team first so monthly recap can be calculated.',
      actionLabel: 'Select Team',
      onAction: () => Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SelectTeamsPage()),
        (route) => false,
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
    );
  }

  Widget _buildRecapContent(RecapData recap) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MonthDropdown(
            value: recap.selectedMonth?.key ?? recap.months.first.key,
            months: recap.months,
            onChanged: _changeMonth,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  icon: Icons.event_note,
                  value: recap.totalSessions.toString(),
                  label: 'Total Sessions',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.trending_up,
                  value: '${recap.averageAttendance}%',
                  label: 'Avg Attendance',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(height: 236, child: _RecapTable(members: recap.members)),
          const SizedBox(height: 16),
          _SectionTitle(
            title: 'Attendance Rate',
            subtitle: 'Scroll untuk lihat semua anggota',
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 230,
            child: _AttendanceRateList(
              members: recap.members,
              totalSessions: recap.totalSessions,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecapHeader extends StatelessWidget {
  const _RecapHeader({required this.onBack});

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
                'Monthly Recap',
                style: TextStyle(
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
    );
  }
}

class _MonthDropdown extends StatelessWidget {
  const _MonthDropdown({
    required this.value,
    required this.months,
    required this.onChanged,
  });

  final String value;
  final List<RecapMonthOption> months;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      icon: const Icon(
        Icons.keyboard_arrow_down,
        color: _RecapPageState._primary,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _RecapPageState._border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _RecapPageState._primary),
        ),
      ),
      onChanged: onChanged,
      items: months
          .map(
            (month) => DropdownMenuItem(
              value: month.key,
              child: Text(
                month.label,
                style: const TextStyle(
                  color: _RecapPageState._primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $value',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE4EBFF)),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(16, 49, 107, 0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF0FF),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _RecapPageState._primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _RecapPageState._primary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _RecapPageState._muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecapTable extends StatelessWidget {
  const _RecapTable({required this.members});

  final List<RecapMember> members;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4EBFF)),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(16, 49, 107, 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 44,
            color: const Color(0xFFF4F7FF),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: const Row(
              children: [
                _CompactHeaderCell('Name'),
                _CompactHeaderCell('H', tooltip: 'Hadir'),
                _CompactHeaderCell('T', tooltip: 'Telat'),
                _CompactHeaderCell('A', tooltip: 'Alpha'),
                _CompactHeaderCell('S', tooltip: 'Sakit'),
                _CompactHeaderCell('I', tooltip: 'Izin'),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: members.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFE4EBFF),
              ),
              itemBuilder: (context, index) {
                final member = members[index];

                return _CompactTableRow(member: member);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactHeaderCell extends StatelessWidget {
  const _CompactHeaderCell(this.label, {this.tooltip});

  final String label;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: label == 'Name' ? TextAlign.left : TextAlign.center,
      style: const TextStyle(
        color: Color(0xFF4C5B8A),
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );

    return Expanded(
      flex: label == 'Name' ? 5 : 2,
      child: tooltip == null ? text : Tooltip(message: tooltip!, child: text),
    );
  }
}

class _CompactTableRow extends StatelessWidget {
  const _CompactTableRow({required this.member});

  final RecapMember member;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Text(
                member.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF0B1D45),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _CompactValueCell(member.present.toString()),
            _CompactValueCell(
              member.late.toString(),
              color: _RecapPageState._warning,
            ),
            _CompactValueCell(
              member.alpha.toString(),
              color: _RecapPageState._danger,
            ),
            _CompactValueCell(member.sick.toString()),
            _CompactValueCell(member.permission.toString()),
          ],
        ),
      ),
    );
  }
}

class _CompactValueCell extends StatelessWidget {
  const _CompactValueCell(this.value, {this.color = _RecapPageState._primary});

  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _RecapPageState._primary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Flexible(
          child: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: _RecapPageState._muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _AttendanceRateList extends StatelessWidget {
  const _AttendanceRateList({
    required this.members,
    required this.totalSessions,
  });

  final List<RecapMember> members;
  final int totalSessions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4EBFF)),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(16, 49, 107, 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: members.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final member = members[index];
          final rate = totalSessions == 0
              ? 0
              : ((member.attended / totalSessions) * 100).round();

          return _RateItem(name: member.name, rate: rate);
        },
      ),
    );
  }
}

class _RateItem extends StatelessWidget {
  const _RateItem({required this.name, required this.rate});

  final String name;
  final int rate;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Attendance rate for $name is $rate percent',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF4C5B8A),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$rate%',
                style: const TextStyle(
                  color: Color(0xFF0B1D45),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: rate / 100,
              minHeight: 7,
              backgroundColor: const Color(0xFFEAF0FF),
              valueColor: const AlwaysStoppedAnimation<Color>(
                _RecapPageState._primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecapBottomNav extends StatelessWidget {
  const _RecapBottomNav();

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
              const _BottomNavItem(
                label: 'Recap',
                icon: Icons.bar_chart,
                active: true,
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
