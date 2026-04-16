import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cronicle/features/anime/data/datasources/anilist_auth_datasource.dart';
import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';

/// Conexión Anilist: en móvil con redirect HTTPS puente, OAuth sin pegar token; si no, flujo PIN.
Future<void> showAnilistConnectFlow(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;
  if (kIsWeb) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.anilistOAuthWebUnavailable)),
    );
    return;
  }

  final auth = ref.read(anilistAuthProvider);
  final bridge = AnilistAuthDatasource.usesHttpsImplicitBridge;
  final mobile = defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  if (bridge && mobile) {
    try {
      await ref.read(anilistTokenProvider.notifier).connectOAuthBridge();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.anilistConnectSuccess),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } on UnsupportedError {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.anilistOAuthWebUnavailable)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final msg = _anilistConnectErrorMessage(l10n, e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    }
    return;
  }

  final launched = await launchUrl(
    Uri.parse(auth.authorizeUrl),
    mode: LaunchMode.externalApplication,
  );
  if (!launched) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.anilistOAuthLaunchFailed)),
      );
    }
    return;
  }

  if (!context.mounted) return;

  final controller = TextEditingController();
  final cs = Theme.of(context).colorScheme;
  final useBridgeHint = bridge && !mobile;

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.animation_rounded, color: cs.primary, size: 22),
          const SizedBox(width: 8),
          Text(l10n.anilistConnectTitle),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withAlpha(50),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StepRow(number: '1', text: l10n.anilistStep1, cs: cs),
                const SizedBox(height: 6),
                _StepRow(
                  number: '2',
                  text: useBridgeHint ? l10n.anilistStep2Bridge : l10n.anilistStep2,
                  cs: cs,
                ),
                const SizedBox(height: 6),
                _StepRow(
                  number: '3',
                  text: useBridgeHint ? l10n.anilistStep3Bridge : l10n.anilistStep3,
                  cs: cs,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: l10n.anilistTokenLabel,
              hintText: l10n.anilistTokenHint,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.key, size: 20),
              suffixIcon: IconButton(
                icon: const Icon(Icons.content_paste_go, size: 20),
                tooltip: l10n.anilistPasteTooltip,
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null) {
                    controller.text = data!.text!;
                  }
                },
              ),
            ),
            maxLines: 1,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.cancel),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.check, size: 18),
          label: Text(l10n.connect),
          onPressed: () async {
            final token = controller.text.trim();
            if (token.isEmpty) return;
            await ref.read(anilistTokenProvider.notifier).setToken(token);
            if (!ctx.mounted) return;
            Navigator.pop(ctx);
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(l10n.anilistConnectSuccess),
                backgroundColor: Colors.green.shade700,
              ),
            );
          },
        ),
      ],
    ),
  );
}

String _anilistConnectErrorMessage(AppLocalizations l10n, Object e) {
  if (e is StateError) {
    switch (e.message) {
      case 'oauth_timeout':
        return l10n.anilistOAuthTimeout;
      case 'launch_failed':
        return l10n.anilistOAuthLaunchFailed;
      case 'not_configured':
        return l10n.anilistBridgeNotConfigured;
      default:
        return l10n.errorWithMessage(e.message);
    }
  }
  return l10n.errorWithMessage(e);
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.text,
    required this.cs,
  });

  final String number;
  final String text;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: cs.primary.withAlpha(35),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            number,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: cs.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}
