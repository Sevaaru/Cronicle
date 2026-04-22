import 'package:flutter/material.dart';

/// Tier (PSN-like): Bronze, Silver, Gold, Platinum.
enum AchievementTier {
  bronze(15, Color(0xFFCD7F32)),
  silver(30, Color(0xFFC0C0C0)),
  gold(90, Color(0xFFFFD700)),
  platinum(180, Color(0xFF93D5F8));

  const AchievementTier(this.points, this.color);
  final int points;
  final Color color;
}

/// Localised pair (es/en).
class L10nPair {
  const L10nPair(this.es, this.en);
  final String es;
  final String en;
  String resolve(Locale l) => l.languageCode == 'es' ? es : en;
}

/// Snapshot of all signals the engine can use to evaluate achievements.
class AchievementContext {
  AchievementContext({
    required this.entries,
    required this.completedCount,
    required this.totalCount,
    required this.kindCounts,
    required this.notesCount,
    required this.scoredCount,
    required this.totalAnimeProgress,
    required this.totalChapterProgress,
    required this.completedBooks,
    required this.completedGames,
    required this.completedAnime,
    required this.completedMangaSeries,
    required this.completedMoviesAndShows,
    required this.progressIncrementsTotal,
    required this.wearUpdatesTotal,
    required this.usedAtNight,
    required this.unlockedCount,
    required this.totalAchievementsExceptPlatinum,
  });

  final int entries;
  final int totalCount;
  final int completedCount;
  /// Map of MediaKind.code to entry count.
  final Map<int, int> kindCounts;
  final int notesCount;
  final int scoredCount;
  final int totalAnimeProgress;
  final int totalChapterProgress;
  final int completedBooks;
  final int completedGames;
  final int completedAnime;
  final int completedMangaSeries;
  final int completedMoviesAndShows;
  final int progressIncrementsTotal;
  final int wearUpdatesTotal;
  final bool usedAtNight;
  final int unlockedCount;
  final int totalAchievementsExceptPlatinum;
}

/// A single achievement definition.
class Achievement {
  const Achievement({
    required this.id,
    required this.tier,
    required this.icon,
    required this.title,
    required this.description,
    required this.target,
    required this.evaluate,
    this.secret = false,
  });

  final String id;
  final AchievementTier tier;
  final IconData icon;
  final L10nPair title;
  final L10nPair description;

  /// Total target for progress bar (e.g. 10 chapters, 100 entries).
  final int target;

  /// Returns current progress 0..target given the snapshot.
  final int Function(AchievementContext ctx) evaluate;

  /// Hides description until unlocked.
  final bool secret;
}

/// Catalogue of all achievements. Order is the display order.
class AchievementCatalog {
  static const _platinumId = 'cronicle_supreme';

  static List<Achievement> all = [
    // ── BRONZE ──────────────────────────────────────────────────────────────
    Achievement(
      id: 'welcome_to_the_club',
      tier: AchievementTier.bronze,
      icon: Icons.emoji_events_outlined,
      title: L10nPair('Bienvenido al Club', 'Welcome to the Club'),
      description: L10nPair(
        'Registra tu primer ítem en cualquier categoría.',
        'Add your first item in any category.',
      ),
      target: 1,
      evaluate: (c) => c.totalCount.clamp(0, 1),
    ),
    Achievement(
      id: 'collector_10',
      tier: AchievementTier.bronze,
      icon: Icons.collections_bookmark_rounded,
      title: L10nPair('Coleccionista en Ciernes', 'Budding Collector'),
      description: L10nPair(
        'Ten 10 ítems en tu biblioteca.',
        'Have 10 items in your library.',
      ),
      target: 10,
      evaluate: (c) => c.totalCount.clamp(0, 10),
    ),
    Achievement(
      id: 'first_book',
      tier: AchievementTier.bronze,
      icon: Icons.menu_book_rounded,
      title: L10nPair('Primera Lectura', 'First Read'),
      description: L10nPair(
        'Termina tu primer libro.',
        'Finish your first book.',
      ),
      target: 1,
      evaluate: (c) => c.completedBooks.clamp(0, 1),
    ),
    Achievement(
      id: 'first_game',
      tier: AchievementTier.bronze,
      icon: Icons.sports_esports_rounded,
      title: L10nPair('GG, Player 1', 'GG, Player 1'),
      description: L10nPair(
        'Marca un juego como completado.',
        'Mark a game as completed.',
      ),
      target: 1,
      evaluate: (c) => c.completedGames.clamp(0, 1),
    ),
    Achievement(
      id: 'first_anime_done',
      tier: AchievementTier.bronze,
      icon: Icons.animation_rounded,
      title: L10nPair('Otaku Nivel 1', 'Otaku Lv. 1'),
      description: L10nPair(
        'Completa tu primer anime.',
        'Complete your first anime.',
      ),
      target: 1,
      evaluate: (c) => c.completedAnime.clamp(0, 1),
    ),
    Achievement(
      id: 'time_master_wear',
      tier: AchievementTier.bronze,
      icon: Icons.watch_rounded,
      title: L10nPair('Maestro del Tiempo', 'Time Master'),
      description: L10nPair(
        'Actualiza un progreso desde tu Wear OS.',
        'Update progress from your Wear OS watch.',
      ),
      target: 1,
      evaluate: (c) => c.wearUpdatesTotal.clamp(0, 1),
    ),
    Achievement(
      id: 'night_owl',
      tier: AchievementTier.bronze,
      icon: Icons.bedtime_rounded,
      title: L10nPair('Ave Nocturna', 'Night Owl'),
      description: L10nPair(
        'Usa Cronicle entre las 00:00 y las 04:00.',
        'Use Cronicle between midnight and 4 AM.',
      ),
      target: 1,
      evaluate: (c) => c.usedAtNight ? 1 : 0,
    ),
    Achievement(
      id: 'score_5',
      tier: AchievementTier.bronze,
      icon: Icons.star_rounded,
      title: L10nPair('Crítico Aprendiz', 'Apprentice Critic'),
      description: L10nPair(
        'Puntúa 5 ítems.',
        'Score 5 items.',
      ),
      target: 5,
      evaluate: (c) => c.scoredCount.clamp(0, 5),
    ),

    // ── SILVER ──────────────────────────────────────────────────────────────
    Achievement(
      id: 'completed_5',
      tier: AchievementTier.silver,
      icon: Icons.flag_circle_rounded,
      title: L10nPair('Cinco en Línea', 'High Five'),
      description: L10nPair(
        'Completa 5 ítems en tu biblioteca.',
        'Complete 5 items in your library.',
      ),
      target: 5,
      evaluate: (c) => c.completedCount.clamp(0, 5),
    ),
    Achievement(
      id: 'elite_critic',
      tier: AchievementTier.silver,
      icon: Icons.edit_note_rounded,
      title: L10nPair('Crítico de Élite', 'Elite Critic'),
      description: L10nPair(
        'Escribe 10 notas personalizadas.',
        'Write 10 personal notes.',
      ),
      target: 10,
      evaluate: (c) => c.notesCount.clamp(0, 10),
    ),
    Achievement(
      id: 'progress_addict',
      tier: AchievementTier.silver,
      icon: Icons.trending_up_rounded,
      title: L10nPair('Sin Pausa', 'Unstoppable'),
      description: L10nPair(
        'Pulsa “+1” 100 veces para avanzar progreso.',
        'Tap “+1” 100 times to advance progress.',
      ),
      target: 100,
      evaluate: (c) => c.progressIncrementsTotal.clamp(0, 100),
    ),
    Achievement(
      id: 'binge_anime',
      tier: AchievementTier.silver,
      icon: Icons.local_movies_rounded,
      title: L10nPair('Maratón Otaku', 'Anime Binger'),
      description: L10nPair(
        'Acumula 100 episodios de anime.',
        'Accumulate 100 anime episodes.',
      ),
      target: 100,
      evaluate: (c) => c.totalAnimeProgress.clamp(0, 100),
    ),
    Achievement(
      id: 'movie_buff',
      tier: AchievementTier.silver,
      icon: Icons.theaters_rounded,
      title: L10nPair('Cinéfilo', 'Movie Buff'),
      description: L10nPair(
        'Completa 10 películas o series.',
        'Complete 10 movies or shows.',
      ),
      target: 10,
      evaluate: (c) => c.completedMoviesAndShows.clamp(0, 10),
    ),
    Achievement(
      id: 'score_25',
      tier: AchievementTier.silver,
      icon: Icons.stars_rounded,
      title: L10nPair('Voz de Autoridad', 'Voice of Authority'),
      description: L10nPair(
        'Puntúa 25 ítems.',
        'Score 25 items.',
      ),
      target: 25,
      evaluate: (c) => c.scoredCount.clamp(0, 25),
    ),

    // ── GOLD ────────────────────────────────────────────────────────────────
    Achievement(
      id: 'royal_librarian',
      tier: AchievementTier.gold,
      icon: Icons.library_books_rounded,
      title: L10nPair('Bibliotecario Real', 'Royal Librarian'),
      description: L10nPair(
        'Ten al menos un ítem en cada una de las 6 categorías.',
        'Have at least one item in each of the 6 categories.',
      ),
      target: 6,
      evaluate: (c) => c.kindCounts.values.where((v) => v > 0).length.clamp(0, 6),
    ),
    Achievement(
      id: 'completed_25',
      tier: AchievementTier.gold,
      icon: Icons.workspace_premium_rounded,
      title: L10nPair('Veterano de la Lista', 'List Veteran'),
      description: L10nPair(
        'Completa 25 ítems.',
        'Complete 25 items.',
      ),
      target: 25,
      evaluate: (c) => c.completedCount.clamp(0, 25),
    ),
    Achievement(
      id: 'library_100',
      tier: AchievementTier.gold,
      icon: Icons.auto_awesome_rounded,
      title: L10nPair('La Gran Crónica', 'The Great Chronicle'),
      description: L10nPair(
        'Acumula 100 ítems en tu biblioteca.',
        'Accumulate 100 items in your library.',
      ),
      target: 100,
      evaluate: (c) => c.totalCount.clamp(0, 100),
    ),
    Achievement(
      id: 'page_turner',
      tier: AchievementTier.gold,
      icon: Icons.auto_stories_rounded,
      title: L10nPair('Pasapáginas', 'Page Turner'),
      description: L10nPair(
        'Lee 1.000 páginas o capítulos en total.',
        'Read 1,000 pages or chapters in total.',
      ),
      target: 1000,
      evaluate: (c) => c.totalChapterProgress.clamp(0, 1000),
    ),

    // ── PLATINUM ────────────────────────────────────────────────────────────
    Achievement(
      id: _platinumId,
      tier: AchievementTier.platinum,
      icon: Icons.diamond_rounded,
      title: L10nPair('El Cronista Supremo', 'The Supreme Chronicler'),
      description: L10nPair(
        'Desbloquea todos los demás logros.',
        'Unlock every other achievement.',
      ),
      target: 1,
      evaluate: (c) =>
          c.unlockedCount >= c.totalAchievementsExceptPlatinum ? 1 : 0,
    ),
  ];

  static Achievement byId(String id) =>
      all.firstWhere((a) => a.id == id, orElse: () => all.first);

  static int get totalPoints =>
      all.fold(0, (sum, a) => sum + a.tier.points);

  static int get nonPlatinumCount =>
      all.where((a) => a.tier != AchievementTier.platinum).length;
}
