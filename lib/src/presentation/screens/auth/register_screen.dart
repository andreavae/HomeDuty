import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/providers/repositories_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _passwordCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _usernameCtrl.dispose();
    _displayNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).register(
        username: _usernameCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        displayName: _displayNameCtrl.text.trim(),
      );
      if (!mounted) return;
      context.go('/household');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(labelText: 'Unique username'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _displayNameCtrl,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordCtrl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loading ? null : _register,
              child: Text(_loading ? 'Please wait...' : 'Create account'),
            ),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Already have an account? Login'),
            ),
          ],
        ),
      ),
    );
  }
}
