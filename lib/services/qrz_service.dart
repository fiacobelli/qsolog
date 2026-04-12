// lib/services/qrz_service.dart
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
    this.name,
    this.qth,
    this.grid,
    this.country,
    this.state,
    this.lat,
    this.lon,
  });
}

class QrzService {
  static const _baseUrl = 'https://xmldata.qrz.com/xml/current/';
  String? _sessionKey;

  Future<bool> login(QrzSettings settings) async {
    if (settings.username.isEmpty || settings.password.isEmpty) return false;
    try {
      final response = await http.get(Uri.parse(
          '$_baseUrl?username=${settings.username}&password=${settings.password}&agent=HamLog1.0'));
      final doc = XmlDocument.parse(response.body);
      final key = doc.findAllElements('Key').firstOrNull?.innerText;
      if (key != null) {
        _sessionKey = key;
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<QrzCallsignData?> lookupCallsign(String callsign, QrzSettings settings) async {
    if (_sessionKey == null) {
      final ok = await login(settings);
      if (!ok) return null;
    }
    try {
      final response = await http.get(
          Uri.parse('$_baseUrl?s=$_sessionKey&callsign=${callsign.toUpperCase()}'));
      final doc = XmlDocument.parse(response.body);

      // Check for session error
      final error = doc.findAllElements('Error').firstOrNull?.innerText;
      if (error != null && error.toLowerCase().contains('session')) {
        _sessionKey = null;
        return await lookupCallsign(callsign, settings); // retry
      }

      final callEl = doc.findAllElements('Callsign').firstOrNull;
      if (callEl == null) return null;

      String? getText(String tag) =>
          callEl.findElements(tag).firstOrNull?.innerText;

      final fname = getText('fname') ?? '';
      final name = getText('name') ?? '';
      final fullName = [fname, name].where((s) => s.isNotEmpty).join(' ');

      final city = getText('addr2') ?? '';
      final state = getText('state') ?? '';
      final country = getText('country') ?? '';
      final qth = [city, state, country].where((s) => s.isNotEmpty).join(', ');

      return QrzCallsignData(
        callsign: callsign.toUpperCase(),
        name: fullName.isNotEmpty ? fullName : null,
        qth: qth.isNotEmpty ? qth : null,
        grid: getText('grid'),
        country: country.isNotEmpty ? country : null,
        state: state.isNotEmpty ? state : null,
        lat: double.tryParse(getText('lat') ?? ''),
        lon: double.tryParse(getText('lon') ?? ''),
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> uploadAdif(String adifContent, QrzSettings settings) async {
    if (_sessionKey == null) {
      final ok = await login(settings);
      if (!ok) return false;
    }
    try {
      final response = await http.post(
        Uri.parse('https://logbook.qrz.com/api'),
        body: {
          'KEY': settings.password, // QRZ uses API key for logbook
          'ACTION': 'INSERT',
          'ADIF': adifContent,
        },
      );
      return response.body.contains('RESULT=OK') || response.body.contains('COUNT=');
    } catch (_) {
      return false;
    }
  }
}
