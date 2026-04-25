// lib/models/models.dart
import 'dart:convert';

class QsoEntry {
  final String id;
  String callsign;
  String band;
  double frequency;
  String mode;
  String rstSent;
  String rstReceived;
  String comments;
  DateTime dateTime; // always UTC

  // Contact (the other station)
  String? contactName;
  String? contactQth;
  String? contactGrid;
  String? contactCountry;
  String? contactState;
  double? contactLat;
  double? contactLon;

  // My station info — stamped automatically on every QSO
  String? myCallsign;
  String? myQth;
  String? myGrid;
  String? myRig;
  double? myPower;

  List<String> tags;
  // Stores ALL extra ADIF fields: satellite name, prop mode, contest exchange, etc.
  Map<String, String> adifFields;
  double? distanceKm;
  bool uploadedToQrz; // true once successfully uploaded to QRZ logbook

  QsoEntry({
    required this.id,
    required this.callsign,
    required this.band,
    required this.frequency,
    this.mode = 'SSB',
    this.rstSent = '59',
    this.rstReceived = '59',
    this.comments = '',
    required this.dateTime,
    this.contactName,
    this.contactQth,
    this.contactGrid,
    this.contactCountry,
    this.contactState,
    this.contactLat,
    this.contactLon,
    this.myCallsign,
    this.myQth,
    this.myGrid,
    this.myRig,
    this.myPower,
    this.tags = const [],
    this.adifFields = const {},
    this.distanceKm,
    this.uploadedToQrz = false,
  });

  // Convenience getters for common satellite / propagation fields
  String? get satName => adifFields['SAT_NAME'];
  String? get satMode => adifFields['SAT_MODE'];
  String? get propMode => adifFields['PROP_MODE'];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'callsign': callsign,
      'band': band,
      'frequency': frequency,
      'mode': mode,
      'rstSent': rstSent,
      'rstReceived': rstReceived,
      'comments': comments,
      'dateTime': dateTime.toUtc().toIso8601String(),
      'contactName': contactName,
      'contactQth': contactQth,
      'contactGrid': contactGrid,
      'contactCountry': contactCountry,
      'contactState': contactState,
      'contactLat': contactLat,
      'contactLon': contactLon,
      'myCallsign': myCallsign,
      'myQth': myQth,
      'myGrid': myGrid,
      'myRig': myRig,
      'myPower': myPower,
      'tags': jsonEncode(tags),
      'adifFields': jsonEncode(adifFields),
      'distanceKm': distanceKm,
      'uploadedToQrz': uploadedToQrz ? 1 : 0,
    };
  }

  factory QsoEntry.fromMap(Map<String, dynamic> map) {
    final rawAdif = map['adifFields'] ?? map['extraFields'];
    return QsoEntry(
      id: map['id'],
      callsign: map['callsign'],
      band: map['band'],
      frequency: (map['frequency'] as num).toDouble(),
      mode: map['mode'] ?? 'SSB',
      rstSent: map['rstSent'] ?? '59',
      rstReceived: map['rstReceived'] ?? '59',
      comments: map['comments'] ?? '',
      dateTime: DateTime.parse(map['dateTime']).toUtc(),
      contactName: map['contactName'],
      contactQth: map['contactQth'],
      contactGrid: map['contactGrid'],
      contactCountry: map['contactCountry'],
      contactState: map['contactState'],
      contactLat: map['contactLat'] != null ? (map['contactLat'] as num).toDouble() : null,
      contactLon: map['contactLon'] != null ? (map['contactLon'] as num).toDouble() : null,
      myCallsign: map['myCallsign'],
      myQth: map['myQth'],
      myGrid: map['myGrid'],
      myRig: map['myRig'],
      myPower: map['myPower'] != null ? (map['myPower'] as num).toDouble() : null,
      tags: map['tags'] != null ? List<String>.from(jsonDecode(map['tags'])) : [],
      adifFields: rawAdif != null ? Map<String, String>.from(jsonDecode(rawAdif)) : {},
      distanceKm: map['distanceKm'] != null ? (map['distanceKm'] as num).toDouble() : null,
      uploadedToQrz: (map['uploadedToQrz'] ?? 0) == 1,
    );
  }
}

class RigDefinition {
  final String id;
  String name;
  double power;

  RigDefinition({required this.id, required this.name, this.power = 100});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'power': power};

  factory RigDefinition.fromJson(Map<String, dynamic> json) => RigDefinition(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    power: json['power'] != null ? (json['power'] as num).toDouble() : 100,
  );
}

class StationSettings {
  String callsign;
  String operatorName;
  String qth;
  double? lat;
  double? lon;
  String grid;
  // active rig id — empty means "none selected"
  String activeRigId;

  StationSettings({
    this.callsign = '',
    this.operatorName = '',
    this.qth = '',
    this.lat,
    this.lon,
    this.grid = '',
    this.activeRigId = '',
  });

  Map<String, dynamic> toJson() => {
    'callsign': callsign,
    'operatorName': operatorName,
    'qth': qth,
    'lat': lat,
    'lon': lon,
    'grid': grid,
    'activeRigId': activeRigId,
  };

  factory StationSettings.fromJson(Map<String, dynamic> json) => StationSettings(
    callsign: json['callsign'] ?? '',
    operatorName: json['operatorName'] ?? '',
    qth: json['qth'] ?? '',
    lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
    lon: json['lon'] != null ? (json['lon'] as num).toDouble() : null,
    grid: json['grid'] ?? '',
    activeRigId: json['activeRigId'] ?? '',
  );
}

class QrzSettings {
  String username;  // used for XML callsign lookup login
  String password;  // used for XML callsign lookup login
  String apiKey;    // used for logbook upload API
  String? sessionKey;

  QrzSettings({
    this.username = '',
    this.password = '',
    this.apiKey = '',
    this.sessionKey,
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'password': password,
    'apiKey': apiKey,
  };

  factory QrzSettings.fromJson(Map<String, dynamic> json) => QrzSettings(
    username: json['username'] ?? '',
    password: json['password'] ?? '',
    apiKey: json['apiKey'] ?? '',
  );
}

class TagDefinition {
  final String id;
  String name;
  String color; // hex color

  TagDefinition({required this.id, required this.name, this.color = '#2196F3'});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'color': color};
  factory TagDefinition.fromJson(Map<String, dynamic> json) =>
      TagDefinition(id: json['id'], name: json['name'], color: json['color'] ?? '#2196F3');
}

class BandFrequency {
  static const Map<String, List<double>> bands = {
    '160m': [1.8, 2.0],
    '80m': [3.5, 4.0],
    '60m': [5.3305, 5.4035],
    '40m': [7.0, 7.3],
    '30m': [10.1, 10.15],
    '20m': [14.0, 14.35],
    '17m': [18.068, 18.168],
    '15m': [21.0, 21.45],
    '12m': [24.89, 24.99],
    '10m': [28.0, 29.7],
    '6m': [50.0, 54.0],
    '2m': [144.0, 148.0],
    '70cm': [420.0, 450.0],
  };

  static String bandFromFrequency(double freq) {
    for (final entry in bands.entries) {
      if (freq >= entry.value[0] && freq <= entry.value[1]) {
        return entry.key;
      }
    }
    return 'Unknown';
  }
}

class PotaSpot {
  final String activatorCallsign;
  final String parkReference;
  final String parkName;
  final double frequency;
  final String mode;
  final String comments;
  final String grid;
  final String state;

  PotaSpot({
    required this.activatorCallsign,
    required this.parkReference,
    required this.parkName,
    required this.frequency,
    required this.mode,
    this.comments = '',
    this.grid = '',
    this.state = '',
  });

  factory PotaSpot.fromJson(Map<String, dynamic> json) {
    // POTA API returns frequency in kHz — convert to MHz
    final freqKhz = double.tryParse(json['frequency']?.toString() ?? '0') ?? 0;
    final freqMhz = freqKhz >= 100 ? freqKhz / 1000.0 : freqKhz; // guard: if already MHz don't double-convert
    return PotaSpot(
      activatorCallsign: json['activator'] ?? '',
      parkReference: json['reference'] ?? '',
      parkName: json['name'] ?? '',
      frequency: freqMhz,
      mode: json['mode'] ?? '',
      comments: json['comments'] ?? '',
      grid: json['grid'] ?? '',
      state: json['locationDesc'] ?? '',
    );
  }
}
