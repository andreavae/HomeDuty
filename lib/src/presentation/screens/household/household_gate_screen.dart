import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/providers/repositories_providers.dart';
import '../../state/household_state.dart';

class HouseholdGateScreen extends ConsumerStatefulWidget {
  const HouseholdGateScreen({super.key});

  @override
  ConsumerState<HouseholdGateScreen> createState() => _HouseholdGateScreenState();
}

class _HouseholdGateScreenState extends ConsumerState<HouseholdGateScreen> {
  final _createCtrl = TextEditingController();
  final _joinCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkMembership();
    });
  }

  Future<void> _checkMembership() async {
    final household = await ref.read(currentHouseholdProvider.future);
    if (!mounted) return;
    if (household != null) context.go('/app');
  }

  Future<void> _create() async {
    setState(() => _loading = true);
    try {
      await ref.read(householdRepositoryProvider).createHousehold(_createCtrl.text.trim());
      ref.invalidate(currentHouseholdProvider);
      if (!mounted) return;
      context.go('/app');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating household: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _join() async {
    setState(() => _loading = true);
    try {
      await ref.read(householdRepositoryProvider).joinHousehold(_joinCtrl.text.trim());
      ref.invalidate(currentHouseholdProvider);
      if (!mounted) return;
      context.go('/app');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining household: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _createCtrl.dispose();
    _joinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Household Setup')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Create a new household'),
          const SizedBox(height: 8),
          TextField(
            controller: _createCtrl,
            decoration: const InputDecoration(labelText: 'Household name'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _loading ? null : _create,
            child: const Text('Create household'),
          ),
          const Divider(height: 32),
          const Text('Or join an existing household'),
          const SizedBox(height: 8),
          TextField(
            controller: _joinCtrl,
            decoration: const InputDecoration(labelText: 'Household ID'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: _loading ? null : _join,
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }
}
