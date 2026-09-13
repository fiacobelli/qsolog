// lib/services/settings_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'package:uuid/uuid.dart';

class SettingsService {
  static const _stationKey = 'station_settings';
  static const _qrzKey = 'qrz_settings';
  static const _tagsKey = 'tag_definitions';
  static const _rigsKey = 'rig_definitions';
  static const _activePluginKey = 'active_plugin';
  static const _distanceUnitKey = 'distance_unit';
  static const _mapQsoCountKey = 'map_qso_count';
  static const _appThemeKey = 'app_theme';
  static const _linksKey = 'custom_links';
  static const _pluginOrderKey = 'plugin_order';
  static const _visiblePluginsKey = 'visible_plugins';
  static const _contestNameKey = 'contest_name';
  static const _contestTxExchangeKey = 'contest_tx_exchange';

  static Future<StationSettings> loadStation() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_stationKey);
    if (json == null) return StationSettings();
    return StationSettings.fromJson(jsonDecode(json));
  }

  static Future<void> saveStation(StationSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stationKey, jsonEncode(s.toJson()));
  }

  static Future<QrzSettings> loadQrz() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_qrzKey);
    if (json == null) return QrzSettings();
    return QrzSettings.fromJson(jsonDecode(json));
  }

  static Future<void> saveQrz(QrzSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_qrzKey, jsonEncode(s.toJson()));
  }

  static Future<List<TagDefinition>> loadTags() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_tagsKey);
    if (json == null) {
      return [
        TagDefinition(id: const Uuid().v4(), name: 'POTA', color: '#4CAF50'),
        TagDefinition(id: const Uuid().v4(), name: 'SOTA', color: '#FF9800'),
        TagDefinition(id: const Uuid().v4(), name: 'Buddy', color: '#9C27B0'),
        TagDefinition(id: const Uuid().v4(), name: 'SST', color: '#F44336'),
        TagDefinition(id: const Uuid().v4(), name: 'Contest', color: '#2196F3'),
      ];
    }
    final list = jsonDecode(json) as List;
    return list.map((e) => TagDefinition.fromJson(e)).toList();
  }

  static Future<void> saveTags(List<TagDefinition> tags) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tagsKey, jsonEncode(tags.map((t) => t.toJson()).toList()));
  }

  static Future<List<RigDefinition>> loadRigs() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_rigsKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => RigDefinition.fromJson(e)).toList();
  }

  static Future<void> saveRigs(List<RigDefinition> rigs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rigsKey, jsonEncode(rigs.map((r) => r.toJson()).toList()));
  }

  static Future<String> loadActivePlugin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activePluginKey) ?? 'standard';
  }

  static Future<void> saveActivePlugin(String plugin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activePluginKey, plugin);
  }

  static Future<String> loadDistanceUnit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_distanceUnitKey) ?? 'km';
  }

  static Future<void> saveDistanceUnit(String unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_distanceUnitKey, unit);
  }

  static Future<int> loadMapQsoCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_mapQsoCountKey) ?? 10;
  }

  static Future<void> saveMapQsoCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_mapQsoCountKey, count);
  }

  static Future<String> loadAppTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_appThemeKey) ?? 'default';
  }

  static Future<void> saveAppTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appThemeKey, theme);
  }

  static Future<List<CustomLink>> loadLinks() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_linksKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => CustomLink.fromJson(e)).toList();
  }

  static Future<void> saveLinks(List<CustomLink> links) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_linksKey, jsonEncode(links.map((l) => l.toJson()).toList()));
  }

  static Future<List<String>?> loadPluginOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_pluginOrderKey);
    if (json == null) return null;
    return (jsonDecode(json) as List).map((e) => e.toString()).toList();
  }

  static Future<void> savePluginOrder(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pluginOrderKey, jsonEncode(ids));
  }

  static Future<List<String>?> loadVisiblePlugins() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_visiblePluginsKey);
    if (json == null) return null;
    return (jsonDecode(json) as List).map((e) => e.toString()).toList();
  }

  static Future<void> saveVisiblePlugins(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_visiblePluginsKey, jsonEncode(ids));
  }

  static Future<String> loadContestName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_contestNameKey) ?? '';
  }

  static Future<void> saveContestName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_contestNameKey, name);
  }

  static Future<String> loadContestTxExchange() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_contestTxExchangeKey) ?? '';
  }

  static Future<void> saveContestTxExchange(String exchange) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_contestTxExchangeKey, exchange);
  }
}
