// lib/plugins/mst_plugin.dart
// ICWC Medium Speed Test (MST)
// Exchange: operator name + serial number (given and received)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../widgets/common_widgets.dart';
import 'package:uuid/uuid.dart';

class MstPlugin extends StatefulWidget {
  const MstPlugin({super.key});

  @override
  State<MstPlugin> createState() => _MstPluginState();
}

class _MstPluginState extends State<MstPlugin> {
  final _callCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _serialRcvdCtrl = TextEditingController();
  late double _freq;
  late String _band;
  late String _mode;
  bool _lookingUp = false;
  int _serialSent = 1;   // auto-increments after each QSO
  int _count = 0;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _freq = state.lastFreq;
    _band = state.lastBand;
    _mode = state.lastMode;
  }

  @override
  void dispose() {
    _callCtrl.dispose();
    _nameCtrl.dispose();
    _serialRcvdCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _lookupCallsign(String call) async {
    if (call.length < 3) return;
    setState(() => _lookingUp = true);
    final state = context.read<AppState>();
    if (state.qrzSettings.username.isNotEmpty) {
      final data = await state.qrzService.lookupCallsign(call, state.qrzSettings);
      if (mounted && data != null) {
        _nameCtrl.text = data.name ?? '';
      }
    }
    if (mounted) setState(() => _lookingUp = false);
  }

  Future<void> _logAndClear() async {
    if (_callCtrl.text.trim().isEmpty) return;
    final state = context.read<AppState>();

    final namePart = _nameCtrl.text.trim();
    final rcvdSerial = _serialRcvdCtrl.text.trim();

    // Exchange stored in comments: sent serial / received serial / name
    final comments = 'MST - Sent: $_serialSent'
        '${rcvdSerial.isNotEmpty ? ' / Rcvd: $rcvdSerial' : ''}'
        '${namePart.isNotEmpty ? ' / Name: $namePart' : ''}';

    final qso = QsoEntry(
      id: const Uuid().v4(),
      callsign: _callCtrl.text.trim().toUpperCase(),
      band: _band,
      frequency: _freq,
      mode: _mode,
      rstSent: '599',
      rstReceived: '599',
      comments: comments,
      dateTime: DateTime.now().toUtc(),
      contactName: namePart.isNotEmpty ? namePart : null,
      tags: ['MST'],
      adifFields: {
        'STX': '$_serialSent',
        if (rcvdSerial.isNotEmpty) 'SRX': rcvdSerial,
        if (namePart.isNotEmpty) 'NAME': namePart,
      },
    );

    await state.addQso(qso);
    if (mounted) {
      setState(() {
        _count++;
        _serialSent++;
        _callCtrl.clear();
        _nameCtrl.clear();
        _serialRcvdCtrl.clear();
      });
      _focusNode.requestFocus();
    }
  }

  void _resetSerial() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset serial number?'),
        content: const Text('This will reset the sent serial number back to 1.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _serialSent = 1);
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MST Logger'),
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
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.swap_horiz, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'MST — ICWC Medium Speed Test. Exchange: name + serial number.',
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
            const SizedBox(height: 16),

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

            // Name (auto-filled from QRZ)
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Contact name',
                border: OutlineInputBorder(),
                helperText: 'Auto-filled from QRZ if available',
              ),
            ),
            const SizedBox(height: 12),

            // Serial numbers row
            Row(
              children: [
                // Sent serial (read-only with reset button)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Serial sent',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey.shade600)),
                              Text('$_serialSent',
                                  style: const TextStyle(
                                      fontSize: 22, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 20),
                          tooltip: 'Reset serial',
                          onPressed: _resetSerial,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Received serial (entered by operator)
                Expanded(
                  child: TextField(
                    controller: _serialRcvdCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Serial received',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
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
