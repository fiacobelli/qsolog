// lib/plugins/pota_activator_plugin.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../widgets/common_widgets.dart';

class PotaActivatorPlugin extends StatefulWidget {
  const PotaActivatorPlugin({super.key});

  @override
  State<PotaActivatorPlugin> createState() => _PotaActivatorPluginState();
}

class _PotaActivatorPluginState extends State<PotaActivatorPlugin> {
  // Park config (set once)
  final _parkCtrl = TextEditingController();
  final _parkNameCtrl = TextEditingController();
  double _freq = 14.225;
  String _band = '20m';
  String _mode = 'SSB';
  bool _parkConfigured = false;

  // Per-QSO fields
  final _callCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _rstSentCtrl = TextEditingController(text: '59');
  final _rstRcvdCtrl = TextEditingController(text: '59');
  final _focusNode = FocusNode();
  int _count = 0;
  bool _lookingUp = false;

  @override
  void dispose() {
    for (final c in [_parkCtrl, _parkNameCtrl, _callCtrl, _stateCtrl, _rstSentCtrl, _rstRcvdCtrl]) c.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _lookupContact(String call) async {
    if (call.length < 3) return;
    setState(() => _lookingUp = true);
    final state = context.read<AppState>();
    if (state.qrzSettings.username.isNotEmpty) {
      final data = await state.qrzService.lookupCallsign(call, state.qrzSettings);
      if (mounted && data != null) {
        _stateCtrl.text = data.state ?? _stateCtrl.text;
      }
    }
    setState(() => _lookingUp = false);
  }

  Future<void> _logQso() async {
    if (_callCtrl.text.trim().isEmpty) return;
    final state = context.read<AppState>();

    final qso = QsoEntry(
      id: const Uuid().v4(),
      callsign: _callCtrl.text.trim().toUpperCase(),
      band: _band,
      frequency: _freq,
      mode: _mode,
      rstSent: _rstSentCtrl.text,
      rstReceived: _rstRcvdCtrl.text,
      comments: 'POTA Activating ${_parkCtrl.text}',
      dateTime: DateTime.now().toUtc(),
      contactState: _stateCtrl.text.isNotEmpty ? _stateCtrl.text : null,
      tags: ['POTA'],
      adifFields: {
        'POTA_REF': _parkCtrl.text,
        'PARK_NAME': _parkNameCtrl.text,
        'MY_POTA_REF': _parkCtrl.text,
      },
    );
    await state.addQso(qso);
    setState(() {
      _count++;
      _callCtrl.clear();
      _stateCtrl.clear();
      _rstSentCtrl.text = '59';
      _rstRcvdCtrl.text = '59';
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POTA Activator'),
        actions: [
          if (_parkConfigured)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text(_parkCtrl.text, style: const TextStyle(color: Colors.white)),
                  backgroundColor: Colors.green.shade700,
                ),
              ),
            ),
          if (_parkConfigured)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text('$_count QSOs', style: const TextStyle(fontSize: 14)),
              ),
            ),
          if (_parkConfigured)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => setState(() => _parkConfigured = false),
              tooltip: 'Change park',
            ),
        ],
      ),
      body: _parkConfigured ? _buildLogForm() : _buildParkConfig(),
    );
  }

  Widget _buildParkConfig() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Configure Park', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Set these once for your activation session.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          TextField(
            controller: _parkCtrl,
            decoration: const InputDecoration(
              labelText: 'Park Reference (e.g. K-0001)',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _parkNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Park Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          BandFrequencySelector(
            initialFreq: _freq,
            initialBand: _band,
            initialMode: _mode,
            onChanged: (f, b, m) => setState(() { _freq = f; _band = b; _mode = m; }),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _parkCtrl.text.isNotEmpty
                  ? () => setState(() => _parkConfigured = true)
                  : null,
              icon: const Icon(Icons.hiking),
              label: const Text('Start Activation'),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: const Text(
              'All QSOs in this session will be tagged POTA with your park reference. '
              'You can change frequency/mode during the activation without resetting.',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick freq/mode change
          BandFrequencySelector(
            initialFreq: _freq,
            initialBand: _band,
            initialMode: _mode,
            onChanged: (f, b, m) => setState(() { _freq = f; _band = b; _mode = m; }),
          ),
          const SizedBox(height: 16),

          // Callsign
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _callCtrl,
                  focusNode: _focusNode,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Callsign',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (v) => _lookupContact(v),
                  onChanged: (v) {
                    if (v.length >= 4) {
                      Future.delayed(const Duration(milliseconds: 600), () {
                        if (_callCtrl.text == v) _lookupContact(v);
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              if (_lookingUp)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // State
          TextField(
            controller: _stateCtrl,
            decoration: const InputDecoration(
              labelText: 'Hunter State',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 12),

          // RST
          Row(
            children: [
              Expanded(child: TextField(
                controller: _rstSentCtrl,
                decoration: const InputDecoration(labelText: 'RST Sent', border: OutlineInputBorder()),
              )),
              const SizedBox(width: 12),
              Expanded(child: TextField(
                controller: _rstRcvdCtrl,
                decoration: const InputDecoration(labelText: 'RST Rcvd', border: OutlineInputBorder()),
              )),
            ],
          ),
          const Spacer(),

          // Log button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _logQso,
              icon: const Icon(Icons.add),
              label: Text('Log Contact #${_count + 1}', style: const TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
