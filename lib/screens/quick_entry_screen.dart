// lib/screens/quick_entry_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import '../services/app_state.dart';

class QuickEntryScreen extends StatefulWidget {
  const QuickEntryScreen({super.key});

  @override
  State<QuickEntryScreen> createState() => _QuickEntryScreenState();
}

class _QuickEntryScreenState extends State<QuickEntryScreen> {
  // ── Column definitions ────────────────────────────────────────────────────

  static const _fixedHeaders = [
    'CALL', 'QSO_DATE', 'TIME_ON', 'BAND',
    'RST_SENT', 'RST_RCVD', 'QTH', 'NAME', 'MODE',
  ];
  static const _numCols = 10; // 9 fixed + 1 extra

  static const _colWidths = [
    112.0, // CALL
    112.0, // QSO_DATE
    80.0,  // TIME_ON
    72.0,  // BAND
    74.0,  // RST_SENT
    74.0,  // RST_RCVD
    112.0, // QTH
    120.0, // NAME
    80.0,  // MODE
    160.0, // extra (dropdown)
  ];

  static const _extraOptions = [
    'FREQ', 'GRIDSQUARE', 'COUNTRY', 'STATE',
    'COMMENT', 'CONT', 'MY_SIG', 'MY_SIG_INFO',
    'SIG', 'SIG_INFO', 'MY_GRIDSQUARE', 'TX_PWR',
    'PROP_MODE', 'SAT_NAME', 'IOTA', 'SOTA_REF', 'POTA_REF',
  ];

  static const _rowH = 36.0;
  static const _headerH = 46.0;

  // ── State ─────────────────────────────────────────────────────────────────

  String _extraField = 'COMMENT';
  final List<List<TextEditingController>> _ctrl = [];
  final List<List<FocusNode>> _nodes = [];

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _addRow(skipSetState: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _nodes.isNotEmpty) _nodes.first[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final row in _ctrl) {
      for (final c in row) c.dispose();
    }
    for (final row in _nodes) {
      for (final n in row) n.dispose();
    }
    super.dispose();
  }

  // ── Row management ────────────────────────────────────────────────────────

  void _addRow({bool skipSetState = false}) {
    final now = DateTime.now().toUtc();
    String date = DateFormat('yyyy-MM-dd').format(now);
    String time = DateFormat('HH:mm').format(now);
    String band = '';
    String mode = '';

    if (_ctrl.isNotEmpty) {
      final prev = _ctrl.last;
      if (prev[1].text.isNotEmpty) date = prev[1].text;
      if (prev[3].text.isNotEmpty) band = prev[3].text;
      if (prev[8].text.isNotEmpty) mode = prev[8].text;
      final t = prev[2].text;
      if (t.length == 5 && t.contains(':')) {
        final p = t.split(':');
        final total =
            (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0) + 1;
        time =
            '${(total ~/ 60 % 24).toString().padLeft(2, '0')}:${(total % 60).toString().padLeft(2, '0')}';
      }
    }

    _ctrl.add([
      TextEditingController(),               // CALL
      TextEditingController(text: date),     // QSO_DATE
      TextEditingController(text: time),     // TIME_ON
      TextEditingController(text: band),     // BAND
      TextEditingController(text: '59'),     // RST_SENT
      TextEditingController(text: '59'),     // RST_RCVD
      TextEditingController(),               // QTH
      TextEditingController(),               // NAME
      TextEditingController(text: mode),     // MODE
      TextEditingController(),               // extra
    ]);
    _nodes.add(List.generate(_numCols, (_) => FocusNode()));

    if (!skipSetState) {
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _nodes.isNotEmpty) _nodes.last[0].requestFocus();
      });
    }
  }

  void _deleteRow(int i) {
    if (_ctrl.length <= 1) return;
    for (final c in _ctrl[i]) c.dispose();
    for (final n in _nodes[i]) n.dispose();
    setState(() {
      _ctrl.removeAt(i);
      _nodes.removeAt(i);
    });
  }

  // ── Keyboard navigation ───────────────────────────────────────────────────

  KeyEventResult _onKey(KeyEvent event, int row, int col) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.tab) {
      _moveFocus(row, col,
          forward: !HardwareKeyboard.instance.isShiftPressed);
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      final sel = _ctrl[row][col].selection;
      if (!sel.isValid ||
          sel.extentOffset >= _ctrl[row][col].text.length) {
        _moveFocus(row, col, forward: true);
        return KeyEventResult.handled;
      }
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      final sel = _ctrl[row][col].selection;
      if (!sel.isValid || sel.baseOffset <= 0) {
        _moveFocus(row, col, forward: false);
        return KeyEventResult.handled;
      }
    }

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _addRow();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _moveFocus(int row, int col, {required bool forward}) {
    if (forward) {
      if (col + 1 < _numCols) {
        _nodes[row][col + 1].requestFocus();
      } else if (row + 1 < _nodes.length) {
        _nodes[row + 1][0].requestFocus();
      } else {
        _addRow(); // Tab at very last cell → new row
      }
    } else {
      if (col > 0) {
        _nodes[row][col - 1].requestFocus();
      } else if (row > 0) {
        _nodes[row - 1][_numCols - 1].requestFocus();
      }
    }
  }

  // ── Parsing ───────────────────────────────────────────────────────────────

  String _parseBand(String s) {
    s = s.trim();
    if (s.isEmpty) return 'Unknown';
    // Treat as MHz frequency if decimal present
    if (s.contains('.')) {
      final f = double.tryParse(s);
      if (f != null) return BandFrequency.bandFromFrequency(f);
    }
    // Integer → band name
    const map = {
      160: '160m', 80: '80m', 60: '60m', 40: '40m', 30: '30m',
      20: '20m', 17: '17m', 15: '15m', 12: '12m', 10: '10m',
      6: '6m', 4: '4m', 2: '2m', 70: '70cm',
    };
    final n = int.tryParse(s);
    return n != null ? (map[n] ?? '${n}m') : s;
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final state = context.read<AppState>();
    int imported = 0, skipped = 0;

    for (final row in _ctrl) {
      final call = row[0].text.trim().toUpperCase();
      if (call.isEmpty) continue;

      DateTime dt;
      try {
        final dp = row[1].text.trim().split('-');
        final tp = row[2].text.trim().split(':');
        dt = DateTime.utc(
          int.parse(dp[0]),
          int.parse(dp[1]),
          int.parse(dp[2]),
          tp.length >= 2 ? int.parse(tp[0]) : 0,
          tp.length >= 2 ? int.parse(tp[1]) : 0,
        );
      } catch (_) {
        dt = DateTime.now().toUtc();
      }

      final bandRaw = row[3].text.trim();
      final band = _parseBand(bandRaw);
      final freq =
          bandRaw.contains('.') ? (double.tryParse(bandRaw) ?? 0.0) : 0.0;

      final mode = row[8].text.trim().isNotEmpty
          ? row[8].text.trim().toUpperCase()
          : 'SSB';
      final extraVal = row[9].text.trim();
      final adifFields = <String, String>{
        if (extraVal.isNotEmpty) _extraField: extraVal,
      };

      final qso = QsoEntry(
        id: const Uuid().v4(),
        callsign: call,
        band: band,
        frequency: freq,
        mode: mode,
        rstSent: row[4].text.isNotEmpty ? row[4].text : '59',
        rstReceived: row[5].text.isNotEmpty ? row[5].text : '59',
        dateTime: dt,
        contactQth:
            row[6].text.trim().isNotEmpty ? row[6].text.trim() : null,
        contactName:
            row[7].text.trim().isNotEmpty ? row[7].text.trim() : null,
        adifFields: adifFields,
        tags: ['QuickEntry'],
      );

      final added = await state.addQso(qso);
      if (added) imported++; else skipped++;
    }

    if (mounted) {
      Navigator.pop(context);
      final msg = skipped > 0
          ? 'Quick Entry: $imported imported, $skipped duplicate${skipped > 1 ? 's' : ''}'
          : 'Quick Entry: $imported QSO${imported != 1 ? 's' : ''} imported';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  // ── Cell widget ───────────────────────────────────────────────────────────

  Widget _buildCell(int row, int col, ThemeData theme) {
    final ctrl = _ctrl[row][col];
    final node = _nodes[row][col];

    TextInputType kbType = TextInputType.text;
    List<TextInputFormatter> formatters = [];
    String? hint;
    TextCapitalization cap =
        col == 0 ? TextCapitalization.characters : TextCapitalization.none;

    switch (col) {
      case 1: // QSO_DATE
        kbType = TextInputType.datetime;
        formatters = [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]'))
        ];
        hint = 'YYYY-MM-DD';
        break;
      case 2: // TIME_ON
        kbType = TextInputType.datetime;
        formatters = [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9:]'))
        ];
        hint = 'HH:MM';
        break;
      case 3: // BAND — numeric only
        kbType =
            const TextInputType.numberWithOptions(decimal: true);
        formatters = [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
        ];
        hint = '60';
        break;
      case 8: // MODE
        cap = TextCapitalization.characters;
        hint = 'SSB';
        break;
    }

    final borderSide =
        BorderSide(color: theme.dividerColor, width: 0.5);

    return Focus(
      onKeyEvent: (_, e) => _onKey(e, row, col),
      child: Container(
        width: _colWidths[col],
        height: _rowH,
        decoration: BoxDecoration(
          color: row.isEven
              ? theme.colorScheme.surface
              : theme.colorScheme.surfaceContainerLow,
          border: Border(
            right: borderSide,
            bottom: borderSide,
          ),
        ),
        child: TextField(
          controller: ctrl,
          focusNode: node,
          keyboardType: kbType,
          textCapitalization: cap,
          inputFormatters: formatters,
          textAlignVertical: TextAlignVertical.center,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            border: InputBorder.none,
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 11,
              color: theme.hintColor.withValues(alpha: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: theme.colorScheme.primary, width: 2),
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerBg = theme.colorScheme.primaryContainer;
    final borderSide = BorderSide(color: theme.dividerColor, width: 0.5);

    Widget headerCell(String label, double width) => Container(
          width: width,
          height: _headerH,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: headerBg,
            border: Border(right: borderSide, bottom: borderSide),
          ),
          child: Text(
            label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 12),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Quick Entry')),
      body: Column(
        children: [
          // ── Table ────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        for (int c = 0; c < 9; c++)
                          headerCell(_fixedHeaders[c], _colWidths[c]),

                        // Extra field dropdown in header
                        Container(
                          width: _colWidths[9],
                          height: _headerH,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: headerBg,
                            border: Border(
                                right: borderSide, bottom: borderSide),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _extraField,
                              isDense: true,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                              dropdownColor:
                                  theme.colorScheme.primaryContainer,
                              items: _extraOptions
                                  .map((f) => DropdownMenuItem(
                                        value: f,
                                        child: Text(f,
                                            style: const TextStyle(
                                                fontSize: 12)),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _extraField = v!),
                            ),
                          ),
                        ),

                        // Delete-col header (spacer)
                        Container(
                          width: 36,
                          height: _headerH,
                          color: headerBg,
                        ),
                      ],
                    ),

                    // Data rows
                    for (int r = 0; r < _ctrl.length; r++)
                      Row(
                        children: [
                          for (int c = 0; c < _numCols; c++)
                            _buildCell(r, c, theme),

                          // Delete row button
                          Container(
                            width: 36,
                            height: _rowH,
                            decoration: BoxDecoration(
                              color: r.isEven
                                  ? theme.colorScheme.surface
                                  : theme.colorScheme.surfaceContainerLow,
                              border: Border(bottom: borderSide),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.close, size: 14),
                              padding: EdgeInsets.zero,
                              tooltip: 'Remove row',
                              onPressed: _ctrl.length > 1
                                  ? () => _deleteRow(r)
                                  : null,
                            ),
                          ),
                        ],
                      ),

                    // Add-row button
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: TextButton.icon(
                        onPressed: _addRow,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add row'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom bar ───────────────────────────────────────────────
          const Divider(height: 1),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
