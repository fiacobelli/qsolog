// lib/plugins/plugin_registry.dart
import 'package:flutter/material.dart';

class PluginInfo {
  final String id;
  final String label;
  final IconData icon;
  const PluginInfo({required this.id, required this.label, required this.icon});
}

/// Canonical list of all plugins known to the app, in their default order.
const List<PluginInfo> kPlugins = [
  PluginInfo(id: 'standard', label: 'Standard QSO', icon: Icons.radio),
  PluginInfo(id: 'pota_hunter', label: 'POTA Hunter', icon: Icons.park),
  PluginInfo(id: 'sst', label: 'SST', icon: Icons.speed),
  PluginInfo(id: 'cwt', label: 'CWT', icon: Icons.radio),
  PluginInfo(id: 'mst', label: 'MST', icon: Icons.swap_horiz),
  PluginInfo(id: 'pota_activator', label: 'POTA Activator', icon: Icons.hiking),
  PluginInfo(id: 'contest', label: 'Contest', icon: Icons.emoji_events),
];

PluginInfo? pluginById(String id) {
  try {
    return kPlugins.firstWhere((p) => p.id == id);
  } catch (_) {
    return null;
  }
}
