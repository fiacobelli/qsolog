// lib/widgets/common_widgets.dart
import 'package:flutter/material.dart';
import 'package:country_flags/country_flags.dart';
import 'dart:math';
import '../models/models.dart';
import '../services/app_state.dart';
import 'package:provider/provider.dart';

/// Maps common country names used in ham radio logs to ISO 3166-1 alpha-2 codes.
String? countryToIso(String? country) {
  if (country == null || country.isEmpty) return null;
  final key = country.trim().toLowerCase();
  const map = {
    'united states': 'US', 'usa': 'US', 'us': 'US', 'united states of america': 'US',
    'canada': 'CA', 'mexico': 'MX',
    'united kingdom': 'GB', 'uk': 'GB', 'england': 'GB', 'scotland': 'GB',
    'wales': 'GB', 'northern ireland': 'GB', 'great britain': 'GB',
    'germany': 'DE', 'deutschland': 'DE',
    'france': 'FR', 'italy': 'IT', 'spain': 'ES', 'portugal': 'PT',
    'netherlands': 'NL', 'holland': 'NL', 'belgium': 'BE', 'luxembourg': 'LU',
    'switzerland': 'CH', 'austria': 'AT', 'denmark': 'DK', 'sweden': 'SE',
    'norway': 'NO', 'finland': 'FI', 'iceland': 'IS',
    'poland': 'PL', 'czech republic': 'CZ', 'czechia': 'CZ', 'slovakia': 'SK',
    'hungary': 'HU', 'romania': 'RO', 'bulgaria': 'BG', 'croatia': 'HR',
    'serbia': 'RS', 'slovenia': 'SI', 'bosnia': 'BA', 'montenegro': 'ME',
    'greece': 'GR', 'turkey': 'TR',
    'russia': 'RU', 'ukraine': 'UA', 'belarus': 'BY', 'moldova': 'MD',
    'estonia': 'EE', 'latvia': 'LV', 'lithuania': 'LT',
    'japan': 'JP', 'china': 'CN', 'south korea': 'KR', 'korea': 'KR',
    'north korea': 'KP', 'taiwan': 'TW', 'hong kong': 'HK',
    'india': 'IN', 'pakistan': 'PK', 'bangladesh': 'BD', 'sri lanka': 'LK',
    'thailand': 'TH', 'vietnam': 'VN', 'philippines': 'PH', 'indonesia': 'ID',
    'malaysia': 'MY', 'singapore': 'SG', 'myanmar': 'MM',
    'australia': 'AU', 'new zealand': 'NZ',
    'brazil': 'BR', 'argentina': 'AR', 'chile': 'CL', 'colombia': 'CO',
    'peru': 'PE', 'venezuela': 'VE', 'ecuador': 'EC', 'bolivia': 'BO',
    'uruguay': 'UY', 'paraguay': 'PY',
    'south africa': 'ZA', 'nigeria': 'NG', 'kenya': 'KE', 'ghana': 'GH',
    'ethiopia': 'ET', 'egypt': 'EG', 'morocco': 'MA', 'tunisia': 'TN',
    'israel': 'IL', 'saudi arabia': 'SA', 'uae': 'AE',
    'united arab emirates': 'AE', 'iran': 'IR', 'iraq': 'IQ',
    'jordan': 'JO', 'kuwait': 'KW', 'qatar': 'QA', 'bahrain': 'BH',
    'cuba': 'CU', 'puerto rico': 'PR', 'jamaica': 'JM',
  };
  // Direct match
  if (map.containsKey(key)) return map[key];
  // Try matching if the country string starts with a known name
  for (final entry in map.entries) {
    if (key.startsWith(entry.key) || entry.key.startsWith(key)) return entry.value;
  }
  // If 2-letter code passed directly, uppercase it
  if (key.length == 2) return country.toUpperCase();
  return null;
}

class CountryFlagWidget extends StatelessWidget {
  final String? country;
  const CountryFlagWidget({super.key, this.country});

  @override
  Widget build(BuildContext context) {
    final iso = countryToIso(country);
    if (iso == null) {
      return Container(
        width: 32, height: 22,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(3),
        ),
        child: const Icon(Icons.flag, size: 14, color: Colors.grey),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: CountryFlag.fromCountryCode(
        iso,
        width: 32,
        height: 22,
      ),
    );
  }
}

class TagChip extends StatelessWidget {
  final String tagName;
  final bool removable;
  final VoidCallback? onRemove;

  const TagChip({super.key, required this.tagName, this.removable = false, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final tag = state.tagById(tagName);
    final color = tag != null ? _parseColor(tag.color) : Colors.blue;
    return Chip(
      label: Text(tagName, style: const TextStyle(fontSize: 11, color: Colors.white)),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      deleteIcon: removable ? const Icon(Icons.close, size: 14, color: Colors.white) : null,
      onDeleted: removable ? onRemove : null,
    );
  }

  static Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.blue;
    }
  }
}

class DistanceBadge extends StatelessWidget {
  final double? km;
  const DistanceBadge({super.key, this.km});

  @override
  Widget build(BuildContext context) {
    if (km == null) return const SizedBox.shrink();
    final state = context.watch<AppState>();
    final label = state.formatDistance(km!);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }
}

double? calculateDistance(double? lat1, double? lon1, double? lat2, double? lon2) {
  if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) return null;
  const R = 6371.0;
  final dLat = _deg2rad(lat2 - lat1);
  final dLon = _deg2rad(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}

double _deg2rad(double deg) => deg * pi / 180;

class BandFrequencySelector extends StatefulWidget {
  final double initialFreq;
  final String initialBand;
  final String initialMode;
  final Function(double freq, String band, String mode) onChanged;

  const BandFrequencySelector({
    super.key,
    required this.initialFreq,
    required this.initialBand,
    required this.initialMode,
    required this.onChanged,
  });

  @override
  State<BandFrequencySelector> createState() => _BandFrequencySelectorState();
}

class _BandFrequencySelectorState extends State<BandFrequencySelector> {
  late TextEditingController _freqCtrl;
  late String _band;
  late String _mode;

  final List<String> _modes = ['SSB', 'CW', 'FT8', 'FT4', 'AM', 'FM', 'RTTY', 'PSK31', 'JS8', 'DIGITAL'];

  @override
  void initState() {
    super.initState();
    _freqCtrl = TextEditingController(text: widget.initialFreq.toStringAsFixed(3));
    _band = widget.initialBand;
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _freqCtrl.dispose();
    super.dispose();
  }

  void _onFreqChanged(String val) {
    final freq = double.tryParse(val);
    if (freq != null) {
      final newBand = BandFrequency.bandFromFrequency(freq);
      setState(() => _band = newBand);
      widget.onChanged(freq, newBand, _mode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: _freqCtrl,
            decoration: const InputDecoration(labelText: 'Frequency (MHz)', isDense: true),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: _onFreqChanged,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: InputDecorator(
            decoration: const InputDecoration(labelText: 'Band', isDense: true),
            child: Text(_band, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            value: _modes.contains(_mode) ? _mode : _modes.first,
            decoration: const InputDecoration(labelText: 'Mode', isDense: true),
            items: _modes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() => _mode = v);
                final freq = double.tryParse(_freqCtrl.text) ?? widget.initialFreq;
                widget.onChanged(freq, _band, v);
              }
            },
          ),
        ),
      ],
    );
  }
}

class TagSelector extends StatefulWidget {
  final List<String> selected;
  final List<TagDefinition> available;
  final Function(List<String>) onChanged;

  const TagSelector({
    super.key,
    required this.selected,
    required this.available,
    required this.onChanged,
  });

  @override
  State<TagSelector> createState() => _TagSelectorState();
}

class _TagSelectorState extends State<TagSelector> {
  late List<String> _selected;
  final _customCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selected);
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  void _addCustomTag(String raw) {
    final tag = raw.trim();
    if (tag.isEmpty) return;
    if (!_selected.contains(tag)) {
      setState(() => _selected.add(tag));
      widget.onChanged(_selected);
    }
    _customCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    // Collect all known tag names for chip display
    final knownNames = widget.available.map((t) => t.name).toSet();
    // Any selected tags not in the known list are custom
    final customSelected = _selected.where((t) => !knownNames.contains(t)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Predefined tags as FilterChips
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            ...widget.available.map((tag) {
              final isSelected = _selected.contains(tag.name);
              final color = _parseColor(tag.color);
              return FilterChip(
                label: Text(tag.name,
                    style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : null)),
                selected: isSelected,
                selectedColor: color,
                onSelected: (v) {
                  setState(() {
                    if (v) _selected.add(tag.name); else _selected.remove(tag.name);
                  });
                  widget.onChanged(_selected);
                },
              );
            }),
            // Custom (free-text) tags already added — shown as deletable chips
            ...customSelected.map((tag) => Chip(
              label: Text(tag, style: const TextStyle(fontSize: 12, color: Colors.white)),
              backgroundColor: Colors.blueGrey,
              deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white),
              onDeleted: () {
                setState(() => _selected.remove(tag));
                widget.onChanged(_selected);
              },
            )),
          ],
        ),
        const SizedBox(height: 8),
        // Free-text input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customCtrl,
                decoration: const InputDecoration(
                  hintText: 'Add custom tag...',
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                onSubmitted: _addCustomTag,
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Add tag',
              onPressed: () => _addCustomTag(_customCtrl.text),
            ),
          ],
        ),
      ],
    );
  }

  static Color _parseColor(String hex) {
    try { return Color(int.parse(hex.replaceFirst('#', '0xFF'))); } catch (_) { return Colors.blue; }
  }
}
