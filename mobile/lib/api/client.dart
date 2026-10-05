import 'dart:convert';
import 'package:http/http.dart' as http;

class OfficeModel {
  final String id;
  final String name;
  final String address;
  final String timezone;
  final String openTime;
  final String closeTime;

  OfficeModel({
    required this.id,
    required this.name,
    required this.address,
    required this.timezone,
    required this.openTime,
    required this.closeTime,
  });

  factory OfficeModel.fromJson(Map<String, dynamic> json) {
    return OfficeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      timezone: json['timezone'] as String,
      openTime: json['open_time'] as String,
      closeTime: json['close_time'] as String,
    );
  }
}

class ServiceModel {
  final String id;
  final String officeId;
  final String code;
  final Map<String, dynamic> names;
  final double priorAvgMinutes;
  final List<dynamic> requiredDocs;
  final bool priorityAllowed;
  final bool requiresPhysicalVisit;
  final String? onlineAlternativeUrl;
  final int? indicativeWaitMinutes;

  ServiceModel({
    required this.id,
    required this.officeId,
    required this.code,
    required this.names,
    required this.priorAvgMinutes,
    required this.requiredDocs,
    required this.priorityAllowed,
    required this.requiresPhysicalVisit,
    this.onlineAlternativeUrl,
    this.indicativeWaitMinutes,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as String,
      officeId: json['office_id'] as String,
      code: json['code'] as String,
      names: (json['names'] as Map<String, dynamic>?) ?? {},
      priorAvgMinutes: (json['prior_avg_minutes'] as num).toDouble(),
      requiredDocs: (json['required_docs'] as List<dynamic>?) ?? [],
      priorityAllowed: json['priority_allowed'] as bool? ?? true,
      requiresPhysicalVisit: json['requires_physical_visit'] as bool? ?? true,
      onlineAlternativeUrl: json['online_alternative_url'] as String?,
      indicativeWaitMinutes: json['indicative_wait_minutes'] as int?,
    );
  }

  String localizedName(String lang) {
    return names[lang]?.toString() ?? names['en']?.toString() ?? code;
  }
}

class TokenModel {
  final String id;
  final String officeId;
  final String serviceId;
  final String businessDate;
  final int seq;
  final String displayCode;
  final String state;
  final String category;
  final String priorityStatus;
  final String createdVia;
  final String? phone;
  final String? counterLabel;
  final String? arrivedAt;
  final String? calledAt;
  final String? servingStartedAt;
  final String? completedAt;
  final double? lastEtaMinutes;
  final double? etaLow;
  final double? etaHigh;
  final int waitingAhead;
  final String? nowServing;

  TokenModel({
    required this.id,
    required this.officeId,
    required this.serviceId,
    required this.businessDate,
    required this.seq,
    required this.displayCode,
    required this.state,
    required this.category,
    required this.priorityStatus,
    required this.createdVia,
    this.phone,
    this.counterLabel,
    this.arrivedAt,
    this.calledAt,
    this.servingStartedAt,
    this.completedAt,
    this.lastEtaMinutes,
    this.etaLow,
    this.etaHigh,
    required this.waitingAhead,
    this.nowServing,
  });

  factory TokenModel.fromJson(Map<String, dynamic> json) {
    return TokenModel(
      id: json['id'] as String,
      officeId: json['office_id'] as String,
      serviceId: json['service_id'] as String,
      businessDate: json['business_date'] as String,
      seq: json['seq'] as int,
      displayCode: json['display_code'] as String,
      state: json['state'] as String,
      category: json['category'] as String,
      priorityStatus: json['priority_status'] as String,
      createdVia: json['created_via'] as String,
      phone: json['phone'] as String?,
      counterLabel: json['counter_label'] as String?,
      arrivedAt: json['arrived_at'] as String?,
      calledAt: json['called_at'] as String?,
      servingStartedAt: json['serving_started_at'] as String?,
      completedAt: json['completed_at'] as String?,
      lastEtaMinutes: (json['last_eta_minutes'] as num?)?.toDouble(),
      etaLow: (json['eta_low'] as num?)?.toDouble(),
      etaHigh: (json['eta_high'] as num?)?.toDouble(),
      waitingAhead: json['waiting_ahead'] as int? ?? 0,
      nowServing: json['now_serving'] as String?,
    );
  }
}

class ApiClient {
  final String baseUrl;
  final http.Client _client = http.Client();

  ApiClient({this.baseUrl = 'http://localhost:8000'});

  Map<String, String> _headers(String? token) {
    final h = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  Future<List<OfficeModel>> fetchOffices() async {
    final res = await _client.get(Uri.parse('$baseUrl/v1/citizen/offices'));
    if (res.statusCode != 200) {
      throw Exception('Failed to load offices: ${res.statusCode}');
    }
    final List<dynamic> body = jsonDecode(res.body);
    return body.map((o) => OfficeModel.fromJson(o as Map<String, dynamic>)).toList();
  }

  Future<List<ServiceModel>> fetchServices(String officeId) async {
    final res = await _client.get(Uri.parse('$baseUrl/v1/citizen/offices/$officeId/services'));
    if (res.statusCode != 200) {
      throw Exception('Failed to load services: ${res.statusCode}');
    }
    final List<dynamic> body = jsonDecode(res.body);
    return body.map((s) => ServiceModel.fromJson(s as Map<String, dynamic>)).toList();
  }

  Future<TokenModel> bookToken({
    required String token,
    required String officeId,
    required String serviceId,
    required String category,
    required String phone,
    String? beneficiaryName,
    String? priorityDocType,
    int travelMinutes = 0,
    required String idempotencyKey,
  }) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/v1/citizen/tokens'),
      headers: {
        ..._headers(token),
        'Idempotency-Key': idempotencyKey,
      },
      body: jsonEncode({
        'office_id': officeId,
        'service_id': serviceId,
        'category': category,
        'phone': phone,
        'beneficiary_name': beneficiaryName,
        'priority_doc_type': priorityDocType,
        'travel_minutes': travelMinutes,
      }),
    );
    if (res.statusCode != 201) {
      final err = jsonDecode(res.body);
      throw Exception(err['error']?['message'] ?? 'Booking failed (${res.statusCode})');
    }
    return TokenModel.fromJson(jsonDecode(res.body));
  }

  Future<TokenModel?> getActiveToken(String token) async {
    final res = await _client.get(
      Uri.parse('$baseUrl/v1/citizen/tokens/me/active'),
      headers: _headers(token),
    );
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch active token: ${res.statusCode}');
    }
    final body = jsonDecode(res.body);
    if (body == null) return null;
    return TokenModel.fromJson(body);
  }

  Future<TokenModel> checkIn({
    required String token,
    required String tokenId,
    required String qrPayload,
  }) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/v1/citizen/tokens/$tokenId/check-in'),
      headers: _headers(token),
      body: jsonEncode({'qr_payload': qrPayload}),
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body);
      throw Exception(err['error']?['message'] ?? 'Check-in failed');
    }
    return TokenModel.fromJson(jsonDecode(res.body));
  }

  Future<TokenModel> cancelToken({
    required String token,
    required String tokenId,
    String? reason,
  }) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/v1/citizen/tokens/$tokenId/cancel'),
      headers: _headers(token),
      body: jsonEncode({'reason': reason}),
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body);
      throw Exception(err['error']?['message'] ?? 'Cancellation failed');
    }
    return TokenModel.fromJson(jsonDecode(res.body));
  }

  Future<void> updateLanguage({
    required String token,
    required String language,
  }) async {
    await _client.patch(
      Uri.parse('$baseUrl/v1/me'),
      headers: _headers(token),
      body: jsonEncode({'language': language}),
    );
  }

  Future<String> getDevToken({
    required String phone,
    String role = 'CITIZEN',
    String? officeId,
    String? name,
  }) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/internal/dev-token'),
      headers: {'Content-Type': 'application/json', 'X-Internal-Secret': 'default_dev_tick_secret'},
      body: jsonEncode({
        'role': role,
        'phone': phone,
        'office_id': officeId,
        'name': name,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to get dev token: ${res.statusCode}');
    }
    final data = jsonDecode(res.body);
    final devTokens = data['dev_tokens'] as Map<String, dynamic>;
    if (devTokens.containsKey('citizen')) {
      return devTokens['citizen']['token'] as String;
    }
    return devTokens.values.first['token'] as String;
  }
}
