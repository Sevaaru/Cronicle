import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/onboarding/presentation/onboarding_notifier.dart';
import 'package:cronicle/l10n/app_localizations.dart';

class _Interest {
  const _Interest({
    required this.id,
    required this.icon,
    required this.label,
    required this.color,
  });

  final String id;
  final IconData icon;
  final String Function(AppLocalizations) label;
  final Color color;
}

final _interests = [
  _Interest(
    id: 'anime',
    icon: Icons.animation_rounded,
    label: (l) => l.onboardingInterestAnime,
    color: const Color(0xFF5C6BC0),
  ),
  _Interest(
    id: 'manga',
    icon: Icons.menu_book_rounded,
    label: (l) => l.onboardingInterestManga,
    color: const Color(0xFFEC407A),
  ),
  _Interest(
    id: 'movie',
    icon: Icons.movie_rounded,
    label: (l) => l.onboardingInterestMovies,
    color: const Color(0xFFFF7043),
  ),
  _Interest(
    id: 'tv',
    icon: Icons.tv_rounded,
    label: (l) => l.onboardingInterestTv,
    color: const Color(0xFF26A69A),
  ),
  _Interest(
    id: 'game',
    icon: Icons.sports_esports_rounded,
    label: (l) => l.onboardingInterestGames,
    color: const Color(0xFF42A5F5),
  ),
];

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final _selected = <String>{};
  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  bool get _canContinue => _selected.isNotEmpty;

  Future<void> _finish() async {
    if (!_canContinue) return;
    await ref
        .read(onboardingCompletedProvider.notifier)
        .complete(_selected);
    if (!mounted) return;
    context.go('/feed');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Icon(
                  Icons.interests_rounded,
                  size: 56,
                  color: cs.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.onboardingTitle,
                  style: tt.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.onboardingSubtitle,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: _interests.map((interest) {
                    final active = _selected.contains(interest.id);
                    return _InterestBubble(
                      label: interest.label(l10n),
                      icon: interest.icon,
                      color: interest.color,
                      selected: active,
                      onTap: () {
                        setState(() {
                          if (active) {
                            _selected.remove(interest.id);
                          } else {
                            _selected.add(interest.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const Spacer(flex: 3),
                AnimatedOpacity(
                  opacity: _canContinue ? 1.0 : 0.4,
                  duration: const Duration(milliseconds: 250),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _canContinue ? _finish : null,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        l10n.onboardingContinue,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InterestBubble extends StatelessWidget {
  const _InterestBubble({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = selected
        ? color.withValues(alpha: 0.18)
        : cs.surfaceContainerHighest.withValues(alpha: 0.55);
    final border = selected ? color : cs.outlineVariant.withValues(alpha: 0.3);
    final fg = selected ? color : cs.onSurfaceVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(50),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: border, width: selected ? 2 : 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    selected ? Icons.check_circle_rounded : icon,
                    key: ValueKey(selected),
                    size: 22,
                    color: fg,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
