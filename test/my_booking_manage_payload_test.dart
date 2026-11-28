import 'dart:convert';
import 'dart:typed_data';

import 'package:allowners/services/api_client.dart';
import 'package:allowners/services/hotel_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// يلتقط جسم كل POST يُرسل فعليًا إلى `/bookings/manage.php`.
///
/// الغرض: إثبات أن تعديل الحجز وإلغاءه من حساب الضيف/الوكيل يُرسلان الحقول
/// التي يعتمد عليها السيرفر (المتطلبات 40–43) — لا أن الشاشة تُرسم فقط.
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
    bodies.add(jsonEncode(options.data ?? const {}));
    return ResponseBody.fromString(jsonEncode({'success': true}), 200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        });
  }
}

void main() {
  late _CaptureAdapter adapter;
  late HotelService service;
  late HttpClientAdapter original;

  setUp(() {
    SharedPreferences.setMockInitialValues({'auth_token': 'test-token'});
    adapter = _CaptureAdapter();
    original = ApiClient.instance.dio.httpClientAdapter;
    ApiClient.instance.dio.httpClientAdapter = adapter;
    service = HotelService();
  });

  tearDown(() {
    ApiClient.instance.dio.httpClientAdapter = original;
  });

  group('إدارة الحجز من حساب الضيف/الوكيل (المتطلبات 40–43)', () {
    test('المتطلبان 40 و42: تعديل الحجز يرسل action=update بالحقول المعدّلة',
        () async {
      await service.editMyBooking(
        bookingId: 77,
        guestName: 'سعد المطيري',
        guestPhone: '0555555555',
        guests: 3,
        notes: 'وصول متأخر',
      );

      expect(adapter.requests.single.path, contains('/bookings/manage.php'));
      final body = jsonDecode(adapter.bodies.single) as Map<String, dynamic>;
      expect(body['booking_id'], 77);
      expect(body['action'], 'update');
      expect(body['guest_name'], 'سعد المطيري');
      expect(body['guest_phone'], '0555555555');
      expect(body['guests'], 3);
      expect(body['notes'], 'وصول متأخر');
    });

    test('المتطلب 42: تعديل بلا حقول اختيارية لا يرسل مفاتيح فارغة', () async {
      await service.editMyBooking(bookingId: 9, guests: 1);
      final body = jsonDecode(adapter.bodies.single) as Map<String, dynamic>;
      expect(body['action'], 'update');
      expect(body.containsKey('guest_name'), isFalse);
      expect(body.containsKey('guest_phone'), isFalse);
      expect(body.containsKey('notes'), isFalse);
      expect(body.containsKey('check_in'), isFalse);
    });

    test('المتطلبان 41 و43: إلغاء الحجز يرسل action=cancel مع رقم الحجز',
        () async {
      await service.cancelMyBooking(77);
      expect(adapter.requests.single.path, contains('/bookings/manage.php'));
      final body = jsonDecode(adapter.bodies.single) as Map<String, dynamic>;
      expect(body['booking_id'], 77);
      expect(body['action'], 'cancel');
    });
  });
}
