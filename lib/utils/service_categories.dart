import 'package:flutter/material.dart';

/// تصنيفات خدمات الوحدة الخمسة الواردة في مستند المتطلبات (المتطلب 76):
/// المفارش، الطعام والمشروبات، الحمام، الوسائط والتكنولوجيا، الخدمة والمعدات.
///
/// التصنيف يُشتق من `icon` القادم من قاعدة البيانات (نفس الحقل الذي تقرأه
/// `AmenityIcons`)، ثم من الاسم الحر كاحتياطي. لا نخترع أي مرفق: أي عنصر لا
/// ينتمي لتصنيف معروف يُدرج تحت «خدمات أخرى» بدل إسقاطه أو وضعه في تصنيف خاطئ.
enum ServiceCategory {
  bedding,
  food,
  bathroom,
  media,
  equipment,
  other,
}

class ServiceCategoryMeta {
  final ServiceCategory category;
  final IconData icon;

  const ServiceCategoryMeta(this.category, this.icon);
}

/// تصنيف خدمة/مرفق واحد مع عناصره.
class ServiceCategoryGroup {
  final ServiceCategory category;
  final List<Map<String, dynamic>> items;

  const ServiceCategoryGroup({required this.category, required this.items});

  bool get isEmpty => items.isEmpty;
}

class ServiceCategories {
  ServiceCategories._();

  /// ترتيب العرض المطابق لترتيب المستند.
  static const List<ServiceCategory> order = [
    ServiceCategory.bedding,
    ServiceCategory.food,
    ServiceCategory.bathroom,
    ServiceCategory.media,
    ServiceCategory.equipment,
    ServiceCategory.other,
  ];

  static const Map<ServiceCategory, IconData> _icons = {
    ServiceCategory.bedding: Icons.bed_outlined,
    ServiceCategory.food: Icons.restaurant_outlined,
    ServiceCategory.bathroom: Icons.bathtub_outlined,
    ServiceCategory.media: Icons.tv_outlined,
    ServiceCategory.equipment: Icons.handyman_outlined,
    ServiceCategory.other: Icons.check_circle_outline_rounded,
  };

  static IconData iconFor(ServiceCategory c) => _icons[c]!;

  /// مفاتيح `icon` من قاعدة البيانات لكل تصنيف. الترتيب مهم: البحث يتم
  /// بالاحتواء، لذا نضع المفاتيح الأكثر تحديدًا أولًا.
  static const Map<ServiceCategory, List<String>> _keys = {
    ServiceCategory.bedding: [
      'bed',
      'bedding',
      'linen',
      'pillow',
      'blanket',
      'mattress',
      'extra_bed',
      'مفارش',
      'سرير',
      'أسرّة',
      'فراش',
    ],
    ServiceCategory.food: [
      'restaurant',
      'room_service',
      'coffee',
      'breakfast',
      'kitchen',
      'minibar',
      'bar',
      'meal',
      'dining',
      'food',
      'طعام',
      'مشروب',
      'وجبة',
      'مطعم',
      'قهوة',
      'إفطار',
      'ميني بار',
    ],
    ServiceCategory.bathroom: [
      'bathroom',
      'bathtub',
      'shower',
      'toilet',
      'hair_dryer',
      'towels',
      'حمام',
      'دش',
      'منشف',
      'مستلزمات الحمام',
    ],
    ServiceCategory.media: [
      'tv',
      'wifi',
      'internet',
      'media',
      'telephone',
      'phone',
      'streaming',
      'screen',
      'audio',
      'وسائط',
      'تلفاز',
      'تلفزيون',
      'انترنت',
      'إنترنت',
      'واي فاي',
      'هاتف',
    ],
    ServiceCategory.equipment: [
      'safe',
      'laundry',
      'elevator',
      'iron',
      'desk',
      'wardrobe',
      'closet',
      'ac_unit',
      'air_conditioning',
      'heating',
      'kitchenette',
      'equipment',
      'cleaning',
      'service',
      'معدات',
      'خزنة',
      'غسيل',
      'مصعد',
      'مكواة',
      'تكييف',
      'تدفئة',
      'خدمة',
    ],
  };

  /// يحدّد تصنيف عنصر مرفق واحد اعتمادًا على `icon` ثم الاسمين.
  static ServiceCategory classify({
    String? iconKey,
    String? nameEn,
    String? nameAr,
  }) {
    final haystack = '${_slug(iconKey)} ${_slug(nameEn)} ${_slug(nameAr)}';
    for (final category in order) {
      if (category == ServiceCategory.other) continue;
      for (final key in _keys[category]!) {
        if (haystack.contains(_slug(key))) return category;
      }
    }
    return ServiceCategory.other;
  }

  /// يجمع قائمة المرافق الخام في مجموعات مرتبة. المجموعات الفارغة تُحذف.
  static List<ServiceCategoryGroup> group(List<Map<String, dynamic>> items) {
    final buckets = <ServiceCategory, List<Map<String, dynamic>>>{};
    for (final item in items) {
      final category = classify(
        iconKey: item['icon']?.toString(),
        nameEn: item['name_en']?.toString(),
        nameAr: item['name_ar']?.toString(),
      );
      buckets.putIfAbsent(category, () => []).add(item);
    }
    return [
      for (final category in order)
        if ((buckets[category] ?? const []).isNotEmpty)
          ServiceCategoryGroup(category: category, items: buckets[category]!),
    ];
  }

  static String _slug(String? value) =>
      (value ?? '').toLowerCase().replaceAll('_', ' ').trim();
}
