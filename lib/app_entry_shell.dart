import 'package:flutter/material.dart';

import 'app_motion.dart';

typedef AppEntryBodyBuilder =
    Widget Function(
      BuildContext context,
      BoxConstraints constraints,
      ScrollController? scrollController,
    );

class AppEntryShell extends StatefulWidget {
  const AppEntryShell({
    super.key,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.bodyBuilder,
    this.leading,
    this.trailing,
    this.badgeText = 'Choir Practice Attendance',
    this.showLogo = true,
    this.enableDraggableBody = false,
    this.initialBodySize = 0.56,
    this.minBodySize = 0.52,
    this.maxBodySize = 0.9,
  });

  final String heroTitle;
  final String heroSubtitle;
  final Widget? leading;
  final Widget? trailing;
  final String? badgeText;
  final bool showLogo;
  final bool enableDraggableBody;
  final double initialBodySize;
  final double minBodySize;
  final double maxBodySize;
  final AppEntryBodyBuilder bodyBuilder;

  @override
  State<AppEntryShell> createState() => _AppEntryShellState();
}

class _AppEntryShellState extends State<AppEntryShell> {
  List<double> get _snapSizes {
    final sizes = <double>{
      widget.minBodySize,
      widget.initialBodySize,
      widget.maxBodySize,
    }.toList()..sort();
    return sizes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.42, 1],
                  colors: [
                    Color(0xFF2F6DF6),
                    Color(0xFF0B409C),
                    Color(0xFFF4F7FF),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: widget.enableDraggableBody
                ? Stack(
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                          child: SoftFadeIn(
                            duration: const Duration(milliseconds: 420),
                            offset: 10,
                            child: _EntryHeroContent(
                              heroTitle: widget.heroTitle,
                              heroSubtitle: widget.heroSubtitle,
                              leading: widget.leading,
                              trailing: widget.trailing,
                              badgeText: widget.badgeText,
                              showLogo: widget.showLogo,
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: SoftFadeIn(
                          duration: const Duration(milliseconds: 460),
                          offset: 24,
                          child: DraggableScrollableSheet(
                            initialChildSize: widget.initialBodySize,
                            minChildSize: widget.minBodySize,
                            maxChildSize: widget.maxBodySize,
                            snap: true,
                            snapSizes: _snapSizes,
                            builder: (context, scrollController) {
                              return _EntryBodyCard(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return widget.bodyBuilder(
                                      context,
                                      constraints,
                                      scrollController,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        child: SoftFadeIn(
                          duration: const Duration(milliseconds: 420),
                          offset: 10,
                          child: _EntryHeroContent(
                            heroTitle: widget.heroTitle,
                            heroSubtitle: widget.heroSubtitle,
                            leading: widget.leading,
                            trailing: widget.trailing,
                            badgeText: widget.badgeText,
                            showLogo: widget.showLogo,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SoftFadeIn(
                          duration: const Duration(milliseconds: 460),
                          offset: 24,
                          child: _EntryBodyCard(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return widget.bodyBuilder(
                                  context,
                                  constraints,
                                  null,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class AppEntrySectionHeader extends StatelessWidget {
  const AppEntrySectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF10316B),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF6C7B9A),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

class _EntryHeroContent extends StatelessWidget {
  const _EntryHeroContent({
    required this.heroTitle,
    required this.heroSubtitle,
    required this.leading,
    required this.trailing,
    required this.badgeText,
    required this.showLogo,
  });

  final String heroTitle;
  final String heroSubtitle;
  final Widget? leading;
  final Widget? trailing;
  final String? badgeText;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _HeaderSlot(child: leading),
            const Spacer(),
            _HeaderSlot(child: trailing),
          ],
        ),
        if (showLogo) ...[const SizedBox(height: 10), const _EntryLogo()],
        if (badgeText != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 255, 255, 0.16),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: const Color.fromRGBO(255, 255, 255, 0.2),
              ),
            ),
            child: Text(
              badgeText!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          heroTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          heroSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFDCE7FF),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _EntryBodyCard extends StatelessWidget {
  const _EntryBodyCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF4F7FF),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(16, 49, 107, 0.08),
            blurRadius: 22,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 12),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD4E0FA),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class AppEntryTextField extends StatelessWidget {
  const AppEntryTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.readOnly = false,
    this.onTap,
    this.textInputAction,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF10316B),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          readOnly: readOnly,
          onTap: onTap,
          textInputAction: textInputAction,
          style: const TextStyle(
            color: Color(0xFF10316B),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF8A99C6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: prefixIcon == null
                ? null
                : Icon(prefixIcon, color: const Color(0xFF10316B)),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFD2DCF3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF10316B),
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AppEntryPrimaryButton extends StatelessWidget {
  const AppEntryPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10316B), Color(0xFF0B409C)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(16, 49, 107, 0.2),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(icon, color: Colors.white, size: 18),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppEntryTextLinkRow extends StatelessWidget {
  const AppEntryTextLinkRow({
    super.key,
    required this.prompt,
    required this.actionLabel,
    required this.onTap,
  });

  final String prompt;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Text(
          prompt,
          style: const TextStyle(
            color: Color(0xFF6C7B9A),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: const Text(' ', style: TextStyle(fontSize: 0)),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF10316B),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            minimumSize: Size.zero,
          ),
          child: Text(
            actionLabel,
            style: const TextStyle(
              color: Color(0xFF10316B),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class AppEntryHeaderButton extends StatelessWidget {
  const AppEntryHeaderButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: const Color.fromRGBO(255, 255, 255, 0.16),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class AppTeamOptionCard extends StatelessWidget {
  const AppTeamOptionCard({
    super.key,
    required this.title,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final String title;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  String get _initials {
    final parts = title
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) return 'T';
    return parts.map((part) => part[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials,
                  style: const TextStyle(
                    color: Color(0xFF10316B),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF10316B),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Choir Team',
                      style: TextStyle(
                        color: Color(0xFF6C7B9A),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (onEdit != null || onDelete != null)
                PopupMenuButton<String>(
                  tooltip: 'Team actions',
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Color(0xFF8A99C6),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit?.call();
                    } else if (value == 'delete') {
                      onDelete?.call();
                    }
                  },
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                  ],
                )
              else
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Color(0xFF8A99C6),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryLogo extends StatelessWidget {
  const _EntryLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(11, 64, 156, 0.2),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF10316B),
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/logo.jpg',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.music_note_rounded,
                color: Colors.white,
                size: 40,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HeaderSlot extends StatelessWidget {
  const _HeaderSlot({this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 44, height: 44, child: child);
  }
}
