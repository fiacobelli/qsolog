# QSOLog - Ham Radio QSO Logger

A full-featured ham radio contact logging application built with Flutter. Runs on Windows, macOS, Linux, iOS, Android, and Web.

---

## Features

### Main Log Screen
- All QSOs listed with country flag, callsign, name, location (QTH + state/province + country), band, mode, distance, and tags
- Live **UTC clock** displayed in the app bar with date and time
- QSOs always sorted most recent first
- Search by callsign, name, or QTH
- Filter by tag (POTA, SOTA, SST, etc.)
- Long-press to select individual QSOs; select-by-tag also available
- Delete selected QSOs with confirmation
- Export selected or all filtered QSOs to ADIF file
- Import QSOs from ADIF file (supports UTF-8 and Latin-1/Windows-1252 encodings)
- Upload directly to QRZ logbook

### QSO Logging
- Log callsign, band, frequency, mode, RST sent/received, comments, and tags
- Band auto-detected from frequency as you type
- QRZ XML lookup auto-fills name, QTH, grid square, country, and state as you type the callsign
- Distance to contact calculated automatically from your station coordinates
- Your station callsign, QTH, grid, rig, and power are stamped on every QSO automatically
- Delete button available when editing an existing QSO
- **Duplicate detection**: QSOs with the same callsign and band within 30 minutes of each other are skipped automatically on both manual entry and import
- All times stored and displayed in UTC

### Tags
- Predefined tags: POTA, SOTA, Buddy, SST, Contest
- Create custom tags with a color picker
- Type any free-text tag directly in the QSO form
- Drag-to-reorder tags; tags preserved in ADIF export/import
- Filter and select QSOs by tag from the main screen

### Plugin System
The active plugin is selected once from the chip bar at the top of the main screen. Tapping + always opens the selected plugin directly.

1. **Standard QSO** — General contact logging form
2. **POTA Hunter** — Live POTA spots from pota.app; tap any spot to pre-fill callsign, park, band, frequency, and mode; auto-tagged POTA
3. **SST Logger** — Saturday Speed Test rapid-entry; auto QRZ name/state lookup; all QSOs tagged SST
4. **POTA Activator** — Configure park reference and mode once per session, then log hunters one at a time; all QSOs tagged POTA with park reference embedded

### Statistics (menu → Statistics)
- Total QSO count
- Top 3 most-worked callsigns (gold/silver/bronze)
- QSOs by tag with color-coded progress bars
- QSOs by band with progress bars
- QSOs by country with flags and progress bars

### Map (menu → Map)
- Plots the most recent N QSOs that have coordinate data on an interactive world map
- Lines drawn from your station to each contact
- Tap any dot to see callsign, name, country, distance, band, and mode
- Pinch to zoom, drag to pan, reset button to restore default view
- Number of QSOs shown on the map is configurable in Settings → Prefs
- No internet connection or API key required — map is rendered locally

### Settings
- **Station** tab: Your callsign, operator name, QTH, grid square, latitude, longitude
- **Rig** tab: Add multiple transceivers with name and power; select the active rig with a radio button; active rig power is included in every QSO and ADIF export
- **QRZ** tab: Username and password/API key for callsign lookups and logbook uploads; test connection button
- **Prefs** tab: Distance unit (km or miles); number of recent QSOs to display on the map

---

## ADIF Support

### Export
- Standard ADIF 3.1.4 format
- Includes `STATION_CALLSIGN`, `MY_GRIDSQUARE`, `MY_CITY`, `TX_PWR` from your station settings
- Tags exported as `APP_HAMLOG_TAGS`
- All extra fields (satellite name, propagation mode, contest exchange, etc.) round-trip correctly

### Import
- Reads standard ADIF files from any logging software (Logger32, Log4OM, Ham Radio Deluxe, WSJT-X, etc.)
- Supports UTF-8 and Latin-1/Windows-1252 encodings automatically
- All ADIF fields not mapped to dedicated columns are stored in `adifFields` (including `SAT_NAME`, `PROP_MODE`, `CONTEST_ID`, etc.)
- Duplicate QSOs (same callsign + band within 30 minutes) are skipped; the import summary reports how many were imported vs. skipped
- Your station info is stamped on imported QSOs where not already present in the ADIF

---

## Database

QSOLog uses **SQLite** via the `sqflite` package with `sqflite_common_ffi` for desktop platforms.

| Platform | Database location |
|----------|-------------------|
| Windows  | `C:\Users\<user>\Documents\qsolog.db` |
| macOS    | `~/Library/Application Support/qsolog.db` |
| Linux    | `~/.local/share/qsolog.db` |
| Android  | App sandbox documents directory |
| iOS      | App sandbox documents directory |

The database file is standard SQLite and can be opened with [DB Browser for SQLite](https://sqlitebrowser.org/).

Station preferences (QRZ credentials, rig list, active plugin, distance unit, map count) are stored separately in `SharedPreferences`.

---

## QRZ Integration

### Callsign Lookup
- Requires a **QRZ XML Data subscription**
- Enter your QRZ username and password in Settings → QRZ
- Lookups trigger automatically as you type a callsign (3+ characters)
- Fills in name, QTH, grid square, country, state, and coordinates

### Logbook Upload
- Requires your **QRZ Logbook API key** (found in QRZ.com → Logbook → Settings → API)
- Enter this as the Password/API Key field in Settings → QRZ
- Select QSOs on the main screen, then tap the cloud upload icon, or tap Upload to QRZ from the toolbar

---

## Setup

### Prerequisites
- Flutter 3.x SDK: https://flutter.dev/docs/get-started/install
- For Windows: Visual Studio with "Desktop development with C++" workload
- For iOS/macOS: Xcode

### Install & Run

```bash
# Copy the project files, keeping the directory structure
cd qsolog

# Get dependencies
flutter pub get

# Enable Windows desktop (first time only)
flutter config --enable-windows-desktop

# Add Windows support to project (first time only)
flutter create --platforms=windows .

# Run
flutter run -d windows    # Windows
flutter run -d macos      # macOS
flutter run -d linux      # Linux
flutter run -d chrome     # Web
flutter run               # Mobile device/emulator
```

### Windows: Enable Developer Mode
If you see a symlink error on Windows:
1. Run: `start ms-settings:developers`
2. Enable Developer Mode
3. Restart terminal and try again

---

## Build for Distribution

### Windows Installer (MSIX)
Add to `pubspec.yaml`:
```yaml
msix_config:
  display_name: QSOLog
  publisher_display_name: Your Name
  identity_name: com.yourname.qsolog
  msix_version: 1.0.0.0
```
Then:
```bash
flutter build windows --release
dart run msix:create
```

### Traditional Installer (Inno Setup)
1. Build the release: `flutter build windows --release`
2. Point [Inno Setup](https://jrsoftware.org/isinfo.php) at `build\windows\x64\runner\Release\`
3. No certificate required — good for local distribution

---

## Adding More Plugins
Create a new file in `lib/plugins/` following the pattern of the existing plugins, then:
1. Add it to `_plugins` list in `lib/screens/log_screen.dart`
2. Add a `case` for it in `_openActivePlugin()` in the same file

---

## Project Structure
```
lib/
  main.dart                    # App entry, theme, sqflite FFI init
  models/
    models.dart                # QsoEntry, StationSettings, RigDefinition,
                               # BandFrequency, PotaSpot, etc.
  services/
    database_service.dart      # SQLite CRUD + duplicate detection
    settings_service.dart      # SharedPreferences (station, QRZ, rigs, prefs)
    qrz_service.dart           # QRZ XML API: login, lookup, logbook upload
    adif_service.dart          # ADIF 3.1.4 import/export
    app_state.dart             # ChangeNotifier: all state, distance calc,
                               # station stamping, formatDistance()
  screens/
    log_screen.dart            # Main QSO list + UTC clock + plugin selector
    add_qso_screen.dart        # Add/edit/delete QSO form
    settings_screen.dart       # Station / Rig / QRZ / Prefs tabs
    tags_screen.dart           # Tag management
    stats_screen.dart          # Statistics dashboard
    map_screen.dart            # Interactive world map
  widgets/
    common_widgets.dart        # TagChip, DistanceBadge, CountryFlagWidget,
                               # BandFrequencySelector, TagSelector
  plugins/
    pota_hunter_plugin.dart    # Live POTA spots from pota.app
    sst_plugin.dart            # Saturday Speed Test contest logger
    pota_activator_plugin.dart # POTA park activation session logger
```

---

73 de QSOLog
