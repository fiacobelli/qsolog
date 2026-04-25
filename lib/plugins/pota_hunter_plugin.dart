// lib/plugins/pota_hunter_plugin.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/models.dart';
import '../services/app_state.dart';
import '../widgets/common_widgets.dart';

class PotaHunterPlugin extends StatefulWidget {
  const PotaHunterPlugin({super.key});

  @override
  State<PotaHunterPlugin> createState() => _PotaHunterPluginState();
}

class _PotaHunterPluginState extends State<PotaHunterPlugin> {
  List<PotaSpot> _spots = [];
  bool _loading = true;
  String? _error;
  String _modeFilter = 'All';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  // All known POTA modes — built from spots dynamically + common ones
  static const _allModesLabel = 'All';
  final _availableModes = <String>[_allModesLabel];

  @override
  void initState() {
    super.initState();
    _fetchSpots();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchSpots() async {
    setState(() { _loading = true; _error = null; });
    try {
      final resp = await http.get(Uri.parse('https://api.pota.app/spot/activator'));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        final spots = data.map((e) => PotaSpot.fromJson(e)).toList();

        // Collect unique modes from live data
        final modes = <String>{};
        for (final s in spots) {
          if (s.mode.isNotEmpty) modes.add(s.mode.toUpperCase());
        }
        final sortedModes = modes.toList()..sort();

        setState(() {
          _spots = spots;
          _loading = false;
          _availableModes
            ..clear()
            ..add(_allModesLabel)
            ..addAll(sortedModes);
          // Reset filter if previously selected mode no longer exists
          if (!_availableModes.contains(_modeFilter)) {
            _modeFilter = _allModesLabel;
          }
        });
      } else {
        setState(() { _error = 'Failed to load spots (${resp.statusCode})'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Network error: $e'; _loading = false; });
    }
  }

  List<PotaSpot> get _filtered {
    return _spots.where((s) {
      final modeOk = _modeFilter == _allModesLabel ||
          s.mode.toUpperCase() == _modeFilter;
      final q = _searchQuery.toLowerCase();
      final searchOk = q.isEmpty ||
          s.activatorCallsign.toLowerCase().contains(q) ||
          s.parkReference.toLowerCase().contains(q) ||
          s.parkName.toLowerCase().contains(q) ||
          s.state.toLowerCase().contains(q);
      return modeOk && searchOk;
    }).toList();
  }

  Color _modeColor(String mode) {
    switch (mode.toUpperCase()) {
      case 'SSB':   return Colors.blue.shade700;
      case 'CW':    return Colors.orange.shade700;
      case 'FT8':   return Colors.purple.shade700;
      case 'FT4':   return Colors.deepPurple.shade700;
      case 'FM':    return Colors.teal.shade700;
      case 'AM':    return Colors.brown.shade600;
      case 'RTTY':  return Colors.indigo.shade700;
      case 'JS8':   return Colors.cyan.shade700;
      default:      return Colors.green.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('POTA Hunter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchSpots,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search callsign, park, state...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        })
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // Mode filter chips
          if (!_loading && _error == null)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                children: _availableModes.map((mode) {
                  final isSelected = _modeFilter == mode;
                  final color = mode == _allModesLabel
                      ? Colors.green.shade700
                      : _modeColor(mode);
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(
                        mode,
                        style: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: color,
                      checkmarkColor: Colors.white,
                      onSelected: (_) => setState(() => _modeFilter = mode),
                    ),
                  );
                }).toList(),
              ),
            ),

          // Results count bar
          if (!_loading && _error == null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              child: Row(children: [
                Text(
                  '${filtered.length} spot${filtered.length != 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (_modeFilter != _allModesLabel) ...[
                  const SizedBox(width: 6),
                  Text('· mode: $_modeFilter',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
                if (_searchQuery.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text('· "$_searchQuery"',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
                const Spacer(),
                if (_modeFilter != _allModesLabel || _searchQuery.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() { _modeFilter = _allModesLabel; _searchQuery = ''; });
                    },
                    child: const Text('Clear filters', style: TextStyle(fontSize: 12)),
                  ),
              ]),
            ),

          // Spots list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(_error!, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _fetchSpots,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.park, size: 48, color: Colors.grey),
                                const SizedBox(height: 12),
                                Text(
                                  _spots.isEmpty
                                      ? 'No active POTA spots right now'
                                      : 'No spots match your filters',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                if (_modeFilter != _allModesLabel || _searchQuery.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() { _modeFilter = _allModesLabel; _searchQuery = ''; });
                                    },
                                    child: const Text('Clear filters'),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, i) => _SpotTile(
                              spot: filtered[i],
                              modeColor: _modeColor(filtered[i].mode),
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => _PotaContactForm(spot: filtered[i]))),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _SpotTile extends StatelessWidget {
  final PotaSpot spot;
  final Color modeColor;
  final VoidCallback onTap;

  const _SpotTile({required this.spot, required this.modeColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.park, color: Colors.white, size: 18),
      ),
      title: Row(
        children: [
          Text(spot.activatorCallsign,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8)),
            child: Text(spot.parkReference,
                style: TextStyle(fontSize: 11, color: Colors.green.shade900)),
          ),
          const Spacer(),
          // Mode badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
                color: modeColor,
                borderRadius: BorderRadius.circular(8)),
            child: Text(spot.mode.toUpperCase(),
                style: const TextStyle(fontSize: 11, color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(spot.parkName,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Row(children: [
            const Icon(Icons.radio, size: 12, color: Colors.grey),
            const SizedBox(width: 3),
            Text('${spot.frequency.toStringAsFixed(3)} MHz',
                style: const TextStyle(fontSize: 12)),
            if (spot.state.isNotEmpty) ...[
              const SizedBox(width: 8),
              const Icon(Icons.location_on, size: 12, color: Colors.grey),
              const SizedBox(width: 2),
              Text(spot.state,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
            if (spot.comments.isNotEmpty) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(spot.comments,
                    style: const TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ]),
        ],
      ),
      trailing: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          minimumSize: const Size(56, 34),
        ),
        child: const Text('Log'),
      ),
      isThreeLine: false,
    );
  }
}

class _PotaContactForm extends StatefulWidget {
  final PotaSpot spot;
  const _PotaContactForm({required this.spot});

  @override
  State<_PotaContactForm> createState() => _PotaContactFormState();
}

class _PotaContactFormState extends State<_PotaContactForm> {
  late TextEditingController _rstSentCtrl, _rstRcvdCtrl, _nameCtrl;
  late double _freq;
  late String _band, _mode;
  bool _logging = false;
  bool _lookingUpName = false;

  @override
  void initState() {
    super.initState();
    _rstSentCtrl = TextEditingController(text: '59');
    _rstRcvdCtrl = TextEditingController(text: '59');
    _nameCtrl = TextEditingController();
    _freq = widget.spot.frequency;
    _band = BandFrequency.bandFromFrequency(_freq);
    _mode = widget.spot.mode;
    // Auto-lookup the activator's name from QRZ
    WidgetsBinding.instance.addPostFrameCallback((_) => _lookupActivatorName());
  }

  Future<void> _lookupActivatorName() async {
    final state = context.read<AppState>();
    if (state.qrzSettings.username.isEmpty) return;
    setState(() => _lookingUpName = true);
    final data = await state.qrzService.lookupCallsign(
        widget.spot.activatorCallsign, state.qrzSettings);
    if (mounted && data?.name != null) {
      _nameCtrl.text = data!.name!;
    }
    if (mounted) setState(() => _lookingUpName = false);
  }

  @override
  void dispose() {
    _rstSentCtrl.dispose();
    _rstRcvdCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _log() async {
    setState(() => _logging = true);
    final state = context.read<AppState>();

    // Name already pre-filled from QRZ on init — no need to look up again
    final qso = QsoEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      callsign: widget.spot.activatorCallsign.toUpperCase(),
      band: _band,
      frequency: _freq,
      mode: _mode,
      rstSent: _rstSentCtrl.text,
      rstReceived: _rstRcvdCtrl.text,
      comments: 'POTA ${widget.spot.parkReference} — ${widget.spot.parkName}',
      dateTime: DateTime.now().toUtc(),
      contactName: _nameCtrl.text.isNotEmpty ? _nameCtrl.text : null,
      contactGrid: widget.spot.grid.isNotEmpty ? widget.spot.grid : null,
      contactState: widget.spot.state.isNotEmpty ? widget.spot.state : null,
      tags: ['POTA'],
      adifFields: {
        'POTA_REF': widget.spot.parkReference,
        'PARK_NAME': widget.spot.parkName,
      },
    );

    final added = await state.addQso(qso);
    if (mounted) {
      if (added) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Logged ${qso.callsign} — ${widget.spot.parkReference}')));
        Navigator.pop(context);
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Duplicate QSO — skipped')));
        setState(() => _logging = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Log POTA — ${widget.spot.activatorCallsign}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Park info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.park, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(widget.spot.parkName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold))),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(widget.spot.parkReference,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade900,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                          '${widget.spot.frequency.toStringAsFixed(3)} MHz',
                          style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.blue.shade700,
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(widget.spot.mode.toUpperCase(),
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ]),
                    if (widget.spot.state.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(widget.spot.state,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                    if (widget.spot.comments.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(widget.spot.comments,
                          style: const TextStyle(
                              fontSize: 12, fontStyle: FontStyle.italic)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Activator name — pre-filled from QRZ
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: "Activator's name",
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person),
                suffixIcon: _lookingUpName
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)))
                    : null,
                helperText: _lookingUpName ? 'Looking up from QRZ...' : null,
              ),
            ),
            const SizedBox(height: 12),

            // Freq / band / mode
            BandFrequencySelector(
              initialFreq: _freq,
              initialBand: _band,
              initialMode: _mode,
              onChanged: (f, b, m) =>
                  setState(() { _freq = f; _band = b; _mode = m; }),
            ),
            const SizedBox(height: 12),

            // RST
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _rstSentCtrl,
                  decoration: const InputDecoration(
                      labelText: 'RST sent',
                      border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _rstRcvdCtrl,
                  decoration: const InputDecoration(
                      labelText: 'RST rcvd',
                      border: OutlineInputBorder()),
                ),
              ),
            ]),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _logging ? null : _log,
                icon: _logging
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(_logging ? 'Logging...' : 'Log QSO'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
