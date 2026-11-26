import 'staff_permissions_strings.dart';

/// صلاحيات موظفي المالك (المتطلب 74) — القائمة المرجعية الوحيدة.
///
/// المفتاح wire name يُرسل حرفيًا إلى `user/owner-staff.php`، فلا تُغيَّر
/// التسميات دون تحديث العقد في `docs/BACKEND_INTEGRATION_HANDOVER.md`.
const List<String> kStaffPermissionKeys = [
  'can_manage_bookings',
  'can_manage_services',
  'can_check_in_out',
  'can_view_finance',
];

/// الصلاحيات الافتراضية حسب الدور — مطابقة لما يفرضه التطبيق فعلًا على
/// الشاشات، حتى لا تظهر خانات مفتوحة لدور لا يستطيع استخدامها.
Map<String, bool> defaultStaffPermissions(String role) {
  final canManage = role != 'booking_agent';
  return {
    'can_manage_bookings': canManage,
    'can_manage_services': true,
    'can_check_in_out': canManage,
    'can_view_finance': false,
  };
}

/// يقرأ الصلاحيات من السيرفر بثلاثة أشكال محتملة، ويسقط إلى الافتراضي.
///
///   • `{"can_manage_bookings": true, …}` خريطة منطقية
///   • `["can_manage_bookings", …]` قائمة أسماء
///   • غياب الحقل: تُستخدم صلاحيات الدور
Map<String, bool> parseStaffPermissions(dynamic raw, {required String role}) {
  final defaults = defaultStaffPermissions(role);
  if (raw is Map) {
    final result = Map<String, bool>.from(defaults);
    for (final key in kStaffPermissionKeys) {
      final value = raw[key];
      if (value is bool) {
        result[key] = value;
      } else if (value is num) {
        result[key] = value != 0;
      } else if (value is String) {
        result[key] = value == '1' || value.toLowerCase() == 'true';
      }
    }
    return result;
  }
  if (raw is List) {
    final names = raw.map((e) => e.toString().trim()).toSet();
    if (names.isEmpty) return defaults;
    return {
      for (final key in kStaffPermissionKeys) key: names.contains(key),
    };
  }
  return defaults;
}

/// الحمولة المرسلة عند الحفظ — تُرسل الخريطة كاملة كي يبقى السيرفر مرجعًا
/// واحدًا للحقيقة بدل تطبيق فروق جزئية.
Map<String, dynamic> staffPermissionsPayload({
  required int staffId,
  required Map<String, bool> permissions,
}) {
  return {
    'action': 'set_permissions',
    'id': staffId,
    'permissions': {
      for (final key in kStaffPermissionKeys) key: permissions[key] ?? false
    },
  };
}

bool staffPermissionsChanged(Map<String, bool> a, Map<String, bool> b) {
  for (final key in kStaffPermissionKeys) {
    if ((a[key] ?? false) != (b[key] ?? false)) return true;
  }
  return false;
}

/// الطلب يُرفض محليًا إن حاول المالك إعطاء موظف صلاحية مالية وهو غير مشترك،
/// لأن السيرفر يمنع الوصول للمالية أصلًا في هذه الحالة.
String? staffPermissionBlockReason({
  required Map<String, bool> permissions,
  required bool ownerSubscriptionActive,
}) {
  if (permissions['can_view_finance'] == true && !ownerSubscriptionActive) {
    return 'staff_finance_needs_subscription';
  }
  return null;
}

String staffPermissionLabel(bool isArabic, String key) =>
    staffPermissionLabels(isArabic)[key] ?? key;
