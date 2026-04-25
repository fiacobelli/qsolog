// lib/plugins/sst_plugin.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../widgets/common_widgets.dart';
import 'package:uuid/uuid.dart';

class SstPlugin extends StatefulWidget {
  const SstPlugin({super.key});

  @override
  State<SstPlugin> createState() => _SstPluginState();
}

class _SstPluginState extends State<SstPlugin> {
  final _callCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  late double _freq;
  late String _band;
  late String _mode;
  bool _lookingUp = false;
  int _count = 0;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Carry forward last used band/mode/freq
    final state = context.read<AppState>();
    _freq = state.lastFreq;
    _band = state.lastBand;
    _mode = state.lastMode;
  }

  @override
  void dispose() {
    _callCtrl.dispose();
    _nameCtrl.dispose();
    _stateCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _lookupCallsign(String call) async {
    if (call.length < 3) return;
    setState(() => _lookingUp = true);
    final state = context.read<AppState>();
    if (state.qrzSettings.username.isEmpty) {
      setState(() => _lookingUp = false);
      return;
    }
    final data = await state.qrzService.lookupCallsign(call, state.qrzSettings);
    if (mounted && data != null) {
      _nameCtrl.text = data.name ?? '';
      _stateCtrl.text = data.state ?? '';
    }
    if (mounted) setState(() => _lookingUp = false);
  }

  Future<void> _logAndClear() async {
    if (_callCtrl.text.trim().isEmpty) return;
    final state = context.read<AppState>();

    final qso = QsoEntry(
      id: const Uuid().v4(),
      callsign: _callCtrl.text.trim().toUpperCase(),
      band: _band,
      frequency: _freq,
      mode: _mode,
      rstSent: '599',
      rstReceived: '599',
      comments: 'SST - ${_nameCtrl.text} ${_stateCtrl.text}'.trim(),
      dateTime: DateTime.now().toUtc(),
      contactName: _nameCtrl.text.isNotEmpty ? _nameCtrl.text : null,
      contactState: _stateCtrl.text.isNotEmpty ? _stateCtrl.text : null,
      tags: ['SST'],
      adifFields: {
        if (_nameCtrl.text.isNotEmpty) 'SST_NAME': _nameCtrl.text,
        if (_stateCtrl.text.isNotEmpty) 'SST_STATE': _stateCtrl.text,
      },
    );
    await state.addQso(qso);
    if (mounted) {
      setState(() {
        _count++;
        _callCtrl.clear();
        _nameCtrl.clear();
        _stateCtrl.clear();
      });
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SST Logger'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('$_count QSOs', style: const TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.speed, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Slow Speed Contest — All QSOs tagged SST automatically',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Band / Freq / Mode
            BandFrequencySelector(
              initialFreq: _freq,
              initialBand: _band,
              initialMode: _mode,
              onChanged: (f, b, m) => setState(() {
                _freq = f;
                _band = b;
                _mode = m;
              }),
            ),
            const SizedBox(height: 20),

            // Callsign
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _callCtrl,
                    focusNode: _focusNode,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Callsign',
                      border: OutlineInputBorder(),
                      hintText: 'Enter callsign...',
                    ),
                    onSubmitted: (v) => _lookupCallsign(v),
                    onChanged: (v) {
                      if (v.length >= 4) {
                        Future.delayed(const Duration(milliseconds: 600), () {
                          if (_callCtrl.text == v) _lookupCallsign(v);
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                if (_lookingUp)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Name
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // State
            TextField(
              controller: _stateCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'State',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Log button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _logAndClear,
                icon: const Icon(Icons.check),
                label: const Text(
                  'Log QSO + Next',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
