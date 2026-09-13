# QSOLog — Architecture & Plugin Guide

QSOLog is a Flutter app for logging amateur radio contacts (QSOs). It runs on
Windows, macOS, Linux, Android, and iOS from a single codebase, using SQLite
for QSO storage and `shared_preferences` for app settings.

## 1. How the app is organized

```
lib/
  main.dart                  App entry point, theme, DB init
  app_themes.dart            Named Material theme definitions
  models/
    models.dart              All plain data model classes
  services/
    database_service.dart    SQLite access (QSO table only)
    settings_service.dart    shared_preferences access (everything else)
    app_state.dart            Central ChangeNotifier — app-wide state
    adif_service.dart        ADIF import/export
    qrz_service.dart         QRZ.com XML lookup + logbook upload API
  screens/
    log_screen.dart          Home screen: QSO list, search, toolbar, plugin launcher
    add_qso_screen.dart      Manual "Standard QSO" entry/edit form
    quick_entry_screen.dart  Spreadsheet-style rapid multi-row entry
    settings_screen.dart     Station/QRZ/rig/theme/unit settings
    tags_screen.dart         Tag CRUD
    stats_screen.dart        Logging statistics
    map_screen.dart          Map of recent contacts
    plugins_screen.dart      Enable/disable & reorder plugins
  plugins/
    plugin_registry.dart     Canonical list of plugins (id, label, icon)
    contest_plugin.dart      General contest logging UI
    cwt_plugin.dart, mst_plugin.dart, sst_plugin.dart
                              Specific weekly-contest loggers (CWops/NAQCC/SKCC style)
    pota_hunter_plugin.dart  Browse live POTA spots and log a hunter QSO
    pota_activator_plugin.dart
                              Rapid-fire logging while activating a POTA park
  widgets/
    common_widgets.dart      Shared UI pieces reused by screens/plugins
```

### Layering

- **Models** (`models/models.dart`) are plain Dart classes with `toMap`/`fromMap`
  or `toJson`/`fromJson` — no Flutter or storage dependencies.
- **Services** own all persistence and I/O: `DatabaseService` (SQLite),
  `SettingsService` (`shared_preferences`), `QrzService` (QRZ.com HTTP/XML),
  `AdifService` (ADIF text format).
- **`AppState`** (`services/app_state.dart`) is the single `ChangeNotifier`
  injected at the app root via `provider`. It holds all in-memory app state
  (QSO list, filters, settings, active plugin, "my station" info, last-used
  band/mode/freq) and is the only thing screens and plugins should mutate
  through — they never call the DB or settings services directly.
- **Screens** are full-page `Scaffold`s reached via `Navigator.push`, wired
  together from `log_screen.dart`, the home/root screen.
- **Plugins** are just screens with a special contract (see §3) that plug
  into the home screen's "current logging mode" button instead of being
  reached from the main menu.

### App startup

`main()` calls `DatabaseService.initialize()` (sets up the FFI SQLite driver
on desktop platforms), then wraps the app in a `ChangeNotifierProvider` that
creates and initializes `AppState`. `AppState.initialize()` loads all
settings and the QSO log from disk before the first frame that needs them is
built. `LogScreen` is the app's `home`.

### Data flow for logging a QSO

Every entry point (Add QSO form, Quick Entry, or a plugin) builds a
`QsoEntry` and calls `AppState.addQso(qso)`. That method:

1. Checks `DatabaseService.isDuplicate` (same callsign + band within a
   30-minute UTC window).
2. Stamps "my station" fields (`myCallsign`, `myQth`, `myGrid`, `myRig`,
   `myPower`) from current `StationSettings`/active rig if the plugin didn't
   already set them.
3. Computes great-circle `distanceKm` from station ↔ contact lat/lon, if both
   are known.
4. Inserts into SQLite and reloads the in-memory QSO list.
5. Remembers `lastBand`/`lastMode`/`lastFreq` so the next logging screen
   opens pre-filled with sensible defaults.

This is why plugins should always log through `AppState.addQso` rather than
calling `DatabaseService` directly — duplicate-checking and station-stamping
only happen there.

## 2. Database structure

There is exactly **one SQLite table**, `qsos`, opened via
`sqflite`/`sqflite_common_ffi` (`database_service.dart`). Everything else
(station info, QRZ credentials, tags, rigs, theme, plugin order, per-plugin
scratch state like "last contest name") lives in `shared_preferences` as
JSON blobs, not in SQLite.

### `qsos` table (current schema version 4)

| Column          | Type    | Notes |
|-----------------|---------|-------|
| `id`            | TEXT PK | UUID v4, generated client-side |
| `callsign`      | TEXT    | Contact's callsign, stored upper-case |
| `band`          | TEXT    | e.g. `20m`, derived from frequency via `BandFrequency` |
| `frequency`     | REAL    | MHz |
| `mode`          | TEXT    | e.g. `SSB`, `CW`, `FT8` |
| `rstSent`       | TEXT    | |
| `rstReceived`   | TEXT    | |
| `comments`      | TEXT    | |
| `dateTime`      | TEXT    | ISO-8601, always stored/read as UTC |
| `contactName`   | TEXT    | nullable |
| `contactQth`    | TEXT    | nullable |
| `contactGrid`   | TEXT    | nullable, Maidenhead grid square |
| `contactCountry`| TEXT    | nullable |
| `contactState`  | TEXT    | nullable |
| `contactLat`    | REAL    | nullable |
| `contactLon`    | REAL    | nullable |
| `myCallsign`    | TEXT    | nullable — stamped from station settings if empty |
| `myQth`         | TEXT    | nullable |
| `myGrid`        | TEXT    | nullable |
| `myRig`         | TEXT    | nullable |
| `myPower`       | REAL    | nullable |
| `tags`          | TEXT    | JSON-encoded `List<String>` |
| `adifFields`    | TEXT    | JSON-encoded `Map<String,String>` — see below |
| `distanceKm`    | REAL    | nullable, computed great-circle distance |
| `uploadedToQrz` | INTEGER | 0/1, set once successfully pushed to QRZ logbook |

`adifFields` is the escape hatch for anything not modeled as a first-class
column: satellite name/mode, propagation mode, contest ID and exchange
strings, serial numbers, POTA/SOTA references, IOTA, grid square overrides,
etc. `QsoEntry` exposes convenience getters (`satName`, `satMode`,
`propMode`) that just read out of this map. **New plugin-specific fields
should go into `adifFields` rather than adding new table columns**, unless
the field is genuinely universal to every QSO.

`QsoEntry.toMap()`/`fromMap()` (in `models/models.dart`) are the single
source of truth for the column list and JSON encoding — update them whenever
the schema changes.

### Schema migrations

`DatabaseService._initDb` uses `openDatabase(..., version: 4, onUpgrade: ...)`.
Each version bump adds an `if (oldVersion < N)` block in `onUpgrade` that
runs `ALTER TABLE` statements wrapped in `try/catch` (SQLite's limited
`ALTER TABLE` support and the possibility of re-running a partial migration
make the try/catch necessary — failures are swallowed rather than crashing
existing installs). To add a column:

1. Add the field to `QsoEntry` and its `toMap`/`fromMap`.
2. Add it to `_createTable` (for fresh installs).
3. Bump `version` and add a new `if (oldVersion < newVersion)` block with the
   `ALTER TABLE` statement (for existing installs).

### Non-SQLite persisted data (`SettingsService`, `shared_preferences`)

Each is a JSON string (or primitive) under its own key: `StationSettings`,
`QrzSettings`, `List<TagDefinition>`, `List<RigDefinition>`, active plugin
id, distance unit, map QSO count, app theme, `List<CustomLink>`, plugin
order/visibility, and small per-plugin scratch values (e.g. contest name and
transmitted exchange, so a contest logger remembers them across restarts).

## 3. Writing a new plugin

A "plugin" is a full-screen `StatefulWidget` that replaces the standard "Add
QSO" form as the app's current logging mode. Plugins are not dynamically
loaded — they are ordinary Dart files compiled into the app; "plugin" here
means *pluggable logging mode*, not a runtime/dynamic plugin system.

### Steps to add one

1. **Create the widget** in `lib/plugins/your_plugin.dart`, following the
   pattern in `contest_plugin.dart` or `pota_hunter_plugin.dart`:
   - `StatefulWidget` with its own `Scaffold` (own `AppBar`, own body) —
     it's pushed full-screen via `Navigator.push`, not embedded.
   - Read shared state via `context.read<AppState>()` /
     `context.watch<AppState>()` (the widget is under the app-root
     `ChangeNotifierProvider`, so `Provider` is always available).
   - On init, seed frequency/band/mode from `AppState.lastFreq` /
     `lastBand` / `lastMode` so the UI matches whatever the user was doing
     before switching modes.
   - Build a `QsoEntry` (`id: const Uuid().v4()`, `dateTime:
     DateTime.now().toUtc()`) and log it via `await
     context.read<AppState>().addQso(qso)` — never call
     `DatabaseService` directly (see §1 for why).
   - Put anything that isn't a first-class `QsoEntry` field (contest ID,
     exchange, serial number, POTA reference, satellite name, etc.) into
     `adifFields: {...}`, matching real ADIF field names (`CONTEST_ID`,
     `SRX_STRING`, `STX_STRING`, `STX`, `SAT_NAME`, `POTA_REF`, ...) so
     exports stay ADIF-compliant.
   - If the plugin should tag its QSOs (e.g. `Contest`, `POTA`), set
     `tags: const ['YourTag']`.
   - After logging, clear the form and refocus the callsign field so rapid
     serial logging works — this is the expected UX for every existing
     plugin.
   - If the plugin needs settings that should survive app restarts (a
     contest name, a park reference, an operator's last exchange), add
     load/save methods to `SettingsService` and expose them through
     `AppState`, the same way `contestName`/`contestTxExchange` work.

2. **Register it** in `lib/plugins/plugin_registry.dart`: add a
   `PluginInfo(id: 'your_id', label: 'Your Label', icon: Icons.something)`
   entry to `kPlugins`. The `id` is also the persisted string stored in
   `shared_preferences`, so pick it once and don't rename it later (existing
   installs would fall back to `standard`).

3. **Wire it into the launcher** in `lib/screens/log_screen.dart`:
   - Import the plugin file.
   - Add a `case 'your_id': screen = const YourPlugin(); break;` arm to the
     `switch` in `_openActivePlugin`.

That's it — `plugins_screen.dart` (show/hide + reorder) and the mode-picker
button in `log_screen.dart` both drive off `kPlugins`/`AppState.pluginOrder`
automatically; you don't need to touch them.

### Conventions/constraints new plugins must follow

- **Log through `AppState.addQso`**, not `DatabaseService.insertQso`, so
  duplicate detection and "my station" stamping stay consistent everywhere.
- **Don't add new `qsos` columns** for plugin-specific data — use
  `adifFields` with real ADIF field names so ADIF export/import
  (`adif_service.dart`) keeps working without changes.
- **Store times in UTC.** `QsoEntry.dateTime` is normalized to UTC on
  write/read; plugins should call `.toUtc()` when constructing it.
- **Callsigns are upper-cased** by convention throughout the app
  (`callsign.trim().toUpperCase()`).
- **The plugin `id` is a stable, persisted string** — used in
  `shared_preferences` (active plugin, plugin order, visibility). Never
  reuse or repurpose an existing id.
- **QRZ lookups are optional**: check
  `state.qrzSettings.username.isNotEmpty` before calling
  `state.qrzService.lookupCallsign(...)`, matching every existing plugin, so
  the plugin still works for users who haven't configured QRZ.
- **No dynamic loading, no external plugin packages** — a "plugin" is just a
  screen shipped in the same app binary. Anything requiring truly
  hot-loadable/third-party plugins would need a different architecture than
  what exists today.
