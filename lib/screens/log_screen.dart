// lib/screens/log_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import '../models/models.dart';
import '../services/app_state.dart';
import '../services/adif_service.dart';
import '../widgets/common_widgets.dart';
import 'add_qso_screen.dart';
import 'settings_screen.dart';
import 'tags_screen.dart';
import 'stats_screen.dart';
import 'map_screen.dart';
import '../plugins/pota_hunter_plugin.dart';
import '../plugins/sst_plugin.dart';
import '../plugins/pota_activator_plugin.dart';

const _plugins = [
  {'id': 'standard',       'label': 'Standard QSO',   'icon': Icons.radio},
  {'id': 'pota_hunter',    'label': 'POTA Hunter',    'icon': Icons.park},
  {'id': 'sst',            'label': 'SST',            'icon': Icons.speed},
  {'id': 'pota_activator', 'label': 'POTA Activator', 'icon': Icons.hiking},
];

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});
  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  final _searchCtrl = TextEditingController();
  late Timer _clockTimer;
  DateTime _utcNow = DateTime.now().toUtc();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _utcNow = DateTime.now().toUtc());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _clockTimer.cancel();
    super.dispose();
  }

  void _openActivePlugin(BuildContext context) {
    final plugin = context.read<AppState>().activePlugin;
    Widget screen;
    switch (plugin) {
      case 'pota_hunter':    screen = const PotaHunterPlugin(); break;
      case 'sst':            screen = const SstPlugin(); break;
      case 'pota_activator': screen = const PotaActivatorPlugin(); break;
      default:               screen = const AddQsoScreen(); break;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _exportAdif(BuildContext context) async {
    final state = context.read<AppState>();
    final content = AdifService.exportQsos(state.exportList, state.station, rig: state.activeRig);
    if (kIsWeb) {
      await showDialog(context: context, builder: (_) => AlertDialog(
        title: const Text('ADIF Export'),
        content: SizedBox(width: 500, height: 400,
            child: SingleChildScrollView(child: SelectableText(content))),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ));
      return;
    }
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save ADIF',
      fileName: 'hamlog_${DateFormat('yyyyMMdd').format(DateTime.now())}.adi',
      type: FileType.custom,
      allowedExtensions: ['adi', 'adif'],
    );
    if (path != null) {
      await File(path).writeAsString(content);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported ${state.exportList.length} QSOs to $path')));
    }
  }

  Future<void> _importAdif(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['adi', 'adif'], withData: true);
    if (result == null || result.files.isEmpty) return;

    String content;
    try {
      // Always read as raw bytes first so we control the decoding
      late Uint8List bytes;
      if (kIsWeb) {
        bytes = result.files.first.bytes!;
      } else {
        bytes = await File(result.files.first.path!).readAsBytes();
      }
      // Try UTF-8 first; fall back to Latin-1 (covers ISO-8859-1 and Windows-1252)
      // Most ham radio logging software writes Latin-1
      try {
        content = utf8.decode(bytes);
      } catch (_) {
        content = latin1.decode(bytes);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to read file: $e')));
      }
      return;
    }

    final qsos = AdifService.importAdif(content);
    final state = context.read<AppState>();
    int imported = 0, skipped = 0;
    for (final q in qsos) {
      final added = await state.addQso(q);
      if (added) imported++; else skipped++;
    }
    if (context.mounted) {
      final msg = skipped > 0
          ? 'Imported $imported QSOs, skipped $skipped duplicates'
          : 'Imported $imported QSOs';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _uploadToQrz(BuildContext context) async {
    final state = context.read<AppState>();
    if (state.qrzSettings.username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configure QRZ credentials in Settings first')));
      return;
    }
    final content = AdifService.exportQsos(state.exportList, state.station, rig: state.activeRig);
    final ok = await state.qrzService.uploadAdif(content, state.qrzSettings);
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Uploaded to QRZ successfully!' : 'QRZ upload failed. Check API key.')));
  }

  void _showSelectByTag(BuildContext context) {
    final state = context.read<AppState>();
    showDialog(context: context, builder: (_) => SimpleDialog(
      title: const Text('Select QSOs by tag'),
      children: state.tags.map((t) => SimpleDialogOption(
        child: Text(t.name),
        onPressed: () { Navigator.pop(context); state.selectByTag(t.name); },
      )).toList(),
    ));
  }

  Future<void> _deleteSelected(BuildContext context) async {
    final state = context.read<AppState>();
    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: Text('Delete ${state.selectedIds.length} QSOs?'),
      content: const Text('This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
      ],
    ));
    if (confirm == true) {
      final ids = List.from(state.selectedIds);
      for (final id in ids) await state.deleteQso(id as String);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final qsos = state.filteredQsos;
    final hasSelection = state.selectedIds.isNotEmpty;
    final activePluginInfo = _plugins.firstWhere(
        (p) => p['id'] == state.activePlugin, orElse: () => _plugins.first);

    return Scaffold(
      appBar: AppBar(
        title: hasSelection
            ? Text('${state.selectedIds.length} selected')
            : _UtcClockTitle(utcNow: _utcNow),
        leading: hasSelection ? IconButton(icon: const Icon(Icons.close), onPressed: state.clearSelection) : null,
        actions: [
          if (hasSelection) ...[
            IconButton(icon: const Icon(Icons.upload), tooltip: 'Upload to QRZ', onPressed: () => _uploadToQrz(context)),
            IconButton(icon: const Icon(Icons.download), tooltip: 'Export ADIF', onPressed: () => _exportAdif(context)),
            PopupMenuButton(itemBuilder: (_) => [
              PopupMenuItem(child: const Text('Select by tag...'), onTap: () => _showSelectByTag(context)),
              PopupMenuItem(child: const Text('Delete selected'), onTap: () => _deleteSelected(context)),
            ]),
          ] else ...[
            IconButton(icon: const Icon(Icons.download), tooltip: 'Export ADIF', onPressed: () => _exportAdif(context)),
            IconButton(icon: const Icon(Icons.upload_file), tooltip: 'Import ADIF', onPressed: () => _importAdif(context)),
            IconButton(icon: const Icon(Icons.cloud_upload), tooltip: 'Upload to QRZ', onPressed: () => _uploadToQrz(context)),
            PopupMenuButton(itemBuilder: (_) => [
              PopupMenuItem(child: const Text('Settings'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
              PopupMenuItem(child: const Text('Manage Tags'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TagsScreen()))),
              PopupMenuItem(child: const Text('Statistics'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen()))),
              PopupMenuItem(child: const Text('Map'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen()))),
              PopupMenuItem(child: const Text('Select by tag...'), onTap: () => _showSelectByTag(context)),
            ]),
          ],
        ],
        bottom: null,
      ),
      body: Column(
        children: [
          // Plugin selector bar
          Container(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(children: _plugins.map((p) {
                final isActive = p['id'] == state.activePlugin;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    avatar: Icon(p['icon'] as IconData, size: 16,
                        color: isActive ? Theme.of(context).colorScheme.onPrimary : null),
                    label: Text(p['label'] as String),
                    selected: isActive,
                    selectedColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isActive ? Theme.of(context).colorScheme.onPrimary : null,
                      fontSize: 12,
                    ),
                    onSelected: (_) => state.setActivePlugin(p['id'] as String),
                  ),
                );
              }).toList()),
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search or use after:YYYY-MM-DD  band:20m  mode:SSB',
                hintStyle: const TextStyle(fontSize: 12),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear),
                        onPressed: () { _searchCtrl.clear(); state.setSearch(''); })
                    : null,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onChanged: state.setSearch,
            ),
          ),
          // Active operator badges — only shown when operators are in use
          if (state.activeSearchOperators.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
              child: Wrap(
                spacing: 6,
                children: state.activeSearchOperators.entries.map((e) {
                  return Chip(
                    label: Text('${e.key}: ${e.value}',
                        style: const TextStyle(fontSize: 11, color: Colors.white)),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white70),
                    onDeleted: () {
                      final updated = _searchCtrl.text
                          .replaceAll(RegExp('${e.key}:${e.value}',
                              caseSensitive: false), '')
                          .trim();
                      _searchCtrl.text = updated;
                      state.setSearch(updated);
                    },
                  );
                }).toList(),
              ),
            ),
          // Tag filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
            child: Row(children: [
              FilterChip(label: const Text('All'), selected: state.filterTag == null,
                  onSelected: (_) => state.setFilterTag(null)),
              const SizedBox(width: 6),
              ...state.tags.map((t) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text(t.name),
                  selected: state.filterTag == t.name,
                  onSelected: (_) => state.setFilterTag(
                      state.filterTag == t.name ? null : t.name),
                ),
              )),
            ]),
          ),
          // QSO list
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : qsos.isEmpty
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.radio, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('No QSOs logged yet', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        const Text('Tap + to log your first contact'),
                      ]))
                    : ListView.separated(
                        itemCount: qsos.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) => _QsoTile(qso: qsos[i]),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openActivePlugin(context),
        icon: Icon(activePluginInfo['icon'] as IconData),
        label: Text(activePluginInfo['label'] as String),
      ),
    );
  }
}

class _QsoTile extends StatelessWidget {
  final QsoEntry qso;
  const _QsoTile({required this.qso});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isSelected = state.selectedIds.contains(qso.id);
    // Shorter date format to save horizontal space on small screens
    final dt = DateFormat('MM-dd HH:mm').format(qso.dateTime.toUtc());

    // Build location string: combine QTH, state, country sensibly
    final locationParts = <String>[];
    if (qso.contactQth != null && qso.contactQth!.isNotEmpty) locationParts.add(qso.contactQth!);
    if (qso.contactState != null && qso.contactState!.isNotEmpty &&
        !(qso.contactQth?.contains(qso.contactState!) ?? false)) {
      locationParts.add(qso.contactState!);
    }
    if (qso.contactCountry != null && qso.contactCountry!.isNotEmpty &&
        !(qso.contactQth?.contains(qso.contactCountry!) ?? false)) {
      locationParts.add(qso.contactCountry!);
    }
    final locationStr = locationParts.join(', ');

    return InkWell(
      onTap: () {
        if (state.selectedIds.isNotEmpty) {
          state.toggleSelection(qso.id);
        } else {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => AddQsoScreen(existing: qso)));
        }
      },
      onLongPress: () => state.toggleSelection(qso.id),
      child: Container(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.selectedIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8, top: 2),
                child: Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 20,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey),
              ),
            // Country flag
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 2),
              child: CountryFlagWidget(country: qso.contactCountry),
            ),
            // Main content — takes all remaining space
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Callsign + band + mode — use Flexible so badges wrap
                  // if the callsign is long
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    runSpacing: 2,
                    children: [
                      Text(qso.callsign,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .secondaryContainer,
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(qso.band,
                            style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .tertiaryContainer,
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(qso.mode,
                            style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onTertiaryContainer)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Contact name
                  if (qso.contactName != null && qso.contactName!.isNotEmpty)
                    Text(qso.contactName!,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                  // Location + distance
                  if (locationStr.isNotEmpty || qso.distanceKm != null)
                    Row(children: [
                      if (locationStr.isNotEmpty)
                        Expanded(
                          child: Text(locationStr,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600),
                              overflow: TextOverflow.ellipsis),
                        ),
                      DistanceBadge(km: qso.distanceKm),
                    ]),
                  // Tags
                  if (qso.tags.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: qso.tags
                            .map((t) => TagChip(tagName: t))
                            .toList()),
                  ],
                ],
              ),
            ),
            // Right column — fixed width so it never causes overflow
            SizedBox(
              width: 88,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$dt Z',
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade600)),
                  const SizedBox(height: 2),
                  Text('${qso.frequency.toStringAsFixed(3)}',
                      style: const TextStyle(fontSize: 10)),
                  Text('${qso.rstSent}/${qso.rstReceived}',
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UtcClockTitle extends StatelessWidget {
  final DateTime utcNow;
  const _UtcClockTitle({required this.utcNow});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm:ss').format(utcNow);
    final dateStr = DateFormat('yyyy-MM-dd').format(utcNow);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('QSOLog', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.access_time, size: 12, color: Colors.white70),
            const SizedBox(width: 3),
            Text(
              '$timeStr UTC  ·  $dateStr',
              style: const TextStyle(fontSize: 11, color: Colors.white70, letterSpacing: 0.3),
            ),
          ],
        ),
      ],
    );
  }
}
