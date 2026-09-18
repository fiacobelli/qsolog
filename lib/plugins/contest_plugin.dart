// lib/plugins/contest_plugin.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import 'package:uuid/uuid.dart';

const _contestModes = ['CW', 'SSB', 'FT8', 'FT4', 'RTTY', 'DIGITAL', 'PSK31', 'AM', 'FM'];

class ContestPlugin extends StatefulWidget {
  const ContestPlugin({super.key});

  @override
  State<ContestPlugin> createState() => _ContestPluginState();
}

class _ContestPluginState extends State<ContestPlugin> {
  final _contestNameCtrl = TextEditingController();
  final _callCtrl = TextEditingController();
  final _modeCtrl = TextEditingController();
  final _rstRcvdCtrl = TextEditingController(text: '599');
  final _rstSentCtrl = TextEditingController(text: '599');
  final _nameCtrl = TextEditingController();
  final _qthCtrl = TextEditingController();
  final _exchangeRcvdCtrl = TextEditingController();
  final _exchangeSentCtrl = TextEditingController();
  final _serialCtrl = TextEditingController(text: '1');
  late double _freq;
  late String _band;
  late final TextEditingController _freqCtrl;
  bool _lookingUp = false;
  int _count = 0;
  final _callFocusNode = FocusNode();
  // Cached from QRZ lookup
  double? _contactLat;
  double? _contactLon;
  String? _contactGrid;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _freq = state.lastFreq;
    _band = state.lastBand;
    _freqCtrl = TextEditingController(text: _freq.toStringAsFixed(5));
    _modeCtrl.text = state.lastMode;
    _contestNameCtrl.text = state.contestName;
    _exchangeSentCtrl.text = state.contestTxExchange;
  }

  @override
  void dispose() {
    _contestNameCtrl.dispose();
    _callCtrl.dispose();
    _modeCtrl.dispose();
    _rstRcvdCtrl.dispose();
    _rstSentCtrl.dispose();
    _nameCtrl.dispose();
    _qthCtrl.dispose();
    _exchangeRcvdCtrl.dispose();
    _exchangeSentCtrl.dispose();
    _serialCtrl.dispose();
    _freqCtrl.dispose();
    _callFocusNode.dispose();
    super.dispose();
  }

  void _onFreqChanged(String val) {
    final freq = double.tryParse(val);
    if (freq != null) {
      setState(() {
        _freq = freq;
        _band = BandFrequency.bandFromFrequency(freq);
      });
    }
  }

  Future<void> _lookupCallsign(String call) async {
    if (call.length < 3) return;
    setState(() => _lookingUp = true);
    final state = context.read<AppState>();
    if (state.qrzSettings.username.isNotEmpty) {
      final data = await state.qrzService.lookupCallsign(call, state.qrzSettings);
      if (mounted && data != null) {
        _nameCtrl.text = data.name ?? '';
        _qthCtrl.text = data.qth ?? '';
        _contactLat = data.lat;
        _contactLon = data.lon;
        _contactGrid = data.grid;
      }
    }
    if (mounted) setState(() => _lookingUp = false);
  }

  Future<void> _logAndClear() async {
    if (_callCtrl.text.trim().isEmpty) return;
    final state = context.read<AppState>();

    final serial = int.tryParse(_serialCtrl.text.trim()) ?? 1;
    final contestName = _contestNameCtrl.text.trim();
    final mode = _modeCtrl.text.trim().isEmpty ? 'SSB' : _modeCtrl.text.trim().toUpperCase();
    final exchangeRcvd = _exchangeRcvdCtrl.text.trim();
    final exchangeSent = _exchangeSentCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final qth = _qthCtrl.text.trim();

    final qso = QsoEntry(
      id: const Uuid().v4(),
      callsign: _callCtrl.text.trim().toUpperCase(),
      band: _band,
      frequency: _freq,
      mode: mode,
      rstSent: _rstSentCtrl.text.trim().isEmpty ? '599' : _rstSentCtrl.text.trim(),
      rstReceived: _rstRcvdCtrl.text.trim().isEmpty ? '599' : _rstRcvdCtrl.text.trim(),
      comments: contestName,
      dateTime: DateTime.now().toUtc(),
      contactName: name.isNotEmpty ? name : null,
      contactQth: qth.isNotEmpty ? qth : null,
      contactGrid: _contactGrid,
      contactLat: _contactLat,
      contactLon: _contactLon,
      tags: const ['Contest'],
      adifFields: {
        if (contestName.isNotEmpty) 'CONTEST_ID': contestName,
        if (exchangeRcvd.isNotEmpty) 'SRX_STRING': exchangeRcvd,
        if (exchangeSent.isNotEmpty) 'STX_STRING': exchangeSent,
        'STX': serial.toString(),
        if (_contactGrid != null) 'GRIDSQUARE': _contactGrid!,
      },
    );
    await state.addQso(qso);
    await state.saveContestName(contestName);
    await state.saveContestTxExchange(exchangeSent);

    if (mounted) {
      setState(() {
        _count++;
        _callCtrl.clear();
        _nameCtrl.clear();
        _qthCtrl.clear();
        _exchangeRcvdCtrl.clear();
        _serialCtrl.text = (serial + 1).toString();
        _contactLat = null;
        _contactLon = null;
        _contactGrid = null;
      });
      _callFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contest Logger'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('$_count QSOs', style: const TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.emoji_events, color: Colors.purple.shade700),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Contest — All QSOs tagged Contest automatically',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Contest name (persists across sessions)
            TextField(
              controller: _contestNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Contest Name',
                border: OutlineInputBorder(),
                helperText: 'Remembered between sessions',
              ),
              onChanged: (v) => context.read<AppState>().saveContestName(v),
            ),
            const SizedBox(height: 12),

            // Frequency / Band / Mode
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _freqCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Frequency (MHz)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: _onFreqChanged,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Band',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    child: Text(_band, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownMenu<String>(
                    controller: _modeCtrl,
                    expandedInsets: EdgeInsets.zero,
                    enableFilter: true,
                    requestFocusOnTap: true,
                    label: const Text('Mode'),
                    dropdownMenuEntries: _contestModes
                        .map((m) => DropdownMenuEntry(value: m, label: m))
                        .toList(),
                    onSelected: (v) {
                      if (v != null) _modeCtrl.text = v;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Callsign / RST received / RST sent
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _callCtrl,
                    focusNode: _callFocusNode,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Callsign',
                      border: const OutlineInputBorder(),
                      hintText: 'Enter callsign...',
                      suffixIcon: _lookingUp
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
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
                Expanded(
                  child: TextField(
                    controller: _rstRcvdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'RST Received',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _rstSentCtrl,
                    decoration: const InputDecoration(
                      labelText: 'RST Sent',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Operator name / QTH (auto-filled from QRZ)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Operator Name',
                      border: OutlineInputBorder(),
                      helperText: 'Auto-filled from QRZ if available',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _qthCtrl,
                    decoration: const InputDecoration(
                      labelText: 'QTH',
                      border: OutlineInputBorder(),
                      helperText: 'Auto-filled from QRZ if available',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Received exchange
            TextField(
              controller: _exchangeRcvdCtrl,
              decoration: const InputDecoration(
                labelText: 'Received Exchange',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Transmitted exchange (persists across sessions)
            TextField(
              controller: _exchangeSentCtrl,
              decoration: const InputDecoration(
                labelText: 'Transmitted Exchange',
                border: OutlineInputBorder(),
                helperText: 'Remembered between sessions',
              ),
              onChanged: (v) => context.read<AppState>().saveContestTxExchange(v),
            ),
            const SizedBox(height: 12),

            // Serial number transmitted
            TextField(
              controller: _serialCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Serial Number Transmitted',
                border: OutlineInputBorder(),
                helperText: 'Auto-increments after each QSO; editable',
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
