import 'package:allowners/screens/bookings/my_bookings_screen.dart';
import 'package:allowners/screens/hotel_staff/hotel_bookings_screen.dart';
import 'package:allowners/screens/hotel_staff/hotel_requests_screen.dart';
import 'package:allowners/screens/owner/owner_bookings_screen.dart';
import 'package:allowners/screens/owner/owner_maintenance_screen.dart';
import 'package:allowners/screens/owner/owner_notifications_screen.dart';
import 'package:allowners/screens/owner/owner_subscription_screen.dart';
import 'package:allowners/screens/owner/owner_wallet_screen.dart';
import 'package:allowners/utils/notification_routing.dart';
import 'package:allowners/utils/push_tap_router.dart';
import 'package:flutter_test/flutter_test.dart';

/// القسم 10: ضغطة الإشعار يجب أن تفتح شاشة يملك الدور صلاحية عرضها.
void main() {
  group('توجيه الضغطات حسب الدور', () {
    test('إشعار حجز يفتح حجوزات الضيف', () {
      final screen = screenForNotificationTap(
        {'type': 'booking_confirmed', 'booking_id': 9},
        role: 'guest',
      );
      expect(screen, isA<MyBookingsScreen>());
    });

    test('إشعار حجز يفتح حجوزات المالك', () {
      final screen = screenForNotificationTap(
        {'type': 'booking_created', 'booking_id': 9},
        role: 'owner',
      );
      expect(screen, isA<OwnerBookingsScreen>());
    });

    test('إشعار حجز يفتح حجوزات الفندق', () {
      final screen = screenForNotificationTap(
        {'type': 'booking_created', 'booking_id': 9},
        role: 'hotel_manager',
      );
      expect(screen, isA<HotelBookingsScreen>());
    });

    test('إشعار خدمة يفتح طلبات الفندق أو صيانة المالك', () {
      expect(
        screenForNotificationTap({'type': 'service_request'},
            role: 'hotel_manager'),
        isA<HotelRequestsScreen>(),
      );
      expect(
        screenForNotificationTap({'type': 'service_request'}, role: 'owner'),
        isA<OwnerMaintenanceScreen>(),
      );
    });

    test('المحفظة والاشتراك للمالك فقط', () {
      expect(
        screenForNotificationTap({'target': 'wallet'}, role: 'owner'),
        isA<OwnerWalletScreen>(),
      );
      expect(screenForNotificationTap({'target': 'wallet'}, role: 'guest'),
          isNull);
      expect(
        screenForNotificationTap({'target': 'subscription'}, role: 'owner'),
        isA<OwnerSubscriptionScreen>(),
      );
      expect(
          screenForNotificationTap({'target': 'subscription'}, role: 'guest'),
          isNull);
    });

    test('حدث غير معروف لا يفتح شاشة عشوائية', () {
      expect(screenForNotificationTap(const {}, role: 'guest'), isNull);
      expect(
          screenForNotificationTap({'type': 'something_else'}, role: 'owner'),
          isNull);
      expect(screenForNotificationTap({'target': 'made_up'}, role: 'owner'),
          isNull);
    });

    test('تلميح target يتقدّم على نوع الحدث', () {
      final screen = screenForNotificationTap(
        {'type': 'booking', 'target': 'wallet'},
        role: 'owner',
      );
      expect(screen, isA<OwnerWalletScreen>());
    });

    test('الوجهة الاحتياطية هي إشعارات المالك', () {
      expect(
          notificationsScreenForRole('owner'), isA<OwnerNotificationsScreen>());
      expect(notificationsScreenForRole('guest'), isNull);
    });

    test('كل حدث معروف له وجهة محددة', () {
      for (final event in NotificationEvent.values) {
        final target = targetForEvent(event);
        expect(target, isNotNull);
      }
      expect(
          targetForEvent(NotificationEvent.unknown), NotificationTarget.none);
    });
  });
}
