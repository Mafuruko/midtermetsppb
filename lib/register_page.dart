import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_entry_shell.dart';
import 'auth_error_message.dart';
import 'select_teams_page.dart';
import 'user_repository.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _gmailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isLoading = false;
  final _userRepository = const UserRepository();

  @override
  void dispose() {
    _nameController.dispose();
    _gmailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _createAccount() {
    if (_isLoading) return;
    _submitCreateAccount();
  }

  Future<void> _submitCreateAccount() async {
    final name = _nameController.text.trim();
    final email = _gmailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama, Gmail, dan password wajib diisi.'),
          duration: Duration(milliseconds: 1200),
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konfirmasi password belum sama.'),
          duration: Duration(milliseconds: 1200),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await credential.user?.updateDisplayName(name);
      final user = credential.user;
      if (user != null) {
        _userRepository
            .upsertUserProfile(user, name: name, includeCreatedAt: true)
            .catchError((_) {});
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SelectTeamsPage()),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authErrorMessage(error)),
          duration: const Duration(milliseconds: 1800),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openLogin() {
    if (_isLoading) return;
    Navigator.pop(context);
  }

  void _handleBack() {
    if (_isLoading) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AppEntryShell(
      heroTitle: 'Create your account',
      heroSubtitle:
          'Start organizing teams, sessions, and attendance in one place.',
      enableDraggableBody: true,
      leading: AppEntryHeaderButton(
        icon: Icons.arrow_back_rounded,
        tooltip: 'Back',
        onTap: _handleBack,
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
                    title: 'Register',
                    subtitle: 'Set up your account details to get started.',
                  ),
                  const SizedBox(height: 24),
                  AppEntryTextField(
                    label: 'Full Name',
                    controller: _nameController,
                    hint: 'Enter your full name',
                    prefixIcon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 18),
                  AppEntryTextField(
                    label: 'Gmail',
                    controller: _gmailController,
                    hint: 'name@example.com',
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 18),
                  AppEntryTextField(
                    label: 'Password',
                    controller: _passwordController,
                    hint: 'Enter a password',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: !_passwordVisible,
                    textInputAction: TextInputAction.next,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFF6C7B9A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  AppEntryTextField(
                    label: 'Confirm Password',
                    controller: _confirmPasswordController,
                    hint: 'Re-enter your password',
                    prefixIcon: Icons.verified_user_outlined,
                    obscureText: !_confirmPasswordVisible,
                    textInputAction: TextInputAction.done,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _confirmPasswordVisible = !_confirmPasswordVisible;
                        });
                      },
                      icon: Icon(
                        _confirmPasswordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFF6C7B9A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppEntryPrimaryButton(
                    label: _isLoading
                        ? 'Creating Account...'
                        : 'Create Account',
                    icon: Icons.arrow_forward_rounded,
                    onTap: _createAccount,
                  ),
                  const Spacer(),
                  const SizedBox(height: 16),
                  AppEntryTextLinkRow(
                    prompt: 'Already have an account?',
                    actionLabel: 'Login',
                    onTap: _openLogin,
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
