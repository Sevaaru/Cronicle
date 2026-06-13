import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/identity/data/cronicle_auth_service.dart';
import 'package:cronicle/features/identity/presentation/cronicle_auth_providers.dart';
import 'package:cronicle/features/onboarding/presentation/onboarding_notifier.dart';
import 'package:cronicle/features/settings/presentation/app_defaults_notifier.dart';
import 'package:cronicle/l10n/app_localizations.dart';

class CronicleUsernamePage extends ConsumerStatefulWidget {
  const CronicleUsernamePage({super.key});

  @override
  ConsumerState<CronicleUsernamePage> createState() =>
      _CronicleUsernamePageState();
}

class _CronicleUsernamePageState extends ConsumerState<CronicleUsernamePage> {
  final _controller = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context)!;
    final raw = _controller.text.trim().toLowerCase();

    if (!CronicleAuthService.isConfigured) return;
    if (!RegExp(r'^[a-z0-9_]{3,24}$').hasMatch(raw)) {
      setState(() => _error = l10n.cronicleUsernameInvalid);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final auth = ref.read(cronicleAuthServiceProvider);
      final available = await auth.isUsernameAvailable(raw);
      if (!available) {
        setState(() {
          _error = l10n.cronicleUsernameTaken;
          _saving = false;
        });
        return;
      }

      await auth.claimUsername(raw);
      await ref.read(cronicleMyProfileProvider.notifier).refresh();
      if (!mounted) return;

      final onboardingDone = ref.read(onboardingCompletedProvider);
      if (!onboardingDone) {
        context.go('/onboarding');
      } else {
        context.go(ref.read(defaultStartPageProvider));
      }
    } on StateError catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message == 'username_taken'
            ? l10n.cronicleUsernameTaken
            : l10n.errorWithMessage(e.message);
        _saving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = l10n.errorWithMessage(e.toString());
        _saving = false;
      });
    }
  }

  Future<void> _signOut() async {
    await ref.read(cronicleAuthServiceProvider).signOut();
    await ref.read(cronicleMyProfileProvider.notifier).refresh();
    if (!mounted) return;
    context.go('/cronicle-login');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: _saving ? null : _signOut,
            child: Text(l10n.cronicleAccountSignOut),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.cronicleUsernameTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.cronicleUsernameSubtitle,
                    style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _controller,
                    autocorrect: false,
                    decoration: InputDecoration(
                      prefixText: '@',
                      labelText: l10n.cronicleUsernameHint,
                      border: const OutlineInputBorder(),
                      errorText: _error,
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _continue(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _saving ? null : _continue,
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.cronicleUsernameContinue),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
