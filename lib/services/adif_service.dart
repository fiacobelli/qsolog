// lib/services/adif_service.dart
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

/// ADIF fields that are mapped to dedicated QsoEntry properties.
/// Everything else goes into / comes from adifFields map.
const _mappedFields = {
  // Contact
  'CALL', 'QSO_DATE', 'TIME_ON', 'TIME_OFF',
  'BAND', 'FREQ', 'MODE', 'SUBMODE',
  'RST_SENT', 'RST_RCVD',
  'NAME', 'QTH', 'GRIDSQUARE', 'COUNTRY', 'STATE',
  'LAT', 'LON',
  'COMMENT', 'NOTES',
  // My station
  'STATION_CALLSIGN', 'OPERATOR',
  'MY_GRIDSQUARE', 'MY_CITY', 'MY_STATE', 'MY_COUNTRY',
  'MY_LAT', 'MY_LON',
  'TX_PWR',
  'MY_RIG',
  // App internal
  'APP_HAMLOG_TAGS', 'APP_QRZLOG_LOGID', 'APP_QRZLOG_QSOID',
  // Header
  'ADIF_VER', 'PROGRAMID', 'CREATED_TIMESTAMP', 'EOH', 'EOR',
};

class AdifService {
  // ── Export ─────────────────────────────────────────────────────────────

  static String exportQsos(
    List<QsoEntry> qsos,
    StationSettings station, {
    RigDefinition? rig,
  }) {
    final buf = StringBuffer();

    // ADIF header
    buf.writeln(_field('ADIF_VER', '3.1.4'));
    buf.writeln(_field('PROGRAMID', 'QSOLog'));
    buf.writeln(_field('CREATED_TIMESTAMP',
        DateFormat('yyyyMMdd HHmmss').format(DateTime.now().toUtc())));
    buf.writeln('<EOH>');
    buf.writeln();

    for (final q in qsos) {
      final dt   = q.dateTime.toUtc();
      final date = DateFormat('yyyyMMdd').format(dt);
      final time = DateFormat('HHmmss').format(dt);

      // ── Mandatory fields ──────────────────────────────────────────────
      buf.write(_field('CALL',     q.callsign));
      buf.write(_field('QSO_DATE', date));
      buf.write(_field('TIME_ON',  time));
      buf.write(_field('BAND',     q.band));
      buf.write(_field('FREQ',     q.frequency.toStringAsFixed(4)));
      buf.write(_field('MODE',     q.mode));
      buf.write(_field('RST_SENT', q.rstSent));
      buf.write(_field('RST_RCVD', q.rstReceived));

      // ── Contact info ──────────────────────────────────────────────────
      if (q.contactName    != null) buf.write(_field('NAME',       q.contactName!));
      if (q.contactQth     != null) buf.write(_field('QTH',        q.contactQth!));
      if (q.contactGrid    != null) buf.write(_field('GRIDSQUARE', q.contactGrid!));
      if (q.contactCountry != null) buf.write(_field('COUNTRY',    q.contactCountry!));
      if (q.contactState   != null) buf.write(_field('STATE',      q.contactState!));
      if (q.contactLat     != null) buf.write(_field('LAT',  _fmtLatLon(q.contactLat!,  isLat: true)));
      if (q.contactLon     != null) buf.write(_field('LON',  _fmtLatLon(q.contactLon!, isLat: false)));

      // ── My station info ───────────────────────────────────────────────
      // Prefer per-QSO stamped values, fall back to current settings
      final myCall  = _coalesce(q.myCallsign,  station.callsign);
      final myGrid  = _coalesce(q.myGrid,      station.grid);
      final myQth   = _coalesce(q.myQth,       station.qth);
      final myRig   = _coalesce(q.myRig,       rig?.name);
      final myPower = q.myPower ?? rig?.power;

      if (myCall  != null) buf.write(_field('STATION_CALLSIGN', myCall));
      if (myGrid  != null) buf.write(_field('MY_GRIDSQUARE',    myGrid));
      if (myQth   != null) buf.write(_field('MY_CITY',          myQth));
      if (myRig   != null) buf.write(_field('MY_RIG',           myRig));
      if (myPower != null && myPower > 0)
        buf.write(_field('TX_PWR', myPower.toStringAsFixed(0)));

      // Station lat/lon
      if (station.lat != null)
        buf.write(_field('MY_LAT', _fmtLatLon(station.lat!, isLat: true)));
      if (station.lon != null)
        buf.write(_field('MY_LON', _fmtLatLon(station.lon!, isLat: false)));

      // ── Comments and tags ─────────────────────────────────────────────
      if (q.comments.isNotEmpty) buf.write(_field('COMMENT', q.comments));
      if (q.tags.isNotEmpty)
        buf.write(_field('APP_HAMLOG_TAGS', q.tags.join(',')));

      // ── Extra ADIF fields (POTA_REF, SOTA_REF, contest exchange, etc.) ─
      for (final entry in q.adifFields.entries) {
        final key = entry.key.toUpperCase();
        // Skip any field already exported above to avoid duplicates
        if (!_mappedFields.contains(key)) {
          buf.write(_field(key, entry.value));
        }
      }

      buf.writeln('<EOR>');
      buf.writeln();
    }

    return buf.toString();
  }

  // ── Import ─────────────────────────────────────────────────────────────

  static List<QsoEntry> importAdif(String content) {
    final qsos = <QsoEntry>[];
    final uuid = const Uuid();

    // Strip everything before (and including) <EOH>
    final eohIdx = content.toUpperCase().indexOf('<EOH>');
    final body   = eohIdx >= 0 ? content.substring(eohIdx + 5) : content;

    for (final record in body.split(RegExp(r'<EOR>', caseSensitive: false))) {
      if (record.trim().isEmpty) continue;

      final f = _parseRecord(record);
      if (!f.containsKey('CALL')) continue;

      final callsign = f['CALL']!.trim().toUpperCase();
      if (callsign.isEmpty) continue;

      // ── Date / time ──────────────────────────────────────────────────
      final dateStr = f['QSO_DATE'] ?? '';
      final timeStr = (f['TIME_ON'] ?? '000000').padRight(6, '0');
      DateTime dt;
      try {
        dt = DateTime.utc(
          int.parse(dateStr.substring(0, 4)),
          int.parse(dateStr.substring(4, 6)),
          int.parse(dateStr.substring(6, 8)),
          int.parse(timeStr.substring(0, 2)),
          int.parse(timeStr.substring(2, 4)),
          int.parse(timeStr.substring(4, 6)),
        );
      } catch (_) {
        dt = DateTime.now().toUtc();
      }

      // ── Frequency / band ─────────────────────────────────────────────
      final freq = double.tryParse(f['FREQ'] ?? '') ?? 14.0;
      final band = f['BAND'] ?? BandFrequency.bandFromFrequency(freq);

      // ── Contact coordinates ───────────────────────────────────────────
      final contactLat = _parseAdifLatLon(f['LAT']);
      final contactLon = _parseAdifLatLon(f['LON']);

      // ── My station ────────────────────────────────────────────────────
      final myCallsign = _nonEmpty(f['STATION_CALLSIGN'] ?? f['OPERATOR']);
      final myGrid     = _nonEmpty(f['MY_GRIDSQUARE']);
      final myQth      = _nonEmpty(f['MY_CITY']);
      final myRig      = _nonEmpty(f['MY_RIG']);
      final myPower    = double.tryParse(f['TX_PWR'] ?? '');

      // ── Tags ──────────────────────────────────────────────────────────
      final tagsStr = f['APP_HAMLOG_TAGS'] ?? '';
      final tags    = tagsStr.isNotEmpty
          ? tagsStr.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList()
          : <String>[];

      // ── Extra fields → adifFields ─────────────────────────────────────
      final adifFields = <String, String>{};
      for (final entry in f.entries) {
        if (!_mappedFields.contains(entry.key)) {
          adifFields[entry.key] = entry.value;
        }
      }

      qsos.add(QsoEntry(
        id:              uuid.v4(),
        callsign:        callsign,
        band:            band,
        frequency:       freq,
        mode:            f['MODE'] ?? 'SSB',
        rstSent:         f['RST_SENT'] ?? '59',
        rstReceived:     f['RST_RCVD'] ?? '59',
        comments:        f['COMMENT'] ?? f['NOTES'] ?? '',
        dateTime:        dt,
        contactName:     _nonEmpty(f['NAME']),
        contactQth:      _nonEmpty(f['QTH']),
        contactGrid:     _nonEmpty(f['GRIDSQUARE']),
        contactCountry:  _nonEmpty(f['COUNTRY']),
        contactState:    _nonEmpty(f['STATE']),
        contactLat:      contactLat,
        contactLon:      contactLon,
        myCallsign:      myCallsign,
        myGrid:          myGrid,
        myQth:           myQth,
        myRig:           myRig,
        myPower:         myPower,
        tags:            tags,
        adifFields:      adifFields,
      ));
    }

    return qsos;
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  static String _field(String name, String value) {
    if (value.isEmpty) return '';
    return '<$name:${value.length}>$value ';
  }

  /// ADIF LAT/LON format: XDDD MM.MMM  where X = N/S/E/W
  static String _fmtLatLon(double value, {required bool isLat}) {
    final positive = value >= 0;
    final abs = value.abs();
    final deg = abs.floor();
    final min = (abs - deg) * 60.0;
    final hemi = isLat ? (positive ? 'N' : 'S') : (positive ? 'E' : 'W');
    return '$hemi${deg.toString().padLeft(isLat ? 2 : 3, '0')} ${min.toStringAsFixed(3).padLeft(6, '0')}';
  }

  /// Parse ADIF LAT/LON format back to decimal degrees
  static double? _parseAdifLatLon(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final s = raw.trim();
      final hemi = s[0].toUpperCase();
      final rest = s.substring(1).trim();
      final parts = rest.split(' ');
      final deg = double.parse(parts[0]);
      final min = parts.length > 1 ? double.parse(parts[1]) : 0.0;
      final dec = deg + min / 60.0;
      return (hemi == 'S' || hemi == 'W') ? -dec : dec;
    } catch (_) {
      // Try plain decimal fallback
      return double.tryParse(raw.trim());
    }
  }

  /// Returns the first non-null non-empty value
  static String? _coalesce(String? a, [String? b]) {
    if (a != null && a.isNotEmpty) return a;
    if (b != null && b.isNotEmpty) return b;
    return null;
  }

  static String? _nonEmpty(String? s) =>
      (s != null && s.isNotEmpty) ? s : null;

  /// Parse a single ADIF record into a field map (keys uppercased)
  static Map<String, String> _parseRecord(String record) {
    final result = <String, String>{};
    final re = RegExp(
        r'<([A-Za-z_][A-Za-z0-9_]*)(?::(\d+)(?::[A-Za-z])?)?>([^<]*)',
        caseSensitive: false);
    for (final m in re.allMatches(record)) {
      final name   = m.group(1)!.toUpperCase();
      final lenStr = m.group(2);
      final rest   = m.group(3) ?? '';
      if (name == 'EOH' || name == 'EOR') continue;
      final len    = int.tryParse(lenStr ?? '');
      final value  = (len != null && len <= rest.length)
          ? rest.substring(0, len)
          : rest.trim();
      if (value.isNotEmpty) result[name] = value;
    }
    return result;
  }
}
