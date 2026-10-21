import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:allowners/services/api_client.dart';
import 'package:allowners/services/hotel_staff_service.dart';
import 'package:allowners/services/owner_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// يلتقط آخر جسم طلب أُرسل فعليًا إلى `/hotel/requests.php` و`/hotel/prices.php`.
///
/// الغرض: إثبات أن أزرار تأكيد/تسعير الخدمات تُرسل الحقول التي يعتمد عليها
/// السيرفر — لا أن الشاشة تُرسم فقط. المتطلبات 82–92.
class _CaptureAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  final bodies = <String>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (requestStream != null) {
      final chunks = await requestStream.toList();
      bodies.add(
          utf8.decode(chunks.expand((c) => c).toList(), allowMalformed: true));
    } else {
      bodies.add(jsonEncode(options.data ?? const {}));
    }
    return ResponseBody.fromString(jsonEncode({'success': true}), 200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        });
  }
}

void main() {
  late _CaptureAdapter adapter;
  late HotelStaffService service;
  late HttpClientAdapter original;

  setUp(() {
    SharedPreferences.setMockInitialValues({'auth_token': 'test-token'});
    adapter = _CaptureAdapter();
    original = ApiClient.instance.dio.httpClientAdapter;
    ApiClient.instance.dio.httpClientAdapter = adapter;
    service = HotelStaffService();
  });

  tearDown(() {
    ApiClient.instance.dio.httpClientAdapter = original;
  });

  group('تأكيد الطلبات يُرسل الحقول الحقيقية (المتطلبات 83، 85، 88، 90)', () {
    for (final type in const ['cleaning', 'maintenance', 'meal', 'extra_bed']) {
      test('تأكيد $type يرسل action=confirm مع الوصف والسعر', () async {
        await service.actOnRequest(
          type: type,
          id: 402,
          action: 'confirm',
          note: 'تم التنفيذ',
          price: 150.5,
        );
        expect(adapter.requests.single.path, contains('/hotel/requests.php'));
        final body = jsonDecode(adapter.bodies.single) as Map<String, dynamic>;
        expect(body['type'], type);
        expect(body['id'], 402);
        expect(body['action'], 'confirm');
        expect(body['note'], 'تم التنفيذ');
        expect(body['price'], 150.5);
      });
    }

    test('طلب بلا وصف/سعر لا يُرسل مفاتيح فارغة', () async {
      await service.actOnRequest(type: 'meal', id: 5, action: 'reject');
      final body = jsonDecode(adapter.bodies.single) as Map<String, dynamic>;
      expect(body.containsKey('note'), isFalse);
      expect(body.containsKey('price'), isFalse);
      expect(body.containsKey('settlement'), isFalse);
    });

    test('المتطلب 86: تسجيل الإنجاز يرسل action=done مع الوصف', () async {
      await service.actOnRequest(
        type: 'maintenance',
        id: 33,
        action: 'done',
        note: 'تم إصلاح التسريب واستبدال الحنفية',
      );
      final body = jsonDecode(adapter.bodies.single) as Map<String, dynamic>;
      expect(body['action'], 'done');
      expect(body['type'], 'maintenance');
      expect(body['id'], 33);
      expect(body['note'], 'تم إصلاح التسريب واستبدال الحنفية');
    });

    test('المتطلبات 390–394: حقل settlement يُرسل عند اختياره', () async {
      await service.actOnRequest(
        type: 'maintenance',
        id: 7,
        action: 'confirm',
        settlement: 'unit_balance',
      );
      final body = jsonDecode(adapter.bodies.single) as Map<String, dynamic>;
      expect(body['settlement'], 'unit_balance');
    });

    test('المتطلب 92: صورة طلب الصيانة تُرسل كـ multipart', () async {
      final tmp = File('${Directory.systemTemp.path}/req92_img.png')
        ..writeAsBytesSync(const [137, 80, 78, 71, 13, 10, 26, 10]);
      addTearDown(() => tmp.existsSync() ? tmp.deleteSync() : null);

      await service.actOnRequest(
        type: 'maintenance',
        id: 12,
        action: 'confirm',
        note: 'صورة العطل',
        imagePath: tmp.path,
      );

      final req = adapter.requests.single;
      expect(req.path, contains('/hotel/requests.php'));
      // FormData يُرسل كـ multipart/form-data لا كـ JSON
      expect(req.contentType?.contains('multipart/form-data'), isTrue,
          reason: 'الطلب بصورة يجب أن يُرسل multipart');
      final raw = adapter.bodies.single;
      expect(raw, contains('name="image"'));
      expect(raw, contains('name="type"'));
      expect(raw, contains('maintenance'));
      expect(raw, contains('name="id"'));
    });
  });

  group('استقبال طلبات المالك (المتطلب 91)', () {
    test('جلب الطلبات يمرّر النوع والحالة إلى /hotel/requests.php', () async {
      await service.getRequests(type: 'maintenance', status: 'open');
      final req = adapter.requests.single;
      expect(req.path, contains('/hotel/requests.php'));
      expect(req.queryParameters['type'], 'maintenance');
      expect(req.queryParameters['status'], 'open');
    });
  });

  group('تسعير خدمات الفندق (المتطلبات 82، 87، 89)', () {
    test('حفظ سعر خدمة يرسل النوع والوحدة والسعر', () async {
      await service.savePrice(
        hotelId: 2,
        unitId: 11,
        serviceType: 'cleaning',
        price: 120,
      );
      expect(adapter.requests.single.path, contains('/hotel/prices.php'));
      final body = jsonDecode(adapter.bodies.single) as Map<String, dynamic>;
      expect(body['action'], 'save');
      expect(body['hotel_id'], 2);
      expect(body['unit_id'], 11);
      expect(body['service_type'], 'cleaning');
      expect(body['price'], 120);
    });

    test('تعديل سعر قائم يرسل المعرّف (id)', () async {
      await service.savePrice(
        id: 5,
        hotelId: 2,
        serviceType: 'meal',
        price: 90,
      );
      final body = jsonDecode(adapter.bodies.single) as Map<String, dynamic>;
      expect(body['id'], 5);
      expect(body['service_type'], 'meal');
    });

    test('حذف سعر يرسل action=delete مع المعرّف', () async {
      await service.deletePrice(9);
      final body = jsonDecode(adapter.bodies.single) as Map<String, dynamic>;
      expect(body['action'], 'delete');
      expect(body['id'], 9);
    });

    test('سعر بلا وحدة يرسل null للوحدة (سعر لكل الوحدات)', () async {
      await service.savePrice(
        hotelId: 2,
        serviceType: 'extra_bed',
        price: 75,
      );
      final body = jsonDecode(adapter.bodies.single) as Map<String, dynamic>;
      expect(body['unit_id'], isNull);
      expect(body['service_type'], 'extra_bed');
    });
  });

  group('تسجيل الدخول/الخروج من إدارة الفندق (المتطلبان 78، 79)', () {
    test('تأكيد الدخول يرسل action=check_in مع رقم الحجز', () async {
      await service.checkIn(44);
      expect(adapter.requests.single.path, contains('/hotel/bookings.php'));
      final body = jsonDecode(adapter.bodies.single) as Map<String, dynamic>;
      expect(body['booking_id'], 44);
      expect(body['action'], 'check_in');
    });

    test('تأكيد الخروج يرسل action=check_out مع رقم الحجز', () async {
      await service.checkOut(44);
      expect(adapter.requests.single.path, contains('/hotel/bookings.php'));
      final body = jsonDecode(adapter.bodies.single) as Map<String, dynamic>;
      expect(body['booking_id'], 44);
      expect(body['action'], 'check_out');
    });
  });

  group('إنشاء طلب صيانة من المالك (المتطلب 72)', () {
    late OwnerService ownerService;
    setUp(() => ownerService = OwnerService());

    test('بصورة: يُرسل multipart مع الحقول والصورة', () async {
      final tmp = File('${Directory.systemTemp.path}/req72_img.png')
        ..writeAsBytesSync(const [137, 80, 78, 71, 13, 10, 26, 10]);
      addTearDown(() => tmp.existsSync() ? tmp.deleteSync() : null);

      await ownerService.createMaintenanceRequest(
        hotelId: 2,
        unitId: 13,
        title: 'تسريب ماء',
        description: 'الحنفية تسرّب',
        imagePath: tmp.path,
      );

      final req = adapter.requests.single;
      expect(req.path, contains('/user/owner-maintenance.php'));
      expect(req.contentType?.contains('multipart/form-data'), isTrue,
          reason: 'الطلب بصورة يجب أن يُرسل multipart');
      final raw = adapter.bodies.single;
      expect(raw, contains('name="hotel_id"'));
      expect(raw, contains('name="unit_id"'));
      expect(raw, contains('name="title"'));
      expect(raw, contains('name="image"'));
    });

    test('بلا صورة: يُرسل JSON كما كان (لا يغيّر العقد)', () async {
      await ownerService.createMaintenanceRequest(
        hotelId: 2,
        title: 'تسريب ماء',
      );
      final req = adapter.requests.single;
      expect(req.contentType?.contains('multipart/form-data'), isFalse);
      final body = jsonDecode(adapter.bodies.single) as Map<String, dynamic>;
      expect(body['hotel_id'], 2);
      expect(body['title'], 'تسريب ماء');
      expect(body.containsKey('image'), isFalse);
    });
  });

  group('عملاء الوكيل (المتطلب 93)', () {
    late OwnerService ownerService;

    setUp(() => ownerService = OwnerService());

    test('إضافة عميل جديد ترسل action=add بالاسم والهاتف', () async {
      await ownerService.saveAgentClient(
        fullName: 'سعد المطيري',
        phone: '0555555555',
        email: 'saad@example.com',
        idNumber: '1234567890',
        notes: 'عميل دائم',
      );
      expect(adapter.requests.single.path, contains('/user/agent-clients.php'));
      final body = jsonDecode(adapter.bodies.single) as Map<String, dynamic>;
      expect(body['action'], 'add');
      expect(body['full_name'], 'سعد المطيري');
      expect(body['phone'], '0555555555');
      expect(body['email'], 'saad@example.com');
      expect(body['id_number'], '1234567890');
      expect(body.containsKey('id'), isFalse);
    });

    test('تعديل عميل قائم يرسل action=update مع المعرّف', () async {
      await ownerService.saveAgentClient(
        id: 5,
        fullName: 'سعد المطيري',
        phone: '0500000000',
      );
      final body = jsonDecode(adapter.bodies.single) as Map<String, dynamic>;
      expect(body['action'], 'update');
      expect(body['id'], 5);
      expect(body.containsKey('email'), isFalse);
      expect(body.containsKey('id_number'), isFalse);
    });

    test('حذف عميل يرسل action=delete مع المعرّف', () async {
      await ownerService.deleteAgentClient(5);
      final body = jsonDecode(adapter.bodies.single) as Map<String, dynamic>;
      expect(body['action'], 'delete');
      expect(body['id'], 5);
    });
  });
}
