// lib/services/qrz_service.dart
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/models.dart';


class QrzCallsignData {
  final String callsign;
  final String? name;
  final String? qth;
  final String? grid;
  final String? country;
  final String? state;
  final double? lat;
  final double? lon;

  QrzCallsignData({
    required this.callsign,
    this.name, this.qth, this.grid,
    this.country, this.state,
    this.lat, this.lon,
  });
}

/// Result from a paginated FETCH operation
class QrzFetchResult {
  final List<Map<String, String>> records; // each record is a map of ADIF field → value
  final int count;
  final bool ok;
  final String? error;

  QrzFetchResult({required this.records, required this.count,
      this.ok = true, this.error});
}

class QrzService {
  static const _xmlBase  = 'https://xmldata.qrz.com/xml/current/';
  static const _apiBase  = 'https://logbook.qrz.com/api';
  static const _pageSize = 250;
  String? _sessionKey;

  // ── XML callsign lookup ──────────────────────────────────────────────────

  Future<bool> login(QrzSettings settings, {Duration timeout = const Duration(seconds: 10)}) async {
    if (settings.username.isEmpty || settings.password.isEmpty) return false;
    try {
      final response = await http.get(Uri.parse(
          '$_xmlBase?username=${settings.username}&password=${settings.password}&agent=QSOLog1.0'),
      ).timeout(timeout);
      final doc = XmlDocument.parse(response.body);
      final key = doc.findAllElements('Key').firstOrNull?.innerText;
      if (key != null) { _sessionKey = key; return true; }
    } catch (_) {}
    return false;
  }

  // timeout is intentionally short so background lookups fail fast when offline.
  Future<QrzCallsignData?> lookupCallsign(
    String callsign,
    QrzSettings settings, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (settings.username.isEmpty || settings.password.isEmpty) return null;
    if (_sessionKey == null) {
      final ok = await login(settings, timeout: timeout);
      if (!ok) return null;
    }
    try {
      final response = await http.get(Uri.parse(
          '$_xmlBase?s=$_sessionKey&callsign=${callsign.toUpperCase()}'),
      ).timeout(timeout);
      final doc = XmlDocument.parse(response.body);
      // Retry on session expiry
      final error = doc.findAllElements('Error').firstOrNull?.innerText;
      if (error != null && error.toLowerCase().contains('session')) {
        _sessionKey = null;
        return await lookupCallsign(callsign, settings, timeout: timeout);
      }
      final callEl = doc.findAllElements('Callsign').firstOrNull;
      if (callEl == null) return null;
      String? get(String tag) => callEl.findElements(tag).firstOrNull?.innerText;
      final fname   = get('fname') ?? '';
      final name    = get('name')  ?? '';
      final fullName = [fname, name].where((s) => s.isNotEmpty).join(' ');
      final city    = get('addr2') ?? '';
      final state   = get('state') ?? '';
      final country = get('country') ?? '';
      final qth = [city, state, country].where((s) => s.isNotEmpty).join(', ');
      return QrzCallsignData(
        callsign: callsign.toUpperCase(),
        name: fullName.isNotEmpty ? fullName : null,
        qth: qth.isNotEmpty ? qth : null,
        grid: get('grid'),
        country: country.isNotEmpty ? country : null,
        state: state.isNotEmpty ? state : null,
        lat: double.tryParse(get('lat') ?? ''),
        lon: double.tryParse(get('lon') ?? ''),
      );
    } catch (_) { return null; }
  }

  Future<bool> testLogin(QrzSettings settings) async {
    _sessionKey = null;
    return await login(settings);
  }

  // ── Logbook API helpers ──────────────────────────────────────────────────

  /// Parse the flat key=value header portion of a QRZ API response.
  /// The ADIF block (everything from the first '<' onward) is excluded
  /// from this parsing and handled separately.
  Map<String, String> _parseResponseHeader(String body) {
    final result = <String, String>{};
    // Extract only the part before the ADIF block starts
    final adifStart = body.indexOf('<');
    final header = adifStart >= 0 ? body.substring(0, adifStart) : body;
    for (final part in header.split('&')) {
      final idx = part.indexOf('=');
      if (idx > 0) {
        final key = part.substring(0, idx).trim();
        final val = part.substring(idx + 1).trim();
        result[key] = val;
      }
    }
    return result;
  }

  /// Extract the raw ADIF block from a QRZ FETCH response body.
  /// QRZ returns: RESULT=OK&COUNT=N&ADIF=<field:len>value...<eor>...
  /// The ADIF starts at the first '<' character.
  String _extractAdif(String body) {
    final adifStart = body.indexOf('<');
    if (adifStart < 0) return '';
    return body.substring(adifStart);
  }

  /// Sometimes ADIF may come HTML escaped... 
  String _simpleUnescape(String input) {
    return input
      .replaceAll('&gt;', '>')
      .replaceAll('&lt;', '<')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'");
  }
  /// Parse ADIF records from a raw ADIF string returned by QRZ FETCH.
  /// Returns a list of field maps, each keyed by uppercase ADIF field name.
  List<Map<String, String>> _parseAdifRecords(String adif) {
    final records = <Map<String, String>>[];
    // Split on <eor> case-insensitively
    final parts = adif.split(RegExp(r'<eor>', caseSensitive: false));
    // ADIF field pattern: <FIELDNAME:LENGTH>VALUE or <FIELDNAME>VALUE
    final fieldPattern = RegExp(
        r'<([A-Za-z_][A-Za-z0-9_]*)(?::\d+(?::[A-Za-z])?)?>([^<]*)',
        caseSensitive: false);

    for (final part in parts) {
      if (part.trim().isEmpty) continue;
      final fields = <String, String>{};
      for (final m in fieldPattern.allMatches(part)) {
        final name = m.group(1)!.toUpperCase();
        final value = m.group(2) ?? '';
        // Skip header-like fields
        if (name == 'EOH') continue;
        if (value.trim().isNotEmpty) fields[name] = value.trim();
      }
      // Only add if it looks like a QSO record
      if (fields.containsKey('CALL')) records.add(fields);
    }
    return records;
  }

  // ── Upload (paginated) ───────────────────────────────────────────────────

  Future<bool> testApiKey(QrzSettings settings) async {
    if (settings.apiKey.isEmpty) return false;
    try {
      final response = await http.post(
        Uri.parse(_apiBase),
        headers: {'User-Agent': 'QSOLog/1.0'},
        body: {'KEY': settings.apiKey, 'ACTION': 'STATUS'},
      ).timeout(const Duration(seconds: 15));
      return response.body.contains('RESULT=OK') ||
             response.body.contains('LOGID=') ||
             response.body.contains('COUNT=');
    } catch (_) { return false; }
  }

  /// Upload QSOs one record at a time (QRZ INSERT only processes the first
  /// record from a multi-record ADIF block). Returns count actually uploaded.
  Future<int> uploadAdifPaginated(
    String adifContent,
    QrzSettings settings, {
    void Function(int uploaded, int total)? onProgress,
  }) async {
    if (settings.apiKey.isEmpty) return 0;

    // Strip ADIF header (everything up to and including <EOH>) so the first
    // split chunk isn't contaminated with header fields.
    final eohIdx = adifContent.toUpperCase().indexOf('<EOH>');
    final body = eohIdx >= 0 ? adifContent.substring(eohIdx + 5) : adifContent;

    final records = body
        .split(RegExp(r'<eor>', caseSensitive: false))
        .map((r) => r.trim())
        .where((r) => r.isNotEmpty)
        .toList();

    int uploaded = 0;
    final total = records.length;

    for (final record in records) {
      try {
        final response = await http.post(
          Uri.parse(_apiBase),
          headers: {'User-Agent': 'QSOLog/1.0'},
          body: {'KEY': settings.apiKey, 'ACTION': 'INSERT', 'ADIF': '$record<EOR>'},
        ).timeout(const Duration(seconds: 30));
        if (response.body.contains('RESULT=OK')) {
          uploaded++;
        }
      } catch (_) {}
      onProgress?.call(uploaded, total);
    }
    return uploaded;
  }

  Future<bool> uploadAdif(String adifContent, QrzSettings settings) async {
    final uploaded = await uploadAdifPaginated(adifContent, settings);
    return uploaded > 0;
  }

  // ── Download (paginated FETCH) ───────────────────────────────────────────

  Future<QrzFetchResult> fetchQsosSince(
    QrzSettings settings,
    DateTime? afterDate, {
    void Function(int fetched)? onProgress,
  }) async {
    if (settings.apiKey.isEmpty) {
      return QrzFetchResult(records: [], count: 0, ok: false,
          error: 'No API key configured');
    }

    final allRecords = <Map<String, String>>[];
    int afterLogId = 0;

    // Build BETWEEN date option. QRZ format: BETWEEN:YYYY-MM-DD+YYYY-MM-DD
    String dateOption = '';
    if (afterDate != null) {
      String fmt(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
      final now = DateTime.now().toUtc();
      dateOption = ',BETWEEN:${fmt(afterDate)}+${fmt(now)}';
    }

    while (true) {
      // Build OPTIONS string — no spaces, comma-separated name:value pairs
      final options = 'MAX:$_pageSize,AFTERLOGID:$afterLogId$dateOption';

      try {
        final response = await http.post(
          Uri.parse(_apiBase),
          headers: {'User-Agent': 'QSOLog/1.0'},
          body: {
            'KEY': settings.apiKey,
            'ACTION': 'FETCH',
            'OPTION': options,
          },
        ).timeout(const Duration(seconds: 45));

        // DEBUG — print raw response so we can diagnose
        debugPrint('QRZ FETCH OPTIONS: $options');

        final body = _simpleUnescape(response.body);
        debugPrint('QRZ FETCH RAW RESPONSE: ${response.body}');

        // Check for failure in the header portion
        final header = _parseResponseHeader(body);
        if (header['RESULT'] == 'FAIL') {
          return QrzFetchResult(
              records: allRecords, count: allRecords.length,
              ok: false, error: header['REASON'] ?? 'QRZ returned FAIL');
        }

        // Extract and parse the ADIF block
        final adif = _extractAdif(body);
        if (adif.isEmpty) break; // no ADIF data — done

        final pageRecords = _parseAdifRecords(adif);
        if (pageRecords.isEmpty) break;

        allRecords.addAll(pageRecords);
        onProgress?.call(allRecords.length);

        // If fewer than a full page, we've reached the end
        if (pageRecords.length < _pageSize) break;

        // Find the highest logid for next page cursor
        int maxLogId = 0;
        for (final r in pageRecords) {
          // QRZ returns the logid as APP_QRZLOG_LOGID or APP_QRZLOG_QSOID
          final raw = r['APP_QRZLOG_LOGID'] ?? r['APP_QRZLOG_QSOID'] ?? '';
          final lid = int.tryParse(raw) ?? 0;
          if (lid > maxLogId) maxLogId = lid;
        }

        if (maxLogId == 0) break; // logid not returned — can't paginate safely
        afterLogId = maxLogId + 1;

      } catch (e) {
        return QrzFetchResult(
            records: allRecords, count: allRecords.length,
            ok: false, error: 'Network error: $e');
      }
    }

    return QrzFetchResult(
        records: allRecords, count: allRecords.length, ok: true);
  }
}
