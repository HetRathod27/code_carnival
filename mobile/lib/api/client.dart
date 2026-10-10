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
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      address: (json['address'] as String?) ?? '',
      timezone: (json['timezone'] as String?) ?? 'Asia/Kolkata',
      openTime: (json['open_time'] as String?) ?? '',
      closeTime: (json['close_time'] as String?) ?? '',
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
  final String counterStatus;

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
    this.counterStatus = 'OPEN',
  });

  bool get isCounterOpen => counterStatus == 'OPEN';
  bool get isCounterOnBreak => counterStatus == 'BREAK';
  bool get isCounterClosed => counterStatus == 'CLOSED';

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: (json['id'] as String?) ?? '',
      officeId: (json['office_id'] as String?) ?? '',
      code: (json['code'] as String?) ?? '',
      names: (json['names'] as Map<String, dynamic>?) ?? {},
      priorAvgMinutes: (json['prior_avg_minutes'] as num?)?.toDouble() ?? 0.0,
      requiredDocs: (json['required_docs'] as List<dynamic>?) ?? [],
      priorityAllowed: json['priority_allowed'] as bool? ?? true,
      requiresPhysicalVisit: json['requires_physical_visit'] as bool? ?? true,
      onlineAlternativeUrl: json['online_alternative_url'] as String?,
      indicativeWaitMinutes: (json['indicative_wait_minutes'] as num?)?.round(),
      counterStatus: (json['counter_status'] as String?) ?? 'OPEN',
    );
  }

  String localizedName(String lang) {
    return names[lang]?.toString() ?? names['en']?.toString() ?? code;
  }
}


class SlotItemModel {
  final String slotTime;
  final String startTime;
  final String endTime;
  final bool available;
  final String status;
  final String reasonCode;
  final int remainingCapacity;
  final int bookedCount;
  final int totalCapacity;

  SlotItemModel({
    required this.slotTime,
    required this.startTime,
    required this.endTime,
    required this.available,
    required this.status,
    required this.reasonCode,
    required this.remainingCapacity,
    required this.bookedCount,
    required this.totalCapacity,
  });

  factory SlotItemModel.fromJson(Map<String, dynamic> json) {
    return SlotItemModel(
      slotTime: (json['slot_time'] as String?) ?? '',
      startTime: (json['start_time'] as String?) ?? '',
      endTime: (json['end_time'] as String?) ?? '',
      available: json['available'] as bool? ?? false,
      status: json['status'] as String? ?? 'AVAILABLE',
      reasonCode: json['reason_code'] as String? ?? 'AVAILABLE',
      remainingCapacity: (json['remaining_capacity'] as num?)?.toInt() ?? 0,
      bookedCount: (json['booked_count'] as num?)?.toInt() ?? 0,
      totalCapacity: (json['total_capacity'] as num?)?.toInt() ?? 4,
    );
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
  final String? lastEtaReason;
  final double? etaLow;
  final double? etaHigh;
  final String? onMyWayAt;
  final String? graceDeadline;
  final int waitingAhead;
  final String? nowServing;
  final String? verificationSecret;
  final String? verificationQr;
  final bool? isVerified;
  final String? beneficiaryName;
  final String? parentTokenId;
  final String? appointmentDate;
  final String? appointmentSlot;
  final List<TokenModel> childTokens;

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
    this.lastEtaReason,
    this.etaLow,
    this.etaHigh,
    this.onMyWayAt,
    this.graceDeadline,
    required this.waitingAhead,
    this.nowServing,
    this.verificationSecret,
    this.verificationQr,
    this.isVerified,
    this.beneficiaryName,
    this.parentTokenId,
    this.appointmentDate,
    this.appointmentSlot,
    this.childTokens = const [],
  });

  factory TokenModel.fromJson(Map<String, dynamic> json) {
    return TokenModel(
      id: (json['id'] as String?) ?? '',
      officeId: (json['office_id'] as String?) ?? '',
      serviceId: (json['service_id'] as String?) ?? '',
      businessDate: (json['business_date'] as String?) ?? '',
      seq: (json['seq'] as num?)?.toInt() ?? 0,
      displayCode: (json['display_code'] as String?) ?? '',
      state: (json['state'] as String?) ?? 'WAITING',
      category: (json['category'] as String?) ?? 'NORMAL',
      priorityStatus: (json['priority_status'] as String?) ?? 'PENDING',
      createdVia: (json['created_via'] as String?) ?? 'APP',
      phone: json['phone'] as String?,
      counterLabel: json['counter_label'] as String?,
      arrivedAt: json['arrived_at'] as String?,
      calledAt: json['called_at'] as String?,
      servingStartedAt: json['serving_started_at'] as String?,
      completedAt: json['completed_at'] as String?,
      lastEtaMinutes: (json['last_eta_minutes'] as num?)?.toDouble(),
      lastEtaReason: json['last_eta_reason'] as String?,
      etaLow: (json['eta_low'] as num?)?.toDouble(),
      etaHigh: (json['eta_high'] as num?)?.toDouble(),
      onMyWayAt: json['on_my_way_at'] as String?,
      graceDeadline: json['grace_deadline'] as String?,
      waitingAhead: (json['waiting_ahead'] as num?)?.toInt() ?? 0,
      nowServing: json['now_serving'] as String?,
      verificationSecret: json['verification_secret'] as String?,
      verificationQr: json['verification_qr'] as String?,
      isVerified: json['is_verified'] as bool?,
      beneficiaryName: json['beneficiary_name'] as String?,
      parentTokenId: json['parent_token_id'] as String?,
      appointmentDate: json['appointment_date'] as String?,
      appointmentSlot: json['appointment_slot'] as String?,
      childTokens: (json['child_tokens'] as List<dynamic>?)
              ?.map((item) => TokenModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class ProfileModel {
  final String id;
  final String? phone;
  final String? name;
  final String language;
  final String role;
  final String? officeId;
  final int priorityStrikes;

  ProfileModel({
    required this.id,
    this.phone,
    this.name,
    required this.language,
    required this.role,
    this.officeId,
    required this.priorityStrikes,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: (json['id'] as String?) ?? '',
      phone: json['phone'] as String?,
      name: json['name'] as String?,
      language: (json['language'] as String?) ?? 'en',
      role: (json['role'] as String?) ?? 'CITIZEN',
      officeId: json['office_id'] as String?,
      priorityStrikes: (json['priority_strikes'] as num?)?.toInt() ?? 0,
    );
  }
}

class ApiClient {
  static String _activeBaseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static String get defaultBaseUrl => _activeBaseUrl;

  static void setBaseUrl(String url) {
    var cleaned = url.trim();
    if (cleaned.isEmpty) return;
    if (!cleaned.startsWith('http://') && !cleaned.startsWith('https://')) {
      cleaned = 'http://$cleaned';
    }
    _activeBaseUrl = cleaned.replaceAll(RegExp(r'/+$'), '');
  }

  static Future<bool> pingServer([String? testUrl]) async {
    final target = testUrl ?? _activeBaseUrl;
    try {
      final res = await http.get(Uri.parse('$target/healthz')).timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  final String baseUrl;
  final http.Client _client;

  ApiClient({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? _activeBaseUrl,
        _client = client ?? http.Client();

  Map<String, String> _headers(String? token) {
    final h = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  Never _handleNetworkError(Object error, Uri uri) {
    final errStr = error.toString().toLowerCase();
    if (errStr.contains('socketexception') ||
        errStr.contains('connection refused') ||
        errStr.contains('clientexception')) {
      throw Exception(
        'Server not reachable at ${uri.host}:${uri.port}.\n\n'
        '• If using USB cable: run "adb reverse tcp:8000 tcp:8000" in PC terminal.\n'
        '• If on Wi-Fi: tap ⚙️ Server on top-right to set your PC IP (e.g. 10.152.45.97:8000).',
      );
    }
    throw error;
  }

  Future<http.Response> _safeGet(Uri uri, {Map<String, String>? headers}) async {
    try {
      return await _client.get(uri, headers: headers);
    } catch (e) {
      _handleNetworkError(e, uri);
    }
  }

  Future<http.Response> _safePost(Uri uri, {Map<String, String>? headers, Object? body}) async {
    try {
      return await _client.post(uri, headers: headers, body: body);
    } catch (e) {
      _handleNetworkError(e, uri);
    }
  }

  Future<http.Response> _safePatch(Uri uri, {Map<String, String>? headers, Object? body}) async {
    try {
      return await _client.patch(uri, headers: headers, body: body);
    } catch (e) {
      _handleNetworkError(e, uri);
    }
  }

  Future<List<OfficeModel>> fetchOffices() async {
    final res = await _safeGet(Uri.parse('$baseUrl/v1/citizen/offices'));
    if (res.statusCode != 200) {
      throw Exception('Failed to load offices: ${res.statusCode}');
    }
    final List<dynamic> body = jsonDecode(res.body);
    return body.map((o) => OfficeModel.fromJson(o as Map<String, dynamic>)).toList();
  }

  Future<List<ServiceModel>> fetchServices(String officeId) async {
    final res = await _safeGet(Uri.parse('$baseUrl/v1/citizen/offices/$officeId/services'));
    if (res.statusCode != 200) {
      throw Exception('Failed to load services: ${res.statusCode}');
    }
    final List<dynamic> body = jsonDecode(res.body);
    return body.map((s) => ServiceModel.fromJson(s as Map<String, dynamic>)).toList();
  }

  Future<List<SlotItemModel>> fetchSlots({
    required String officeId,
    required String serviceId,
    String? date,
    int partySize = 1,
  }) async {
    final queryParams = <String, String>{
      'party_size': partySize.toString(),
    };
    if (date != null && date.isNotEmpty) {
      queryParams['date'] = date;
    }
    final uri = Uri.parse('$baseUrl/v1/citizen/offices/$officeId/services/$serviceId/slots')
        .replace(queryParameters: queryParams);
    final res = await _safeGet(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to load slots: ${res.statusCode}');
    }
    final List<dynamic> body = jsonDecode(res.body);
    return body.map((s) => SlotItemModel.fromJson(s as Map<String, dynamic>)).toList();
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
    String? appointmentDate,
    String? appointmentSlot,
    bool isFixed = true,
    List<Map<String, dynamic>>? accompanyingMembers,
    required String idempotencyKey,
  }) async {
    final res = await _safePost(
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
        'appointment_date': appointmentDate,
        'appointment_slot': appointmentSlot,
        'is_fixed': isFixed,
        if (accompanyingMembers != null && accompanyingMembers.isNotEmpty)
          'accompanying_members': accompanyingMembers,
      }),
    );
    if (res.statusCode != 201) {
      final err = jsonDecode(res.body);
      throw Exception(err['error']?['message'] ?? 'Booking failed (${res.statusCode})');
    }
    return TokenModel.fromJson(jsonDecode(res.body));
  }

  Future<TokenModel?> getActiveToken(String token) async {
    final res = await _safeGet(
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
    final res = await _safePost(
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
    final res = await _safePost(
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

  Future<TokenModel> onMyWay({
    required String token,
    required String tokenId,
  }) async {
    final res = await _safePost(
      Uri.parse('$baseUrl/v1/citizen/tokens/$tokenId/on-my-way'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body);
      throw Exception(err['error']?['message'] ?? 'On-my-way request failed');
    }
    return TokenModel.fromJson(jsonDecode(res.body));
  }

  Future<void> confirmCompletion({
    required String token,
    required String tokenId,
    required bool serviceCompleted,
    String? reasonIfNot,
    required int rating,
    String? feedbackText,
  }) async {
    final res = await _safePost(
      Uri.parse('$baseUrl/v1/citizen/tokens/$tokenId/confirm-completion'),
      headers: _headers(token),
      body: jsonEncode({
        'service_completed': serviceCompleted,
        'reason_if_not': reasonIfNot,
        'rating': rating,
        'feedback_text': feedbackText,
      }),
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body);
      throw Exception(err['error']?['message'] ?? 'Failed to submit completion confirmation');
    }
  }

  Future<ProfileModel> getProfile(String token) async {
    final res = await _safeGet(
      Uri.parse('$baseUrl/v1/citizen/me'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to load profile (${res.statusCode})');
    }
    return ProfileModel.fromJson(jsonDecode(res.body));
  }

  Future<void> updateProfile({
    required String token,
    String? name,
    String? language,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (language != null) body['language'] = language;

    final res = await _safePatch(
      Uri.parse('$baseUrl/v1/citizen/me'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body);
      throw Exception(err['error']?['message'] ?? 'Failed to update profile');
    }
  }

  Future<void> updateLanguage({
    required String token,
    required String language,
  }) async {
    await updateProfile(token: token, language: language);
  }

  Future<void> registerDevice({
    required String token,
    required String fcmToken,
    String platform = 'android',
    String language = 'en',
  }) async {
    final res = await _safePost(
      Uri.parse('$baseUrl/v1/devices'),
      headers: _headers(token),
      body: jsonEncode({
        'fcm_token': fcmToken,
        'platform': platform,
        'language': language,
      }),
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body);
      throw Exception(err['error']?['message'] ?? 'Device registration failed');
    }
  }

  Future<String> getDevToken({
    required String phone,
    String role = 'CITIZEN',
    String? officeId,
    String? name,
  }) async {
    final res = await _safePost(
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
