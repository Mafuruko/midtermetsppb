import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_entry_shell.dart';
import 'auth_error_message.dart';
import 'register_page.dart';
import 'select_teams_page.dart';
import 'user_repository.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _gmailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _isLoading = false;
  final _userRepository = const UserRepository();

  @override
  void dispose() {
    _gmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn() {
    if (_isLoading) return;
    _submitSignIn();
  }

  Future<void> _submitSignIn() async {
    final email = _gmailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gmail dan password wajib diisi.'),
          duration: Duration(milliseconds: 1200),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        _userRepository.upsertUserProfile(user).catchError((_) {});
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

  void _openRegister() {
    if (_isLoading) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppEntryShell(
      heroTitle: 'Welcome back',
      heroSubtitle:
          'Continue with your choir attendance, sessions, and team updates.',
      enableDraggableBody: true,
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
                    title: 'Login',
                    subtitle: 'Enter your account details to continue.',
                  ),
                  const SizedBox(height: 24),
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
                    hint: 'Enter your password',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: !_passwordVisible,
                    textInputAction: TextInputAction.done,
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
                  const SizedBox(height: 24),
                  AppEntryPrimaryButton(
                    label: _isLoading ? 'Signing In...' : 'Sign In',
                    icon: Icons.arrow_forward_rounded,
                    onTap: _signIn,
                  ),
                  const Spacer(),
                  const SizedBox(height: 16),
                  AppEntryTextLinkRow(
                    prompt: 'Don\'t have an account?',
                    actionLabel: 'Register',
                    onTap: _openRegister,
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
