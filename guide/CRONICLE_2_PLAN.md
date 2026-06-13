# Cronicle 2 — Plan maestro (social nativo + web)

> **Rama de desarrollo:** `cronicle-2`  
> **Estado:** Planificación (sin implementación de código de producto aún)  
> **Última actualización:** 2025-06-13  
> **Relacionado:** [CRONICLE_GUIDE.md](./CRONICLE_GUIDE.md) (Cronicle 1.x)

---

## 1. Visión y objetivos

### 1.1 Qué es Cronicle 2

Cronicle 2 evoluciona la app de **tracker personal offline-first** a una **plataforma social nativa** donde:

- Cada usuario tiene **identidad Cronicle** (perfil, `@username`, avatar, bio).
- Puede **seguir** a otros usuarios Cronicle (grafo propio, independiente de AniList).
- Publica **actividades** cross-media: anime, manga, películas, series, juegos y libros en **un solo feed**.
- Comparte biblioteca, listas y favoritos con **controles de privacidad** granulares.
- Accede desde **móvil (Android/iOS)** y **web (PWA)** con la misma cuenta y datos sincronizados.

### 1.2 Qué NO es Cronicle 2 (alcance explícito)

- **No** reemplaza AniList, Trakt, IGDB ni Steam como fuentes de catálogo.
- **No** sube tokens OAuth de terceros al backend (permanecen en dispositivo / backup Drive opcional).
- **No** abandona Drift: la base local sigue siendo la fuente de verdad en cada dispositivo.
- **No** exige conexión permanente: modo offline completo para biblioteca y lectura de feed cacheado.

### 1.3 Diferenciador frente a AniList / Letterboxd / Backloggd

| Competidor | Limitación | Cronicle 2 |
|------------|------------|------------|
| AniList | Solo anime/manga | Feed unificado 6 tipos de media |
| Letterboxd | Solo cine | Incluye anime, juegos, libros |
| Backloggd | Solo juegos | Social cross-media |
| Cronicle 1.x | Social = proxy externo | Red social **propia** |

### 1.4 Métricas de éxito (MVP)

- Registro/login en < 30 s (Google OAuth).
- Feed de seguidos con latencia < 2 s (con red).
- Cambio en biblioteca → visible en feed de amigos en < 10 s (Realtime).
- Web usable: biblioteca + feed + perfil en Chrome/Firefox/Safari.
- 0 regresiones en flujo offline de biblioteca local.

---

## 2. Principios de arquitectura

### 2.1 Reglas inmutables (heredadas de Cronicle 1)

```
presentation → domain → data (nunca al revés)
```

- Riverpod 2.5+ con `@riverpod` + codegen.
- Modelos inmutables con Freezed.
- Errores con `AppResult<T>` / `AppFailure`.
- GoRouter para navegación.
- **Nunca** `setState` para estado global de app.

### 2.2 Nuevo modelo híbrido: Local-first + Cloud social

```
┌─────────────────────────────────────────────────────────────┐
│                    DISPOSITIVO (móvil / web)                 │
│  ┌─────────────┐    ┌──────────────┐    ┌─────────────────┐ │
│  │ Drift SQLite│◄──►│ Sync Engine  │◄──►│ Outbox (cola)   │ │
│  │ (biblioteca)│    │ (push/pull)  │    │ eventos sociales│ │
│  └─────────────┘    └──────────────┘    └─────────────────┘ │
│         │                    │                               │
│         ▼                    ▼                               │
│  AniList / Trakt / IGDB   Supabase Client                   │
│  (opcional, local)        (auth + social + sync)            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                         SUPABASE                             │
│  Auth │ Postgres │ Realtime │ Storage │ Edge Functions      │
│  RLS en todas las tablas de usuario                         │
└─────────────────────────────────────────────────────────────┘
```

### 2.3 Tres capas de datos

| Capa | Responsabilidad | Tecnología |
|------|-----------------|------------|
| **Local** | Biblioteca, caché de feed, outbox, prefs | Drift + SharedPreferences |
| **Social cloud** | Perfiles, follows, actividades, listas compartidas | Supabase Postgres + Realtime |
| **Externa** | Catálogo y sync opcional con servicios de terceros | AniList, Trakt, IGDB, Books API |

### 2.4 Drive backup vs Supabase

| Mecanismo | Uso en Cronicle 2 |
|-----------|-------------------|
| **Google Drive** (`cronicle_backup.json`) | Backup completo opcional, migración desde v1, recuperación de desastre |
| **Supabase** | Identidad, grafo social, feed, sync incremental de biblioteca compartible |

Ambos coexisten. Drive no se elimina en v2.

---

## 3. Stack tecnológico

### 3.1 Cliente (Flutter)

| Paquete | Uso |
|---------|-----|
| `supabase_flutter` | Auth, Postgres client, Realtime, Storage |
| `drift` + `drift_flutter` | DB local (sin cambios) |
| `flutter_riverpod` | Estado (sin cambios) |
| `go_router` | Rutas nuevas: `/u/:username`, `/lists/:id` |
| `connectivity_plus` | Disparar sync al recuperar red |
| `google_sign_in` + `google_sign_in_web` | Login Google → Supabase Auth |
| `sign_in_with_apple` | Login Apple (iOS + web) |

### 3.2 Backend (Supabase)

| Servicio | Uso |
|----------|-----|
| **Auth** | Email, Google, Apple; JWT para RLS |
| **Postgres** | Tablas sociales + sync |
| **Realtime** | Feed, notificaciones in-app, presencia opcional |
| **Storage** | Avatares, banners de perfil |
| **Edge Functions** | Webhooks, limpieza, agregaciones pesadas, proxy IGDB (web) |

### 3.3 Web

| Componente | Detalle |
|------------|---------|
| Hosting | Firebase Hosting, Netlify o Cloudflare Pages |
| Drift WASM | `sqlite3.wasm` + `drift_worker.dart.js` (ya preparado) |
| OAuth web | Redirect al mismo origen; en local siempre `http://localhost:60889` (`WebDevConfig`, `scripts/run_web.ps1`) |
| PWA | `manifest.json` + service worker básico (fase posterior) |
| Proxy IGDB | Edge Function Supabase (`DEV_API_PROXY` → producción) |

### 3.4 DevOps

| Herramienta | Uso |
|-------------|-----|
| Supabase CLI | Migraciones SQL, tipos generados |
| GitHub Actions | CI: `flutter analyze`, tests, deploy web en `cronicle-2` |
| Entornos | `dev` (proyecto Supabase local o staging) + `prod` |

---

## 4. Modelo de datos Supabase (esquema completo)

### 4.1 Diagrama ER (MVP + extensiones)

```
profiles ─────┬───── follows (grafo)
              │
              ├───── activities (feed)
              │
              ├───── library_entries_sync (biblioteca compartible)
              │
              ├───── shared_lists ─── shared_list_items
              │
              ├───── list_collaborators
              │
              ├───── notifications
              │
              └───── external_account_links (AniList ID, Trakt slug — sin tokens)

sync_outbox_ack (opcional, servidor)
user_settings (privacidad global)
blocks (bloquear usuario)
reports (moderación, fase posterior)
```

### 4.2 SQL — Migración inicial

**Archivo listo para copiar/ejecutar:** [`supabase/migrations/001_cronicle2_core.sql`](../supabase/migrations/001_cronicle2_core.sql)

Incluye tablas, RLS completo, trigger de registro (`handle_new_user`), helpers y Realtime.

<details>
<summary>SQL inline (referencia; usar el archivo .sql de arriba)</summary>

```sql
-- Extensiones
create extension if not exists "pgcrypto";

-- ─── Perfiles ───────────────────────────────────────────────
create table public.profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  username      text unique not null,
  display_name  text not null default '',
  avatar_url    text,
  banner_url    text,
  bio           text default '' check (char_length(bio) <= 500),
  privacy_default text not null default 'followers'
    check (privacy_default in ('public', 'followers', 'private')),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index profiles_username_idx on public.profiles (lower(username));

-- ─── Follows ────────────────────────────────────────────────
create table public.follows (
  follower_id   uuid not null references public.profiles(id) on delete cascade,
  following_id  uuid not null references public.profiles(id) on delete cascade,
  created_at    timestamptz not null default now(),
  primary key (follower_id, following_id),
  check (follower_id <> following_id)
);

create index follows_following_idx on public.follows (following_id);

-- ─── Actividades (feed) ─────────────────────────────────────
create table public.activities (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references public.profiles(id) on delete cascade,
  kind          text not null
    check (kind in (
      'added', 'started', 'progress', 'completed', 'dropped', 'paused',
      'rated', 'reviewed', 'favorited', 'list_created', 'list_item_added',
      'status_text'
    )),
  media_kind    smallint,          -- 0=anime,1=movie,2=tv,3=game,4=manga,5=book; null para status_text
  external_id   text,              -- id en servicio origen (AniList, Trakt, etc.)
  title         text not null default '',
  poster_url    text,
  payload       jsonb not null default '{}',  -- score, progress, old→new status, etc.
  visibility    text not null default 'followers'
    check (visibility in ('public', 'followers', 'private')),
  created_at    timestamptz not null default now()
);

create index activities_feed_idx on public.activities (created_at desc);
create index activities_user_idx on public.activities (user_id, created_at desc);

-- ─── Biblioteca sincronizada (opcional por ítem) ────────────
create table public.library_entries_sync (
  user_id       uuid not null references public.profiles(id) on delete cascade,
  media_kind    smallint not null,
  external_id   text not null,
  title         text not null,
  poster_url    text,
  status        text not null default 'PLANNING',
  score         integer,
  progress      integer,
  total_episodes integer,
  notes         text,                -- NUNCA sincronizar si privacy = private en notas
  visibility    text not null default 'followers'
    check (visibility in ('public', 'followers', 'private')),
  updated_at    timestamptz not null default now(),
  primary key (user_id, media_kind, external_id)
);

create index library_sync_user_updated_idx
  on public.library_entries_sync (user_id, updated_at desc);

-- ─── Listas compartidas ─────────────────────────────────────
create table public.shared_lists (
  id            uuid primary key default gen_random_uuid(),
  owner_id      uuid not null references public.profiles(id) on delete cascade,
  title         text not null,
  description   text default '',
  visibility    text not null default 'public'
    check (visibility in ('public', 'followers', 'private', 'collaborative')),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create table public.shared_list_items (
  list_id       uuid not null references public.shared_lists(id) on delete cascade,
  media_kind    smallint not null,
  external_id   text not null,
  title         text not null,
  poster_url    text,
  added_by      uuid references public.profiles(id),
  note          text,
  position      integer not null default 0,
  created_at    timestamptz not null default now(),
  primary key (list_id, media_kind, external_id)
);

-- ─── Vínculos externos (sin tokens) ─────────────────────────
create table public.external_account_links (
  user_id       uuid not null references public.profiles(id) on delete cascade,
  provider      text not null check (provider in ('anilist', 'trakt', 'steam')),
  external_user_id text not null,
  display_name  text,
  avatar_url    text,
  linked_at     timestamptz not null default now(),
  primary key (user_id, provider)
);

-- ─── Notificaciones in-app ──────────────────────────────────
create table public.notifications (
  id            uuid primary key default gen_random_uuid(),
  recipient_id  uuid not null references public.profiles(id) on delete cascade,
  actor_id      uuid references public.profiles(id) on delete set null,
  kind          text not null
    check (kind in ('follow', 'activity_like', 'list_invite', 'mention')),
  entity_id     uuid,
  payload       jsonb not null default '{}',
  read_at       timestamptz,
  created_at    timestamptz not null default now()
);

create index notifications_recipient_idx
  on public.notifications (recipient_id, created_at desc);

-- ─── Bloqueos ───────────────────────────────────────────────
create table public.blocks (
  blocker_id    uuid not null references public.profiles(id) on delete cascade,
  blocked_id    uuid not null references public.profiles(id) on delete cascade,
  created_at    timestamptz not null default now(),
  primary key (blocker_id, blocked_id)
);
```

</details>

### 4.3 Row Level Security (RLS) — reglas clave

> Implementación completa en [`001_cronicle2_core.sql`](../supabase/migrations/001_cronicle2_core.sql).

```sql
alter table public.profiles enable row level security;
alter table public.follows enable row level security;
alter table public.activities enable row level security;
alter table public.library_entries_sync enable row level security;
alter table public.shared_lists enable row level security;
alter table public.notifications enable row level security;

-- Perfiles: lectura pública de campos no sensibles; escritura solo propia
create policy "profiles_select" on public.profiles for select using (true);
create policy "profiles_update_own" on public.profiles for update
  using (auth.uid() = id);

-- Actividades: ver si public, o followers y te siguen, o es tuya
create policy "activities_select" on public.activities for select using (
  visibility = 'public'
  or user_id = auth.uid()
  or (
    visibility = 'followers'
    and exists (
      select 1 from public.follows f
      where f.follower_id = auth.uid() and f.following_id = activities.user_id
    )
  )
);

-- Actividades: insert solo como uno mismo
create policy "activities_insert_own" on public.activities for insert
  with check (auth.uid() = user_id);

-- Follows: insert/delete propio; select público (para contadores)
-- ... (completar en implementación)
```

### 4.4 Drift local — tablas nuevas (cliente)

```dart
// lib/core/database/tables/sync_outbox.dart
class SyncOutboxEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operation => text()();       // 'upsert_activity', 'upsert_library', ...
  TextColumn get payloadJson => text()();
  IntColumn get createdAt => integer()();
  IntColumn get retryCount => integer().withDefault(Constant(0))();
  BoolColumn get synced => boolean().withDefault(Constant(false))();
}

// lib/core/database/tables/cached_activities.dart
class CachedActivities extends Table { ... }  // feed offline

// lib/core/database/tables/cronicle_profile_cache.dart
class CronicleProfileCache extends Table { ... }
```

---

## 5. Autenticación e identidad

### 5.1 Flujos de login

| Método | Móvil | Web |
|--------|-------|-----|
| Google | `google_sign_in` → Supabase `signInWithIdToken` | Mismo flujo (popup, sin redirect a localhost) |
| Email + contraseña | `signInWithPassword` / `signUp` | Igual |
| Apple | `sign_in_with_apple` | Apple JS (fase 2) |

### 5.2 Onboarding Cronicle 2 (nuevo)

1. Pantalla bienvenida → elegir login.
2. Si primer acceso: elegir `@username` (validación en tiempo real contra Supabase).
3. Elegir intereses (reutilizar onboarding v1).
4. Configurar privacidad por defecto (`public` / `followers` / `private`).
5. Opcional: vincular AniList / Trakt (sin cambiar flujos OAuth existentes).
6. Opcional: importar biblioteca local existente → subir a `library_entries_sync`.

### 5.3 Vinculación cuenta Cronicle ↔ Google Drive backup

- Tras login Supabase, ofrecer «Restaurar desde Google Drive» (backup v1).
- El backup **no** crea cuenta; la cuenta Cronicle es independiente.
- Migración: `AppBackupBundle.restoreFromJson` local + push inicial a Supabase.

### 5.4 Sesión y tokens

- JWT Supabase en memoria + refresh automático (`supabase_flutter`).
- Tokens AniList/Trakt/Steam: **solo** `FlutterSecureStorage` local (nunca Postgres).

---

## 6. Motor de sincronización

### 6.1 Outbox pattern (cliente)

```
Usuario edita biblioteca
    → Drift.upsertLibraryEntry()
    → ActivityEmitter.detectChange() → encola SyncOutboxEntry
    → Si hay red: SyncEngine.flush()
        → POST activities + UPSERT library_entries_sync
    → Si falla: reintento exponencial (max 5); queda en outbox
```

### 6.2 Puntos de emisión de actividades

| Evento local | `activities.kind` | `payload` ejemplo |
|--------------|-------------------|-------------------|
| Añadir a biblioteca | `added` | `{ "status": "PLANNING" }` |
| Cambiar estado → Watching | `started` | `{ "status": "WATCHING" }` |
| +1 episodio | `progress` | `{ "progress": 5, "total": 12 }` |
| Completar | `completed` | `{ "status": "COMPLETED", "score": 85 }` |
| Puntuar | `rated` | `{ "score": 90 }` |
| Favorito local | `favorited` | `{ "favorited": true }` |

**Hook central:** envolver `AppDatabase.upsertLibraryEntry` en un `LibraryRepository` de dominio que emita eventos (no tocar cada pantalla).

### 6.3 Pull (servidor → local)

| Trigger | Acción |
|---------|--------|
| App foreground | Pull feed últimas 50 actividades de seguidos |
| Realtime event | Insertar en `CachedActivities` |
| Abrir perfil ajeno | Pull `library_entries_sync` de ese usuario (si permiso) |
| Login / registro | Pull perfil propio + sync biblioteca |

### 6.4 Conflictos biblioteca

- Regla: **Last-Write-Wins** por `(user_id, media_kind, external_id)` usando `updated_at`.
- Igual que v1 (`upsertLibraryEntryIfNewer`).
- El feed es **append-only** (sin conflictos de merge).

### 6.5 Modo offline

- Biblioteca: 100 % local (Drift).
- Feed: última caché en `CachedActivities`.
- Outbox: se vacía al recuperar `connectivity_plus`.

---

## 7. Funcionalidades sociales (detalle por feature)

### 7.1 Perfil Cronicle (`/u/:username`)

**Datos mostrados:**
- Avatar, banner, display name, `@username`, bio.
- Contadores: seguidores, siguiendo, ítems en biblioteca (por tipo).
- Pestañas: Actividad | Biblioteca | Listas | Favoritos | Estadísticas.
- Botón Seguir / Dejar de seguir / Bloquear.

**Diferencia con `/user/:id` (AniList):** rutas coexisten; perfil Cronicle es la identidad principal en v2.

### 7.2 Feed social unificado (`/social`)

**Fuentes mezcladas (configurable en Ajustes):**

| Fuente | Toggle | Prioridad MVP |
|--------|--------|---------------|
| Cronicle (seguidos) | ON por defecto | P0 |
| AniList (seguidos) | ON si conectado | P1 (ya existe) |
| Steam amigos | ON si conectado | P2 (ya existe) |
| Global Cronicle | OFF por defecto | P3 |

**UI:** reutilizar `SocialUnifiedFeed` → añadir `_CronicleEntry`.

**Interacciones MVP:**
- Ver actividad → tap abre detalle media.
- Tap avatar → perfil Cronicle.
- Like en actividad (fase 2: tabla `activity_likes`).

### 7.3 Seguir / descubrir

- Buscar usuarios por `@username` o display name (`/search` nueva pestaña «Personas»).
- Sugeridos: «Usuarios con gustos similares» (fase 3: agregación por géneros).
- QR / link compartible: `https://cronicle.app/u/username`.

### 7.4 Listas compartidas

- Crear lista → añadir ítems desde biblioteca o búsqueda.
- Visibilidad: pública / seguidores / privada / colaborativa.
- Colaborativa: otros usuarios pueden añadir ítems (`list_collaborators`).
- Feed emite `list_item_added` al añadir.

### 7.5 Notificaciones

| Canal | MVP | Futuro |
|-------|-----|--------|
| In-app (campana) | Nuevo seguidor | Likes, menciones |
| Push (FCM) | — | Fase 4 |
| Email | — | Opcional |

### 7.6 Privacidad

**Niveles globales (`profiles.privacy_default`):**
- `public` — cualquiera ve actividades y biblioteca.
- `followers` — solo seguidores aprobados (follow público, no «request» en MVP).
- `private` — perfil visible, contenido oculto excepto actividades marcadas `public`.

**Overrides por ítem:** `library_entries_sync.visibility` y `activities.visibility`.

**Nunca sincronizar:** campo `notes` de biblioteca si usuario marca notas como privadas (setting global).

---

## 8. Plataforma web

### 8.1 Objetivo web MVP

Paridad con móvil en:
- Login Supabase (Google).
- Biblioteca CRUD.
- Feed social Cronicle.
- Perfil propio y ajeno.
- Ajustes (tema, idioma, privacidad).
- Búsqueda media (Trakt, Books; IGDB vía proxy).

### 8.2 Desbloqueos técnicos web (checklist)

| # | Tarea | Archivos afectados |
|---|-------|-------------------|
| W1 | Init `GoogleSignIn` en web | `main.dart` |
| W2 | Init `Supabase.initialize` | `main.dart`, `env_config.dart` |
| W3 | Habilitar Drive backup en web (opcional, coexistir con Supabase) | `settings_page.dart` |
| W4 | OAuth AniList/Trakt/Steam/Google Drive en web | `auth_callback.html`, `trakt_oauth_callback.html`, `steam_oauth_bridge.html`, `web_oauth_bootstrap.dart` |
| W5 | OAuth Trakt web (redirect mismo origen) | `trakt_providers.dart` |
| W6 | Proxy IGDB Edge Function | `supabase/functions/igdb-proxy/` |
| W7 | Deploy `sqlite3.wasm` | `web/` |
| W8 | CORS Trakt origins en panel Trakt | documentación |
| W9 | `flutter build web --release` CI | GitHub Actions |

### 8.3 URLs web

| Ruta | Pantalla |
|------|----------|
| `/` | Feed o home según prefs |
| `/auth/callback` | OAuth callback Supabase + AniList |
| `/u/:username` | Perfil Cronicle |
| `/social` | Feed social |
| `/library` | Biblioteca |
| `/lists/:id` | Lista compartida |

### 8.4 Variables de entorno nuevas

```json
{
  "SUPABASE_URL": "https://xxx.supabase.co",
  "SUPABASE_ANON_KEY": "eyJ...",
  "SUPABASE_REDIRECT_URL": "https://app.cronicle.dev/auth/callback"
}
```

Añadir a `dart_defines.example.json` y `EnvConfig`.

---

## 9. Estructura de código nueva (`lib/`)

```
lib/
├── core/
│   ├── supabase/
│   │   ├── supabase_client_provider.dart
│   │   └── supabase_auth_listener.dart
│   ├── sync/
│   │   ├── domain/
│   │   │   ├── sync_repository.dart
│   │   │   └── activity_emitter.dart
│   │   ├── data/
│   │   │   ├── supabase_sync_datasource.dart
│   │   │   └── sync_outbox_local_datasource.dart
│   │   └── presentation/
│   │       └── sync_status_provider.dart
│   └── database/
│       ├── tables/sync_outbox.dart
│       ├── tables/cached_activities.dart
│       └── tables/cronicle_profile_cache.dart
├── features/
│   ├── identity/
│   │   ├── domain/
│   │   │   ├── entities/cronicle_profile.dart
│   │   │   ├── repositories/profile_repository.dart
│   │   │   └── usecases/
│   │   │       ├── register_username.dart
│   │   │       ├── follow_user.dart
│   │   │       └── update_privacy.dart
│   │   ├── data/
│   │   │   ├── datasources/supabase_profile_datasource.dart
│   │   │   └── repositories/profile_repository_impl.dart
│   │   └── presentation/
│   │       ├── auth_gate.dart              # redirect si no hay sesión
│   │       ├── login_page.dart
│   │       ├── username_setup_page.dart
│   │       └── profile_providers.dart
│   ├── cronicle_social/                    # feed nativo (no confundir con social/ v1)
│   │   ├── domain/
│   │   │   ├── entities/activity.dart
│   │   │   └── repositories/activity_repository.dart
│   │   ├── data/
│   │   │   └── datasources/supabase_activity_datasource.dart
│   │   └── presentation/
│   │       ├── cronicle_feed_provider.dart
│   │       ├── cronicle_activity_card.dart
│   │       └── cronicle_profile_page.dart  # /u/:username
│   ├── shared_lists/
│   │   └── ... (misma estructura clean)
│   └── notifications/
│       └── ... (in-app bell)
```

### 9.1 Router — rutas nuevas

```dart
// Añadir en app_router.dart
GoRoute(path: '/login', builder: ...),
GoRoute(path: '/onboarding/username', builder: ...),
GoRoute(path: '/u/:username', builder: ...),
GoRoute(path: '/lists/:listId', builder: ...),
GoRoute(
  path: '/notifications',
  builder: ...,
),
```

### 9.2 Auth gate

- `CronicleApp` envuelve router con `AuthGate`: si no hay sesión Supabase → `/login`.
- Excepción: rutas públicas (`/u/:username` perfil público, landing web).

---

## 10. Integración con Cronicle 1.x

### 10.1 Coexistencia durante desarrollo

- Rama `main` = Cronicle 1.x estable.
- Rama `cronicle-2` = todo el trabajo v2.
- Merge a `main` solo cuando MVP social esté validado.

### 10.2 Migración de usuarios v1 → v2

1. Usuario actualiza app (build con flag `CRONICLE_2`).
2. Pantalla «Crear tu cuenta Cronicle» (obligatoria para social).
3. Opción «Importar biblioteca local a la nube» (push masivo a `library_entries_sync`).
4. Backup Drive sigue disponible.
5. AniList/Trakt: sin cambios; `external_account_links` guarda solo IDs públicos.

### 10.3 Feature flags

```dart
// lib/core/config/feature_flags.dart
abstract final class FeatureFlags {
  static const cronicle2Social = bool.fromEnvironment(
    'CRONICLE_2_SOCIAL',
    defaultValue: false,
  );
}
```

Permite compilar v2 en rama sin romper builds de `main` si se hace cherry-pick parcial.

---

## 11. Fases de implementación (roadmap detallado)

### Fase 0 — Fundamentos (2–3 semanas)

**Objetivo:** Infra lista; cero UI social visible.

| ID | Tarea | Entregable |
|----|-------|------------|
| 0.1 | Crear proyecto Supabase (dev + staging) | URL + keys en `dart_defines.local.json` |
| 0.2 | Aplicar migración SQL `001_cronicle2_core.sql` | Tablas + RLS básico |
| 0.3 | Añadir `supabase_flutter` a `pubspec.yaml` | Dependencia |
| 0.4 | `Supabase.initialize` en `main.dart` | Cliente global |
| 0.5 | `EnvConfig`: `SUPABASE_URL`, `SUPABASE_ANON_KEY` | Defines |
| 0.6 | Tablas Drift: `SyncOutbox`, `CachedActivities` | Migración Drift v8 |
| 0.7 | `SyncEngine` skeleton (flush outbox vacío) | Tests unitarios |
| 0.8 | CI: `flutter analyze` en rama `cronicle-2` | GitHub Action |
| 0.9 | Web: `sqlite3.wasm` en repo + build web verde | Artifact CI |

**Criterio de done:** `flutter run -d chrome` arranca con Supabase conectado (sin UI nueva).

---

### Fase 1 — Identidad (2–3 semanas)

**Objetivo:** Login, registro, perfil propio.

| ID | Tarea | Entregable |
|----|-------|------------|
| 1.1 | `LoginPage` (Google → Supabase) | móvil + web |
| 1.2 | `UsernameSetupPage` + validación única | trigger o RPC Supabase |
| 1.3 | `AuthGate` en router | redirect `/login` |
| 1.4 | `CronicleProfilePage` (propio) | `/profile` enlaza a perfil Cronicle |
| 1.5 | Editar bio, avatar (Storage), privacidad | formulario |
| 1.6 | Logout + borrado sesión local | |
| 1.7 | l10n ES/EN todas las cadenas auth | ARB |

**Criterio de done:** Usuario puede registrarse, elegir username, ver y editar su perfil en Android y Chrome.

---

### Fase 2 — Grafo social + feed (3–4 semanas)

**Objetivo:** Seguir usuarios y ver feed Cronicle.

| ID | Tarea | Entregable |
|----|-------|------------|
| 2.1 | `follow_user` / `unfollow_user` use cases | Supabase `follows` |
| 2.2 | `ActivityEmitter` en `LibraryRepository` | eventos en outbox |
| 2.3 | `SyncEngine.flush` → `activities` + Realtime | |
| 2.4 | `CachedActivities` + pull on foreground | offline feed |
| 2.5 | `CronicleActivityCard` + merge en `SocialUnifiedFeed` | UI |
| 2.6 | `CronicleProfilePage` ajeno `/u/:username` | |
| 2.7 | Buscar usuarios en `/search` | pestaña Personas |
| 2.8 | Contadores followers/following | |
| 2.9 | Privacidad: respetar RLS en cliente | tests |

**Criterio de done:** Usuario A sigue a B; B completa un anime; A lo ve en feed < 10 s.

---

### Fase 3 — Sync biblioteca cloud (2–3 semanas)

**Objetivo:** Biblioteca visible en perfil (con permisos).

| ID | Tarea | Entregable |
|----|-------|------------|
| 3.1 | Push `library_entries_sync` en cada upsert local | |
| 3.2 | Pull biblioteca al abrir perfil ajeno | |
| 3.3 | Toggle «Compartir biblioteca» en Ajustes | |
| 3.4 | Migración inicial v1 → cloud (wizard) | |
| 3.5 | LWW conflictos + tests | |
| 3.6 | Coexistencia con Drive backup | documentado |

**Criterio de done:** Biblioteca de un amigo visible en su perfil (si `followers`).

---

### Fase 4 — Web producción (2 semanas, paralelo parcial)

| ID | Tarea | Entregable |
|----|-------|------------|
| 4.1 | OAuth web completo (Google, AniList, Trakt) | |
| 4.2 | Edge Function proxy IGDB | |
| 4.3 | Deploy staging `app.cronicle.dev` | |
| 4.4 | Trakt CORS origins | |
| 4.5 | PWA manifest básico | |

---

### Fase 5 — Listas compartidas (2–3 semanas)

| ID | Tarea | Entregable |
|----|-------|------------|
| 5.1 | CRUD `shared_lists` | |
| 5.2 | UI crear / editar / añadir ítems | |
| 5.3 | Ruta `/lists/:id` pública | |
| 5.4 | Colaboradores (opcional MVP) | |
| 5.5 | Actividad `list_item_added` en feed | |

---

### Fase 6 — Notificaciones + pulido (2 semanas)

| ID | Tarea | Entregable |
|----|-------|------------|
| 6.1 | Tabla `notifications` + campana UI | |
| 6.2 | Realtime notificaciones | |
| 6.3 | Bloquear usuario | |
| 6.4 | Moderación básica (report) | opcional |
| 6.5 | Performance feed (paginación) | |

---

### Fase 7 — Beta y lanzamiento

| ID | Tarea |
|----|-------|
| 7.1 | TestFlight / Play Internal Testing rama `cronicle-2` |
| 7.2 | Documentación usuario |
| 7.3 | Merge `cronicle-2` → `main` |
| 7.4 | Versión app `3.0.0` |

---

## 12. Estimación global

| Fase | Duración | Acumulado |
|------|----------|-----------|
| 0 Fundamentos | 2–3 sem | 3 sem |
| 1 Identidad | 2–3 sem | 6 sem |
| 2 Feed social | 3–4 sem | 10 sem |
| 3 Sync biblioteca | 2–3 sem | 13 sem |
| 4 Web prod | 2 sem (paralelo) | 13 sem |
| 5 Listas | 2–3 sem | 16 sem |
| 6 Notificaciones | 2 sem | 18 sem |
| 7 Beta/Launch | 2 sem | **~20 semanas** |

*Estimación para 1 desarrollador a tiempo parcial; ~10–12 semanas full-time.*

---

## 13. Testing

### 13.1 Unitarios

- `ActivityEmitter`: cada transición de estado genera el `kind` correcto.
- `SyncEngine`: outbox vacío tras flush exitoso; reintento tras fallo.
- `upsertLibraryEntryIfNewer` vs sync cloud LWW.

### 13.2 Integración

- Supabase local (`supabase start`) + tests contra RLS.
- Mock `SupabaseClient` para repositorios.

### 13.3 E2E (opcional MVP)

- `integration_test`: login → añadir ítem → ver en feed propio.

### 13.4 Manual QA checklist

- [ ] Login Google móvil + web misma cuenta → mismo perfil.
- [ ] Offline: editar biblioteca → al volver red, sync outbox.
- [ ] Privado: usuario C no ve biblioteca de A (followers only).
- [ ] Bloqueado: B no aparece en búsqueda de A.
- [ ] Migración backup v1 → cuenta nueva v2.

---

## 14. Seguridad

| Riesgo | Mitigación |
|--------|------------|
| Tokens OAuth en cloud | **Prohibido** en schema; code review |
| RLS bypass | Tests automatizados por política |
| Username squatting | Reservar en registro; reportar |
| Spam actividades | Rate limit Edge Function (max N/min) |
| XSS en bio | Sanitizar en cliente; `char_length` en SQL |
| API keys en web | Solo `anon` key; IGDB vía Edge Function |

---

## 15. Costes Supabase (orientativo)

| Tier | Uso estimado MVP | Coste |
|------|------------------|-------|
| Free | < 50k MAU, DB 500 MB | $0 |
| Pro | Realtime + Storage + backups | ~$25/mes |

Monitorear: tamaño `activities` (retención 90 días → job de limpieza).

---

## 16. Riesgos y mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| Scope creep social | Alta | Alto | Fases estrictas; MVP = Fase 0–2 |
| Complejidad sync | Media | Alto | Outbox simple; LWW; no CRDT en v1 |
| Web WASM lento | Media | Medio | Lazy load; caché agresivo |
| Supabase vendor lock | Baja | Medio | SQL estándar; export periódico |
| Regresión offline v1 | Media | Alto | Feature flag; tests Drift |

---

## 17. Próximos pasos inmediatos (esta rama)

1. ✅ Crear rama `cronicle-2` en GitHub.
2. ✅ Documentar plan (este archivo).
3. ✅ Crear proyecto Supabase staging (`pidlodpgabmgguzzwksn`).
4. ✅ Aplicar `001_cronicle2_core.sql` + `002_fix_shared_lists_rls.sql`.
5. ✅ Fase 0.3–0.5: `supabase_flutter`, `EnvConfig`, init en `main.dart`, login Google + email/contraseña + username (`/cronicle-login`, `/cronicle-username`). Sesión persistente en `localStorage` (web).
6. ⬜ Fase 2: follow + feed Cronicle + `ActivityEmitter`.

---

## 18. Referencias

- [Supabase Flutter Auth](https://supabase.com/docs/guides/auth/auth-helpers/flutter-auth)
- [Supabase RLS](https://supabase.com/docs/guides/auth/row-level-security)
- [Drift web setup](https://drift.simonbinder.eu/platforms/web/)
- [CRONICLE_GUIDE.md](./CRONICLE_GUIDE.md) — arquitectura v1
- Rama GitHub: `cronicle-2`

---

*Documento vivo: actualizar al cerrar cada fase.*
