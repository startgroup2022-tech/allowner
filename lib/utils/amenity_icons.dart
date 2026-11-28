import 'package:flutter/material.dart';

/// يترجم `icon_key` القادم من قاعدة البيانات إلى أيقونة Material.
///
/// المرافق في الـ API ترجع حقل `icon` بقيم مثل: wifi, ac_unit, restaurant,
/// room_service, coffee_maker, smoke_free, accessible, meeting_room, car...
/// إذا ظهر مفتاح جديد من لوحة التحكم، نرجع أيقونة عامة بدل الانهيار أو
/// أيقونة خاطئة — لا نص ولا أيقونة ثابتة مبنية على الاسم العربي.
class AmenityIcons {
  AmenityIcons._();

  static const Map<String, IconData> _map = {
    'wifi': Icons.wifi_rounded,
    'parking': Icons.local_parking_outlined,
    'pool': Icons.pool_outlined,
    'gym': Icons.fitness_center_outlined,
    'fitness': Icons.fitness_center_outlined,
    'ac_unit': Icons.ac_unit_rounded,
    'air_conditioning': Icons.ac_unit_rounded,
    'restaurant': Icons.restaurant_outlined,
    'room_service': Icons.room_service_outlined,
    'coffee_maker': Icons.coffee_maker_outlined,
    'coffee': Icons.coffee_maker_outlined,
    'smoke_free': Icons.smoke_free_outlined,
    'accessible': Icons.accessible_rounded,
    'meeting_room': Icons.meeting_room_outlined,
    'car': Icons.directions_car_outlined,
    'transport': Icons.directions_car_outlined,
    'family': Icons.family_restroom_outlined,
    'pets': Icons.pets_outlined,
    'tv': Icons.tv_outlined,
    'bathroom': Icons.bathtub_outlined,
    'bed': Icons.bed_outlined,
    'breakfast': Icons.free_breakfast_outlined,
    'kitchen': Icons.kitchen_outlined,
    'laundry': Icons.local_laundry_service_outlined,
    'elevator': Icons.elevator_outlined,
    'safe': Icons.lock_outline_rounded,
    'shuttle': Icons.airport_shuttle_outlined,
    'spa': Icons.spa_outlined,
    'beach': Icons.beach_access_rounded,
    'kids': Icons.child_friendly_outlined,
    'non_smoking': Icons.smoke_free_outlined,
  };

  /// أيقونة المرفق: نبحث بالمفتاح أولًا، ثم بنص حر (احتياطي للتوافق مع
  /// بيانات قديمة تُخزّن وصفًا بدل مفتاح).
  static IconData resolve({String? iconKey, String? nameEn, String? nameAr}) {
    final key = _slug(iconKey);
    if (key != null && _map.containsKey(key)) return _map[key]!;

    final haystack =
        '${_slug(nameEn) ?? ''} ${_slug(nameAr) ?? ''} ${key ?? ''}';
    for (final entry in _map.entries) {
      if (haystack.contains(entry.key)) return entry.value;
    }
    return Icons.check_circle_outline_rounded;
  }

  static String? _slug(String? value) {
    if (value == null) return null;
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) return null;
    return trimmed.replaceAll(RegExp(r'[\s-]+'), '_');
  }
}
