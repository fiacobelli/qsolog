// lib/plugins/pota_hunter_plugin.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/models.dart';
import '../services/app_state.dart';
import '../widgets/common_widgets.dart';
import '../screens/add_qso_screen.dart';

class PotaHunterPlugin extends StatefulWidget {
  const PotaHunterPlugin({super.key});

  @override
  State<PotaHunterPlugin> createState() => _PotaHunterPluginState();
}

class _PotaHunterPluginState extends State<PotaHunterPlugin> {
  List<PotaSpot> _spots = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSpots();
  }

  Future<void> _fetchSpots() async {
    setState(() { _loading = true; _error = null; });
    try {
      final resp = await http.get(Uri.parse('https://api.pota.app/spot/activator'));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        setState(() {
          _spots = data.map((e) => PotaSpot.fromJson(e)).toList();
          _loading = false;
        });
      } else {
        setState(() { _error = 'Failed to load spots'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Network error: $e'; _loading = false; });
    }
  }

  void _logContact(PotaSpot spot) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PotaContactForm(spot: spot),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POTA Hunter'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchSpots, tooltip: 'Refresh'),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                    ElevatedButton(onPressed: _fetchSpots, child: const Text('Retry')),
                  ],
                ))
              : _spots.isEmpty
                  ? const Center(child: Text('No active POTA spots right now'))
                  : ListView.separated(
                      itemCount: _spots.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) => _SpotTile(spot: _spots[i], onTap: () => _logContact(_spots[i])),
                    ),
    );
  }
}

class _SpotTile extends StatelessWidget {
  final PotaSpot spot;
  final VoidCallback onTap;

  const _SpotTile({required this.spot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.park, color: Colors.white, size: 20),
      ),
      title: Row(
        children: [
          Text(spot.activatorCallsign, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(8)),
            child: Text(spot.parkReference, style: TextStyle(fontSize: 11, color: Colors.green.shade800)),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(spot.parkName, style: const TextStyle(fontSize: 12)),
          Row(
            children: [
              Text('${spot.frequency.toStringAsFixed(3)} MHz', style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 8),
              Text(spot.mode, style: const TextStyle(fontSize: 12)),
              if (spot.state.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(spot.state, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ],
          ),
          if (spot.comments.isNotEmpty)
            Text(spot.comments, style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
        ],
      ),
      trailing: ElevatedButton(
        onPressed: onTap,
        child: const Text('Log'),
      ),
      isThreeLine: true,
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

  @override
  void initState() {
    super.initState();
    _rstSentCtrl = TextEditingController(text: '59');
    _rstRcvdCtrl = TextEditingController(text: '59');
    _nameCtrl = TextEditingController();
    _freq = widget.spot.frequency;
    _band = BandFrequency.bandFromFrequency(_freq);
    _mode = widget.spot.mode;
  }

  @override
  void dispose() {
    _rstSentCtrl.dispose(); _rstRcvdCtrl.dispose(); _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _log() async {
    final state = context.read<AppState>();
    // Try QRZ lookup for the activator's name
    if (_nameCtrl.text.isEmpty && state.qrzSettings.username.isNotEmpty) {
      final data = await state.qrzService.lookupCallsign(widget.spot.activatorCallsign, state.qrzSettings);
      if (data?.name != null) _nameCtrl.text = data!.name!;
    }

    final dist = calculateDistance(
      state.station.lat, state.station.lon,
      null, null, // POTA spots don't always have coords
    );

    final qso = QsoEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      callsign: widget.spot.activatorCallsign.toUpperCase(),
      band: _band,
      frequency: _freq,
      mode: _mode,
      rstSent: _rstSentCtrl.text,
      rstReceived: _rstRcvdCtrl.text,
      comments: 'POTA ${widget.spot.parkReference} - ${widget.spot.parkName}',
      dateTime: DateTime.now().toUtc(),
      contactName: _nameCtrl.text.isNotEmpty ? _nameCtrl.text : null,
      contactGrid: widget.spot.grid.isNotEmpty ? widget.spot.grid : null,
      contactState: widget.spot.state.isNotEmpty ? widget.spot.state : null,
      tags: ['POTA'],
      adifFields: {
        'POTA_REF': widget.spot.parkReference,
        'PARK_NAME': widget.spot.parkName,
      },
      distanceKm: dist,
    );
    await state.addQso(qso);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logged ${qso.callsign} - ${widget.spot.parkReference}')));
      Navigator.pop(context);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Log POTA - ${widget.spot.activatorCallsign}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.park, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text(widget.spot.parkName, style: const TextStyle(fontWeight: FontWeight.bold))),
                    ]),
                    const SizedBox(height: 4),
                    Text(widget.spot.parkReference, style: const TextStyle(color: Colors.grey)),
                    Text('${widget.spot.frequency.toStringAsFixed(3)} MHz · ${widget.spot.mode}'),
                    if (widget.spot.state.isNotEmpty) Text(widget.spot.state),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: "Activator's Name", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            BandFrequencySelector(
              initialFreq: _freq,
              initialBand: _band,
              initialMode: _mode,
              onChanged: (f, b, m) => setState(() { _freq = f; _band = b; _mode = m; }),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextFormField(
                  controller: _rstSentCtrl,
                  decoration: const InputDecoration(labelText: 'RST Sent', border: OutlineInputBorder()),
                )),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(
                  controller: _rstRcvdCtrl,
                  decoration: const InputDecoration(labelText: 'RST Rcvd', border: OutlineInputBorder()),
                )),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _log,
                icon: const Icon(Icons.save),
                label: const Text('Log QSO'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
