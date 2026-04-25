// lib/screens/add_qso_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../services/qrz_service.dart';
import '../widgets/common_widgets.dart';

class AddQsoScreen extends StatefulWidget {
  final QsoEntry? existing;
  final Map<String, String>? prefilledExtra;
  final List<String>? prefilledTags;
  final double? prefilledFreq;
  final String? prefilledMode;
  final String? prefilledCallsign;

  const AddQsoScreen({
    super.key,
    this.existing,
    this.prefilledExtra,
    this.prefilledTags,
    this.prefilledFreq,
    this.prefilledMode,
    this.prefilledCallsign,
  });

  @override
  State<AddQsoScreen> createState() => _AddQsoScreenState();
}

class _AddQsoScreenState extends State<AddQsoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _callCtrl, _rstSentCtrl, _rstRcvdCtrl, _commentCtrl,
      _nameCtrl, _qthCtrl, _gridCtrl, _countryCtrl, _stateCtrl, _timeCtrl;
  late double _freq;
  late String _band, _mode;
  late List<String> _tags;
  late DateTime _qsoDateTime;
  bool _lookingUp = false;
  String? _lookupError;

  @override
  void initState() {
    super.initState();
    final q = widget.existing;
    final state = context.read<AppState>();
    _qsoDateTime = q?.dateTime ?? DateTime.now().toUtc();
    _callCtrl = TextEditingController(text: q?.callsign ?? widget.prefilledCallsign ?? '');
    _rstSentCtrl = TextEditingController(text: q?.rstSent ?? '59');
    _rstRcvdCtrl = TextEditingController(text: q?.rstReceived ?? '59');
    _commentCtrl = TextEditingController(text: q?.comments ?? '');
    _nameCtrl = TextEditingController(text: q?.contactName ?? '');
    _qthCtrl = TextEditingController(text: q?.contactQth ?? '');
    _gridCtrl = TextEditingController(text: q?.contactGrid ?? '');
    _countryCtrl = TextEditingController(text: q?.contactCountry ?? '');
    _stateCtrl = TextEditingController(text: q?.contactState ?? '');
    _timeCtrl = TextEditingController(text: _formatDateTime(_qsoDateTime));
    // For new QSOs carry forward the last used band/mode/freq
    _freq = q?.frequency ?? widget.prefilledFreq ?? state.lastFreq;
    _band = q?.band ?? BandFrequency.bandFromFrequency(_freq);
    _mode = q?.mode ?? widget.prefilledMode ?? state.lastMode;
    _tags = q?.tags ?? List.from(widget.prefilledTags ?? []);
  }

  String _formatDateTime(DateTime dt) {
    final u = dt.toUtc();
    return '${u.year.toString().padLeft(4,'0')}-'
        '${u.month.toString().padLeft(2,'0')}-'
        '${u.day.toString().padLeft(2,'0')} '
        '${u.hour.toString().padLeft(2,'0')}:'
        '${u.minute.toString().padLeft(2,'0')}Z';
  }

  DateTime? _parseDateTime(String s) {
    // Accept formats: YYYY-MM-DD HH:MMZ  or  YYYY-MM-DD HH:MM
    try {
      final clean = s.replaceAll('Z', '').trim();
      return DateTime.parse('${clean.replaceAll(' ', 'T')}:00Z');
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    for (final c in [_callCtrl, _rstSentCtrl, _rstRcvdCtrl, _commentCtrl,
        _nameCtrl, _qthCtrl, _gridCtrl, _countryCtrl, _stateCtrl, _timeCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _lookupQrz() async {
    if (_callCtrl.text.trim().isEmpty) return;
    setState(() { _lookingUp = true; _lookupError = null; });
    final state = context.read<AppState>();
    final data = await state.qrzService.lookupCallsign(_callCtrl.text.trim(), state.qrzSettings);
    setState(() { _lookingUp = false; });
    if (data != null) {
      _nameCtrl.text = data.name ?? _nameCtrl.text;
      _qthCtrl.text = data.qth ?? _qthCtrl.text;
      _gridCtrl.text = data.grid ?? _gridCtrl.text;
      _countryCtrl.text = data.country ?? _countryCtrl.text;
      _stateCtrl.text = data.state ?? _stateCtrl.text;
    } else {
      setState(() => _lookupError = 'Not found on QRZ');
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete QSO?'),
        content: Text('Delete contact with ${_callCtrl.text}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<AppState>().deleteQso(widget.existing!.id);
      if (mounted) Navigator.pop(context, true);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final state = context.read<AppState>();

    double? contactLat, contactLon, dist;
    if (_callCtrl.text.isNotEmpty) {
      final data = await state.qrzService.lookupCallsign(_callCtrl.text, state.qrzSettings);
      if (data != null) {
        contactLat = data.lat;
        contactLon = data.lon;
      }
    }
    dist = calculateDistance(state.station.lat, state.station.lon, contactLat, contactLon);

    final qso = QsoEntry(
      id: widget.existing?.id ?? const Uuid().v4(),
      callsign: _callCtrl.text.trim().toUpperCase(),
      band: _band,
      frequency: _freq,
      mode: _mode,
      rstSent: _rstSentCtrl.text,
      rstReceived: _rstRcvdCtrl.text,
      comments: _commentCtrl.text,
      dateTime: _parseDateTime(_timeCtrl.text) ?? _qsoDateTime,
      contactName: _nameCtrl.text.isNotEmpty ? _nameCtrl.text : null,
      contactQth: _qthCtrl.text.isNotEmpty ? _qthCtrl.text : null,
      contactGrid: _gridCtrl.text.isNotEmpty ? _gridCtrl.text : null,
      contactCountry: _countryCtrl.text.isNotEmpty ? _countryCtrl.text : null,
      contactState: _stateCtrl.text.isNotEmpty ? _stateCtrl.text : null,
      contactLat: contactLat,
      contactLon: contactLon,
      tags: _tags,
      adifFields: widget.prefilledExtra ?? widget.existing?.adifFields ?? {},
      distanceKm: dist,
    );

    if (widget.existing != null) {
      await state.updateQso(qso);
      if (mounted) Navigator.pop(context, true);
    } else {
      final added = await state.addQso(qso);
      if (mounted) {
        if (!added) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Duplicate QSO skipped — same callsign/band within 30 minutes')),
          );
        } else {
          Navigator.pop(context, true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing != null ? 'Edit QSO' : 'Log QSO'),
        actions: [
          if (widget.existing != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
              tooltip: 'Delete QSO',
              color: Colors.red.shade200,
            ),
        ],
      ),
      // Prominent save FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        icon: const Icon(Icons.save, size: 26),
        label: Text(
          widget.existing != null ? 'Save Changes' : 'Log QSO',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        elevation: 6,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Callsign + QRZ lookup
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _callCtrl,
                      decoration: InputDecoration(
                        labelText: 'Callsign *',
                        errorText: _lookupError,
                        border: const OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      onChanged: (v) {
                        if (v.length >= 3 && state.qrzSettings.username.isNotEmpty) {
                          Future.delayed(const Duration(milliseconds: 800), () {
                            if (_callCtrl.text == v) _lookupQrz();
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    child: _lookingUp
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
                        : ElevatedButton.icon(
                            onPressed: _lookupQrz,
                            icon: const Icon(Icons.search),
                            label: const Text('QRZ'),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Freq / Band / Mode
              BandFrequencySelector(
                initialFreq: _freq,
                initialBand: _band,
                initialMode: _mode,
                onChanged: (freq, band, mode) {
                  setState(() { _freq = freq; _band = band; _mode = mode; });
                },
              ),
              const SizedBox(height: 16),

              // RST
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _rstSentCtrl,
                      decoration: const InputDecoration(labelText: 'RST Sent', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _rstRcvdCtrl,
                      decoration: const InputDecoration(labelText: 'RST Rcvd', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date/Time UTC — editable
              TextFormField(
                controller: _timeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Date/Time (UTC)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                  helperText: 'Format: YYYY-MM-DD HH:MMZ',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (_parseDateTime(v) == null) return 'Use format: YYYY-MM-DD HH:MMZ';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Contact info
              const Text('Contact Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _qthCtrl,
                decoration: const InputDecoration(labelText: 'QTH', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _gridCtrl,
                      decoration: const InputDecoration(labelText: 'Grid Square', border: OutlineInputBorder()),
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _countryCtrl,
                      decoration: const InputDecoration(labelText: 'Country', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _stateCtrl,
                      decoration: const InputDecoration(labelText: 'State', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tags
              const Text('Tags', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              TagSelector(
                selected: _tags,
                available: state.tags,
                onChanged: (t) => setState(() => _tags = t),
              ),
              const SizedBox(height: 16),

              // Comments
              TextFormField(
                controller: _commentCtrl,
                decoration: const InputDecoration(
                  labelText: 'Comments',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
