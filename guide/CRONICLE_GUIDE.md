# Cronicle — Guía completa del proyecto

## Cronicle 2 (rama `cronicle-2`)

Evolución hacia **social nativo** (identidad Cronicle, follows, feed cross-media, listas compartidas) + **web** con sync Supabase, manteniendo Drift offline-first.

| Recurso | Descripción |
|---------|-------------|
| **[CRONICLE_2_PLAN.md](./CRONICLE_2_PLAN.md)** | Plan maestro: arquitectura híbrida Drift + Supabase, esquema SQL, fases 0–7, web, RLS, roadmap ~20 semanas |
| **Rama Git** | `cronicle-2` (desarrollo v2; `main` permanece estable v1.x) |

---

## Descripción

Cronicle es una app Flutter para registrar progreso y listas de anime, manga, películas, series, juegos y **libros**. Funciona **offline-first** con Drift (SQLite), se sincroniza opcionalmente con **Anilist** (anime/manga/actividad; OAuth implícito con PIN o **puente HTTPS** + deep link `cronicle://` en móvil), consulta **IGDB v4** (vía credenciales **Twitch**; «Conectar Twitch» usa puente HTTPS) para **juegos**, **Trakt.tv** para películas/series (listados con `TRAKT_CLIENT_ID`; OAuth con **puente HTTPS** recomendado y retorno a la app vía `cronicle://` en Android), y **Google Books API v1** para catálogo de libros (search/trending/subject/work + detalle de ediciones). El **perfil** agrupa favoritos (Anilist, películas/series Trakt **marcadas con el corazón en la app**, juegos locales y libros locales) con acceso a listas detalladas por categoría. Incluye backup/restauración local en JSON. En **Android/iOS** puede mostrar **notificaciones del sistema** (nuevos capítulos en emisión y, opcionalmente, bandeja Anilist), configurables en Ajustes.

---

## Arquitectura

```
presentation → domain → data (nunca al revés)
```

- **Estado**: Riverpod 2.5+ con codegen (`@riverpod`, `@Riverpod`). Nunca `setState` para estado global.
- **Modelos**: Freezed + json_serializable (inmutables).
- **Errores**: `fpdart` Either (`AppResult<T>`) + `AppFailure`.
- **Navegación**: GoRouter con `ShellRoute` (incluye `redirect` para URIs `cronicle://` que no son rutas internas).
- **OAuth / deep links**: `app_links` + `url_launcher` (Trakt Android, Anilist puente en móvil); `flutter_web_auth_2` (Twitch/IGDB, Trakt en iOS/desktop según plataforma).
- **UI**: Material 3 + glassmorphism. Modo oscuro por defecto.
- **Offline-first**: Drift local → sync remoto opcional.
- **Codegen**: ejecutar `dart run build_runner build --delete-conflicting-outputs` tras cambiar anotaciones Drift, Riverpod o Freezed.

---

## Estructura de carpetas

```
lib/
├── main.dart                          # Entry point; init Google Sign-In (móvil); Workmanager + notificaciones; `NotificationWorkScheduler` según prefs
├── cronicle_app.dart                  # MaterialApp.router; monta `NotificationPermissionBootstrap` (permiso diferido hasta completar onboarding)
├── l10n/                              # Internacionalización (ARB)
│   ├── app_es.arb                     # Español (plantilla)
│   ├── app_en.arb                     # Inglés
│   ├── app_localizations.dart         # Generado
│   ├── app_localizations_es.dart      # Generado
│   └── app_localizations_en.dart      # Generado
├── core/
│   ├── backup/
│   │   ├── domain/backup_repository.dart        # Contrato legacy (Drive)
│   │   ├── data/drive_backup_repository.dart     # Implementación legacy
│   │   ├── data/stub_drive_backup_repository.dart
│   │   └── backup_repository_provider.dart
│   ├── config/env_config.dart         # ANILIST_*, TWITCH_*, TRAKT_*, GOOGLE_*, STEAM_API_KEY, STEAM_REDIRECT_URI
│   ├── constants/app_constants.dart
│   ├── database/
│   │   ├── app_database.dart          # Tablas Drift + queries
│   │   └── database_provider.dart     # Provider singleton
│   ├── di/providers.dart
│   ├── errors/app_failure.dart        # Tipos de error
│   ├── network/
│   │   ├── api_endpoints.dart
│   │   ├── connectivity_service.dart
│   │   ├── dio_provider.dart
│   │   └── google_sign_in_provider.dart
│   ├── router/app_router.dart         # GoRouter + rutas (`/profile`, `/profile/personal-stats`, `/profile/favorites/:kind`, …); `redirect` ignora `cronicle://…` (OAuth) → `/settings`
│   ├── notifications/
│   │   ├── cronicle_local_notifications.dart   # flutter_local_notifications: canales, permiso, mostrar
│   │   ├── device_notification_prefs.dart      # Claves SharedPreferences (maestro, airing, Anilist…)
│   │   ├── notification_background.dart        # `Workmanager.initialize` + `callbackDispatcher` (@pragma vm:entry-point)
│   │   ├── notification_sync_runner.dart       # Polling: capítulos en emisión + inbox Anilist (sin resetear unread)
│   │   └── notification_work_scheduler.dart    # `registerPeriodicTask` / cancel según prefs
│   ├── storage/shared_preferences_provider.dart
│   ├── theme/app_theme.dart           # Light + Dark themes
│   └── utils/
│       ├── app_logger.dart
│       ├── pending_token.dart         # Export condicional web/stub
│       ├── pending_token_stub.dart
│       └── pending_token_web.dart
├── features/
│   ├── anime/
│   │   ├── data/datasources/
│   │   │   ├── anilist_auth_datasource.dart     # OAuth + SecureStorage
│   │   │   └── anilist_graphql_datasource.dart   # GraphQL queries/mutations (incluye foros: fetchMediaThreads, fetchForumThread, saveThreadComment)
│   │   └── presentation/
│   │       ├── anime_page.dart
│   │       ├── anime_providers.dart              # Providers de Anilist; `AnilistToken.connectOAuthBridge()` (móvil + puente HTTPS); incluye `anilistMediaThreadsProvider`, `anilistForumThreadProvider`
│   │       ├── anilist_connect_flow.dart        # Flujo unificado Conectar Anilist (Ajustes + barra de anime): puente móvil o PIN/pegar token
│   │       ├── media_detail_page.dart            # Detalle de anime/manga; secciones **Personajes** y **Staff** (carruseles horizontales con "Ver todos"), **Discusiones del foro** (3 hilos + "Ver más"); tags de estado localizados
│   │       ├── character_detail_page.dart        # Detalle de personaje Anilist: imagen + nombre, toggle favorito, info (edad/género/sangre/cumpleaños), nombres alternativos (con reveal de spoilers), descripción y apariciones (con voice actors)
│   │       ├── staff_detail_page.dart            # Detalle de staff Anilist: ocupaciones, info (edad/género/lugar/sangre/fechas/años activo), descripción, character roles y staff media
│   │       ├── media_characters_page.dart        # Lista paginada completa de personajes de un media (`/media/:id/characters`)
│   │       ├── media_staff_page.dart             # Lista paginada completa de staff de un media (`/media/:id/staff`)
│   │       ├── forum_thread_page.dart            # Hilo completo: cuerpo, comentarios anidados (childComments como JSON escalar), likes (THREAD/THREAD_COMMENT), input de comentario con estado de respuesta
│   │       └── forum_media_threads_page.dart     # Lista completa de hilos de un media (`/forum/media/:id`)
│   ├── books/
│   │   ├── data/datasources/
│   │   │   └── google_books_api_datasource.dart  # REST Google Books API v1 (search, trending, subject, work, editions); normaliza a shape compatible con cards y AddToLibrarySheet; retry automático en 503; normaliza slugs con guiones bajos a espacios
│   │   ├── domain/
│   │   │   ├── book_progress_calculator.dart     # Lógica pura de progreso (páginas/%/capítulos)
│   │   │   └── models/book_edition.dart          # Modelo tipado de edición (Freezed/json)
│   │   └── presentation/
│   │       ├── book_providers.dart               # Providers Google Books + favoritos locales + ediciones por obra
│   │       ├── books_home_feed_view.dart         # Home de libros (tendencias/temas)
│   │       ├── books_home_section_list_page.dart # Listado completo por sección de home
│   │       ├── book_subject_browse_page.dart     # Exploración por tema con orden local
│   │       └── book_detail_page.dart             # Detalle libro + tarjeta de progreso de lectura
│   ├── auth/presentation/auth_page.dart
│   ├── feed/presentation/
│   │   ├── feed_page.dart                        # Feed con filtros: **Discover** (siempre primero) + categorías visibles (anime/manga/movie/tv/game); rail anime/manga con chips de browse y **animación progresiva** al deslizar entre pestañas
│   │   ├── summary_feed_view.dart                # **Discover / Resumen**: secciones trending de todas las categorías visibles, botón «Suerte», diseños variados (hero, carousel, wide, numbered rank)
│   │   ├── anilist_notifications_page.dart     # Bandeja de notificaciones Anilist (`/notifications`)
│   │   └── activity_replies_page.dart            # Comentarios/replies de actividad; mismo estilo de input que forum_thread_page
│   ├── social/presentation/
│   │   └── social_page.dart                      # Tab Social (5.ª pestaña inferior): feed Anilist de seguidos / global (reemplaza el antiguo tab Perfil)
│   ├── onboarding/presentation/
│   │   ├── onboarding_notifier.dart              # `OnboardingCompleted` notifier (SharedPreferences `onboarding_completed`); `complete(selectedInterests)` configura layouts de feed/biblioteca
│   │   └── onboarding_notifier.g.dart            # Generado por build_runner│   ├── games/
│   │   ├── data/datasources/
│   │   │   ├── igdb_auth_datasource.dart         # Token Twitch client_credentials + SecureStorage
│   │   │   └── igdb_api_datasource.dart          # POST Apicalypse a api.igdb.com/v4
│   │   └── presentation/
│   │       ├── games_page.dart                   # Scaffold + GamesHomeFeedView
│   │       ├── games_home_feed_view.dart         # Secciones IGDB (popular, próximos, reseñas…)
│   │       ├── game_detail_page.dart             # Detalle juego + añadir a biblioteca
│   │       ├── igdb_game_review_detail_page.dart # Lectura reseña IGDB por id
│   │       ├── igdb_detail_helpers.dart          # Enlaces externos / utilidades UI
│   │       └── game_providers.dart               # igdbApi, búsqueda, home, detalle, review
│   ├── library/presentation/
│   │   ├── library_page.dart                     # Biblioteca unificada
│   │   ├── library_providers.dart                # PaginatedLibrary, filtros
│   │   ├── anilist_sync_service.dart             # Import/merge Anilist
│   │   ├── trakt_sync_service.dart               # Import historial visto Trakt (OAuth)
│   │   └── home_page.dart                        # (No usada en router)
│   ├── trakt/
│   │   ├── data/
│   │   │   ├── trakt_genre_utils.dart            # Excluye género `anime` (anti-duplicado AniList)
│   │   │   ├── trakt_normalize.dart              # Mapa Trakt → shape Anilist-like (cards / biblioteca)
│   │   │   ├── trakt_library_remote_sync.dart   # Sincronización opcional con cuenta Trakt (historial, watchlist, ratings)
│   │   │   └── datasources/
│   │   │       ├── trakt_api_datasource.dart     # REST api.trakt.tv (trending, anticipated, watching shows, búsqueda, sync, stats usuario, watchlist…)
│   │   │       └── trakt_auth_datasource.dart    # OAuth2 + SecureStorage
│   │   └── presentation/
│   │       ├── trakt_providers.dart              # Riverpod: home, búsqueda, detalle, sesión, favoritos; OAuth Android = externo + `app_links` (`_traktOAuthAndroidExternalBrowser`)
│   │       ├── trakt_detail_widgets.dart        # Hero detalle Trakt, fila biblioteca+favorito, tarjeta progreso episodios, pills
│   │       ├── trakt_home_feed_view.dart        # Carruseles película/TV (feed, búsqueda, /movies, /tv)
│   │       ├── trakt_movie_detail_page.dart     # Detalle película Trakt + biblioteca
│   │       └── trakt_show_detail_page.dart      # Detalle serie Trakt + biblioteca + progreso episodios
│   ├── steam/
│   │   ├── data/datasources/
│   │   │   ├── steam_auth_datasource.dart        # OpenID 2.0 vía puente HTTPS (`web/steam_oauth_bridge.html`); guarda SteamID64 + perfil en SecureStorage; Android usa `app_links` + browser externo
│   │   │   └── steam_api_datasource.dart         # Steam Web API + endpoints públicos sin key; métodos: GetOwnedGames, GetPlayerSummaries, GetPlayerAchievements, GetSchemaForGame, GetFriendList, appdetails, appreviews, ISteamNews, ISteamUserStats; helper `artworkCandidates(appId, preferHeader)` devuelve lista ordenada de URLs candidatas (Cloudflare/Akamai/shared CDN × library_600x900/header/capsule/hero); `fetchSteamSpyTags(appId)` → SteamSpy API etiquetas populares
│   │   └── presentation/
│   │       ├── steam_providers.dart              # Riverpod: `steamAuthProvider`, `steamApiProvider`, `steamSessionProvider` (AsyncNotifier con `connect()`/`disconnect()`/`refreshPlayerSummary()`), `steamOwnedGamesProvider` (cache JSON 6 h), `steamGameAchievementsProvider.family<int>` (cruza player + schema), `steamAppDetailsProvider.family<int>` (appdetails public), `steamAppNewsProvider.family<int>` (ISteamNews), `steamFriendsWithGameProvider.family<int>` (cap 100, concurrencia 8), `steamCurrentPlayersProvider.family<int>`, `steamUserReviewsProvider.family<int>`, `steamSpyTagsProvider.family<int>` (etiquetas SteamSpy); **todos sin `autoDispose`** para que los datos persistan en memoria mientras el usuario hace scroll
│   │       ├── steam_library_page.dart           # `/profile/steam`: cabecera con persona name + avatar, búsqueda y orden (horas, último jugado, nombre), lista de juegos con portada en `_ChainedSteamArt` (7+ URLs candidatas × CDN con fallback cadena)
│   │       └── steam_game_detail_page.dart      # `/profile/steam/game/:appid`: ver sección "Detalle Steam" abajo. Si IGDB no encuentra equivalente al añadir a biblioteca, se construye un ítem sintético (`externalId = steam:<appid>`, portada = `capsuleUrl`) y se añade igualmente con `steamAppId` rellenado — el detalle se abre vía Steam, no vía IGDB
│   ├── movies/presentation/movies_page.dart      # Home Trakt películas (sin shell)
│   ├── profile/presentation/
│   │   ├── profile_page.dart                     # Cabecera Anilist (banner, avatar; segundo avatar Trakt si hay sesión y URL guardada), bio, bloque **Favoritos** (tarjeta única: filas por categoría con contador + miniaturas — anime/manga, películas/TV, juegos, libros, **personajes** y **staff** de Anilist; toque → `/profile/favorites/...`), enlace «Estadísticas personales», cuentas Anilist/Trakt; usuario sin Anilist: biblioteca local + texto `profileConnectHint` (AniList y Trakt en Ajustes)
│   │   ├── profile_favorites_page.dart           # Lista en rejilla por categoría: anime/manga (Anilist), películas/series (`favoriteTraktTitlesProvider`), juegos (`favoriteGamesProvider`), libros (`favoriteBooksProvider`) y **personajes/staff** Anilist (`_PersonGrid`, tiles → `/character/:id` o `/staff/:id`)
│   │   ├── profile_favorites_kind.dart           # Segmentos de ruta: `anime`, `manga`, `games`, `movies`, `tv`, `books`, `characters`, `staff`
│   │   ├── profile_favorites_preview.dart        # Filas del bloque Favoritos: contador en chip de **tamaño fijo**; miniaturas calculadas con `LayoutBuilder` para llenar el ancho (badge `+N` si hay más títulos que cupos)
│   │   ├── personal_stats_page.dart              # Estadísticas detalladas: anime/manga, **stats** Trakt vía `profileTraktExtrasProvider`, carruseles de favoritos cine/TV desde **`favoriteTraktTitlesProvider`**, juegos en Drift
│   │   ├── profile_stats_shared.dart             # Widgets compartidos (cabeceras de sección, barras de género, `ProfileTraktFavCard`, etc.)
│   │   ├── profile_trakt_extras_provider.dart    # Riverpod: **solo** `fetchUserStats(slug)` cuando hay sesión Trakt (extras ya **no** traen favoritos de la API de Trakt)
│   │   └── user_profile_page.dart                # Perfil de otro usuario Anilist (incluye carruseles **Favorite Characters** y **Favorite Staff** con `_FavPersonCard` → `/character/:id` o `/staff/:id`)
│   ├── search/presentation/search_page.dart      # Buscador unificado: Anilist + Trakt + IGDB + Google Books (incluye filtro Libros)
│   ├── settings/presentation/
│   │   ├── settings_page.dart                    # Ajustes: Apariencia (tema, idioma, barras feed/biblioteca), notificaciones, copia local + opciones Drive; sección **Copia local**: botones Guardar/Restaurar con misma altura mínima y texto de ayuda solo sobre archivo (ARB); detalle OAuth/defines en esta guía
│   │   ├── device_notifications_notifier.dart    # Preferencias notificaciones locales + agenda Workmanager
│   │   ├── feed_filter_layout_notifier.dart      # Orden/visibilidad chips del feed
│   │   ├── library_kind_layout_notifier.dart     # Orden/visibilidad tipos en Biblioteca
│   │   ├── layout_customization_pages.dart       # Pantallas de edición de barras
│   │   ├── locale_notifier.dart                  # Idioma
│   │   ├── theme_mode_notifier.dart              # Tema
│   │   └── app_defaults_notifier.dart            # Página inicio, tab feed y ocultar actividades de texto
│   └── tv/presentation/tv_page.dart              # Home Trakt series (sin shell)
└── shared/
    ├── models/
    │   ├── media_item.dart            # Modelo genérico (Freezed)
    │   ├── feed_activity.dart         # Actividad del feed (Freezed)
    │   └── media_kind.dart            # Enum: anime, movie, tv, game, manga, book
    └── widgets/
        ├── app_shell.dart             # Shell con GlassBottomNav (5 tabs); icono Home = `Icons.home_outlined/rounded`; **`ProfileAvatarButton`** en AppBar leading (navega a `/profile`); `pageTitleStyle()` (Inter 700)
        ├── glass_bottom_nav.dart      # Barra inferior glassmorphism
        ├── glass_card.dart            # Tarjeta con efecto glass
        ├── add_to_library_sheet.dart  # Modal de añadir/editar biblioteca; sliders de puntuación avanzada (Anilist) según `scoringSystemSettingProvider` y `anilistAdvancedScoringEnabledProvider`
        ├── anilist_markdown.dart      # Parser/render markdown Anilist custom
        ├── fullscreen_image_viewer.dart  # Visor fullscreen en **navigator raíz** con `ChildBackButtonDispatcher` para que atrás de Android/gesto del sistema cierre el visor **antes** que GoRouter navegue
        ├── remote_network_image.dart
        ├── remote_network_image_io.dart
        ├── remote_network_image_web.dart
        └── feature_placeholder_page.dart
```

---

## Rutas (GoRouter)

### Dentro del ShellRoute (con barra de navegación inferior)

| Ruta | Pantalla | Descripción |
|------|----------|-------------|
| `/feed` | `FeedPage` | Feed con filtros: **Discover** (resumen trending de categorías visibles) + Anime/Manga + películas/TV Trakt + juegos IGDB + libros Google Books; Discover siempre visible y seleccionado por defecto al abrir |
| `/library` | `LibraryPage` | Biblioteca del usuario |
| `/search` | `SearchPage` | Búsqueda global |
| `/social` | `SocialPage` | Tab Social: feed Anilist (seguidos/global); **reemplaza** el antiguo tab Perfil en la barra inferior |
| `/profile` | `ProfilePage` | Perfil personal — accesible desde el **avatar en el AppBar** (arriba a la izquierda) |
| `/profile/personal-stats` | `PersonalStatsPage` | Anime/manga Anilist, estadísticas y favoritos locales (cine/TV/libros), juegos en Drift |
| `/profile/favorites/:kind` | `ProfileFavoritesPage` | Favoritos filtrados: `kind` ∈ `anime`, `manga`, `games`, `movies`, `tv`, `books`, `characters`, `staff`. Películas/TV = `favoriteTraktTitlesProvider`; libros = `favoriteBooksProvider`; personajes/staff = nodos de `favourites` del perfil Anilist |
| `/settings` | `SettingsPage` | Ajustes |
| `/notifications` | `AnilistNotificationsPage` | Bandeja de notificaciones Anilist (requiere token) |
| `/media/:id?kind=X` | `MediaDetailPage` | Detalle de anime/manga (kind = código numérico); incluye secciones **Personajes**, **Staff** y **Discusiones del foro** (carruseles + "Ver todos"/"Ver más") |
| `/media/:id/characters` | `MediaCharactersPage` | Lista paginada completa de personajes de un media Anilist |
| `/media/:id/staff` | `MediaStaffPage` | Lista paginada completa de staff de un media Anilist |
| `/character/:id` | `CharacterDetailPage` | Detalle de personaje Anilist (info + apariciones + voice actors); botón **toggle favorito** (requiere token Anilist) |
| `/staff/:id` | `StaffDetailPage` | Detalle de staff Anilist (character roles + staff media); botón **toggle favorito** |
| `/user/:id` | `UserProfilePage` | Perfil de otro usuario Anilist |
| `/activity/:id/replies` | `ActivityRepliesPage` | Comentarios de una actividad |
| `/review/:id` | `ReviewDetailPage` | Reseña Anilist (extra: datos iniciales opcionales) |
| `/game/:id` | `GameDetailPage` | Detalle de juego IGDB + reseñas comunidad si existen |
| `/igdb-review/:id` | `IgdbGameReviewDetailPage` | Reseña de usuario IGDB por id |
| `/trakt-movie/:id` | `TraktMovieDetailPage` | Detalle película (id numérico Trakt) |
| `/trakt-show/:id` | `TraktShowDetailPage` | Detalle serie (id numérico Trakt) |
| `/book/:workKey` | `BookDetailPage` | Detalle de libro (volumeId de Google Books) + progreso de lectura |
| `/books/section/:slug` | `BooksHomeSectionListPage` | Ver todo de una sección de libros |
| `/books/subject?subject=X&sort=Y` | `BookSubjectBrowsePage` | Exploración por tema de Google Books (orden local; slugs con guiones bajos se normalizan a espacios) |
| `/forum/media/:id` | `ForumMediaThreadsPage` | Lista de todos los hilos del foro para un media (mediaId) |
| `/forum/thread/:id` | `ForumThreadPage` | Hilo completo: cuerpo + comentarios anidados + likes + campo de respuesta |

### Fuera del ShellRoute (sin barra inferior)

| Ruta | Pantalla |
|------|----------|
| `/movies` | `MoviesPage` — home Trakt (tendencias, más esperadas, popular) |
| `/tv` | `TvPage` — home Trakt series |
| `/games` | `GamesPage` — listado IGDB (mismas secciones que el filtro Juegos del feed) |
| `/books` | `BooksHomeFeedView` — home de libros Google Books (secciones destacadas y temas) |
| `/auth` | `AuthPage` (placeholder) |

### Navegación entre tabs

Índices 0–4: `/feed` (icono `home`), `/library`, `/search`, `/social`, `/settings`

> **Nota:** el antiguo tab Perfil (índice 3) fue reemplazado por **Social**. El perfil personal ahora es accesible desde el **`ProfileAvatarButton`** en el `AppBar leading` del shell (arriba a la izquierda), que navega a `/profile` con `context.push`.

La ruta inicial se lee de `defaultStartPageProvider` (por defecto `/feed`).

### Búsqueda (`SearchPage`)

- **Filtros**: Todo, Anime, Manga, Películas, TV, Juegos, Libros.
- **Anime / Manga / Todo (parcial)**: GraphQL Anilist (`anilistSearchProvider`, etc.).
- **Películas / TV**: API Trakt (`traktSearchMoviesProvider`, `traktSearchShowsProvider`); con query vacía, mismo home que el feed: **películas** (tendencias, más esperadas `/movies/anticipated`, popular); **series** (tendencias, viendo ahora `/shows/watching`, popular); sin género `anime`.
- **Juegos**:
  - Con consulta vacía: rejilla de tendencia **`igdbPopularProvider`**; toque → `/game/:id`.
  - Con texto: **`igdbSearchProvider`**; resultados normalizados con `IgdbApiDatasource.normalize` (mismo shape que usa `AddToLibrarySheet` para `MediaKind.game`).
- **Libros (Google Books)**:
  - Con consulta vacía: se renderiza el home de libros (`BooksHomeFeedView`) como descubrimiento.
  - Con texto: **`bookSearchProvider`** con resultados normalizados (`workKey` = volumeId, portada, autores, páginas, rating y géneros).
- En **“Todo”**, además de anime/manga, se muestran secciones de resultados para juegos y libros cuando hay query.

---

## Base de datos (Drift / SQLite)

### Tablas

**`LibraryEntries`**
| Columna | Tipo | Notas |
|---------|------|-------|
| `id` | `int` autoincrement | PK |
| `kind` | `int` | Código de `MediaKind` |
| `externalId` | `text` | ID externo (Anilist para anime/manga; **id Trakt** para movie/tv; IGDB para juegos; **workKey** para libros) |
| `title` | `text` | Título |
| `posterUrl` | `text?` | URL de portada |
| `status` | `text` | `CURRENT`, `PLANNING`, `COMPLETED`, `PAUSED`, `DROPPED`, `REPEATING` |
| `score` | `int?` | Puntuación 0-100 |
| `progress` | `int?` | Episodios/capítulos vistos |
| `totalEpisodes` | `int?` | Total de episodios/capítulos |
| `editionKey` | `text?` | (Libros) volumeId de edición Google Books seleccionada |
| `isbn` | `text?` | (Libros) ISBN preferido de la edición |
| `totalPagesFromApi` | `int?` | (Libros) páginas detectadas desde API/edición |
| `totalChaptersFromApi` | `int?` | (Libros) capítulos detectados desde API/edición |
| `userTotalPagesOverride` | `int?` | (Libros) override manual de páginas |
| `userTotalChaptersOverride` | `int?` | (Libros) override manual de capítulos |
| `currentChapter` | `int?` | (Libros) capítulo actual cuando el modo es por capítulos |
| `bookTrackingMode` | `text?` | (Libros) `pages` \| `percentage` \| `chapters` |
| `notes` | `text?` | Notas del usuario |
| `updatedAt` | `dateTime` | Última actualización |

Restricción única: `(kind, externalId)`

> **Migración reciente (schema v4):** añade las columnas de tracking de libros a `library_entries`. El flujo mantiene compatibilidad con entradas antiguas y aplica fallback de total (`user override -> API -> totalEpisodes legacy`).

**`KeyValueEntries`**
| Columna | Tipo |
|---------|------|
| `id` | `int` autoincrement |
| `key` | `text` (único) |
| `value` | `text` |

### Métodos principales

- `upsertLibraryEntry(...)` — Insert or update
- `deleteLibraryEntry(id)`
- `getLibraryEntryById(id)`
- `incrementProgress(id)`
- `incrementBookProgress(id)` — incremento específico para libros según modo (`pages`, `%` o `chapters`) con cap y autocompletado
- `getLibraryPage({kindCode, status, limit, offset, orderBy, ascending})` — Paginado
- `countLibrary({kindCode, status})`
- `watchLibraryByKind(kindCode, {status})` — Stream
- `watchAllLibrary({status})` — Stream
- `normalizeStatuses()` — Migración a mayúsculas

---

## Providers (Riverpod)

### Core
| Provider | Tipo | Descripción |
|----------|------|-------------|
| `databaseProvider` | `AppDatabase` | Singleton DB |
| `dioProvider` | `Dio` | Cliente HTTP |
| `googleSignInProvider` | `GoogleSignIn` | Instancia Google Sign-In |
| `connectivityServiceProvider` | `bool` | Estado de conectividad |
| `backupRepositoryProvider` | `BackupRepository` | Legacy (Drive) |
| `appRouterProvider` | `GoRouter` | Router (keepAlive) |
| `sharedPreferencesProvider` | `SharedPreferences` | Override en main |

### Anime / Anilist
| Provider | Tipo | Descripción |
|----------|------|-------------|
| `anilistAuthProvider` | `AnilistAuthDatasource` | Auth helper |
| `anilistGraphqlProvider` | `AnilistGraphqlDatasource` | API client |
| `anilistTokenProvider` | `AsyncNotifier<String?>` | Token actual; `connectOAuthBridge()` en móvil si `usesHttpsImplicitBridge` (define HTTPS ≠ PIN) |
| `anilistSearchProvider(query, type)` | `Future<List<Map>>` | Búsqueda |
| `anilistPopularProvider(type)` | `Future<List<Map>>` | Trending (keepAlive) |
| `anilistMediaDetailProvider(id)` | `Future<Map>` | Detalle media (keepAlive) |
| `anilistProfileProvider` | `Future<Map?>` | Perfil del viewer |
| `anilistFeedProvider` | `AsyncNotifier<List<FeedActivity>>` | Feed global paginado (anime + manga + texto) |
| `anilistFeedByTypeProvider` | `AsyncNotifier<List<FeedActivity>>` | Feed por tipo paginado |
| `anilistFeedFollowingProvider` | `AsyncNotifier<List<FeedActivity>>` | Feed de seguidos (incluye texto) |
| `anilistMediaThreadsProvider(mediaId)` | `Future<List<Map>>` | Hilos del foro para un media (por `mediaCategoryId`, orden `REPLIED_AT_DESC`) |
| `anilistForumThreadProvider(threadId)` | `Future<Map?>` | Hilo completo con comentarios, `isLiked`, `likeCount` (usa token si disponible) |

### Juegos / IGDB (Twitch)
| Provider | Tipo | Descripción |
|----------|------|-------------|
| `igdbAuthProvider` | `IgdbAuthDatasource` | Client ID/secret desde `EnvConfig`, token en `FlutterSecureStorage` |
| `igdbApiProvider` | `IgdbApiDatasource` | Cliente IGDB (Dio + bearer) |
| `igdbSearchProvider(query)` | `Future<List<Map>>` | Búsqueda de juegos (normalizado con `IgdbApiDatasource.normalize`) |
| `igdbPopularProvider` | `Future<List<Map>>` | “Popular ahora”: primero **una sola** query `/games` por `total_rating` (rápida); si no hay datos, **PopScore** (`popularity_primitives` + `/games` por ids) y demás fallbacks |
| `igdbGamesHomeAsideProvider` | `Future<IgdbGamesHomeAsideData>` | Carruseles del home juegos salvo “Popular” (más esperados, recién salidos, próximamente, reseñas); en paralelo con popular |
| `igdbGameDetailProvider(gameId)` | `Future<Map?>` | Detalle + `igdb_reviews` (time-to-beat y reseñas se piden **en paralelo** tras el documento del juego) |
| `igdbReviewByIdProvider(reviewId)` | `Future<Map?>` | Una reseña IGDB por id (detalle lectura) |
| `favoriteGamesProvider` | `Notifier<List<Map>>` | Favoritos **solo locales** (SharedPreferences `favorite_games_v1`) |

### Libros / Google Books
| Provider | Tipo | Descripción |
|----------|------|-------------|
| `googleBooksApiProvider` | `GoogleBooksApiDatasource` | Cliente REST Google Books API v1 (keepAlive) |
| `bookSearchProvider(query)` | `Future<List<Map>>` | Búsqueda de libros por texto |
| `bookTrendingProvider` | `Future<List<Map>>` | Trending (subject:fiction, newest) |
| `bookSubjectProvider(subject)` | `Future<List<Map>>` | Obras por tema (normaliza slug con guiones bajos a espacios) |
| `bookSubjectBrowseProvider(subject)` | `Future<List<Map>>` | Browse enriquecido por tema (vía search API) |
| `bookWorkProvider(workKey)` | `Future<Map>` | Detalle de volumen con autores, rating, páginas |
| `bookWorkEditionsProvider(workKey)` | `Future<List<Map>>` | Ediciones relacionadas (búsqueda por título + autor) |
| `bookEditionProvider(editionKey)` | `Future<Map>` | Detalle de una edición/volumen específico |
| `bookWorkEditionModelsProvider(workKey)` | `Future<List<BookEdition>>` | Ediciones tipadas para UI/form |
| `favoriteBooksProvider` | `Notifier<List<Map>>` | Favoritos de libros **solo locales** (`favorite_books_v1`) |

### Library
| Provider | Tipo | Descripción |
|----------|------|-------------|
| `paginatedLibraryProvider(params)` | `AsyncNotifier<List<LibraryEntry>>` | Biblioteca paginada (15/página) |
| `defaultLibraryFilterProvider` | `AsyncNotifier<String>` | Filtro por defecto |
| `libraryByKindProvider` | `Stream<List<LibraryEntry>>` | Por tipo |
| `libraryAllProvider` | `Stream<List<LibraryEntry>>` | Todos |
| `libraryFilteredProvider` | `Stream<List<LibraryEntry>>` | Filtrado |

### Steam
| Provider | Tipo | Descripción |
|----------|------|-------------|
| `steamAuthProvider` | `SteamAuthDatasource` | Auth helper (SecureStorage) |
| `steamApiProvider` | `SteamApiDatasource` | API wrapper (Dio) |
| `steamSessionProvider` | `AsyncNotifier<SteamSessionState>` | Sesión: `connect()`, `disconnect()`, `refreshPlayerSummary()` |
| `steamOwnedGamesProvider` | `FutureProvider<List<Map>>` | Biblioteca Steam (cache JSON 6 h en `JsonCache`) |
| `steamGameAchievementsProvider(appId)` | `FutureProvider.family<SteamAchievementsResult, int>` | Logros player + schema cruzados; **sin autoDispose** |
| `steamAppDetailsProvider(appId)` | `FutureProvider.family<Map?, int>` | Store details (appdetails public API): `short_description`, `developers`, `metacritic`, `website`, `support_info`, `pc_requirements`, `header_image`; **sin autoDispose** |
| `steamAppNewsProvider(appId)` | `FutureProvider.family<List<Map>, int>` | Eventos y anuncios vía ISteamNews/GetNewsForApp/v2 (`feeds=steam_community_announcements`); **sin autoDispose** |
| `steamFriendsWithGameProvider(appId)` | `FutureProvider.family<SteamFriendsActivity, int>` | Amigos que poseen el juego (cap 100, concurrencia 8 para evitar rate-limit); **sin autoDispose** |
| `steamCurrentPlayersProvider(appId)` | `FutureProvider.family<int?, int>` | Jugadores actuales (ISteamUserStats/GetNumberOfCurrentPlayers) |
| `steamUserReviewsProvider(appId)` | `FutureProvider.family<Map?, int>` | Resumen de reseñas de usuarios (Steam Store reviews API) |
| `steamSpyTagsProvider(appId)` | `FutureProvider.family<Map<String,int>, int>` | Etiquetas populares de SteamSpy (sin API key, ordenadas por votos descendente) |
| `favoriteSteamGamesNotifierProvider` | `Notifier<List<Map>>` | Favoritos Steam locales (SharedPreferences `favorite_steam_games_v1`) |

> **Nota — `autoDispose` eliminado**: Los providers `.family` de detalle Steam **no** usan `autoDispose`. Al hacer scroll en un `ListView`, los widgets se desmontan del árbol y un provider `autoDispose` se libera y re-fetcha al volver a estar en pantalla. Sin `autoDispose`, los datos quedan cacheados en el contenedor Riverpod durante toda la sesión.

### Trakt (películas / TV)
| Provider | Tipo | Descripción |
|----------|------|-------------|
| `traktSessionProvider` | (codegen) | Sesión OAuth opcional; **Android:** navegador externo + `app_links` + deep link `cronicle://trakt-oauth`; **otras plataformas:** `FlutterWebAuth2` |
| `traktMoviesHomeProvider` | `Future<TraktMoviesHomeData>` | Tendencias, más esperadas, popular (películas) |
| `traktShowsHomeProvider` | `Future<TraktShowsHomeData>` | Tendencias, “viendo ahora”, popular (series) |
| `traktSearchMoviesProvider` / `traktSearchShowsProvider` | `Future<List<Map>>` | Búsqueda por query |
| `traktMovieDetailProvider` / `traktShowDetailProvider` | `Future<Map?>` | Resumen extendido para pantallas de detalle |
| `favoriteTraktTitlesProvider` | `Notifier<List<Map>>` | Favoritos **solo locales** (SharedPreferences `favorite_trakt_titles_v1`; clave compuesta `id` + `trakt_type` `movie`/`show`). Son los que marca el **corazón** en detalle Trakt (`TraktFavoriteButton`); alimentan perfil, estadísticas personales y `/profile/favorites/movies|tv` (**no** equivalen a los favoritos de la web Trakt vía API) |
| `profileTraktExtrasProvider` | `Future<ProfileTraktExtras?>` | Si hay sesión Trakt: **solo** mapa de estadísticas públicas (`/users/{slug}/stats`). Favoritos cine/TV en UI: ver `favoriteTraktTitlesProvider` |

### Settings
| Provider | Tipo | Descripción |
|----------|------|-------------|
| `scoringSystemSettingProvider` | `Notifier<ScoringSystem>` | Sistema de puntuación: `point100`, `point10Decimal`, `point10`, `point5`, `point3`; incluye `formatScore(double)`, `fromStoredScore(int?)`, `toStoredScore(double)` |
| `anilistAdvancedScoringEnabledProvider` | `Notifier<bool>` | Activa sliders de puntuación avanzada Anilist (Story/Characters/Visuals/Audio/Enjoyment) |
| `anilistAdvancedScoresProvider` | `Notifier<Map<String,double>>` | Valores de las 5 categorías de puntuación avanzada |
| `onboardingCompletedProvider` | `Notifier<bool>` | Onboarding inicial completado (`onboarding_completed` en SharedPreferences); `complete(selectedInterests)` configura layouts |
| `themeModeNotifierProvider` | `Notifier<ThemeMode>` | Tema |
| `deviceNotificationSettingsProvider` | `Notifier<DeviceNotificationState>` | Maestro + “nuevos capítulos” + inbox Anilist en dispositivo + social Anilist; persiste prefs y llama a `NotificationWorkScheduler.applyFromPrefs` |
| `feedFilterLayoutNotifierProvider` | (codegen) | Orden y visibilidad de chips del feed (anime, manga, movie, tv, game, book); **Discover / summary no forma parte de este layout** — siempre se antepone en `FeedPage` |
| `libraryKindLayoutNotifierProvider` | (codegen) | Orden y visibilidad de tipos en Biblioteca |
| `defaultStartPageProvider` | `Notifier<String>` | Página de inicio (`/feed` «Inicio» / `/library`) |
| `defaultFeedTabProvider` | `Notifier<String>` | Pestaña de inicio por defecto. Valores: `summary` (Discover — default), `anime`, `manga`, `movie`, `tv`, `game`, `book`. Resuelto en `FeedPage._build` cayendo a `summary` si la pestaña guardada no está visible en `feedFilterLayoutProvider` |
| `hideTextActivitiesProvider` | `Notifier<bool>` | Oculta/mostrar actividades de texto |

---

## Detalle Steam (`steam_game_detail_page.dart`)

### Ruta
`/profile/steam/game/:appid` — `SteamGameDetailPage` (StatefulWidget con Riverpod).

### Toggle Steam ↔ IGDB inline
El botón "Ver en IGDB" **no navega** a una nueva ruta. En su lugar usa dos campos de estado:
- `bool _showIgdbInline` — si es `true`, el `build()` retorna un `PopScope(canPop: false, child: GameDetailPage(gameId: _cachedIgdbId!, onSwitchToSteam: …))` **antes de cualquier `ref.watch`**, evitando conflictos con el árbol de providers.
- `int? _cachedIgdbId` — asignado atómicamente junto con `_showIgdbInline = true` en el mismo `setState` del callback `onIgdb`.

`GameDetailPage` acepta `onSwitchToSteam` opcional; cuando está presente, su estado local `_showSteamInline` muestra `SteamGameDetailPage` inline. Ninguna de las dos páginas llama a `Navigator.push`/`pushReplacement`.

### Secciones (en orden de aparición en el ListView)
| Widget | Descripción |
|--------|-------------|
| `_SteamHeaderImage` | Header con cadena de URLs candidatas; `_SteamScreenshotsCarousel` debajo |
| (horas / última partida) | Row con tiempo jugado y fecha última sesión |
| (botones de acción) | Añadir a biblioteca, toggle IGDB |
| `_SteamGameInfoCard` | Descripción corta (HTML), developer, puntuación Metacritic, jugadores actuales |
| `_SteamPopularTagsCard` | Top 15 etiquetas SteamSpy como contenedores pill (ver `steamSpyTagsProvider`) |
| `_SteamFriendsCard` | Amigos que poseen el juego y sus horas (ver `steamFriendsWithGameProvider`) |
| `_SteamNewsCard` | Eventos y anuncios recientes (ver `steamAppNewsProvider`) |
| `_SteamCommunityLinksCard` | 7 enlaces a Steam Community: hub, guías, discusiones, workshop, anuncios, historial de actualizaciones, tienda de puntos — como `ActionChip`s |
| `_SteamExternalLinksCard` | `website` + `support_info.url` de `steamAppDetailsProvider`; `_socialIconFor(url)` detecta la red social por host (Twitter/X, Facebook, YouTube, Discord, Reddit, Instagram, TikTok, Twitch) |
| `_SteamSystemRequirementsCard` | `pc_requirements.minimum` + `pc_requirements.recommended` (HTML); `_stripHtml()` convierte `<br>`, `<ul>/<li>`, `<strong>` y entidades HTML a texto limpio |
| `_AchievementsSummaryCard` | Logros del jugador (color/gris + fecha unlock) |
| `_SteamReviewsCard` | Resumen de reseñas de usuarios |
| `_SteamSimilarGamesCard` | Solo si `_cachedIgdbId != null`; lee `igdbGameDetailProvider(_cachedIgdbId!)` y renderiza `similar_games` de IGDB en un `ListView` horizontal (cubiertas 100×130, tap → `/game/$id`) |
| (botón "Ver en Steam") | Abre la ficha en la app/web de Steam |

### Internacionalización (claves ARB añadidas)
| Clave | ES | EN |
|-------|----|----|
| `steamCommunityLinks` | "Comunidad Steam" | "Steam Community" |
| `steamLinkCommunityHub` | "Hub de comunidad" | "Community Hub" |
| `steamLinkGuides` | "Guías" | "Guides" |
| `steamLinkDiscussions` | "Discusiones" | "Discussions" |
| `steamLinkWorkshop` | "Workshop" | "Workshop" |
| `steamLinkAnnouncements` | "Anuncios" | "Announcements" |
| `steamLinkUpdateHistory` | "Historial de actualizaciones" | "Update History" |
| `steamLinkPointsShop` | "Tienda de puntos" | "Points Shop" |
| `steamExternalLinks` | "Enlacesos externos" | "External Links" |
| `steamLinkOfficialSite` | "Sitio oficial" | "Official Site" |
| `steamLinkSupport` | "Soporte" | "Support" |
| `steamPopularTags` | "Etiquetas populares" | "Popular Tags" |
| `steamSystemRequirements` | "Requisitos del sistema" | "System Requirements" |
| `steamSysReqMinimum` | "Mínimos" | "Minimum" |
| `steamSysReqRecommended` | "Recomendados" | "Recommended" |
| `steamSimilarGames` | "Juegos similares" | "Similar Games" |

---

## Foros de Anilist

### Arquitectura

- **Sección en detalle de anime/manga** (`media_detail_page.dart`): `_buildForumThreads()` usa `anilistMediaThreadsProvider(mediaId)` (Consumer) y muestra hasta 3 hilos con `_ForumThreadTile`. El botón "Ver más" navega a `/forum/media/$mediaId`.
- **`ForumMediaThreadsPage`** (`/forum/media/:id`): lista completa de hilos usando `anilistMediaThreadsProvider`.
- **`ForumThreadPage`** (`/forum/thread/:id`): `ConsumerStatefulWidget` completo. Recibe `threadId` e `initialData` (datos ligeros del tile para mostrar título inmediatamente). Carga el hilo directamente con `anilistGraphqlProvider.fetchForumThread` (pasando token para recibir `isLiked`).

### Estado local en `ForumThreadPage`

| Campo | Descripción |
|-------|-------------|
| `_thread` | Datos del hilo |
| `_comments` | Lista de comentarios de nivel superior |
| `_threadIsLiked` / `_threadLikeCount` | Estado like del hilo principal |
| `Map<int,bool> _commentIsLiked` | Like por id de comentario (top-level + childComments) |
| `Map<int,int> _commentLikeCount` | Conteo like por id |
| `_replyTarget` | `({int id, String name})?` — comentario al que se responde |
| `_replyFocusNode` | Focus para activar teclado al pulsar "Responder" |

### Comentarios anidados

- Anilist devuelve `childComments` como un **campo JSON escalar** (no tipo objeto GraphQL). Se solicita sin sub-selección y se parsea en Dart con `.whereType<Map>().map(Map<String,dynamic>.from)`.
- `_CommentTile` es `StatefulWidget`; gestiona `_collapsed` localmente.
- Al colapsar (tap en el chip entre el comentario y sus respuestas): se ocultan los `_ChildCommentTile` y se muestra un chip que indica cuántas respuestas hay. Al expandir se muestran de nuevo.
- El chip toggle (expandir/colapsar) está situado **entre** el cuerpo del comentario y las respuestas — el cuerpo del comentario principal y sus botones siempre son visibles.

### Likes

- **Like de hilo**: llama a `toggleLike(id, token, type: 'THREAD')`. El fragmento `... on Thread { id isLiked likeCount }` está incluido en la mutación `ToggleLikeV2`.
- **Like de comentario**: `toggleLike(id, token, type: 'THREAD_COMMENT')`. Fragmento `... on ThreadComment { id isLiked likeCount }`.
- Ambos actualizan estado local optimistamente (sin refetch).

### Publicar comentarios y respuestas

- `saveThreadComment(threadId, text, token, {replyCommentId})` — mutación `SaveThreadComment` con campo `replyCommentId` opcional.
- Al seleccionar "Responder" en un comentario o sub-comentario: se guarda `_replyTarget` con `id` y `name`, se muestra el banner "Respondiendo a @username" encima del campo de texto, y se hace focus automático.
- Cancelar respuesta: botón `×` en el banner limpia `_replyTarget`.
- Tras enviar: se hace `_load()` completo para refrescar el árbol de comentarios con la nueva respuesta en su lugar correcto.

### `_ReplyInputBar`

- Sticky al final de la pantalla (fuera del `CustomScrollView`).
- Muestra banner "Respondiendo a @name" cuando hay `replyTarget` activo.
- Hint: "Inicia sesión en Anilist para comentar" si no hay sesión; "Escribe una respuesta…" si la hay.
- Deshabilita el campo y el botón de envío si no hay sesión o si `_sending` es true.

---

## Personajes y Staff de Anilist

### Visualización en detalle de media

- En `media_detail_page.dart` (`_buildCharacters` y `_buildStaff`) se muestran dos carruseles horizontales (altura 175 / 165) entre las secciones de relaciones y recomendaciones, leyendo `media['characters'].edges` y `media['staff'].edges` que vienen ya en `fetchMediaDetail` (`characters(sort:[ROLE,RELEVANCE,ID], perPage:12)` y `staff(sort:[RELEVANCE,ID], perPage:8)`).
- Cada tarjeta de personaje muestra imagen + nombre + rol localizado (`_formatCharacterRole(role, l10n)` → `MAIN`/`SUPPORTING`/`BACKGROUND` traducidos) + primer voice actor (linkable a su staff).
- Botón **"Ver todos"** navega a `/media/:id/characters` o `/media/:id/staff` para la lista paginada completa (`MediaCharactersPage` / `MediaStaffPage`, scroll infinito vía `fetchMediaCharacters` / `fetchMediaStaff`).

### Detalle individual

- **`CharacterDetailPage`** (`/character/:id`) — usa `anilistCharacterDetailProvider(characterId)`:
  - Header con imagen + nombre + nombre nativo, **botón corazón** que llama a `toggleFavouriteCharacter` (requiere token; si no hay, muestra `loginRequiredFavoriteCharacter`).
  - Tarjeta de información: edad, género, fecha de nacimiento, tipo de sangre.
  - Chips de **nombres alternativos**; los `alternativeSpoiler` aparecen ocultos hasta tap (mismo patrón que reseñas spoiler).
  - Descripción con `AnilistMarkdown` y expand. Como el widget no soporta `maxLines`, se recorta visualmente con `ConstrainedBox` + `SingleChildScrollView(physics: NeverScrollableScrollPhysics())` mientras está colapsada.
  - **Apariciones**: lista de `_MediaEdgeTile` con poster del media (linkable a `/media/:id?kind=…`), rol del personaje en ese media y chips de voice actors (linkable a `/staff/:id`).

- **`StaffDetailPage`** (`/staff/:id`) — usa `anilistStaffDetailProvider(staffId)`:
  - Header equivalente con toggle favorito (`toggleFavouriteStaff`).
  - Chips de `primaryOccupations`.
  - Info: edad, género, lugar de nacimiento, tipo de sangre, fecha nacimiento/muerte, años activo.
  - Descripción Markdown.
  - **Character roles** (`_CharacterRoleTile`): edges de `characterMedia` con personaje (linkable) + media en el que aparece.
  - **Staff roles** (`_StaffRoleTile`): edges de `staffMedia` con rol (Director, Original Creator…) + media.

### Favoritos en perfil

- `fetchViewerProfile` y `fetchUserProfile` extienden el bloque `favourites` con `characters(perPage:25){nodes{...}}` y `staff(perPage:25){nodes{...}}`.
- **Perfil personal** (`profile_page.dart`): el bloque "Favoritos" añade dos filas extra (Personajes / Staff) con icono, contador y miniaturas (`thumbsFromCharStaff`); tap → `/profile/favorites/characters` o `/profile/favorites/staff`.
- **`ProfileFavoritesPage`** maneja `ProfileFavoritesKind.characters` y `.staff` con `_charStaffBody` + `_PersonGrid` (3 columnas, aspect ratio 0.62, tap → detalle correspondiente). No requiere merge con favoritos locales — son **solo del servidor Anilist**.
- **Perfil de otro usuario** (`user_profile_page.dart`): añade dos carruseles `_FavPersonCard` después de favoritos manga.
- `ProfileFavoritesKind` extiende su enum con `characters('characters')` y `staff('staff')` para los segmentos de ruta.

### Providers (`anime_providers.dart`)

| Provider | Tipo | Descripción |
|----------|------|-------------|
| `anilistCharacterDetailProvider(characterId)` | `Future<Map<String,dynamic>?>` | Detalle de personaje (incluye `isFavourite` si hay token). Se invalida desde `_invalidateSessionScopedProviders` al cambiar de sesión |
| `anilistStaffDetailProvider(staffId)` | `Future<Map<String,dynamic>?>` | Detalle de staff. Mismo manejo de invalidación |

> Tras tocar el corazón en detalle de personaje/staff, las pantallas hacen `ref.invalidate(anilistProfileProvider)` para refrescar el bloque de favoritos del perfil.

---

## Sistema de puntuación (Ajustes)

### `ScoringSystem` enum (`app_defaults_notifier.dart`)

| Valor | Descripción | Rango |
|-------|-------------|-------|
| `point100` | Entero 0–100 | 0–100 |
| `point10Decimal` | Decimal 0.0–10.0 (pasos 0.5) | 0.0–10.0 |
| `point10` | Entero 0–10 | 0–10 |
| `point5` | Estrellas 1–5 | 0–5 |
| `point3` | Smileys 1–3 | 0–3 |

Métodos del enum: `max`, `divisions`, `formatScore(double)`, `fromStoredScore(int?)`, `toStoredScore(double)`.

### Providers

- `scoringSystemSettingProvider` — `Notifier<ScoringSystem>` (SharedPreferences `anilist_scoring_system`).
- `anilistAdvancedScoringEnabledProvider` — `Notifier<bool>` (clave `anilist_advanced_scoring_enabled`).
- `anilistAdvancedScoresProvider` — `Notifier<Map<String,double>>` (clave `anilist_advanced_scores_json`).

### UI

- **`settings_page.dart` → `_ScoringSection`**: ChoiceChips para elegir sistema + SwitchListTile para puntuación avanzada.
- **`add_to_library_sheet.dart`**: slider adaptado al sistema elegido; si avanzada activa y media es anime/manga, se muestran 5 sliders adicionales (Story, Characters, Visuals, Audio, Enjoyment). En `initState` convierte la puntuación almacenada (0–100 int) con `scoring.fromStoredScore(e?.score)`; al guardar, usa `scoring.toStoredScore(_score)`.
- **`library_page.dart`**: muestra la puntuación formateada con `scoring.formatScore(scoring.fromStoredScore(entry.score))`.

### Seguimiento de libros (nuevo)

- **Modo de tracking por entrada** (`add_to_library_sheet.dart`): selector segmentado con `pages`, `percentage` y `chapters`.
- **Edición Google Books seleccionable**: dropdown por obra (`bookWorkEditionsProvider`) para captar páginas/ISBN reales de edición.
- **Overrides manuales**: el usuario puede definir total de páginas o capítulos cuando la API no trae datos fiables.
- **Prioridad de totales** (dominio): `user override -> total desde API -> fallback legacy`.
- **Cálculo reutilizable**: `BookProgressCalculator` centraliza porcentaje, etiquetas de progreso, restante e increment cap.
- **Incremento rápido en biblioteca**: para libros usa `incrementBookProgress` y respeta el modo activo (incluye tope al 100% en modo porcentaje).
- **Detalle libro**: `BookDetailPage` muestra tarjeta de progreso ligada a la entrada local (barra, badge de modo, texto progreso/restante).

---

## API: Google Books (libros)

- **Base**: `https://www.googleapis.com/books/v1`
- **Datasource**: `features/books/data/datasources/google_books_api_datasource.dart`
- **Autenticación**: API key pública (`GOOGLE_BOOKS_API_KEY` en `dart_defines.local.json`; query param `key=`). La clave debe estar restringida **solo por API** (Books API) en Google Cloud Console — las restricciones de app Android bloquean las llamadas REST desde Dio (el identificador de cliente queda `<empty>`). Sin key la API también funciona, con cuota anónima.
- **Cobertura**:
  - `searchBooks(query)` — búsqueda libre
  - `searchBooksBySubject(subject)` — por tema
  - `searchBooksByPublishYear(year, month?)` — por año/mes de publicación
  - `fetchSubject(subject)` — sección de home por tema
  - `fetchTrending()` — trending (subject:fiction, newest)
  - `fetchWork(volumeId)` — detalle de volumen
  - `fetchWorkEditions(volumeId)` — volúmenes relacionados por título + autor
  - `fetchEdition(volumeId)` — detalle de volumen como edición
- **Normalización**: devuelve shape compatible con cards y `AddToLibrarySheet` (`workKey` = volumeId, `title`, `coverImage`, `averageScore`, `pages`, `authors`, etc.); filtra automáticamente resultados con categorías de manga.
- **Resiliencia**:
  - HTTP 503 (rate-limit): `_get<T>()` espera 900 ms y reintenta una vez automáticamente.
  - UTF-8 malformado: Google Books devuelve respuestas gzip cuyas descripciones pueden contener secuencias de bytes no válidas en UTF-8. El decodificador por defecto de Dio lanza `FormatException` y cierra la app. Se usa un `_lenientUtf8Decoder` estático (`utf8.decode(bytes, allowMalformed: true)`) inyectado en todas las peticiones vía `Options(responseDecoder: ...)`. Las secuencias inválidas se reemplazan por U+FFFD en lugar de lanzar excepción.
- **Slugs**: `_normalizeSubject()` convierte slugs internos como `science_fiction` → `science fiction` antes de enviarlos a la API.
- **Imágenes**: URLs de portada forzadas a HTTPS; `zoom=2` para resolución alta.

---

## API: IGDB v4

- **Base**: `https://api.igdb.com/v4` — cuerpo en **text/plain** (sintaxis **Apicalypse**), headers `Client-ID` y `Authorization: Bearer <token>`.
- **Token**: OAuth2 **client credentials** de Twitch (`https://id.twitch.tv/oauth2/token`); credenciales desde **`EnvConfig`** (`TWITCH_CLIENT_ID`, `TWITCH_CLIENT_SECRET` vía `--dart-define` o entorno de compilación). El token de app se guarda en **SecureStorage** (`igdb_access_token`, `igdb_token_expires_at`). **Rendimiento:** `IgdbAuthDatasource` mantiene el bearer en **memoria** unos minutos y **deduplica** peticiones concurrentes a `getValidToken()` para no leer `FlutterSecureStorage` en cada POST (home con varias llamadas en paralelo).
- **Código**: `features/games/data/datasources/igdb_api_datasource.dart` y `igdb_auth_datasource.dart`.
- **Web**: IGDB no admite orígenes navegador (CORS); en **web** las llamadas lanzan `IgdbWebUnsupportedException` y la UI muestra mensaje localizado (`igdbWebNotSupported`).
- **Resiliencia**:
  - Listados de juegos “home” usan **varias consultas candidatas** (`_tryPostGameQueries`) para evitar listas vacías ante campos retirados o filtros demasiado estrictos (`hypes`, `first_release_date` vs `release_dates`, etc.).
  - **Popular:** prioridad a una query rápida por `total_rating`; si no hay resultados, se usa la ruta **PopScore** (`popularity_primitives` + `/games`).
  - Reseñas intentan **`/review`** y **`/reviews`**; tras el primer acierto se **cachea** el endpoint que respondió para las siguientes listas. Ante 404 u otros fallos las listas de reseñas pueden quedar vacías sin tumbar el resto del provider.
  - **Detalle de juego:** tras cargar `/games`, **time-to-beat** (`/game_time_to_beats`) y **reseñas del juego** se solicitan **en paralelo** (`Future.wait`).
- **Imágenes**: URLs construidas con `IgdbApiDatasource.coverUrl(imageId)` → CDN `images.igdb.com`.

### Métodos principales (`IgdbApiDatasource`)

| Área | Métodos (resumen) |
|------|---------------------|
| Búsqueda | `searchGames` |
| Listados | `fetchPopularGames` (rápido por `total_rating`, luego PopScore y fallbacks), `fetchGamesMostAnticipated`, `fetchGamesRecentlyReleased`, `fetchGamesComingSoon` |
| Reseñas | `fetchReviewsRecent`, `fetchReviewsHighScore`, `fetchGameReviews`, `fetchReviewById` |
| Detalle | `fetchGameDetail`, `_fetchGameTimeToBeat` (`/game_time_to_beats`) |
| Utilidad | `normalize(raw)` → mapa común (título, portada, géneros, plataformas, nota…) para búsqueda y biblioteca |

---

## API: Anilist GraphQL

### Queries
| Método | Descripción |
|--------|-------------|
| `fetchRecentActivity` | Actividad global reciente |
| `fetchRecentActivityByType` | Actividad por tipo (anime/manga), soporta `isFollowing` |
| `searchAnime/searchManga/searchMedia` | Búsqueda |
| `fetchPopular(type)` | Trending |
| `fetchMediaDetail(id)` | Detalle completo (relaciones, recomendaciones, reviews, score distribution) |
| `fetchUserMediaList(token, userName, type)` | Lista del usuario |
| `fetchCurrentListWithAiringSchedule(token, userName, type)` | Lista **CURRENT** con `media.status` y `nextAiringEpisode` (anime/manga; notificaciones de emisión) |
| `fetchViewer(token)` | Datos básicos del viewer |
| `fetchViewerProfile(token)` | Perfil completo con stats y favoritos |
| `fetchUserProfile(userId, {token})` | Perfil de otro usuario |
| `fetchUserActivity(userId, {token})` | Actividad reciente de un usuario |
| `fetchActivityReplies(activityId, {token})` | Comentarios de una actividad |
| `fetchMediaThreads(mediaId, {perPage})` | Hilos del foro para un media (`mediaCategoryId`, orden `REPLIED_AT_DESC`); devuelve lista con id, title, createdAt, replyCount, viewCount, user |
| `fetchForumThread(threadId, {token})` | Hilo completo: body, categorías, user, `isLiked`, `likeCount`; comentarios con `childComments` (campo JSON escalar), `isLiked`, `likeCount`; combina `Thread` + `Page.threadComments` en una sola query |
| `fetchCharacterDetail(id, {token, mediaPage, mediaPerPage})` | Detalle de personaje: name (full/native/alternative/alternativeSpoiler), image, description, dateOfBirth, age, gender, bloodType, `isFavourite`, y `media.edges` con `characterRole`, `voiceActors` y nodos de media para listar apariciones |
| `fetchStaffDetail(id, {token, charactersPage, characterMediaPage, staffMediaPage, ...})` | Detalle de staff: name, image, description, primaryOccupations, gender, dateOfBirth/Death, age, yearsActive, homeTown, bloodType, `isFavourite`; `characterMedia.edges` (con personajes interpretados) y `staffMedia.edges` (roles de staff) |
| `fetchMediaCharacters(mediaId, {page, perPage})` | Lista paginada de personajes de un media; cada edge con `role`, `node` (personaje) y `voiceActors(language: JAPANESE)`. Devuelve record `({edges, hasNextPage, total})` |
| `fetchMediaStaff(mediaId, {page, perPage})` | Lista paginada de staff de un media; cada edge con `role` y `node`. Mismo record `({edges, hasNextPage, total})` |

### Mutations
| Método | Descripción |
|--------|-------------|
| `toggleLike(activityId, token, {type})` | Like/unlike — tipos soportados: `ACTIVITY`, `ACTIVITY_REPLY`, `THREAD`, `THREAD_COMMENT` |
| `saveMediaListEntry(mediaId, token, ...)` | Guardar/actualizar entrada en Anilist |
| `deleteMediaListEntry(entryId, token)` | Eliminar entrada de Anilist |
| `toggleFollow(userId, token)` | Seguir/dejar de seguir usuario |
| `saveTextActivity(text, token)` | Publicar actividad de texto |
| `saveActivityReply(activityId, text, token)` | Publicar comentario/reply en actividad |
| `saveThreadComment(threadId, text, token, {replyCommentId})` | Publicar comentario en hilo del foro; `replyCommentId` opcional para respuestas anidadas |
| `toggleFavouriteCharacter({characterId, token})` | Marca/desmarca personaje como favorito en Anilist (`ToggleFavourite` mutation, `characterId`); devuelve los nodos actualizados |
| `toggleFavouriteStaff({staffId, token})` | Marca/desmarca miembro de staff como favorito en Anilist (`ToggleFavourite`, `staffId`) |

### Notas de implementación recientes (importante)
- `fetchNotifications(..., resetNotificationCount: false)` se usa en segundo plano para **no** limpiar el contador de no leídas en Anilist al sincronizar al dispositivo.
- `fetchRecentActivityByType` y `fetchUserActivity` ahora incluyen `TextActivity`.
- Filtro corregido: no excluir actividades de texto por ausencia de `media`.
- Manejo de errores GraphQL mejorado en `_post` para respuestas HTTP 400.
- Mutaciones de texto/reply ajustadas a nullabilidad real del schema de Anilist.
- **`childComments`** en `threadComments` es un campo **JSON escalar** en el schema de Anilist (no un tipo objeto); se pide sin sub-selección (`childComments` bare) y se parsea manualmente con `.whereType<Map>().map(Map<String,dynamic>.from)`.
- Tags de estado en `MediaDetailPage` (`NOT_YET_RELEASED`, `RELEASING`, `FINISHED`, `CANCELLED`, `HIATUS`, y códigos de formato `TV_SHORT`, `OVA`, etc.) pasan por `_formatMediaStatus(raw, isStatus, l10n)` para localizar la cadena; nunca se muestran los valores crudos de la API.

---

## Autenticación

### Twitch / IGDB (token de aplicación + OAuth usuario para «Conectar Twitch»)

1. **Token de aplicación (IGDB):** registrar app en [Twitch Developer Console](https://dev.twitch.tv/console/apps) y obtener **Client ID** + **Client Secret**. Pasar a la compilación: `--dart-define=TWITCH_CLIENT_ID=...` y `--dart-define=TWITCH_CLIENT_SECRET=...` (ver `EnvConfig`). El datasource (`IgdbAuthDatasource`) renueva el token **client_credentials** y lo persiste en **FlutterSecureStorage** (`igdb_access_token`, `igdb_token_expires_at`).
2. **OAuth de usuario (Conectar Twitch en Ajustes):** la consola de Twitch **no** acepta `cronicle://` como Redirect URI. Debe ser **HTTPS** (p. ej. Netlify) sirviendo `web/twitch_oauth_bridge.html`, registrada como `TWITCH_REDIRECT_URI` y en el panel de Twitch. El HTML redirige a `cronicle://twitch-oauth?…`; en la app, `FlutterWebAuth2` + `CallbackActivity` completan el flujo (`game_providers.dart`).

### Anilist (OAuth implícito `response_type=token`)

**Código:** `AnilistAuthDatasource` (`lib/features/anime/data/datasources/anilist_auth_datasource.dart`), flujo UI `showAnilistConnectFlow` (`anilist_connect_flow.dart`), token en Riverpod `anilistTokenProvider` (`anime_providers.dart`).

1. **Client ID** por defecto: `39257` (`defaultAnilistClientId`). Override opcional: `--dart-define=ANILIST_CLIENT_ID=…` → `EnvConfig.anilistClientId`.
2. **URL de autorización** (solo `client_id` + `response_type=token`; **no** enviar `redirect_uri` en la query): si se añade `redirect_uri` junto con `token`, Anilist responde `unsupported_grant_type`. El destino tras autorizar lo decide **solo** la *Redirect URL* registrada en [anilist.co/settings/developer](https://anilist.co/settings/developer) para esa aplicación.
3. **Modo PIN (por defecto)**  
   - `ANILIST_REDIRECT_URI` sin tocar o apuntando a `https://anilist.co/api/v2/oauth/pin` → pantalla PIN de Anilist; el usuario copia el token y lo pega en el diálogo de la app (Ajustes o pestaña Anime).
4. **Modo puente HTTPS + vuelta a la app (Android / iOS)**  
   - Despliega `web/anilist_oauth_bridge.html` en una URL **HTTPS** (p. ej. Netlify).  
   - En el panel de desarrollador de Anilist, la **Redirect URL** debe coincidir **exactamente** con esa URL (Anilist admite **una** redirect por app).  
   - En `dart_defines.local.json`, `ANILIST_REDIRECT_URI` debe ser esa misma URL HTTPS (sirve para que la app detecte «modo puente» con `AnilistAuthDatasource.usesHttpsImplicitBridge`; **no** se concatena en la URL de `/oauth/authorize`).  
   - Tras autorizar, Anilist redirige al puente con `#access_token=…` en el fragmento; el HTML abre `cronicle://anilist-oauth?access_token=…`. En móvil, `AnilistToken.connectOAuthBridge()` usa `url_launcher` (navegador externo) + `app_links` para leer el deep link (mismo patrón que Trakt en Android).  
   - En **escritorio** con puente, el HTML muestra el token para copiar y el diálogo de la app sigue existiendo.
5. **Web (build Flutter web):** conectar Anilist desde el navegador no está soportado en ese flujo; mensaje localizado. **Web con `auth_callback.html`:** si el proyecto sigue usando captura vía `web/auth_callback.html` / `localStorage` en `main`, documentar en despliegue propio.
6. Token y nombre de usuario en `FlutterSecureStorage` (`anilist_access_token`, `anilist_user_name`); `setToken` rellena el nombre vía GraphQL `Viewer`.

### Deep links `cronicle://` y OAuth en Android

- **`android/app/src/main/AndroidManifest.xml`**
  - **`MainActivity`**: `VIEW` + `BROWSABLE` para `cronicle://trakt-oauth` y `cronicle://anilist-oauth` (el motor Flutter recibe el URI → `app_links`).
  - **`CallbackActivity`** (`flutter_web_auth_2`): solo `cronicle://twitch-oauth` (OAuth IGDB/Twitch con `FlutterWebAuth2.authenticate`).
- **Trakt (Android):** no usar solo Custom Tab para volver a la app; `TraktSession.connectOAuth()` abre el **navegador del sistema** (`LaunchMode.externalApplication`) y espera el callback con **`app_links`** (paquete `app_links`). **iOS** Trakt sigue con `FlutterWebAuth2`.
- **Anilist (Android/iOS)** con puente HTTPS: `connectOAuthBridge()` igual (externo + `app_links`).
- **GoRouter** (`app_router.dart`): si la «ruta» del sistema es `cronicle://…`, un `redirect` envía a **`/settings`** para evitar `GoException: no routes for location` al reentrar desde el navegador.
- **HTML en `web/`** (desplegar en HTTPS; URL exacta en cada consola de proveedor):
  - `trakt_oauth_bridge.html` — Trakt redirige con `?code=&state=` → abre la app (auto `location.replace` + botón de respaldo).
  - `twitch_oauth_bridge.html` — puente hacia `cronicle://twitch-oauth?…`.
  - `anilist_oauth_bridge.html` — lee `#access_token=…` → `cronicle://anilist-oauth?access_token=…` (móvil) o muestra token en PC.

### Google Sign-In
1. `GoogleSignIn.instance.initialize()` en `main` (no web): `serverClientId` = cliente **Web** (`GOOGLE_SERVER_CLIENT_ID`); en Android `clientId` = `GOOGLE_ANDROID_CLIENT_ID` si existe; en iOS `GOOGLE_IOS_CLIENT_ID` si existe (ver `EnvConfig` y `dart_defines.example.json`).
2. Scope en ajustes (sesión Drive): `https://www.googleapis.com/auth/drive.appdata` (sin `email` en el hint, para simplificar OAuth).
3. Usado para backup/restauración a Google Drive.
4. **Android (Cloud Console)**: el cliente OAuth tipo **Android** debe usar el package **`com.cronicle.app.cronicle`** y el **SHA-1** del keystore de la APK que instales (debug, release o firma de **Play App Signing** si publicas en Play). Para listar SHA-1: desde `android/`, `.\gradlew.bat signingReport` (Windows) o `./gradlew signingReport` (macOS/Linux).
5. **`GOOGLE_SERVER_CLIENT_ID`**: debe ser el **cliente Web** del **mismo** proyecto de Google Cloud (no el ID del cliente Android). Sin este valor, en Ajustes se muestra aviso y no se abre el flujo de login.
6. **Visibilidad de paquetes**: en `AndroidManifest.xml` hay `<queries><package android:name="com.google.android.gms" /></queries>` para Android 11+ y Google Play services.

---

## Backup / Restore (local JSON)

- **Ubicación funcional**: `features/settings/presentation/settings_page.dart` (`_BackupSection`)
- **Texto de la sección (l10n)**: `backupSectionSubtitle` describe **únicamente** guardar biblioteca y preferencias en un **archivo**. La copia opcional en **Google Drive** sigue en la misma pantalla pero con textos propios (`backupAutoGoogleTitle`, `backupAutoGoogleSubtitle`, etc.); no mezclar en el subtítulo de “copia local”.
- **Última sincronización (Google Drive)**: la línea `googleLastSyncLine` muestra **fecha + hora** (`formatShortDate` + `formatTimeOfDay` de `MaterialLocalizations`), no solo la hora. Se calcula en `_lastSyncWhen` dentro de `settings_page.dart` a partir de `GoogleDriveBackupPrefs.lastRunMs`.
- **Formato**: JSON con `version`, `exportedAt`, `library`, `keyValues`
- **Exportar**:
  - Genera `cronicle_backup.json`
  - En móvil/escritorio usa archivo temporal + `share_plus`
  - En web comparte el texto JSON
- **Restaurar**:
  - Selector de archivo con `file_picker` (solo `.json`)
  - Confirma cantidad de entradas
  - Restaura con `upsertLibraryEntry` (merge/update por `(kind, externalId)`)
  - Tras restaurar, `AppBackupBundle` invalida proveedores relevantes (incluye **`favoriteGamesProvider`**, **`favoriteSteamGamesProvider`**, **`favoriteTraktTitlesProvider`** y **`favoriteBooksProvider`** para refrescar favoritos en memoria).
- **Schema v4 del backup**: incluye `steamAppId` por entrada y los campos de tracking de libros (`editionKey`, `isbn`, `totalPagesFromApi`, `totalChaptersFromApi`, `userTotalPagesOverride`, `userTotalChaptersOverride`, `currentChapter`, `bookTrackingMode`). Las claves `steam_steamid64`, `steam_persona_name`, `steam_avatar_url`, `steam_profile_url` de SecureStorage también se exportan, así que la sesión Steam sobrevive a una restauración. Los favoritos Steam se preservan vía SharedPreferences (`favorite_steam_games_v1`).
- **Sin login**: no requiere Google ni Anilist

### Dependencias nuevas usadas por backup local
- `file_picker`
- `share_plus`

### Dependencias usadas por notificaciones en el dispositivo
- `flutter_local_notifications`
- `workmanager`

### Dependencias OAuth (deep links en móvil)
- `app_links` — recepción de `cronicle://trakt-oauth` y `cronicle://anilist-oauth` tras el puente HTTPS en navegador externo (Android/iOS).
- `flutter_web_auth_2` — Twitch/IGDB y Trakt en plataformas donde sigue usándose `authenticate()` con `CallbackActivity` / Custom Tab según implementación.

---

## Internacionalización (l10n)

- **Idiomas**: Español (`es`), Inglés (`en`)
- **Plantilla**: `app_es.arb`
- Claves en **`app_es.arb`** / **`app_en.arb`** (incluye textos de juegos IGDB, feed, errores web IGDB, permisos y ajustes de notificaciones del dispositivo, Apariencia en ajustes, etc.)
- **Claves de foros (añadidas en esta sesión):**
  - `forumDiscussions` — "Discusiones" / "Discussions"
  - `forumViewAll` — "Ver todo" / "View all"
  - `forumThread` — "Hilo" / "Thread"
  - `forumReplies` — "{count} respuestas" / "{count} replies" (con `count: int`)
  - `forumNoReplies` — "Sin respuestas aún" / "No replies yet"
  - `forumReplyButton` — "Responder" / "Reply"
  - `forumReplyingTo` — "Respondiendo a @{name}" / "Replying to @{name}" (con `name: String`)
- **Clave de login para comentario:**
  - `loginRequiredComment` — "Inicia sesión en Anilist para comentar" / "Sign in with Anilist to comment"
- **Claves de estado/formato de media (añadidas para media detail):**
  - `mediaStatusFinished`, `mediaStatusReleasing`, `mediaStatusNotYetReleased`, `mediaStatusCancelled`, `mediaStatusHiatus`
  - `mediaFormatTvShort`, `mediaFormatOva`, `mediaFormatOna`, `mediaFormatSpecial`, `mediaFormatMovie`, `mediaFormatMusic`
- **Claves del tab Discover / Summary (sección resumen del feed):**
  - `feedSummary` — "Descubrir" / "Discover" (etiqueta del chip)
  - `summaryTrendingAnime`, `summaryTrendingManga`, `summaryTrendingMovies`, `summaryTrendingShows` — títulos de sección trending por categoría
  - `summaryPopularGames` — sección popular de juegos
  - `summaryTopAnime`, `summaryTopManga` — sección top (no usada actualmente pero reservada)
  - `summaryAnticipatedMovies`, `summaryAnticipatedShows`, `summaryAnticipatedGames` — secciones de anticipados
  - `summaryRandom`, `summaryRandomButton`, `summaryRandomSub` — textos del botón de suerte
  - `summarySeeAll` — "Ver todo" / "See all" en cabeceras de sección
- **Claves de libros (Google Books + tracking):**
  - `filterBooks`, `mediaKindBook`
  - `bookTrackingModeLabel`, `bookTrackingModePages`, `bookTrackingModePercent`, `bookTrackingModeChapters`
  - `bookPercentageRead`, `bookChapterProgress`, `bookReadingProgress`
  - `bookOverrideTotalsTitle`, `bookOverrideTotalsHint`, `bookEditionLabel`, `bookEditionUnknownPages`, `bookEditionNoPageHint`
  - `bookDetailPages`, `bookDetailEditions`, `bookDetailPublishDate`, `bookDetailAuthors`
- **Idioma por defecto**: el del dispositivo (si es `es` o `en`, si no → `en`)
- **Cambio manual**: desde Ajustes → `LocaleNotifier`
- **Generación**: `flutter gen-l10n` o automático al compilar
- **Perfil**: `profileConnectHint` (usuario local) menciona conectar **AniList y Trakt** en Ajustes para estadísticas completas. Etiquetas de favoritos cine/TV (`sectionFavTraktMovies` / `sectionFavTraktShows`) son texto corto (“Favourite movies” / “Películas favoritas”, etc.) sin sufijo “(Trakt)” en la UI.

---

## Preferencias persistentes

### SharedPreferences
| Clave | Default | Descripción |
|-------|---------|-------------|
| `locale_code` | idioma del dispositivo | Idioma seleccionado |
| `theme_mode` | `dark` | Tema visual |
| `default_start_page` | `/feed` | Página al abrir la app |
| `default_feed_tab` | `all` | Tab del feed por defecto |
| `default_library_filter` | `CURRENT` | Filtro biblioteca por defecto |
| `notif_permission_prompted` | `false` hasta el primer diálogo | Evita repetir el aviso de permisos de notificación al arranque |
| `dev_notif_master` | `false` | Maestro: notificaciones locales activas |
| `dev_notif_airing` | `true` | Avisos de nuevos capítulos/episodios (lista CURRENT + medio RELEASING) |
| `dev_notif_anilist` | `true` | Espejo de bandeja Anilist en el sistema |
| `dev_notif_anilist_social` | `true` | Si inbox Anilist activo: incluir actividad/foros/etc.; si `false`, solo `AiringNotification` de Anilist |
| `dev_notif_anilist_backfill_done` | `false` → `true` tras 1.er fetch | Primera sincronización de inbox solo marca IDs vistos sin inundar |
| `dev_notif_anilist_seen_ids_json` | `[]` | JSON array de IDs de notificación Anilist ya procesados |
| `dev_airing_shown_{mediaId}_{episode}` | — | Dedupe por capítulo ya notificado (prefijos `dev_airing_shown_`) |
| `favorite_trakt_titles_v1` | `[]` (JSON array) | Favoritos locales de películas/series Trakt (`id` + `trakt_type`); ver `favoriteTraktTitlesProvider` |
| `favorite_games_v1` | `[]` (JSON array) | Favoritos locales de juegos IGDB; ver `favoriteGamesProvider` |
| `favorite_books_v1` | `[]` (JSON array) | Favoritos locales de libros (Google Books volumeIds); ver `favoriteBooksProvider` |
| `favorite_steam_games_v1` | `[]` (JSON array) | Favoritos locales de juegos Steam; ver `favoriteSteamGamesNotifierProvider` |

### FlutterSecureStorage
| Clave | Descripción |
|-------|-------------|
| `anilist_access_token` | Token OAuth de Anilist |
| `anilist_user_name` | Nombre de usuario Anilist |
| `igdb_access_token` | Bearer de aplicación Twitch/IGDB |
| `igdb_token_expires_at` | Caducidad del token (ms epoch, string) |
| `trakt_access_token` | Bearer OAuth Trakt (opcional) |
| `trakt_refresh_token` | Refresh OAuth Trakt |
| `trakt_token_expires_at_ms` | Caducidad access Trakt (epoch ms, string) |
| `trakt_user_slug` | Slug de usuario Trakt |
| `trakt_user_name` | Nombre visible Trakt |
| `trakt_user_avatar_url` | URL del avatar (Trakt `users/settings` con `extended=full,images`); persiste en sesión y entra en el JSON cifrado de backup |

---

## Modelos principales

### MediaKind (enum)
```
anime(0), movie(1), tv(2), game(3), manga(4), book(5)
```
Función global: `mediaKindLabel(kind, l10n)` para etiqueta localizada.

### MediaItem (Freezed)
Campos: `localId`, `kind`, `externalId`, `title`, `posterUrl`, `status`, `score`, `progress`, `totalEpisodes`, `notes`, `updatedAt`

### FeedActivity (Freezed)
Campos: `id`, `source`, `userName`, `userId`, `userAvatarUrl`, `action`, `mediaTitle`, `mediaPosterUrl`, `mediaId`, `createdAt`, `likeCount`, `replyCount`, `isLiked`, `isTextActivity`

### LibraryEntry (Drift generated)
Mismos campos que la tabla `LibraryEntries`.

---

## Features pendientes / placeholders

| Feature | Estado | Notas |
|---------|--------|-------|
| **Películas / series (Trakt)** | **Implementado** | Feed/búsqueda/`/movies`/`/tv`; detalle `/trakt-movie/:id`, `/trakt-show/:id`; excluye género **anime** en listados; OAuth + import en Ajustes |
| TMDB propio | No | Posters/metadata vía Trakt (`extended=full,images`) |
| **Juegos (IGDB)** | **Implementado** | `/games`, búsqueda (filtro juegos / sección en “Todo”), detalle `/game/:id`, reseñas `/igdb-review/:id`, filtro **Juegos** en `FeedPage`; favoritos locales (`favoriteGamesProvider`) |
| **Libros (Google Books)** | **Implementado** | `/books`, búsqueda por filtro Libros y en “Todo”, detalle `/book/:workKey` (volumeId), browse por tema, selector de edición y tracking avanzado (páginas/%/capítulos) |
| Letterboxd | No implementado | — |
| `HomePage` | No usada | Existe en código pero sin ruta |
| `AnimePage` | No usada | Existe en código pero sin ruta |

---

## Notificaciones en el dispositivo (Android / iOS)

> En **web** no hay notificaciones del sistema; en Ajustes se muestra un texto informativo.

### Dependencias
- `flutter_local_notifications` — canales Android, permisos, `show`.
- `workmanager` — tarea periódica en segundo plano (nombre único `cronicle_notif_sync`, frecuencia orientativa **1 h**; el SO puede aplazarla).

### Flujo
1. **`main.dart`**: `CronicleLocalNotifications.init()`, `ensureNotificationWorkmanagerInitialized()`, `NotificationWorkScheduler.applyFromPrefs(prefs)` si la plataforma es Android o iOS.
2. **`cronicle_app.dart`**: monta `NotificationPermissionBootstrap` en el widget tree sobre el router. El propio bootstrap se encarga de solicitar el permiso en el momento correcto (ver abajo).
3. **`notification_permission_bootstrap.dart`** (`NotificationPermissionBootstrap`):
   - En `initState` (vía `addPostFrameCallback`) lee `onboardingCompletedProvider`.
   - Si el onboarding ya está completado → llama `_maybeRequestNotificationPermission()` inmediatamente.
   - Si NO está completado → usa `ref.listenManual(onboardingCompletedProvider, ...)` y espera a que cambie a `true` antes de solicitar el permiso.
   - `_maybeRequestNotificationPermission()`: si `notif_permission_prompted` no está marcado, muestra diálogo explicativo → opcionalmente `requestSystemPermission()` → si el usuario acepta, `deviceNotificationSettingsProvider.applyDefaultsAfterPermissionGranted()` (maestro + subopciones en `true`). Esto garantiza que el diálogo de permisos **nunca interrumpe** el flujo de onboarding.
4. **`notification_work_scheduler.dart`**: si maestro activo y al menos una de *airing* o *anilist*, `Workmanager.registerPeriodicTask`; si no, `cancelByUniqueName`.
5. **`notification_background.dart`**: `callbackDispatcher` ejecuta `runNotificationSyncTask()` en isolate de fondo (`WidgetsFlutterBinding` + `DartPluginRegistrant`).
6. **`notification_sync_runner.dart`**: lee prefs + token/username Anilist; opcionalmente `fetchCurrentListWithAiringSchedule` (dos llamadas ANIME/MANGA); opcionalmente `fetchNotifications` sin reset; muestra notificaciones y actualiza prefs de dedupe.

### Lógica de “nuevo capítulo”
- Entradas con lista **CURRENT**, `media.status == RELEASING`, `nextAiringEpisode` con `airingAt` **ya pasado**, y `progress < episode`.
- Dedupe: clave `dev_airing_shown_{mediaId}_{episode}`.

### Lógica de inbox Anilist
- Primera ejecución tras activar: solo rellena IDs vistos (`anilist_backfill_done`).
- Con **social desactivado**: solo se muestran notificaciones cuyo `__typename` es `AiringNotification` (el resto se marca visto en el dispositivo para no reprocesar).

### Android (manifest)
- Permisos añadidos: `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `WAKE_LOCK`.

### iOS
- `Info.plist`: `UIBackgroundModes` → `fetch` (Workmanager en iOS es más limitado que en Android).

### Ajustes (UI)
- Sección **“Notificaciones en el dispositivo”** en `settings_page.dart` (`_DeviceNotificationsSection`): interruptores acoplados al `deviceNotificationSettingsProvider`.

### Limitaciones conocidas
- La periodicidad real la marca el sistema (**no** es push instantáneo al minuto del estreno).
- Si tienes activados a la vez **“Nuevos capítulos”** y el espejo de **Anilist** con avisos de emisión, podrías recibir **duplicados** parecidos; desactiva una de las dos fuentes si molesta.

---

## Ajustes: sección «Apariencia»

En `settings_page.dart`, una sola tarjeta **Apariencia** agrupa:
- **Tema**: `SegmentedButton` compacto con iconos (auto / claro / oscuro) y tooltips.
- **Idioma**: `ES` / `EN` a la derecha en pantallas anchas; en estrechas se apilan.
- **Barras de inicio y biblioteca**: enlaces a `FeedFilterLayoutEditorPage` y `LibraryKindLayoutEditorPage` (orden y visibilidad de chips).

---

## Markdown Anilist (importante)

Parser en `shared/widgets/anilist_markdown.dart`:

- Soporta:
  - `img30(...)`, `img220(...)`, `img500(...)` (case-insensitive)
  - `~~~ ... ~~~` inline y multiline (centrado)
  - `~!spoiler!~` interactivo (tap para revelar)
  - `**bold**`, `__bold__`, `*italic*`, `_italic_`, `~~strike~~`
  - enlaces markdown y `<a href="...">...</a>`
  - `<h1>`...`<h6>` convertidos a headers markdown
  - `youtube(...)`, `webm(...)`
- Preprocesado robusto:
  - normaliza `\r\n` a `\n`
  - recompone URLs rotas en varias líneas dentro de `img()/[]()/![]()/youtube()/webm()`
  - limpia tags huérfanos

Limitaciones conocidas:
- HTML arbitrario complejo no se renderiza como HTML real; se normaliza a markdown/plano.

---

## Feed / Actividades (estado actual)

- **Filtros horizontales** (`FeedPage`): **Discover** (siempre primero, no configurable), Anime, Manga, Películas, TV, **Juegos, Libros**. El orden y visibilidad de las categorías (excepto Discover) se configuran en Ajustes → Apariencia → Barra de inicio (`feedFilterLayoutNotifierProvider`); Discover se muestra incluso con una sola categoría visible.
- **Discover / Resumen** (`SummaryFeedView`): secciones trending de todas las categorías visibles del usuario con diseños variados — ver sección dedicada más abajo.
- **Anilist** (Anime, Manga): cuadrícula de exploración con `anilistBrowseMediaProvider` por categoría.
- **Sub-rail Anime / Manga** (chips bajo el filtro): De temporada (solo **anime**; Anilist no expone seasonal de manga de forma equivalente), Trending, Mejor valorados, Próximos, Recientes. Los chips **animan progresivamente** durante el swipe entre pestañas (color, peso de fuente interpolados con `AnimatedBuilder` sobre `TabController.animation`).
- **Juegos** (`_FeedFilter.game`): no usa Anilist; muestra `GamesHomeFeedView` con `igdbPopularProvider` + `igdbGamesHomeAsideProvider` (pull-to-refresh invalida ambos).
- **Libros**: sección dedicada con `BooksHomeFeedView` (tendencias + temas) y detalle por volumen Google Books.
- **Películas / TV**: `TraktHomeFeedView` — tendencias, carril central (**más esperadas** en películas, **viendo ahora** en series) y popular vía Trakt (sin género `anime`). *Nota:* la API de Trakt no expone `/movies/watching` (404); el carril intermedio de películas usa `/movies/anticipated`.
- Ajuste en ajustes: **ocultar actividades de texto** en feeds Anilist.
- **Tab por defecto al abrir el feed**: respeta la preferencia `defaultFeedTabProvider` (Ajustes → Pantalla y pestaña por defecto → «Pestaña de inicio por defecto»). Default = `summary` (Discover). Si la pestaña guardada ya no está visible (capa de `feedFilterLayoutProvider`), cae a Discover. El selector incluye Discover y Libros además del resto de categorías.
- Texto largo: colapsado `Ver más/Ver menos`; clipping corregido.

### Vista home de juegos (`GamesHomeFeedView`)

Misma UI en **`/games`** y en el filtro **Juegos** del feed. Secciones expandibles (carruseles / listas):

1. Popular ahora  
2. Más esperados  
3. Reseñas recientes (IGDB)  
4. Reseñas destacadas / alta puntuación  
5. Recién salidos  
6. Próximamente  

Las secciones con lista vacía no se pintan (no hay título huérfano). Portadas vía `CachedNetworkImage`.

### Discover / Resumen (`SummaryFeedView`)

**Archivo**: `lib/features/feed/presentation/summary_feed_view.dart`

El tab **Discover** (chip `_FeedFilter.summary`, icono `auto_awesome`) es el **primer chip del feed** y está **siempre visible** (no forma parte de `feedFilterLayoutDefaultOrder` ni se puede ocultar en Ajustes). Se muestra incluso con una sola categoría visible. Al abrir la app, el feed arranca en Discover por defecto (`_filter = _FeedFilter.summary`).

#### Widget principal

`SummaryFeedView(onRefresh, onSwitchCategory)` — `ConsumerWidget` que construye un `RefreshIndicator` → `ListView` con secciones dinámicas según las categorías visibles del usuario (`feedFilterLayoutProvider.visibleIdSet`).

#### Secciones

Las secciones se añaden condicionalmente según qué IDs están en `visibleIdSet`:

| Sección | Condición | Layout | Proveedor |
|---------|-----------|--------|-----------|
| **Botón aleatorio** | Siempre | `_RandomPickCard` (tarjeta con `Icons.shuffle_rounded`) | Toma un item al azar de todos los providers cargados |
| **Trending Anime** | `'anime'` visible | `_AsyncHeroSection` → `_HeroSection` (hero grande + posters en un solo `ListView` horizontal) | `anilistPopularProvider('ANIME')` |
| **Trending Manga** | `'manga'` visible | `_AsyncCarouselSection` → `_PosterCarouselSection` (posters 110×160) | `anilistPopularProvider('MANGA')` |
| **Trending + Anticipated Movies** | `'movie'` visible + Trakt configurado | `_TraktCarouselSection` → `_WideCarouselSection` (landscape 200×120) + `_NumberedRankSection` (ranking #1–#8) | `traktMoviesHomeProvider` |
| **Trending + Anticipated TV** | `'tv'` visible + Trakt configurado | `_TraktCarouselSection` (mismo layout que películas) | `traktShowsHomeProvider` |
| **Popular + Anticipated Games** | `'game'` visible | `_GamesCarouselSection` → `_PosterCarouselSection` + `_NumberedRankSection` | `igdbPopularProvider` + `igdbGamesHomeFeedProvider` |

#### Widgets de layout internos

| Widget | Descripción |
|--------|-------------|
| `_HeroSection` | `ListView.separated` horizontal; primer item = `_HeroCard` (155×190, poster grande con título y score superpuestos), resto = `_CarouselCard` (100×145). **Todo scroll junto** (no hay `Row` + `Expanded`) |
| `_PosterCarouselSection` | `ListView.separated` horizontal de `_CarouselCard` (poster 110×160 con badge de score) |
| `_WideCarouselSection` | `ListView.separated` horizontal de `_WideCard` (200×120 landscape con overlay gradiente + título + año) |
| `_NumberedRankSection` | `ListView.separated` horizontal de `_RankCard` (mini poster 50×70 + número de ranking #1–#8 + score con estrella) |
| `_RandomPickCard` | Tarjeta compacta con icono shuffle; al tocar, elige un item al azar de todos los providers cargados y navega a su detalle |
| `_SectionHeader` | Fila con icono + título + botón "Ver todo" → llama a `onSwitchCategory(cat)` para cambiar a la categoría completa |
| `_CarouselCard` | Poster con esquinas redondeadas + `_ScoreBadge` en la esquina superior derecha |
| `_ScoreBadge` | Badge circular con score coloreado (rojo < 50, amarillo 50–74, verde ≥ 75) |

#### Navegación

Cada tarjeta navega a su detalle con `_routeFor(item, kind)`:
- Anime/manga → `/media/:id?kind=X`
- Películas → `/trakt-movie/:id`
- Series → `/trakt-show/:id`
- Juegos → `/game/:id`

"Ver todo" en cada cabecera ejecuta `onSwitchCategory(cat)` que en `FeedPage` cambia `_filter` a la categoría correspondiente.

#### Pull-to-refresh

Invalida todos los providers relevantes según las categorías visibles.

### Animación progresiva de chips de browse (Anime / Manga)

Al seleccionar Anime o Manga en el feed, aparece un sub-rail de chips de categoría (De temporada, Trending, Mejor valorados, Próximos, Recientes). El contenido se muestra en un `TabBarView` controlado por `_browseTabController`.

Los chips **animan progresivamente** durante el swipe horizontal entre pestañas:

- Un `AnimatedBuilder` escucha `_browseTabController!.animation!` (valor decimal: 0.0 → `tabs.length - 1`).
- Para cada chip en el índice `i`, se calcula `t = (1.0 - (animValue - i).abs()).clamp(0.0, 1.0)` — donde `t = 1.0` = completamente seleccionado, `t = 0.0` = sin seleccionar.
- Se interpolan:
  - **Color de fondo**: `Color.lerp(surfaceContainerHighest, secondaryContainer, t)`
  - **Color de texto**: `Color.lerp(onSurfaceVariant, onSecondaryContainer, t)`
  - **Peso de fuente**: `w400` si `t ≤ 0.5`, `w600` si `t > 0.5`
- El resultado: al deslizar el `TabBarView`, los chips transicionan suavemente en paralelo con el deslizamiento, sin esperar a que la pestaña se asiente.

---

## UI y UX fixes recientes

### Material 3 expressive — rediseño de páginas de detalle (2026-04)

Pull `media_detail_page.dart` se reescribió en estilo M3 expressive y los mismos componentes se aplicaron al resto de páginas de detalle. Los widgets compartidos viven en **`lib/shared/widgets/m3_detail.dart`**:

| Widget | Uso |
|--------|-----|
| `M3DetailHero` | Banner + póster solapado + título marquee + subtítulo + pills |
| `M3MarqueeText` | Auto-scroll de títulos largos con `BouncingScrollPhysics` arrastrable; reanuda tras 1 s |
| `M3HeroPill` | Píldora info dentro del hero |
| `M3PillChip` | Chip Material radius 999 con `InkWell` + icono opcional |
| `M3SectionHeader` | Barra primaria 4×16 + label en negrita |
| `M3SurfaceCard` | Tarjeta `surfaceContainerLow` radius 22 (sustituye a `GlassCard` en detalles) |
| `M3FavoriteIconButton` | Botón corazón 52×52 morphing `surfaceContainerHigh ↔ errorContainer.alpha(220)` con `AnimatedSwitcher` ScaleTransition |
| `M3AddToLibraryButton` | Botón añadir/editar h=52 morphing `primary ↔ tertiaryContainer` con sombra |

Páginas migradas a estos componentes:
- `media_detail_page.dart` (anime/manga)
- `book_detail_page.dart`
- `game_detail_page.dart` (incluye sección OpenCritic con `M3SurfaceCard`/`M3PillChip`)
- `trakt_show_detail_page.dart`, `trakt_movie_detail_page.dart`
- `trakt_detail_widgets.dart` (hero, favorito, añadir, links externos, `TraktTvEpisodeProgressCard`)

### Biblioteca — indicador de sincronización wavy (2026-04)

`_SyncIndicatorPill` (en [library_page.dart](lib/features/library/presentation/library_page.dart)) sustituye al spinner clásico que aparecía en la AppBar mientras `_remoteSyncing == true`:

- Pill `cs.primaryContainer` con animación de respiración 1.6 s (`Color.lerp` con `Curves.easeInOut`).
- `CircularProgressIndicator(year2023: false, strokeCap: StrokeCap.round)` — variante **wavy** de M3 expressive.
- Texto `cs.onPrimaryContainer` w700 con tracking 0.2.

### Biblioteca — badge de próximo episodio para anime en emisión (2026-04)

Helper `_animeAiringLabel(entry, l10n)` (en [library_page.dart](lib/features/library/presentation/library_page.dart)) reutiliza `AnimeAiringProgress` y devuelve `(text, behind)`:

- `behind == true` → `"N atrasados"` (l10n `libraryAnimeAiringBehind`) cuando el progreso del usuario va por detrás de los episodios emitidos.
- `behind == false` → `"Ep N en Xd Yh"` (l10n `mediaNextEp`) usando el campo persistido `LibraryEntry.nextEpisodeAirsAt` (Drift `IntColumn nullable`, refrescado por `refreshAnimeLibraryAiringMetadata` y `anilist_sync_service.dart`).

Renderizado:
- **Lista clásica** (`_EntryMetaLine`): chip de texto entre el progreso y el score, color `cs.tertiary` si atrasado, `cs.primary` si countdown.
- **Pinterest masonry** (`_GridEntryTile`): pill flotante en la esquina superior derecha del póster con `cs.primaryContainer` o `cs.tertiaryContainer` + icono `schedule_rounded` / `notifications_active_rounded`.

Hide rules: oculta para no-anime, finalizados o cuando `nextEpisodeAirsAt` está vacío.

### Foros — paginación bidireccional sin colapsar el rate limit (2026-04)

[forum_thread_page.dart](lib/features/anime/presentation/forum_thread_page.dart) reescribió la paginación de comentarios:

- Estado `_minLoadedPage` / `_maxLoadedPage` (sustituye a `_currentPage` + `_hasNextPage`).
- `_setSort(_CommentSort.newest)` resetea y carga **solo la última página**, luego el scroll trae `_minLoadedPage − 1` hacia atrás.
- `_setSort(_CommentSort.oldest)` mantiene paginación forward desde la página 1.
- `_setSort(_CommentSort.mostLiked)` solo reordena los comentarios ya en memoria — **no fetch** para no agotar el rate limit de AniList.
- Eliminados `_loadAllRemainingPages()` y `_loadingAll`.
- Indicador de página: `Pages X–Y / lastPage` (newest) o `Page N / lastPage` (oldest).

### Pestaña por defecto / Pantalla por defecto — fix (2026-04)

- `feed_page.dart`: en `_filterInitialized` ahora se lee `defaultFeedTabProvider` y se resuelve a un `_FeedFilter`; antes siempre forzaba `summary` ignorando la preferencia.
- `settings_page.dart` → `_AppDefaultsSection`: el selector de pestaña incluye `summary` (Discover) y `book` (Libros) además del resto. El icono de \"Inicio\" se cambió a `Icons.home_rounded` (antes `rss_feed_rounded`).
- `settingsStartFeed` ARB pasó de `\"Inicio (Feed)\"` / `\"Home (Feed)\"` a `\"Inicio\"` / `\"Home\"`.
- `settingsFeedTab` ARB pasó de `\"Pestaña del feed por defecto\"` / `\"Default feed tab\"` a `\"Pestaña de inicio por defecto\"` / `\"Default home tab\"`.

### Filtro por defecto en biblioteca — opción \"Todos\" (2026-04)

- `_DefaultFilterSection` añade el chip `'ALL'` (`l10n.statusAll`) como primera opción.
- `library_page.dart` mapea `'ALL' → _selectedStatus = null` al inicializar, de modo que la biblioteca abre sin filtro de estado cuando esa preferencia está activa.

---

## UI y UX fixes recientes

- **Ajustes / Apariencia**: tema + idioma + personalización de barras (feed y biblioteca) agrupados en una categoría; selectores más compactos.
- **Juegos**: detalle `GameDetailPage` migrado a M3 expressive (`M3DetailHero`, `M3SurfaceCard`, `M3PillChip`, `M3FavoriteIconButton`, `M3AddToLibraryButton`); metadatos IGDB, enlaces externos, screenshots, similar games, tiempo estimado si existe `game_time_to_beats`, sección OpenCritic con `M3SurfaceCard` y reseñas comunidad; añadir a biblioteca local como `MediaKind.game` con `externalId` = id IGDB.
- **Libros (Google Books)**: en `AddToLibrarySheet` se añadió selector de edición + modo de tracking + overrides de totales; `BookDetailPage` migrado a M3 expressive (`M3DetailHero`, tarjeta de progreso en `M3SurfaceCard`, materias en `M3PillChip`); `LibraryPage` muestra progreso corto y restante según modo con incremento rápido coherente.
- **Trakt (película / serie):** detalle migrado a componentes M3 expressive de `m3_detail.dart` (ver sección dedicada arriba). Favorito (`M3FavoriteIconButton` + `favoriteTraktTitlesProvider`) a la izquierda, **añadir / editar biblioteca** (`M3AddToLibraryButton`) en `Expanded`. Tarjetas de info y `TraktTvEpisodeProgressCard` usan `M3SurfaceCard` + `M3SectionHeader`. Links externos (IMDb/TMDB/Trakt) son `M3PillChip` con `tertiaryContainer`.
- Portada en `MediaDetailPage` clickeable para fullscreen (hitbox corregido).
- Banner clickeable para fullscreen.
- Fullscreen image viewer:
  - zoom/pan natural con `InteractiveViewer`
  - cerrar tocando fuera (si escala ~1x)
  - botón de descarga en nativo.
  - **Android atrás / gesto del sistema**: el visor se empuja en el **navigator raíz** (`Navigator.of(context, rootNavigator: true).push`). Registra un `ChildBackButtonDispatcher` con prioridad sobre el dispatcher de GoRouter para que el botón atrás o el gesto del sistema **cierre el visor primero** sin navegar hacia atrás en la app. Sin esto, GoRouter interceptaba el evento y lo delegaba al shell navigator, cerrando la pantalla de detalle en vez del visor.
  - Drag-to-dismiss vertical (arriba o abajo) con fade del fondo.
  - Double-tap zoom (toggle entre 1× y 3×).
- Replies input:
  - reposicionado para no quedar oculto por la barra inferior.
- Dropdown de estado en biblioteca:
  - se fuerza cierre al cambiar de pestaña.

---

## Rendimiento

- `GlassCard` optimizado: se eliminó `BackdropFilter` por coste alto en listas.
- `RepaintBoundary` en cards del feed.
- `ListView.builder` con ajustes para reducir jank (`addAutomaticKeepAlives: false` donde aplica).
- Resultado esperado: scroll más estable en dispositivos de alta tasa de refresco.
- **IGDB:** caché de token en memoria + resolución en vuelo única; “popular” con menos round-trips cuando basta el listado por rating; detalle con TTB y reseñas en paralelo; endpoint de reseñas recordado entre llamadas.
- **Trakt (detalle película/serie):** columnas con `CrossAxisAlignment.stretch` para que las tarjetas de información usen todo el ancho útil bajo el padding horizontal.

---

## Android: firma de publicación, AAB y Play Console

Google Play **no acepta** APK/AAB firmados solo con la clave **debug**. Cronicle usa el patrón estándar de Flutter:

1. **Keystore de subida** (una vez): generar un `.jks` (o PKCS12) con `keytool`, p. ej. alias `upload`, y guardar el archivo bajo **`android/`** (p. ej. `android/upload-keystore.jks`). Respalda el archivo y las contraseñas fuera del repo.
2. **`android/key.properties`** (no versionar; ya está en `android/.gitignore`): copiar desde **`android/key.properties.example`** y rellenar `storePassword`, `keyPassword`, `keyAlias`, `storeFile` (ruta **relativa a la carpeta `android/`**, p. ej. `upload-keystore.jks`).
3. **`android/app/build.gradle.kts`**: si existe `key.properties`, el `buildType` **release** usa `signingConfigs.release`; si no existe, sigue usando **debug** (útil en máquinas sin keystore).
4. **Compilar bundle** (con defines JSON, igual que el script del repo):

   ```powershell
   .\scripts\build_android.ps1 -Target appbundle
   ```

   Artefacto típico: `build/app/outputs/bundle/release/app-release.aab`.

5. **`pubspec.yaml` — campo `version`**: formato `nombre+build` (ej. `1.0.0+2`). El número tras **`+`** es el **`versionCode`** de Android; **cada subida** a Play debe usar un `versionCode` **estrictamente mayor** que cualquier versión ya subida (si Play dice “el código de versión 1 ya se ha usado”, sube a `+2`, `+3`, etc.).
6. **Google Sign-In / OAuth Android:** el SHA-1 del keystore con el que **firmas el artefacto que instalas o subes** debe estar en Google Cloud (cliente OAuth tipo Android). Si usas **Play App Signing**, añade también el SHA-1 de **firma de aplicaciones** que muestra Play Console. Comando de huellas: desde `android/`, `.\gradlew.bat signingReport` (Windows) o `./gradlew signingReport`.

---

## Comandos útiles

```bash
# Instalar dependencias
flutter pub get

# Generar código (Drift, Riverpod, Freezed)
dart run build_runner build --delete-conflicting-outputs

# Generar localizaciones
flutter gen-l10n

# Ejecutar con credenciales Twitch para IGDB (ejemplo; no commitear secretos)
flutter run --dart-define=TWITCH_CLIENT_ID=tu_client_id --dart-define=TWITCH_CLIENT_SECRET=tu_secret

# Recomendado: defines en JSON (ver dart_defines.example.json en la raíz; copiar a dart_defines.local.json, gitignored)
flutter run --dart-define-from-file=dart_defines.local.json

# Windows (PowerShell): mismo define + APK release o App Bundle para Play Store
# .\scripts\build_android.ps1 -Release
# .\scripts\build_android.ps1 -Target appbundle

# Ejecutar en Chrome (puerto fijo para OAuth web)
flutter run -d chrome --web-port=5555

# Analizar código
flutter analyze

# Build APK debug
flutter build apk --debug

# Build APK release
flutter build apk --release

# Regenerar iconos de launcher (Android, iOS, web, Windows) tras cambiar assets/app_icon.png
dart run flutter_launcher_icons
```

---

## Icono de la aplicación

La app usa el paquete **`flutter_launcher_icons`** (ver `pubspec.yaml` → sección `flutter_launcher_icons`).

### Fuente única
- **`assets/app_icon.png`** — imagen **cuadrada** en PNG (recomendado **1024×1024** o al menos 512×512). Es la única fuente que debe editarse al cambiar el logo.

### Regenerar todos los tamaños y plataformas
Tras sustituir `assets/app_icon.png`, ejecutar en la raíz del repo:

```bash
dart run flutter_launcher_icons
```

Esto sobrescribe (según la config actual):
- **Android**: iconos en `android/app/src/main/res/mipmap-*/`
- **iOS**: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- **Web**: iconos bajo `web/icons/` (favicons y manifest)
- **Windows**: **`windows/runner/resources/app_icon.ico`** (el `.ico` lo genera el propio paquete; no hace falta crearlo a mano)

### Configuración relevante en `pubspec.yaml`
- `image_path: "assets/app_icon.png"` (Android legacy + iOS + web + Windows).
- `adaptive_icon_background` / `adaptive_icon_foreground` / `adaptive_icon_foreground_inset` — Android adaptativo (ver subsección anterior).
- `remove_alpha_ios: true` — evita problemas de transparencia en revisión de App Store.
- `min_sdk_android: 21`
- Windows: `icon_size: 256` para el recurso generado.

### Copia en la raíz del repo
- **`CronicleIcon.png`** (raíz) — copia de referencia / marca alineada con `assets/app_icon.png`; no la usa Flutter en runtime; sirve para documentación, tiendas o diseño. Si cambias el icono, conviene actualizar ambos archivos y volver a ejecutar `flutter_launcher_icons`.

### SVG
El launcher de Flutter **no** usa SVG para el icono del sistema. Un SVG marketing habría que mantenerlo aparte (p. ej. diseño web) y vectorizar el logo con herramientas externas si hace falta.

### Icono adaptativo (Android)
En **`pubspec.yaml`** → `flutter_launcher_icons` está configurado el **icono adaptativo** (API 26+), recomendable en launchers OEM (p. ej. máscaras circulares):

- `adaptive_icon_background`: color sólido (actualmente `#FFFFFF`).
- `adaptive_icon_foreground`: misma imagen que `image_path` (`assets/app_icon.png`); el paquete genera capas y `mipmap-anydpi-v26/ic_launcher.xml`.
- `adaptive_icon_foreground_inset`: porcentaje de margen interior del frente (actualmente **8**; subir = logo más pequeño dentro del círculo; bajar = más grande). Ajustar si un launcher encoge demasiado el icono.
- Tras cambiar valores: `dart run flutter_launcher_icons`.
- **`AndroidManifest.xml`**: `android:icon` y `android:roundIcon` apuntan a `@mipmap/ic_launcher` (recurso adaptativo).
- **Play Console**: no hay interruptor que corrija el padding del icono; la solución es el recurso generado y un nuevo **AAB/APK**.

---

## Archivos externos importantes

| Archivo | Ubicación | Propósito |
|---------|-----------|-----------|
| `web/auth_callback.html` | `web/` | Captura de token Anilist en **web** (si el flujo web sigue activo en tu rama) |
| `web/trakt_oauth_bridge.html` | `web/` | Puente HTTPS Trakt → `cronicle://trakt-oauth` (auto-redirección + botón de respaldo) |
| `web/twitch_oauth_bridge.html` | `web/` | Puente HTTPS Twitch → `cronicle://twitch-oauth` |
| `web/anilist_oauth_bridge.html` | `web/` | Puente HTTPS: fragmento `#access_token` → app móvil o textarea en escritorio |
| `web/sqlite3.wasm` | `web/` | SQLite para Drift en web |
| `web/drift_worker.dart.js` | `web/` | Worker de Drift para web |
| `assets/app_icon.png` | `assets/` | **Fuente del launcher** (PNG); ver sección [Icono de la aplicación](#icono-de-la-aplicación) |
| `CronicleIcon.png` | raíz | Copia de referencia del mismo arte; no usada en runtime por la app |
| `.cursorrules` | raíz | Reglas de arquitectura para AI |
| `l10n.yaml` | raíz | Config de localización |
| `twitch_secrets.json` | raíz (opcional, **gitignored**) | Referencia local para `dart-define`; la app **no** lee este archivo en runtime |
| `dart_defines.example.json` | raíz | Plantilla de `--dart-define-from-file` (Anilist, Twitch, Trakt, Google OAuth); copiar a `dart_defines.local.json` |
| `dart_defines.local.json` | raíz (**gitignored**) | Valores reales para compilación local / scripts `build_android` |
| `android/key.properties.example` | `android/` | Plantilla de firma release; copiar a `android/key.properties` (gitignored) |
| `scripts/build_android.ps1` | `scripts/` | `flutter build` con `--dart-define-from-file`; parámetros `-Release`, `-Target appbundle` |

### Variables de compilación relevantes

| Define | Uso |
|--------|-----|
| `TWITCH_CLIENT_ID` | Client ID de la app Twitch (IGDB) |
| `TWITCH_CLIENT_SECRET` | Client Secret (solo servidor / app nativa; no exponer en clientes públicos) |
| `TWITCH_REDIRECT_URI` | URL **HTTPS** del `twitch_oauth_bridge.html` registrada en la app Twitch (obligatoria para «Conectar Twitch» en Ajustes) |
| `ANILIST_CLIENT_ID` | Opcional; override del client id Anilist (`EnvConfig`) |
| `ANILIST_REDIRECT_URI` | Opcional. Por defecto PIN Anilist. Si es **HTTPS** distinta del PIN, la app activa modo **puente** en móvil (`usesHttpsImplicitBridge`); la misma URL debe estar como **Redirect URL** en la app de Anilist Developer. **No** se envía en la query de `/oauth/authorize` (solo `client_id` + `response_type=token`). |
| `GOOGLE_SERVER_CLIENT_ID` | Cliente OAuth **Web** (`.apps.googleusercontent.com`); obligatorio en Android para `GoogleSignIn` 7.x como `serverClientId` |
| `GOOGLE_ANDROID_CLIENT_ID` | Opcional; cliente OAuth **Android** como `clientId` en Android |
| `GOOGLE_IOS_CLIENT_ID` | Opcional; cliente OAuth **iOS** como `clientId` en iOS |
| `TRAKT_CLIENT_ID` | Obligatorio para películas/TV; cabecera `trakt-api-key` en todas las peticiones a api.trakt.tv |
| `TRAKT_CLIENT_SECRET` | Solo para OAuth (conectar cuenta / importar historial) |
| `TRAKT_REDIRECT_URI` | Misma URI registrada en [trakt.tv/oauth/applications](https://trakt.tv/oauth/applications). Recomendado: **HTTPS** + `web/trakt_oauth_bridge.html` (Netlify u otro hosting estático). **Web:** añade el origen en “Javascript (cors) origins” en el panel Trakt para `fetch` desde el navegador. |

---

## Trakt.tv (configuración y uso)

### Por qué registrar una app en Trakt

Sin una aplicación creada en [trakt.tv/oauth/applications](https://trakt.tv/oauth/applications) no obtienes **Client ID** ni **Client Secret**. El **Client ID** es obligatorio en Cronicle para películas/TV (cabecera `trakt-api-key` en `https://api.trakt.tv`). El **Client Secret** solo hace falta si quieres **Conectar Trakt** en Ajustes e **importar** el historial visto (`/sync/watched/...`).

### Formulario de la aplicación (panel Trakt)

| Campo | Notas para Cronicle |
|-------|----------------------|
| **Name / Description / Icon** | Libres; el icono debe ser PNG cuadrado **≥ 256×256** (ideal transparente). Lo que pongas en descripción se ve en “Connected apps” al autorizar. |
| **Redirect uri** | Una línea por URI, **sin query strings**. Debe coincidir **exactamente** con `TRAKT_REDIRECT_URI`. Lo habitual es una URL **HTTPS** (p. ej. Netlify) que sirva `web/trakt_oauth_bridge.html`; Trakt redirige allí con `?code=&state=` y el HTML abre `cronicle://trakt-oauth?…`. En **Android**, la app completa el OAuth con **navegador externo + `app_links`** (no depender del Custom Tab para abrir el deep link). En **iOS** puede usarse `FlutterWebAuth2` con el mismo esquema `cronicle`. |
| **`urn:ietf:wg:oauth:2.0:oob`** | Texto de ayuda de Trakt para flujos **device / out-of-band** (copiar código a mano). **Cronicle no usa ese redirect**; no sustituyas tu `cronicle://…` por el `urn` salvo que reimplementes el login en ese modo. |
| **Javascript (cors) origins** | Solo necesario para **Flutter web**: un origen por línea (`http://localhost:PUERTO` en dev, `https://tu-dominio` en prod). Sin wildcards ni paths. En Android/iOS/desktop las peticiones no van limitadas por CORS del navegador. |
| **Permissions** (`/checkin`, `/scrobble`, etc.) | Cronicle **solo lee** historial y ajustes de usuario con OAuth (`GET /sync/watched/movies`, `GET /sync/watched/shows`, `GET /users/settings`). **No** envía check-ins ni scrobble a Trakt; esos permisos son opcionales y puedes dejarlos **desmarcados** si no vas a escribir en Trakt desde la app. |

### `dart_defines.local.json` (Trakt)

Copia las claves desde `dart_defines.example.json` y rellena:

```json
"TRAKT_CLIENT_ID": "<Client ID del panel Trakt>",
"TRAKT_CLIENT_SECRET": "<Client Secret; vacío si no usas OAuth>",
"TRAKT_REDIRECT_URI": "https://tu-sitio.netlify.app/"
```

- **Solo listados públicos** (feed, búsqueda, `/movies`, `/tv`): basta con `TRAKT_CLIENT_ID`; secret y redirect pueden ir vacíos hasta que configures OAuth.
- **Conectar + importar**: las tres claves deben estar rellenadas; **Redirect uri** en el panel Trakt = **`TRAKT_REDIRECT_URI`** (misma cadena, típicamente HTTPS + `trakt_oauth_bridge.html` en la raíz o ruta publicada).

### Peticiones API

- **Base**: `https://api.trakt.tv`
- **Cabeceras obligatorias**: `Content-Type: application/json`, `trakt-api-version: 2`, `trakt-api-key: <TRAKT_CLIENT_ID>`
- **OAuth** (endpoints de usuario): además `Authorization: Bearer <access_token>` tras conectar en Ajustes.

### Comportamiento en la app

- **Filtro anti-anime**: en listados Trakt se excluyen películas/series cuyo array `genres` incluya `anime` (insensible a mayúsculas), para no duplicar el catálogo de AniList.
- **UI**: `TraktHomeFeedView` (tendencias, carril central películas/series como arriba, popular); detalle `/trakt-movie/:id` y `/trakt-show/:id` con id **numérico Trakt**; biblioteca local usa `externalId` = ese id y `MediaKind.movie` / `tv`. **“Favoritos” con el corazón en la app** (`favoriteTraktTitlesProvider`, prefs `favorite_trakt_titles_v1`) son **solo en el dispositivo**; no llaman a `POST` de favoritos en Trakt.tv. El perfil, estadísticas personales y `/profile/favorites/movies|tv` leen **esa** lista (filtrada por `trakt_type`), no el endpoint público `/users/{slug}/favorites/movies|shows` de la API. Con sesión OAuth, la app puede **sincronizar** progreso/historial/watchlist con Trakt desde biblioteca (`trakt_library_remote_sync`, `trakt_api_datasource`).
- **OAuth en web**: “Conectar Trakt” muestra mensaje de no disponible en build **web**; en nativo usa el flujo descrito arriba (HTTPS puente + deep link o `FlutterWebAuth2` según plataforma).
- **Backup JSON** (Drive, etc.): las claves `trakt_*` en **FlutterSecureStorage** entran en el bundle de copia; ver tabla de SecureStorage más arriba.

---

## Wear OS (companion app)

Cronicle incluye una **app companion para Wear OS** (módulo Gradle separado `:wear`) que muestra los ítems en progreso del usuario y permite incrementar capítulos/episodios o marcar como completado desde la muñeca, con **sincronización remota automática** a AniList/Trakt vía la app del móvil.

### Arquitectura

```
[ Wear OS watch ]                          [ Phone ]                            [ Remote API ]
LibraryScreen / DetailScreen   ──msg──►   WearLibraryListenerService  ──┐
(+1, Complete, click → detalle)            ├─ aplica cambio en Drift     │
                                           ├─ broadcast WEAR_LIBRARY_     ├─► WearRemoteSyncService
                                           │  CHANGED → invalida providers│   (foreground service)
                                           │  Riverpod en Flutter UI      │      │
                                           └─ enqueueAndLaunch JSONL ─────┘      │
                                                                                  ▼
                                                                          FlutterEngine headless
                                                                          (entrypoint Dart
                                                                           `wearSyncMain`)
                                                                          ─► AniList GraphQL
                                                                          ─► Trakt API
```

### Módulos / archivos clave

- **Reloj** (`android/wear/`):
  - `MainActivity.kt`: `setContent { Navigation }` con `LibraryScreen` y `DetailScreen`.
  - `LibraryViewModel.kt`: pide snapshot al móvil (`/library/request_sync`), recibe DataItems y expone `StateFlow<List<LibraryItem>>`.
  - `model/LibraryItem.kt`: mirror del `LibraryEntry` con campos para progreso (anime/manga/libros: páginas, capítulos, %).
  - `sync/PhoneSyncClient.kt`: `MessageClient` + `NodeClient` para enviar acciones (`/library/action` con `{action, kind, externalId}`) al móvil.
  - `ui/LibraryScreen.kt`: lista en `ScalingLazyColumn` con miniaturas (Coil) y +1/Completar inline; click → `DetailScreen`.
  - `ui/DetailScreen.kt`: portada de fondo (Coil) con `blur(6.dp)` + degradado oscuro (alphas 0.30→0.70), botones grandes +1 / Completar y diálogo de confirmación.
  - `tile/`: Tile de Wear con próximos ítems.
  - `res/values/wear.xml`: declara la capability `cronicle_wear_companion` para que el móvil detecte que la companion está instalada en el reloj.
- **Móvil — recepción de acciones del reloj** (`android/app/src/main/kotlin/com/cronicle/app/cronicle/wear/`):
  - `WearLibraryListenerService.kt`: `WearableListenerService` que atiende `/library/request_sync` y `/library/action`.
    - Aplica `incrementProgress` o `markCompleted` sobre `cronicle.db.sqlite` directamente con SQLite (sin Flutter).
    - Publica el snapshot de “in progress” en `/library/items` (DataClient) para que el reloj se refresque.
    - Envía broadcast local `WEAR_LIBRARY_CHANGED` para que la app foreground invalide `paginatedLibraryProvider`.
    - Llama a `WearRemoteSyncService.enqueueAndLaunch(...)` para empujar el cambio al backend.
  - `WearRemoteSyncService.kt`: foreground service tipo `dataSync`.
    - Append-only de la acción a `<dataDir>/app_flutter/wear_pending.jsonl`.
    - Arranca un `FlutterEngine` headless con `FlutterInjector.instance().flutterLoader().findAppBundlePath()` y ejecuta el entrypoint Dart `wearSyncMain` del bundle.
    - `MethodChannel("cronicle.wear.sync")` con `done` para liberar el engine; timeout de seguridad de 30s.
  - `CronicleLibraryDb.kt`: abre el SQLite de Drift desde Kotlin probando rutas habituales (`app_flutter/cronicle.db.sqlite`, `filesDir/...`, `getDatabasePath(...)`).
- **Móvil — UI / providers Flutter**:
  - `lib/wear_sync_entry.dart` (`@pragma('vm:entry-point') wearSyncMain`): drena `wear_pending.jsonl`, deduplica por `(kind, externalId)` y empuja a AniList (`AnilistGraphqlDatasource.saveMediaListEntry`) o Trakt (`pushCronicleLibraryStateToTrakt` con `TraktAuthDatasource.getValidAccessToken`). Importado desde `lib/main.dart` para que entre en el bundle Dart.
  - `lib/core/wear/wear_event_listener.dart`: `MethodChannel("cronicle.wear.events")` que escucha `libraryChanged` y hace `ref.invalidate(paginatedLibraryProvider)`. Se inicializa en `cronicle_app.dart`.
  - `lib/core/wear/wear_connection_status_provider.dart`: `MethodChannel("cronicle.wear.status")` que llama a `getStatus` y devuelve `{anyNodeConnected, companionInstalled}` (chequeado vía `NodeClient.connectedNodes` + `CapabilityClient.getCapability("cronicle_wear_companion", FILTER_REACHABLE)`).
  - `MainActivity.kt` (móvil): registra el broadcast `WEAR_LIBRARY_CHANGED` y los dos `MethodChannel` (`events`, `status`).
  - `lib/features/settings/presentation/settings_page.dart` → `_WearOsSection`: tarjeta en Ajustes que muestra:
    - **Reloj conectado · App companion instalada** (verde) si la capability está accesible.
    - **App companion no instalada** (naranja) si hay reloj emparejado pero sin Cronicle.
    - **¿Tienes un reloj Wear OS?** + botón “Abrir Google Play” (`market://details?id=com.cronicle.app.cronicle`) si no hay reloj.

### MethodChannels y broadcasts

| Channel / Action                                    | Origen           | Destino           | Payload / método                                   |
| --------------------------------------------------- | ---------------- | ----------------- | -------------------------------------------------- |
| `cronicle.wear.sync` (`done`)                       | Dart (engine)    | Kotlin service    | Avisa que `wearSyncMain` terminó                   |
| `cronicle.wear.events` (`libraryChanged`)           | Kotlin Activity  | Dart UI           | Invalida `paginatedLibraryProvider`                |
| `cronicle.wear.status` (`getStatus`)                | Dart Settings    | Kotlin Activity   | `{ anyNodeConnected: bool, companionInstalled: bool }` |
| `WEAR_LIBRARY_CHANGED` (`Intent` action)            | `WearLibraryListenerService` | `MainActivity` | Broadcast local (`RECEIVER_NOT_EXPORTED` en T+) |
| Wearable Data Layer `/library/items`                | Móvil            | Reloj             | Snapshot JSON de items en progreso                  |
| Wearable Data Layer `/library/request_sync`         | Reloj            | Móvil             | Pide republicar snapshot                            |
| Wearable Data Layer `/library/action`               | Reloj            | Móvil             | `{action: "increment"|"complete", kind, externalId}` |

### Firma y emparejamiento

- Tanto el módulo móvil como el módulo Wear se firman con la **misma Upload Key** (`android/key.properties`). Wearable Data Layer **rechaza** mensajes entre apps con `applicationId` igual pero certificado distinto.
- Para builds **debug**, ambos build types usan también la `release` `signingConfig` cuando existe `key.properties`, para evitar “Mismatched certificate” durante desarrollo.
- `applicationId` debe ser idéntico (`com.cronicle.app.cronicle`) en `android/app/build.gradle.kts` y `android/wear/build.gradle.kts`.

### Build / instalación rápida

> Comandos detallados en [BUILD_COMMANDS.md](./BUILD_COMMANDS.md).

```powershell
# Móvil (release APK firmado con upload key)
.\scripts\build_android.ps1 -Release

# Reloj (release APK)
.\scripts\build_wear.ps1 -Release

# Reloj (App Bundle para Play Console)
.\scripts\build_wear.ps1 -Target appbundle -Release
```

Salida:

- Móvil APK: `build/app/outputs/flutter-apk/app-release.apk`
- Reloj APK: `build/wear/wear-release.apk`
- Reloj AAB: `build/wear/wear-release.aab`

### Publicación en Play Console (Wear)

1. **Misma cuenta de Play Store** y mismo `applicationId` que la app móvil; ambos suben como **artefactos separados** (móvil + Wear standalone).
2. Sube el AAB desde Play Console → app → Versiones → Wear OS (track interno, abierto, etc.). Cada subida requiere `versionCode` mayor que la anterior.
3. **Firma**: el AAB se sube firmado con la Upload Key. Google Play se encarga del re-firmado con la App Signing Key.
4. **SHA-1**: si la companion necesitara Google Sign-In u otras Google APIs (no es el caso actual), aplicaría lo mismo que en móvil — registrar SHA-1 de Upload Key y de App Signing Key en Google Cloud Console (ver `android/key.properties.example`). La companion actual **no** necesita estos SHA-1 (no usa Google Sign-In).
5. Asegúrate de tener relleno la **ficha de Wear** (capturas a 384×384 o superior, descripción, clasificación de contenido). Sin esto la versión queda en revisión.

