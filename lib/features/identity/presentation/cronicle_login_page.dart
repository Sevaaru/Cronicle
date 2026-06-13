import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cronicle/core/config/env_config.dart';
import 'package:cronicle/core/config/google_web_bootstrap.dart';
import 'package:cronicle/core/network/google_sign_in_provider.dart';
import 'package:cronicle/core/utils/google_web_button.dart';
import 'package:cronicle/features/identity/data/cronicle_auth_service.dart';
import 'package:cronicle/features/identity/presentation/connected_accounts_sync.dart';
import 'package:cronicle/features/identity/presentation/cronicle_auth_providers.dart';
import 'package:cronicle/features/onboarding/presentation/onboarding_notifier.dart';
import 'package:cronicle/features/settings/presentation/app_defaults_notifier.dart';
import 'package:cronicle/l10n/app_localizations.dart';

enum _AuthMode { signIn, signUp }

class CronicleLoginPage extends ConsumerStatefulWidget {
  const CronicleLoginPage({super.key});

  @override
  ConsumerState<CronicleLoginPage> createState() => _CronicleLoginPageState();
}

class _CronicleLoginPageState extends ConsumerState<CronicleLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  _AuthMode _mode = _AuthMode.signIn;
  bool _loading = false;
  bool _obscurePassword = true;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleAuthSub;
  bool _googleListenerAttached = false;

  @override
  void dispose() {
    _googleAuthSub?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _attachGoogleWebListener() {
    if (!kIsWeb || _googleListenerAttached) return;
    _googleListenerAttached = true;
    _googleAuthSub = ref.read(googleSignInProvider).authenticationEvents.listen(
      (event) async {
        if (!mounted) return;
        if (event is! GoogleSignInAuthenticationEventSignIn) return;
        if (ref.read(cronicleAuthSessionProvider).valueOrNull != null) return;

        setState(() => _loading = true);
        final l10n = AppLocalizations.of(context)!;
        try {
          await ref
              .read(cronicleAuthServiceProvider)
              .signInWithGoogleAccount(event.user);
          if (!mounted) return;
          await _afterSignIn();
        } on GoogleSignInException catch (e) {
          if (!mounted) return;
          if (e.code != GoogleSignInExceptionCode.canceled) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.errorWithMessage(e.toString()))),
            );
          }
        } on AuthException catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errorWithMessage(e.message))),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errorWithMessage(e.toString()))),
          );
        } finally {
          if (mounted) setState(() => _loading = false);
        }
      },
      onError: (Object error) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorWithMessage(error.toString()))),
        );
      },
    );
  }

  Future<void> _afterSignIn() async {
    await restoreConnectedAccounts(ref);
    await ref.read(connectedAccountsRepositoryProvider)?.pushAllConnected();
    await ref.read(cronicleMyProfileProvider.notifier).refresh();
    final profile = ref.read(cronicleMyProfileProvider).valueOrNull;
    if (!mounted) return;

    if (profile?.needsUsernameSetup == true) {
      context.go('/cronicle-username');
      return;
    }

    final onboardingDone = ref.read(onboardingCompletedProvider);
    if (!onboardingDone) {
      context.go('/onboarding');
      return;
    }

    context.go(ref.read(defaultStartPageProvider));
  }

  Future<void> _runAuth(Future<void> Function() action) async {
    if (_loading) return;
    setState(() => _loading = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      await action();
      if (!mounted) return;
      await _afterSignIn();
    } on EmailConfirmationRequired {
      if (!mounted) return;
      setState(() => _mode = _AuthMode.signIn);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cronicleAuthEmailConfirmation)),
      );
    } on GoogleSignInException catch (e) {
      if (!mounted) return;
      if (e.code != GoogleSignInExceptionCode.canceled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorWithMessage(e.toString()))),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorWithMessage(e.message))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorWithMessage(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogleNative() {
    return _runAuth(
      () => ref.read(cronicleAuthServiceProvider).signInWithGoogle(),
    );
  }

  Future<void> _submitEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final auth = ref.read(cronicleAuthServiceProvider);

    if (_mode == _AuthMode.signIn) {
      await _runAuth(
        () => auth.signInWithEmailPassword(email: email, password: password),
      );
    } else {
      await _runAuth(
        () => auth.signUpWithEmailPassword(email: email, password: password),
      );
    }
  }

  Widget _buildGoogleSignInControl(AppLocalizations l10n) {
    if (kIsWeb) {
      if (EnvConfig.googleServerClientId.trim().isEmpty) {
        return Text(
          l10n.googleSignInNotConfiguredHint,
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        );
      }
      return SizedBox(
        width: double.infinity,
        height: 44,
        child: buildGoogleWebButton(context),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _loading ? null : _signInWithGoogleNative,
        icon: SvgPicture.asset(
          'assets/google.svg',
          width: 20,
          height: 20,
        ),
        label: Text(l10n.googleSignIn),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _attachGoogleWebListener();

    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isSignIn = _mode == _AuthMode.signIn;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_stories_rounded, size: 56, color: cs.primary),
                  const SizedBox(height: 16),
                  Text(
                    l10n.cronicleLoginTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.cronicleLoginSubtitle,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  SegmentedButton<_AuthMode>(
                    segments: [
                      ButtonSegment(
                        value: _AuthMode.signIn,
                        label: Text(l10n.cronicleAuthSignInTab),
                      ),
                      ButtonSegment(
                        value: _AuthMode.signUp,
                        label: Text(l10n.cronicleAuthSignUpTab),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: _loading
                        ? null
                        : (selection) {
                            setState(() => _mode = selection.first);
                          },
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          enabled: !_loading,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: l10n.cronicleAuthEmailLabel,
                            prefixIcon: const Icon(Icons.mail_outline_rounded),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final v = value?.trim() ?? '';
                            if (v.isEmpty || !v.contains('@')) {
                              return l10n.errorWithMessage(
                                l10n.cronicleAuthEmailLabel,
                              );
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          enabled: !_loading,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submitEmail(),
                          decoration: InputDecoration(
                            labelText: l10n.cronicleAuthPasswordLabel,
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: _loading
                                  ? null
                                  : () => setState(
                                        () => _obscurePassword = !_obscurePassword,
                                      ),
                            ),
                          ),
                          validator: (value) {
                            if ((value ?? '').length < 6) {
                              return l10n.errorWithMessage(
                                l10n.cronicleAuthPasswordLabel,
                              );
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _loading ? null : _submitEmail,
                            child: Text(
                              isSignIn
                                  ? l10n.cronicleAuthSignInButton
                                  : l10n.cronicleAuthSignUpButton,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: Divider(color: cs.outlineVariant)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          l10n.cronicleAuthOrDivider,
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ),
                      Expanded(child: Divider(color: cs.outlineVariant)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_loading)
                    const CircularProgressIndicator()
                  else ...[
                    _buildGoogleSignInControl(l10n),
                    if (kIsWeb &&
                        EnvConfig.googleServerClientId.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        l10n.cronicleGoogleWebOriginHint(
                          currentWebOrigin ?? Uri.base.origin,
                        ),
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                          height: 1.35,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.cronicleGoogleWebClientHint(
                          EnvConfig.googleServerClientId.trim(),
                        ),
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                          height: 1.35,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.cronicleGoogleConsentHint,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                          height: 1.35,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
