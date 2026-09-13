// lib/services/app_state.dart
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../plugins/plugin_registry.dart';
import 'database_service.dart';
import 'settings_service.dart';
import 'qrz_service.dart';

class AppState extends ChangeNotifier {
  List<QsoEntry> qsos = [];
  List<QsoEntry> filteredQsos = [];
  List<TagDefinition> tags = [];
  List<RigDefinition> rigs = [];
  StationSettings station = StationSettings();
  QrzSettings qrzSettings = QrzSettings();
  Set<String> selectedIds = {};
  String searchQuery = '';
  String? filterTag;
  bool isLoading = false;
  String activePlugin = 'standard';
  String distanceUnit = 'km'; // 'km' or 'mi'
  int mapQsoCount = 10;
  String appTheme = 'default';
  List<CustomLink> customLinks = [];
  List<String> pluginOrder = kPlugins.map((p) => p.id).toList();
  Set<String> visiblePluginIds = kPlugins.map((p) => p.id).toSet();
  String contestName = '';
  String contestTxExchange = '';
  final QrzService qrzService = QrzService();

  /// All known plugins, in the user's chosen order.
  List<PluginInfo> get orderedPlugins =>
      pluginOrder.map(pluginById).whereType<PluginInfo>().toList();

  /// Plugins the user has chosen to show on the main screen, in order.
  List<PluginInfo> get visiblePlugins =>
      orderedPlugins.where((p) => visiblePluginIds.contains(p.id)).toList();

  Future<void> savePluginSettings(List<String> order, Set<String> visible) async {
    pluginOrder = List.from(order);
    visiblePluginIds = Set.from(visible);
    await SettingsService.savePluginOrder(pluginOrder);
    await SettingsService.saveVisiblePlugins(visiblePluginIds.toList());
    notifyListeners();
  }

  Future<void> saveContestName(String name) async {
    contestName = name;
    await SettingsService.saveContestName(name);
    notifyListeners();
  }

  Future<void> saveContestTxExchange(String exchange) async {
    contestTxExchange = exchange;
    await SettingsService.saveContestTxExchange(exchange);
    notifyListeners();
  }

  // Last used band/mode/freq — carried forward to new QSOs
  String lastBand = '20m';
  String lastMode = 'SSB';
  double lastFreq = 14.225;

  Future<void> initialize() async {
    isLoading = true;
    notifyListeners();
    station = await SettingsService.loadStation();
    qrzSettings = await SettingsService.loadQrz();
    tags = await SettingsService.loadTags();
    rigs = await SettingsService.loadRigs();
    activePlugin = await SettingsService.loadActivePlugin();
    distanceUnit = await SettingsService.loadDistanceUnit();
    mapQsoCount = await SettingsService.loadMapQsoCount();
    appTheme = await SettingsService.loadAppTheme();
    customLinks = await SettingsService.loadLinks();
    final allIds = kPlugins.map((p) => p.id).toList();
    final savedOrder = await SettingsService.loadPluginOrder();
    if (savedOrder != null) {
      final valid = savedOrder.where(allIds.contains).toList();
      final missing = allIds.where((id) => !valid.contains(id));
      pluginOrder = [...valid, ...missing];
    }
    final savedVisible = await SettingsService.loadVisiblePlugins();
    if (savedVisible != null) {
      visiblePluginIds = savedVisible.where(allIds.contains).toSet();
    }
    contestName = await SettingsService.loadContestName();
    contestTxExchange = await SettingsService.loadContestTxExchange();
    await loadQsos();
    // Seed last band/mode/freq from most recent QSO
    if (qsos.isNotEmpty) {
      lastBand = qsos.first.band;
      lastMode = qsos.first.mode;
      lastFreq = qsos.first.frequency;
    }
    isLoading = false;
    notifyListeners();
  }

  /// Formats a distance in km according to the user's preferred unit
  String formatDistance(double km) {
    if (distanceUnit == 'mi') {
      final miles = km * 0.621371;
      return miles >= 1000
          ? '${(miles / 1000).toStringAsFixed(1)}k mi'
          : '${miles.toStringAsFixed(0)} mi';
    }
    return km >= 1000
        ? '${(km / 1000).toStringAsFixed(1)}k km'
        : '${km.toStringAsFixed(0)} km';
  }

  Future<void> setDistanceUnit(String unit) async {
    distanceUnit = unit;
    await SettingsService.saveDistanceUnit(unit);
    notifyListeners();
  }

  Future<void> setMapQsoCount(int count) async {
    mapQsoCount = count;
    await SettingsService.saveMapQsoCount(count);
    notifyListeners();
  }

  Future<void> setAppTheme(String theme) async {
    appTheme = theme;
    await SettingsService.saveAppTheme(theme);
    notifyListeners();
  }

  Future<void> saveCustomLinks(List<CustomLink> links) async {
    customLinks = List.from(links);
    await SettingsService.saveLinks(links);
    notifyListeners();
  }

  Future<void> loadQsos() async {
    qsos = await DatabaseService.getAllQsos();
    _applyFilter();
    notifyListeners();
  }

  /// Collapses "N days ago" / "N day ago" into a single token "daysago:N"
  /// so the per-token parser can handle it without look-ahead.
  static String _preprocessQuery(String q) => q.replaceAllMapped(
    RegExp(r'(\d+)\s+days?\s+ago', caseSensitive: false),
    (m) => 'daysago:${m.group(1)}',
  );

  /// Parses a date string that may be YYYY-MM-DD or MM-DD (assumes current year).
  static DateTime? _parseSearchDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt != null) return dt;
    final parts = raw.split('-');
    if (parts.length == 2) {
      final month = int.tryParse(parts[0]);
      final day = int.tryParse(parts[1]);
      if (month != null && day != null) {
        return DateTime.utc(DateTime.now().year, month, day);
      }
    }
    return null;
  }

  void _applyFilter() {
    var result = qsos;

    // Parse special operators out of the search query.
    // Supported: today  yesterday  N days ago
    //            after:/since:  before:  (YYYY-MM-DD or MM-DD)
    //            band:20m  mode:SSB
    // Everything else is a plain text search.
    DateTime? afterDate;
    DateTime? beforeDate;
    String? bandFilter;
    String? modeFilter;
    final plainTerms = <String>[];

    if (searchQuery.isNotEmpty) {
      for (final token in _preprocessQuery(searchQuery).trim().split(RegExp(r'\s+'))) {
        final lower = token.toLowerCase();
        if (lower == 'today') {
          final now = DateTime.now().toUtc();
          afterDate = DateTime.utc(now.year, now.month, now.day);
          beforeDate = afterDate.add(const Duration(days: 1));
        } else if (lower == 'yesterday') {
          final now = DateTime.now().toUtc();
          final yesterday = DateTime.utc(now.year, now.month, now.day)
              .subtract(const Duration(days: 1));
          afterDate = yesterday;
          beforeDate = yesterday.add(const Duration(days: 1));
        } else if (lower.startsWith('daysago:')) {
          final n = int.tryParse(token.substring(8));
          if (n != null) {
            final now = DateTime.now().toUtc();
            final target = DateTime.utc(now.year, now.month, now.day)
                .subtract(Duration(days: n));
            afterDate = target;
            beforeDate = target.add(const Duration(days: 1));
          }
        } else if (lower.startsWith('after:') || lower.startsWith('since:')) {
          afterDate = _parseSearchDate(token.substring(6));
        } else if (lower.startsWith('before:')) {
          beforeDate = _parseSearchDate(token.substring(7));
          if (beforeDate != null) {
            beforeDate = beforeDate.add(const Duration(days: 1));
          }
        } else if (lower.startsWith('band:')) {
          bandFilter = token.substring(5).toLowerCase();
        } else if (lower.startsWith('mode:')) {
          modeFilter = token.substring(5).toLowerCase();
        } else if (token.isNotEmpty) {
          plainTerms.add(lower);
        }
      }
    }

    // Plain text search across callsign, name, QTH, country, comments
    if (plainTerms.isNotEmpty) {
      result = result.where((e) {
        return plainTerms.every((term) =>
          e.callsign.toLowerCase().contains(term) ||
          (e.contactName?.toLowerCase().contains(term) ?? false) ||
          (e.contactQth?.toLowerCase().contains(term) ?? false) ||
          (e.contactCountry?.toLowerCase().contains(term) ?? false) ||
          (e.contactState?.toLowerCase().contains(term) ?? false) ||
          (e.comments.toLowerCase().contains(term)));
      }).toList();
    }

    // Date filters
    if (afterDate != null) {
      result = result
          .where((e) => e.dateTime.toUtc().isAfter(afterDate!))
          .toList();
    }
    if (beforeDate != null) {
      result = result
          .where((e) => e.dateTime.toUtc().isBefore(beforeDate!))
          .toList();
    }

    // Band filter
    if (bandFilter != null) {
      result = result
          .where((e) => e.band.toLowerCase() == bandFilter)
          .toList();
    }

    // Mode filter
    if (modeFilter != null) {
      result = result
          .where((e) => e.mode.toLowerCase() == modeFilter)
          .toList();
    }

    // Tag filter
    if (filterTag != null) {
      result = result.where((e) => e.tags.contains(filterTag)).toList();
    }

    filteredQsos = result;
  }

  /// Returns any active date/band/mode operators parsed from the search query,
  /// used by the UI to show filter indicator badges.
  Map<String, String> get activeSearchOperators {
    final ops = <String, String>{};
    if (searchQuery.isEmpty) return ops;
    for (final token in _preprocessQuery(searchQuery).trim().split(RegExp(r'\s+'))) {
      final lower = token.toLowerCase();
      if (lower == 'today') {
        ops['today'] = 'today';
      } else if (lower == 'yesterday') {
        ops['yesterday'] = 'yesterday';
      } else if (lower.startsWith('daysago:')) {
        ops['daysago'] = token.substring(8);
      } else if (lower.startsWith('since:')) {
        ops['since'] = token.substring(6);
      } else if (lower.startsWith('after:') || lower.startsWith('before:') ||
          lower.startsWith('band:') || lower.startsWith('mode:')) {
        final colon = token.indexOf(':');
        ops[token.substring(0, colon).toLowerCase()] = token.substring(colon + 1);
      }
    }
    return ops;
  }

  void setSearch(String q) {
    searchQuery = q;
    _applyFilter();
    notifyListeners();
  }

  void setFilterTag(String? tag) {
    filterTag = tag;
    _applyFilter();
    notifyListeners();
  }

  void toggleSelection(String id) {
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
    } else {
      selectedIds.add(id);
    }
    notifyListeners();
  }

  void selectByTag(String tag) {
    selectedIds = qsos
        .where((q) => q.tags.contains(tag))
        .map((q) => q.id)
        .toSet();
    notifyListeners();
  }

  void clearSelection() {
    selectedIds.clear();
    notifyListeners();
  }

  /// Stamps my station info onto the QSO if not already present, then inserts.
  /// Returns false if the QSO was skipped as a duplicate.
  Future<bool> addQso(QsoEntry qso) async {
    final dup = await DatabaseService.isDuplicate(qso);
    if (dup) return false;

    // Stamp my station fields from current settings if not already set
    final rig = activeRig;
    final stamped = QsoEntry(
      id: qso.id,
      callsign: qso.callsign,
      band: qso.band,
      frequency: qso.frequency,
      mode: qso.mode,
      rstSent: qso.rstSent,
      rstReceived: qso.rstReceived,
      comments: qso.comments,
      dateTime: qso.dateTime,
      contactName: qso.contactName,
      contactQth: qso.contactQth,
      contactGrid: qso.contactGrid,
      contactCountry: qso.contactCountry,
      contactState: qso.contactState,
      contactLat: qso.contactLat,
      contactLon: qso.contactLon,
      myCallsign: qso.myCallsign?.isNotEmpty == true
          ? qso.myCallsign
          : station.callsign.isNotEmpty ? station.callsign : null,
      myQth: qso.myQth?.isNotEmpty == true
          ? qso.myQth
          : station.qth.isNotEmpty ? station.qth : null,
      myGrid: qso.myGrid?.isNotEmpty == true
          ? qso.myGrid
          : station.grid.isNotEmpty ? station.grid : null,
      myRig: qso.myRig?.isNotEmpty == true
          ? qso.myRig
          : rig?.name,
      myPower: qso.myPower ?? rig?.power,
      tags: qso.tags,
      adifFields: qso.adifFields,
      distanceKm: qso.distanceKm ?? _calcDistance(qso),
      uploadedToQrz: qso.uploadedToQrz,
    );

    await DatabaseService.insertQso(stamped);
    // Remember band/mode/freq for the next QSO
    lastBand = stamped.band;
    lastMode = stamped.mode;
    lastFreq = stamped.frequency;
    await loadQsos();
    return true;
  }

  double? _calcDistance(QsoEntry qso) {
    if (station.lat == null || station.lon == null) return null;
    if (qso.contactLat == null || qso.contactLon == null) return null;
    const R = 6371.0;
    final dLat = _deg2rad(qso.contactLat! - station.lat!);
    final dLon = _deg2rad(qso.contactLon! - station.lon!);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(station.lat!)) * cos(_deg2rad(qso.contactLat!)) *
        sin(dLon / 2) * sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _deg2rad(double deg) => deg * 3.141592653589793 / 180;

  Future<void> updateQso(QsoEntry qso) async {
    await DatabaseService.updateQso(qso);
    await loadQsos();
  }

  Future<void> deleteQso(String id) async {
    await DatabaseService.deleteQso(id);
    selectedIds.remove(id);
    await loadQsos();
  }

  Future<void> saveStation(StationSettings s) async {
    station = s;
    await SettingsService.saveStation(s);
    notifyListeners();
  }

  Future<void> saveQrz(QrzSettings s) async {
    qrzSettings = s;
    await SettingsService.saveQrz(s);
    notifyListeners();
  }

  Future<void> saveTags(List<TagDefinition> t) async {
    tags = t;
    await SettingsService.saveTags(t);
    notifyListeners();
  }

  Future<void> saveRigs(List<RigDefinition> r) async {
    rigs = r;
    await SettingsService.saveRigs(r);
    notifyListeners();
  }

  Future<void> setActiveRig(String rigId) async {
    station = StationSettings(
      callsign: station.callsign,
      operatorName: station.operatorName,
      qth: station.qth,
      lat: station.lat,
      lon: station.lon,
      grid: station.grid,
      activeRigId: rigId,
    );
    await SettingsService.saveStation(station);
    notifyListeners();
  }

  Future<void> setActivePlugin(String plugin) async {
    activePlugin = plugin;
    await SettingsService.saveActivePlugin(plugin);
    notifyListeners();
  }

  RigDefinition? get activeRig {
    try {
      return rigs.firstWhere((r) => r.id == station.activeRigId);
    } catch (_) {
      return rigs.isNotEmpty ? rigs.first : null;
    }
  }

  List<QsoEntry> get selectedQsos =>
      qsos.where((q) => selectedIds.contains(q.id)).toList();

  List<QsoEntry> get exportList =>
      selectedIds.isEmpty ? filteredQsos : selectedQsos;

  TagDefinition? tagById(String name) {
    try {
      return tags.firstWhere((t) => t.name == name);
    } catch (_) {
      return null;
    }
  }
}
