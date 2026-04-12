// lib/services/adif_service.dart
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

// ADIF fields mapped to dedicated QsoEntry properties — not stored in adifFields
const _mappedFields = {
  'CALL', 'QSO_DATE', 'TIME_ON', 'BAND', 'FREQ', 'MODE',
  'RST_SENT', 'RST_RCVD', 'NAME', 'QTH', 'GRIDSQUARE',
  'COUNTRY', 'STATE', 'COMMENT', 'NOTES', 'APP_HAMLOG_TAGS',
  'STATION_CALLSIGN', 'MY_GRIDSQUARE', 'TX_PWR', 'MY_CITY',
  'ADIF_VER', 'PROGRAMID', 'EOH', 'EOR',
};

class AdifService {
  static String exportQsos(List<QsoEntry> qsos, StationSettings station,
      {RigDefinition? rig}) {
    final buf = StringBuffer();
    buf.writeln('QSOLog ADIF Export');
    buf.writeln('Generated: ${DateTime.now().toUtc().toIso8601String()}');
    buf.writeln('<ADIF_VER:5>3.1.4');
    buf.writeln('<PROGRAMID:6>QSOLog');
    buf.writeln('<EOH>');
    buf.writeln();

    for (final q in qsos) {
      final dt = q.dateTime.toUtc();
      final date = DateFormat('yyyyMMdd').format(dt);
      final time = DateFormat('HHmmss').format(dt);

      buf.write(_field('CALL', q.callsign));
      buf.write(_field('QSO_DATE', date));
      buf.write(_field('TIME_ON', time));
      buf.write(_field('BAND', q.band));
      buf.write(_field('FREQ', q.frequency.toStringAsFixed(4)));
      buf.write(_field('MODE', q.mode));
      buf.write(_field('RST_SENT', q.rstSent));
      buf.write(_field('RST_RCVD', q.rstReceived));

      // Contact info
      if (q.contactName != null) buf.write(_field('NAME', q.contactName!));
      if (q.contactQth != null) buf.write(_field('QTH', q.contactQth!));
      if (q.contactGrid != null) buf.write(_field('GRIDSQUARE', q.contactGrid!));
      if (q.contactCountry != null) buf.write(_field('COUNTRY', q.contactCountry!));
      if (q.contactState != null) buf.write(_field('STATE', q.contactState!));

      // My station info — prefer per-QSO values, fall back to current settings
      final myCall = q.myCallsign?.isNotEmpty == true ? q.myCallsign! : station.callsign;
      final myGrid = q.myGrid?.isNotEmpty == true ? q.myGrid! : station.grid;
      final myQth  = q.myQth?.isNotEmpty == true ? q.myQth! : station.qth;
      final myPow  = q.myPower ?? rig?.power;

      if (myCall.isNotEmpty) buf.write(_field('STATION_CALLSIGN', myCall));
      if (myGrid.isNotEmpty) buf.write(_field('MY_GRIDSQUARE', myGrid));
      if (myQth.isNotEmpty)  buf.write(_field('MY_CITY', myQth));
      if (myPow != null && myPow > 0) buf.write(_field('TX_PWR', myPow.toStringAsFixed(0)));

      if (q.comments.isNotEmpty) buf.write(_field('COMMENT', q.comments));
      if (q.tags.isNotEmpty) buf.write(_field('APP_HAMLOG_TAGS', q.tags.join(',')));

      // All extra ADIF fields (satellite name, prop mode, contest exchange, etc.)
      for (final entry in q.adifFields.entries) {
        buf.write(_field(entry.key.toUpperCase(), entry.value));
      }

      buf.writeln('<EOR>');
      buf.writeln();
    }
    return buf.toString();
  }

  static String _field(String name, String value) {
    return '<$name:${value.length}>$value ';
  }

  static List<QsoEntry> importAdif(String content) {
    final qsos = <QsoEntry>[];
    final uuid = const Uuid();

    // Strip header before <EOH>
    final eohIndex = content.toUpperCase().indexOf('<EOH>');
    final body = eohIndex >= 0 ? content.substring(eohIndex + 5) : content;

    final records = body.split(RegExp(r'<EOR>', caseSensitive: false));

    for (final record in records) {
      if (record.trim().isEmpty) continue;

      final fields = _parseRecord(record);
      if (!fields.containsKey('CALL')) continue;

      final callsign = (fields['CALL'] ?? '').trim().toUpperCase();
      if (callsign.isEmpty) continue;

      // Parse date/time as UTC
      final dateStr = fields['QSO_DATE'] ?? '';
      final timeStr = fields['TIME_ON'] ?? '000000';
      DateTime dt;
      try {
        dt = DateTime.utc(
          int.parse(dateStr.substring(0, 4)),
          int.parse(dateStr.substring(4, 6)),
          int.parse(dateStr.substring(6, 8)),
          int.tryParse(timeStr.length >= 2 ? timeStr.substring(0, 2) : '0') ?? 0,
          int.tryParse(timeStr.length >= 4 ? timeStr.substring(2, 4) : '0') ?? 0,
        );
      } catch (_) {
        dt = DateTime.now().toUtc();
      }

      final freqStr = fields['FREQ'] ?? '14.0';
      final freq = double.tryParse(freqStr) ?? 14.0;
      final band = fields['BAND'] ?? BandFrequency.bandFromFrequency(freq);

      final tagsStr = fields['APP_HAMLOG_TAGS'] ?? '';
      final tags = tagsStr.isNotEmpty
          ? tagsStr.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList()
          : <String>[];

      // Pull out my station info from the ADIF if present
      // addQso() will fill in any blanks from current settings
      final myCallsign = fields['STATION_CALLSIGN'];
      final myGrid     = fields['MY_GRIDSQUARE'];
      final myQth      = fields['MY_CITY'];
      final myPower    = double.tryParse(fields['TX_PWR'] ?? '');

      // Collect all remaining fields not mapped to dedicated properties
      final adifFields = <String, String>{};
      for (final entry in fields.entries) {
        if (!_mappedFields.contains(entry.key)) {
          adifFields[entry.key] = entry.value;
        }
      }

      qsos.add(QsoEntry(
        id: uuid.v4(),
        callsign: callsign,
        band: band,
        frequency: freq,
        mode: fields['MODE'] ?? 'SSB',
        rstSent: fields['RST_SENT'] ?? '59',
        rstReceived: fields['RST_RCVD'] ?? '59',
        comments: fields['COMMENT'] ?? fields['NOTES'] ?? '',
        dateTime: dt,
        contactName: fields['NAME'],
        contactQth: fields['QTH'],
        contactGrid: fields['GRIDSQUARE'],
        contactCountry: fields['COUNTRY'],
        contactState: fields['STATE'],
        myCallsign: myCallsign,
        myGrid: myGrid,
        myQth: myQth,
        myPower: myPower,
        tags: tags,
        adifFields: adifFields,
      ));
    }
    return qsos;
  }

  // Parses a single ADIF record — keys uppercased, values keep original case
  static Map<String, String> _parseRecord(String record) {
    final result = <String, String>{};
    final re = RegExp(r'<([^:>]+)(?::(\d+)(?::[^>]*)?)?>([^<]*)', caseSensitive: false);
    for (final m in re.allMatches(record)) {
      final name = m.group(1)?.toUpperCase() ?? '';
      final lenStr = m.group(2);
      final rest = m.group(3) ?? '';
      if (name == 'EOH' || name == 'EOR') continue;
      final len = int.tryParse(lenStr ?? '');
      final value = len != null && len <= rest.length
          ? rest.substring(0, len)
          : rest.trim();
      if (value.isNotEmpty) result[name] = value;
    }
    return result;
  }
}
