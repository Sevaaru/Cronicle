# Cronicle Wear OS Companion

Lightweight Wear OS 3+ companion app for the Cronicle phone app. It mirrors the
*in-progress* slice of your library on the watch and lets you increment progress
or mark entries as completed without taking out your phone.

## What it does

- Shows a `ScalingLazyColumn` of every library entry whose `status == CURRENT`
  across **anime · series · books · movies · games · manga**.
- Tap the **+** button on a row → increments chapter / episode / page (mirrors
  `AppDatabase.incrementProgress` / `incrementBookProgress` from the phone app,
  including auto-completion when reaching the total).
- Open the detail screen → big **+1** button and **Completar** button (the
  latter writes `status = 'COMPLETED'`). Movies and games only show the
  Completar button (they do not support increments).
- A **Tile** on the watch face shows the count of in-progress items and the
  next item's title. Tapping the tile opens the app.

## Architecture

```
┌────────────────────────────┐                ┌──────────────────────────────┐
│  Phone (Cronicle Flutter)  │                │   Wear OS (Cronicle Wear)    │
│                            │                │                              │
│  Drift  ───►  cronicle.db  │◄── SQLite ─────│  PhoneSyncClient (Data Layer)│
│                            │   read+write   │           │                  │
│  WearLibraryListenerService│                │           ▼                  │
│  (WearableListenerService) │◄── Messages ──►│  LibraryViewModel  ──► UI    │
│                            │                │                              │
│  publishes JSON snapshot   │  DataClient    │  WearLibraryListener         │
│  at /library/items         │ ──── push ───► │  (auto-refresh on push)      │
└────────────────────────────┘                └──────────────────────────────┘
```

Both APKs share `applicationId = com.cronicle.app.cronicle` so the Wearable
Data Layer pairs them automatically. The watch never talks to AniList / Trakt /
RAWG directly — every action is forwarded to the phone, which applies it to
the local Drift database. The next time the phone app comes to the foreground,
its existing reactive providers (`libraryAllProvider`, etc.) pick up the
changes via Drift's stream queries.

## Sync protocol

| Direction | Path                     | Payload                              | Effect |
| --------- | ------------------------ | ------------------------------------ | ------ |
| Watch → Phone | `/library/request_sync` | empty                                | Phone re-publishes snapshot |
| Watch → Phone | `/library/action`       | `{action,kind,externalId}` JSON     | Phone applies increment / complete |
| Phone → Watch | `/library/items`        | `DataMap{items_json,timestamp}`     | Watch refreshes its list |

Constants live in `WearProtocol.kt` (watch) and `WearLibraryListenerService.kt`
(phone). They MUST stay in sync.

## Module layout

```
android/
├── app/                                 # phone Flutter app (existing)
│   └── src/main/kotlin/.../wear/
│       ├── CronicleLibraryDb.kt         # raw SQLite reader/writer
│       └── WearLibraryListenerService.kt
└── wear/                                # NEW Wear OS module
    └── src/main/
        ├── AndroidManifest.xml
        ├── kotlin/.../wear/
        │   ├── MainActivity.kt
        │   ├── LibraryViewModel.kt
        │   ├── model/LibraryItem.kt
        │   ├── sync/PhoneSyncClient.kt
        │   ├── sync/WearLibraryListener.kt
        │   ├── sync/WearProtocol.kt
        │   ├── tile/LibraryTileService.kt
        │   └── ui/
        │       ├── LibraryScreen.kt
        │       └── DetailScreen.kt
        └── res/...
```

## Building

```powershell
# Debug APK
.\scripts\build_wear.ps1

# Release APK (signed with android/key.properties)
.\scripts\build_wear.ps1 -Release
```

Or directly:

```powershell
cd android
.\gradlew.bat :wear:assembleDebug
```

The APK lands at `build/wear/outputs/apk/debug/wear-debug.apk`.

## Installing on a Wear OS device

1. Pair the watch with the phone via the Wear OS app.
2. Install the **phone APK** as you normally do (`flutter run` or
   `build_android.ps1`).
3. Open the phone app at least once so the Drift database is created at
   `/data/user/0/com.cronicle.app.cronicle/app_flutter/cronicle.db`.
4. Enable ADB debugging on the watch, then install the wear APK:
   ```powershell
   adb -s <watch-serial> install -r build\wear\outputs\apk\debug\wear-debug.apk
   ```
   Or push to the Play Store internal track in a multi-APK release.
5. Open the Cronicle app on the watch. The first launch sends
   `/library/request_sync`; the phone's `WearLibraryListenerService` boots up
   in the background, queries `library_entries WHERE UPPER(status)='CURRENT'`,
   and pushes the snapshot.

## Notes & limitations

- **Standalone mode is OFF** (`com.google.android.wearable.standalone = false`).
  The watch app depends on the phone app being installed; it does not call
  AniList/Trakt/RAWG directly.
- **Database access from Kotlin** is read/write via the platform
  `SQLiteDatabase`. SQLite locking is honored, so concurrent access while the
  Flutter app is open is safe. However Drift caches query results — changes
  written by the watch are reflected by the Flutter UI **on the next stream
  emission** (which fires when any Drift write executes; if the user edits
  anything in the phone app the cache invalidates).
- **No remote push from the watch action**: when you increment from the watch
  while the Flutter app is closed, the AniList / Trakt mirror does NOT update
  immediately. It will be pushed by the phone the next time the user opens the
  app and triggers any sync. (This is the same trade-off as `workmanager`
  background writes today.)
- **Tile freshness**: the tile re-queries the cached snapshot every 10 minutes,
  or when the user opens / closes a panel.
- **No images on the watch**: we send `posterUrl` but the watch UI currently
  does not download images to keep battery usage low. Add `coil-compose` and
  `AsyncImage` if you want covers.

## Future enhancements

- Complications (small dial widgets) — wrap `LibraryTileService` data in a
  `ComplicationDataSourceService`.
- Optional native push of changes to AniList / Trakt from the watch via
  WorkManager scheduled in the phone-side service.
- On-watch image cache (Coil) gated by a Wear "battery saver" check.
- Voice action: "Hey Google, marca el siguiente capítulo de Cronicle".
