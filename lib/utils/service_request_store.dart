/// طلبات الخدمات التي أرسلها الضيف وحالتها كما أعادها السيرفر.
///
/// المتطلب 59 («إظهار حالة طلبات الخدمات للضيف») لا يمكن إنجازه في التطبيق
/// وحده: لا توجد نقطة قراءة على السيرفر (`/services/my-requests.php` مطلوبة من
/// Codex). ما يفعله هذا الملف:
///
/// 1. يحفظ ما أعاده السيرفر فعلًا عند الإرسال (`request{id,status}`) — لا
///    يخترع حالة، وإن غابت الحالة تُعرض «—» مع نص صريح.
/// 2. يدمج القائمة المحلية مع قائمة السيرفر عندما تُعلن النقطة نفسها لاحقًا،
///    فالسيرفر هو المرجع لكل طلب يحمل معرّفًا.
///
/// التخزين محلي ومحدود ([maxRecords]) حتى لا ينمو بلا سقف.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'safe_parse.dart';

const String serviceRequestStoreKey = 'service_requests_local';
const int maxRecords = 20;

/// نوع الطلب كما يرسله التطبيق في `service_type`.
const List<String> serviceRequestTypes = [
  'maintenance',
  'housekeeping',
  'cancellation',
];

class ServiceRequestRecord {
  const ServiceRequestRecord({
    required this.type,
    this.id,
    this.status,
    this.roomNumber,
    this.description,
    required this.createdAt,
  });

  final String type;

  /// معرّف الطلب على السيرفر — `null` إن لم يُرجعه السيرفر.
  final int? id;

  /// حالة الطلب كما أعادها السيرفر — `null` يعني «لم تُعلن بعد».
  final String? status;
  final String? roomNumber;
  final String? description;
  final DateTime createdAt;

  /// يبني سجلًا من استجابة الإرسال. لا يخترع حالة: إن لم يُرجع السيرفر
  /// `status` يبقى `null` وتُعرض «—» في الواجهة.
  factory ServiceRequestRecord.fromServer(
    Map<String, dynamic>? response, {
    required String type,
    String? roomNumber,
    String? description,
    DateTime? now,
  }) {
    final request = response?['request'];
    final data = request is Map ? request : const <String, dynamic>{};
    final id = asInt(data['id'], 0);
    return ServiceRequestRecord(
      type: type,
      id: id > 0 ? id : null,
      status: asStringOrNull(data['status']),
      roomNumber: asStringOrNull(roomNumber),
      description: asStringOrNull(description),
      createdAt: now ?? DateTime.now(),
    );
  }

  /// صف من `/services/my-requests.php` — الحقول مقبولة بأسماء بديلة لأن
  /// السيرفر قد يستخدم `service_type`/`room_number` أو `type`/`unit_number`.
  factory ServiceRequestRecord.fromRemoteRow(Map<String, dynamic> row) {
    final id = asInt(row['id'], 0);
    return ServiceRequestRecord(
      type: asString(row['type'], asString(row['service_type'], 'maintenance')),
      id: id > 0 ? id : null,
      status: asStringOrNull(row['status']),
      roomNumber: asStringOrNull(row['room_number'] ?? row['unit_number']),
      description: asStringOrNull(row['description']),
      createdAt:
          DateTime.tryParse(asString(row['created_at'])) ?? DateTime(1970),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        if (id != null) 'id': id,
        if (status != null) 'status': status,
        if (roomNumber != null) 'room_number': roomNumber,
        if (description != null) 'description': description,
        'created_at': createdAt.toIso8601String(),
      };

  factory ServiceRequestRecord.fromJson(Map<String, dynamic> json) {
    return ServiceRequestRecord(
      type: asString(json['type'], 'maintenance'),
      id: asInt(json['id'], 0) > 0 ? asInt(json['id']) : null,
      status: asStringOrNull(json['status']),
      roomNumber: asStringOrNull(json['room_number']),
      description: asStringOrNull(json['description']),
      createdAt:
          DateTime.tryParse(asString(json['created_at'])) ?? DateTime(1970),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ServiceRequestRecord &&
      other.type == type &&
      other.id == id &&
      other.status == status &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(type, id, status, createdAt);
}

String encodeServiceRequests(List<ServiceRequestRecord> records) =>
    jsonEncode(records.map((r) => r.toJson()).toList());

/// فك ترميز متسامح: أي شكل غير متوقع يُرجع قائمة فارغة بدل استثناء.
List<ServiceRequestRecord> decodeServiceRequests(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((e) => ServiceRequestRecord.fromJson(e.cast<String, dynamic>()))
        .toList();
  } catch (_) {
    return const [];
  }
}

/// دمج القائمة المحلية مع قائمة السيرفر.
///
/// قواعد الدمج:
/// - كل طلب على السيرفر يحمل معرّفًا يستبدل نظيره المحلي (السيرفر مرجع الحالة).
/// - الطلبات المحلية بلا معرّف تبقى ظاهرة (أُرسلت ولم يُرجع السيرفر معرّفًا).
/// - الترتيب بالأحدث أولًا، والسقف [maxRecords].
List<ServiceRequestRecord> mergeServiceRequests(
  List<ServiceRequestRecord> local,
  List<ServiceRequestRecord> remote,
) {
  final byId = <int, ServiceRequestRecord>{};
  final anonymous = <String, ServiceRequestRecord>{};
  void take(ServiceRequestRecord record) {
    if (record.id != null) {
      byId[record.id!] = record;
    } else {
      anonymous['${record.type}|${record.createdAt.toIso8601String()}'] =
          record;
    }
  }

  for (final record in local) {
    take(record);
  }
  for (final record in remote) {
    take(record);
  }
  final merged = [...byId.values, ...anonymous.values]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return merged.length > maxRecords ? merged.sublist(0, maxRecords) : merged;
}

/// واجهة التخزين المحلي — تُستخدم في الشاشة والاختبارات.
class ServiceRequestStore {
  const ServiceRequestStore();

  Future<List<ServiceRequestRecord>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return decodeServiceRequests(prefs.getString(serviceRequestStoreKey));
  }

  Future<List<ServiceRequestRecord>> add(ServiceRequestRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final existing =
        decodeServiceRequests(prefs.getString(serviceRequestStoreKey));
    final merged = mergeServiceRequests(existing, [record]);
    await prefs.setString(
        serviceRequestStoreKey, encodeServiceRequests(merged));
    return merged;
  }

  Future<void> saveAll(List<ServiceRequestRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        serviceRequestStoreKey, encodeServiceRequests(records));
  }
}
