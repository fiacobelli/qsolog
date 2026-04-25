// lib/screens/stats_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../widgets/common_widgets.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _filterTag;

  // ── Filters ──────────────────────────────────────────────────────────────

  List<QsoEntry> _applyFilters(List<QsoEntry> all) {
    var q = all;
    if (_fromDate != null) {
      q = q.where((e) => !e.dateTime.toUtc().isBefore(_fromDate!)).toList();
    }
    if (_toDate != null) {
      final end = _toDate!.add(const Duration(days: 1));
      q = q.where((e) => e.dateTime.toUtc().isBefore(end)).toList();
    }
    if (_filterTag != null) {
      q = q.where((e) => e.tags.contains(_filterTag)).toList();
    }
    return q;
  }

  Future<void> _pickDate(BuildContext context, bool isFrom) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _fromDate : _toDate) ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        if (isFrom) _fromDate = picked.toUtc();
        else _toDate = picked.toUtc();
      });
    }
  }

  void _clearFilters() => setState(() {
    _fromDate = null;
    _toDate = null;
    _filterTag = null;
  });

  // ── Streak calculation ───────────────────────────────────────────────────

  /// Returns {streak, avgPerDay, longestDist} for consecutive days ending today
  Map<String, dynamic> _calcStreak(List<QsoEntry> qsos) {
    if (qsos.isEmpty) return {'streak': 0, 'avg': 0.0, 'longestDist': null};

    // Build a set of UTC dates that have at least one QSO
    final days = <String>{};
    for (final q in qsos) {
      final d = q.dateTime.toUtc();
      days.add('${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}');
    }

    // Walk backwards from today counting consecutive days
    int streak = 0;
    final today = DateTime.now().toUtc();
    DateTime cursor = DateTime.utc(today.year, today.month, today.day);

    while (true) {
      final key = '${cursor.year}-${cursor.month.toString().padLeft(2,'0')}-${cursor.day.toString().padLeft(2,'0')}';
      if (!days.contains(key)) break;
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    if (streak == 0) return {'streak': 0, 'avg': 0.0, 'longestDist': null};

    // QSOs during the streak window
    final streakStart = DateTime.now().toUtc().subtract(Duration(days: streak - 1));
    final streakQsos = qsos.where((q) =>
      !q.dateTime.toUtc().isBefore(DateTime.utc(streakStart.year, streakStart.month, streakStart.day))).toList();

    final avg = streak > 0 ? streakQsos.length / streak : 0.0;

    // Longest distance in streak
    double? longestDist;
    String? longestCall;
    for (final q in streakQsos) {
      if (q.distanceKm != null && (longestDist == null || q.distanceKm! > longestDist!)) {
        longestDist = q.distanceKm;
        longestCall = q.callsign;
      }
    }

    return {
      'streak': streak,
      'avg': avg,
      'longestDist': longestDist,
      'longestCall': longestCall,
    };
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final allQsos = state.qsos;
    final qsos = _applyFilters(allQsos);
    final tags = state.tags;
    final fmt = DateFormat('MM/dd/yy');
    final hasFilters = _fromDate != null || _toDate != null || _filterTag != null;

    if (allQsos.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Statistics')),
        body: const Center(child: Text('No QSOs logged yet.')),
      );
    }

    // ── Compute stats on filtered QSOs ──────────────────────────────────
    final total = qsos.length;

    final countryCounts = <String, int>{};
    for (final q in qsos) {
      final c = q.contactCountry?.trim();
      if (c != null && c.isNotEmpty) {
        countryCounts[c] = (countryCounts[c] ?? 0) + 1;
      }
    }
    final sortedCountries = countryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final callCounts = <String, int>{};
    for (final q in qsos) {
      callCounts[q.callsign] = (callCounts[q.callsign] ?? 0) + 1;
    }
    final top3 = (callCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value))).take(3).toList();

    final tagCounts = <String, int>{};
    for (final q in qsos) {
      for (final t in q.tags) {
        tagCounts[t] = (tagCounts[t] ?? 0) + 1;
      }
    }
    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final bandCounts = <String, int>{};
    for (final q in qsos) {
      bandCounts[q.band] = (bandCounts[q.band] ?? 0) + 1;
    }
    final sortedBands = bandCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Streak (always computed on all QSOs — streak is an absolute concept)
    final streak = _calcStreak(allQsos);
    final streakDays = streak['streak'] as int;
    final streakAvg = streak['avg'] as double;
    final streakDist = streak['longestDist'] as double?;
    final streakCall = streak['longestCall'] as String?;

    // Longest distance in filtered QSOs
    double? longestDist;
    String? longestCall;
    for (final q in qsos) {
      if (q.distanceKm != null && (longestDist == null || q.distanceKm! > longestDist!)) {
        longestDist = q.distanceKm;
        longestCall = q.callsign;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        actions: [
          if (hasFilters)
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.filter_alt_off, size: 18),
              label: const Text('Clear'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Filter bar ────────────────────────────────────────────────
          _StatCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.filter_alt, size: 16,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 6),
                  Text('Filter', style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary)),
                ]),
                const SizedBox(height: 10),
                // Date range row
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 14),
                      label: Text(_fromDate != null
                          ? 'From: ${fmt.format(_fromDate!)}'
                          : 'From date',
                          style: const TextStyle(fontSize: 12)),
                      onPressed: () => _pickDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 14),
                      label: Text(_toDate != null
                          ? 'To: ${fmt.format(_toDate!)}'
                          : 'To date',
                          style: const TextStyle(fontSize: 12)),
                      onPressed: () => _pickDate(context, false),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                // Tag filter
                if (tags.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      FilterChip(
                        label: const Text('All tags'),
                        selected: _filterTag == null,
                        onSelected: (_) => setState(() => _filterTag = null),
                      ),
                      ...tags.map((t) => FilterChip(
                        label: Text(t.name),
                        selected: _filterTag == t.name,
                        onSelected: (_) => setState(() =>
                            _filterTag = _filterTag == t.name ? null : t.name),
                      )),
                    ],
                  ),
                if (hasFilters) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Showing $total of ${allQsos.length} QSOs',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Total QSOs hero card ──────────────────────────────────────
          _StatCard(
            child: Row(children: [
              Icon(Icons.radio, size: 40,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$total',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary)),
                Text(hasFilters ? 'Filtered QSOs' : 'Total QSOs',
                    style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ]),
              if (longestDist != null) ...[
                const Spacer(),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(state.formatDistance(longestDist!),
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16,
                          color: Theme.of(context).colorScheme.secondary)),
                  Text('Longest: $longestCall',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ]),
              ],
            ]),
          ),
          const SizedBox(height: 16),

          // ── On a Roll streak card ─────────────────────────────────────
          if (streakDays > 0) ...[
            _SectionHeader(title: 'On a Roll 🔥', icon: Icons.local_fire_department),
            _StatCard(
              child: Row(children: [
                // Streak days bubble
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange.shade600,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$streakDays',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold)),
                      const Text('days',
                          style: TextStyle(color: Colors.white70, fontSize: 10)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        streakDays == 1
                            ? 'You logged a QSO today — keep it going!'
                            : 'You\'ve logged QSOs $streakDays days in a row!',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${streakAvg.toStringAsFixed(1)} QSOs/day average',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                      if (streakDist != null) ...[
                        const SizedBox(height: 4),
                        Row(children: [
                          Icon(Icons.open_in_full, size: 13,
                              color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            'Longest: ${state.formatDistance(streakDist)} — $streakCall',
                            style: TextStyle(fontSize: 12,
                                color: Colors.grey.shade600),
                          ),
                        ]),
                      ],
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
          ],

          // ── Top callsigns ─────────────────────────────────────────────
          _SectionHeader(title: 'Top Callsigns', icon: Icons.star),
          _StatCard(
            child: total == 0
                ? const Text('No data for this filter')
                : Column(
                    children: top3.asMap().entries.map((entry) {
                      final rank = entry.key + 1;
                      final e = entry.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: [
                              Colors.amber.shade600,
                              Colors.grey.shade400,
                              Colors.brown.shade400,
                            ][entry.key],
                            child: Text('$rank',
                                style: const TextStyle(color: Colors.white,
                                    fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(e.key,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15))),
                          Text('${e.value} QSO${e.value != 1 ? 's' : ''}',
                              style: TextStyle(color: Colors.grey.shade600)),
                        ]),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 16),

          // ── QSOs by tag ───────────────────────────────────────────────
          if (sortedTags.isNotEmpty) ...[
            _SectionHeader(title: 'QSOs by Tag', icon: Icons.label),
            _StatCard(
              child: Column(
                children: sortedTags.map((e) => _BarRow(
                  label: e.key,
                  count: e.value,
                  total: total,
                  color: _tagColor(e.key, state),
                )).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── QSOs by band ──────────────────────────────────────────────
          _SectionHeader(title: 'QSOs by Band', icon: Icons.waves),
          _StatCard(
            child: total == 0
                ? const Text('No data for this filter')
                : Column(
                    children: sortedBands.map((e) => _BarRow(
                      label: e.key,
                      count: e.value,
                      total: total,
                      color: Theme.of(context).colorScheme.primary,
                    )).toList(),
                  ),
          ),
          const SizedBox(height: 16),

          // ── QSOs by country ───────────────────────────────────────────
          if (sortedCountries.isNotEmpty) ...[
            _SectionHeader(title: 'QSOs by Country', icon: Icons.flag),
            _StatCard(
              child: Column(
                children: sortedCountries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(children: [
                    CountryFlagWidget(country: e.key),
                    const SizedBox(width: 10),
                    Expanded(child: Text(e.key)),
                    Text('${e.value}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 100,
                      child: LinearProgressIndicator(
                        value: e.value / sortedCountries.first.value,
                        backgroundColor: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ]),
                )).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Color _tagColor(String name, AppState state) {
    final tag = state.tagById(name);
    if (tag == null) return Colors.blue;
    try {
      return Color(int.parse(tag.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.blue;
    }
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final Widget child;
  const _StatCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Text(title, style: TextStyle(
            fontWeight: FontWeight.bold, fontSize: 14,
            color: Theme.of(context).colorScheme.primary)),
      ]),
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  const _BarRow({required this.label, required this.count,
      required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 60,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600))),
        const SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: Colors.grey.shade200,
            color: color,
            borderRadius: BorderRadius.circular(4),
            minHeight: 10,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text('$count',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }
}
