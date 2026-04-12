// lib/screens/map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/app_state.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  QsoEntry? _selected;
  late TextEditingController _countCtrl;

  @override
  void initState() {
    super.initState();
    _countCtrl = TextEditingController(
        text: context.read<AppState>().mapQsoCount.toString());
  }

  @override
  void dispose() {
    _countCtrl.dispose();
    super.dispose();
  }

  void _applyCount(AppState state) {
    final n = (int.tryParse(_countCtrl.text) ?? 10).clamp(1, 500);
    _countCtrl.text = n.toString();
    state.setMapQsoCount(n);
    FocusScope.of(context).unfocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    final withCoords = state.qsos
        .where((q) => q.contactLat != null && q.contactLon != null)
        .take(state.mapQsoCount)
        .toList();

    final myLat = state.station.lat;
    final myLon = state.station.lon;
    final hasMyStation = myLat != null && myLon != null;

    // Markers
    final markers = <Marker>[];

    if (hasMyStation) {
      markers.add(Marker(
        point: LatLng(myLat, myLon),
        width: 40,
        height: 40,
        child: Tooltip(
          message: 'My station — ${state.station.callsign}',
          child: const Icon(Icons.home_filled,
              color: Colors.green, size: 36,
              shadows: [Shadow(blurRadius: 4, color: Colors.black54)]),
        ),
      ));
    }

    for (final q in withCoords) {
      final isSel = q == _selected;
      markers.add(Marker(
        point: LatLng(q.contactLat!, q.contactLon!),
        width: isSel ? 48 : 34,
        height: isSel ? 48 : 34,
        child: GestureDetector(
          onTap: () => setState(() => _selected = isSel ? null : q),
          child: Tooltip(
            message: '${q.callsign} — ${q.band} ${q.mode}',
            child: Icon(Icons.radio_button_checked,
                color: isSel ? Colors.orange : Colors.red,
                size: isSel ? 44 : 30,
                shadows: const [Shadow(blurRadius: 4, color: Colors.black54)]),
          ),
        ),
      ));
    }

    // Polylines
    final polylines = <Polyline>[];
    if (hasMyStation) {
      for (final q in withCoords) {
        polylines.add(Polyline(
          points: [LatLng(myLat, myLon), LatLng(q.contactLat!, q.contactLon!)],
          color: q == _selected
              ? Colors.orange.withOpacity(0.9)
              : Colors.orange.withOpacity(0.4),
          strokeWidth: q == _selected ? 2.5 : 1.2,
        ));
      }
    }

    final initialCenter = hasMyStation
        ? LatLng(myLat, myLon)
        : withCoords.isNotEmpty
            ? LatLng(withCoords.first.contactLat!, withCoords.first.contactLon!)
            : const LatLng(20, 0);

    return Scaffold(
      appBar: AppBar(
        title: Text('Map — ${withCoords.length} QSOs'),
        actions: [
          // Inline count field
          SizedBox(
            width: 64,
            height: 36,
            child: TextField(
              controller: _countCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white38),
                    borderRadius: BorderRadius.circular(6)),
                focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(6)),
                hintText: '10',
                hintStyle: const TextStyle(color: Colors.white38),
              ),
              onSubmitted: (_) => _applyCount(state),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            tooltip: 'Apply count',
            onPressed: () => _applyCount(state),
          ),
          if (hasMyStation)
            IconButton(
              icon: const Icon(Icons.my_location),
              tooltip: 'Center on my station',
              onPressed: () =>
                  _mapController.move(LatLng(myLat, myLon), 4),
            ),
        ],
      ),
      body: Column(
        children: [
          // Info bar
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Row(children: [
              const Icon(Icons.home_filled, size: 14, color: Colors.green),
              const SizedBox(width: 4),
              const Text('My station', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 16),
              const Icon(Icons.radio_button_checked,
                  size: 14, color: Colors.red),
              const SizedBox(width: 4),
              const Text('Contact', style: TextStyle(fontSize: 12)),
              const Spacer(),
              Text(
                withCoords.isEmpty
                    ? 'No QSOs with coordinates'
                    : '${withCoords.length} of ${state.qsos.length} QSOs plotted',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ]),
          ),
          // Map
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: 2.5,
                minZoom: 1.0,
                maxZoom: 18.0,
                onTap: (_, __) => setState(() => _selected = null),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.yourname.qsolog',
                  maxZoom: 18,
                ),
                if (polylines.isNotEmpty)
                  PolylineLayer(polylines: polylines),
                MarkerLayer(markers: markers),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
          ),
          // Selected QSO detail panel
          if (_selected != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12)),
              ),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_selected!.callsign,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      if (_selected!.contactName != null)
                        Text(_selected!.contactName!,
                            style: const TextStyle(fontSize: 13)),
                      Row(children: [
                        if (_selected!.contactCountry != null)
                          Text(_selected!.contactCountry!,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700)),
                        if (_selected!.contactState != null) ...[
                          Text(' · ',
                              style: TextStyle(
                                  color: Colors.grey.shade500)),
                          Text(_selected!.contactState!,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700)),
                        ],
                        if (_selected!.distanceKm != null) ...[
                          Text(' · ',
                              style: TextStyle(
                                  color: Colors.grey.shade500)),
                          Text(
                              state.formatDistance(
                                  _selected!.distanceKm!),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700)),
                        ],
                      ]),
                      Text(
                          '${_selected!.band} · ${_selected!.mode} · '
                          '${_selected!.frequency.toStringAsFixed(3)} MHz',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _selected = null),
                ),
              ]),
            ),
        ],
      ),
    );
  }
}
