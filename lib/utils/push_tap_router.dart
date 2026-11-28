import 'package:flutter/widgets.dart';

import '../screens/bookings/my_bookings_screen.dart';
import '../screens/hotel_staff/hotel_bookings_screen.dart';
import '../screens/hotel_staff/hotel_requests_screen.dart';
import '../screens/owner/owner_bookings_screen.dart';
import '../screens/owner/owner_maintenance_screen.dart';
import '../screens/owner/owner_notifications_screen.dart';
import '../screens/owner/owner_subscription_screen.dart';
import '../screens/owner/owner_wallet_screen.dart';
import 'notification_routing.dart';

/// يترجم ضغطة إشعار إلى الشاشة المناسبة لدور المستخدم الحالي.
///
/// القاعدة: لا نفتح شاشة لا يملك صاحبها صلاحية عرضها، ولا نُخمّن شاشة غير
/// موجودة. إن لم توجد شاشة مطابقة للدور والهدف نرجع إلى قائمة إشعارات الدور
/// (وهي متاحة لكل الأدوار) بدل تجاهل الضغطة بصمت.
Widget? screenForNotificationTap(Map<String, dynamic> data, {String? role}) {
  final event = parseNotificationEvent(data);
  final target = _targetFromHint(data) ?? targetForEvent(event);
  final isOwner = role == 'owner' ||
      role == 'booking_agent' ||
      role == 'unit_manager' ||
      role == 'employee';
  final isHotel = role == 'hotel_manager' || role == 'hotel_employee';

  switch (target) {
    case NotificationTarget.booking:
      if (isHotel) return const HotelBookingsScreen();
      if (isOwner) return const OwnerBookingsScreen();
      return const MyBookingsScreen();
    case NotificationTarget.serviceRequest:
      if (isHotel) return const HotelRequestsScreen();
      if (isOwner) return const OwnerMaintenanceScreen();
      return const MyBookingsScreen();
    case NotificationTarget.wallet:
      return isOwner ? const OwnerWalletScreen() : null;
    case NotificationTarget.subscription:
      return isOwner ? const OwnerSubscriptionScreen() : null;
    case NotificationTarget.payment:
      if (isHotel) return const HotelBookingsScreen();
      if (isOwner) return const OwnerBookingsScreen();
      return const MyBookingsScreen();
    case NotificationTarget.none:
      return null;
  }
}

/// تلميح `target` من السيرفر يتقدّم على استنتاج الحدث، لأن بعض الأحداث
/// (المحفظة/الاشتراك) لا تحمل `type` معروفًا. القيم المقبولة فقط، وأي قيمة
/// أخرى تُتجاهل بدل تخمين شاشة.
NotificationTarget? _targetFromHint(Map<String, dynamic> data) {
  final raw = (data['target'] ?? data['screen'] ?? '').toString().trim();
  switch (raw.toLowerCase()) {
    case 'booking':
    case 'bookings':
      return NotificationTarget.booking;
    case 'service':
    case 'service_request':
      return NotificationTarget.serviceRequest;
    case 'wallet':
      return NotificationTarget.wallet;
    case 'subscription':
      return NotificationTarget.subscription;
    case 'payment':
      return NotificationTarget.payment;
    default:
      return null;
  }
}

/// شاشة الإشعارات المناسبة للدور — الوجهة الاحتياطية عند غياب شاشة مطابقة.
Widget? notificationsScreenForRole(String? role) {
  final isOwner = role == 'owner' ||
      role == 'booking_agent' ||
      role == 'unit_manager' ||
      role == 'employee';
  return isOwner ? const OwnerNotificationsScreen() : null;
}
