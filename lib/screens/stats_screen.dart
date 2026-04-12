// lib/screens/stats_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../widgets/common_widgets.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final qsos = state.qsos;

    if (qsos.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Statistics')),
        body: const Center(child: Text('No QSOs logged yet.')),
      );
    }

    // --- Compute stats ---
    final total = qsos.length;

    // Per-country counts
    final countryCounts = <String, int>{};
    for (final q in qsos) {
      final c = q.contactCountry?.trim();
      if (c != null && c.isNotEmpty) {
        countryCounts[c] = (countryCounts[c] ?? 0) + 1;
      }
    }
    final sortedCountries = countryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Top 3 callsigns
    final callCounts = <String, int>{};
    for (final q in qsos) {
      callCounts[q.callsign] = (callCounts[q.callsign] ?? 0) + 1;
    }
    final topCallsigns = callCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3 = topCallsigns.take(3).toList();

    // Per-tag counts
    final tagCounts = <String, int>{};
    for (final q in qsos) {
      for (final t in q.tags) {
        tagCounts[t] = (tagCounts[t] ?? 0) + 1;
      }
    }
    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Per-band counts
    final bandCounts = <String, int>{};
    for (final q in qsos) {
      bandCounts[q.band] = (bandCounts[q.band] ?? 0) + 1;
    }
    final sortedBands = bandCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Total QSOs hero card
          _StatCard(
            child: Row(
              children: [
                Icon(Icons.radio, size: 40, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$total', style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary)),
                    const Text('Total QSOs', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Top callsigns
          _SectionHeader(title: 'Top Callsigns', icon: Icons.star),
          _StatCard(
            child: top3.isEmpty
                ? const Text('No data')
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
                                style: const TextStyle(color: Colors.white, fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(e.key,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                          Text('${e.value} QSO${e.value != 1 ? 's' : ''}',
                              style: TextStyle(color: Colors.grey.shade600)),
                        ]),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 16),

          // QSOs by tag
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

          // QSOs by band
          _SectionHeader(title: 'QSOs by Band', icon: Icons.waves),
          _StatCard(
            child: Column(
              children: sortedBands.map((e) => _BarRow(
                label: e.key,
                count: e.value,
                total: total,
                color: Theme.of(context).colorScheme.primary,
              )).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // QSOs by country
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
                        value: e.value / (sortedCountries.first.value),
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
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
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
        SizedBox(width: 60, child: Text(label,
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
