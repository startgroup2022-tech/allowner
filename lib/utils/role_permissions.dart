import 'package:flutter/material.dart';

import 'role_menus.dart';

/// صلاحيات الأدوار — منطق نقي قابل للاختبار.
///
/// المتطلب 74: موظف المالك (`unit_manager`) يستطيع **مشاهدة الوحدات وتبديل
/// حالتها** واستقبال بلاغات الصيانة والتنظيف فقط. لا حذف، ولا وصول للمحفظة أو
/// الإيرادات أو التقارير أو بيانات الحساب البنكي.
///
/// القاعدة المُنفَّذة هنا هي **حجب الوصول**، لا إخفاء زر فقط: القائمة تُبنى من
/// هذه الصلاحيات، فلا تظهر وجهة ممنوعة أصلًا.
class RolePermissions {
  const RolePermissions(this.role);

  final String? role;

  bool get isOwner => role == 'owner';
  bool get isUnitManager => role == 'unit_manager';
  bool get isAgent => role == 'booking_agent';

  /// الوحدات: المالك والموظف فقط. الوكيل لا يملك وحدات.
  bool get canViewUnits => isOwner || isUnitManager;

  /// تبديل حالة الوحدة: متاح للموظف كما للمالك (المتطلب 74).
  bool get canToggleUnitStatus => isOwner || isUnitManager;

  /// الحذف والإضافة للمالك فقط — الموظف ممنوع من الحذف صراحةً (المتطلب 74).
  bool get canDeleteUnits => isOwner;
  bool get canAddUnits => isOwner;

  /// بلاغات الصيانة والتنظيف: يستقبلها الموظف كما المالك.
  bool get canViewMaintenance => isOwner || isUnitManager || isAgent;
  bool get canViewCleaning => isOwner || isUnitManager || isAgent;

  /// المحفظة والمستحقات والاشتراك: للمالك فقط. الموظف ممنوع صراحةً.
  bool get canViewWallet => isOwner;
  bool get canViewSubscription => isOwner;

  /// الإيرادات والتقارير المالية: للمالك، وللوكيل «عمولتي» فقط.
  bool get canViewRevenueReports => isOwner || isAgent;

  /// الحساب البنكي: المالك والوكيل (الوكيل لاستلام العمولات — المتطلب 109).
  /// الموظف ممنوع.
  bool get canViewBankAccount => isOwner || isAgent;

  /// العقود والتصويت والمجتمع وسوق الوحدات: للمالك فقط.
  bool get canViewContracts => isOwner;
  bool get canViewVoting => isOwner;
  bool get canViewCommunity => isOwner;
  bool get canViewMarketplace => isOwner;

  /// القائمة المسموح بها لهذا الدور.
  List<MenuEntry> get menu {
    if (isUnitManager) return unitManagerMenu;
    return menuForRole(role);
  }
}

/// قائمة موظف الوحدة (المتطلب 74): وحداتي + بلاغات الصيانة والتنظيف + الرسائل.
/// بلا حذف، بلا محفظة، بلا إيرادات، بلا بنك.
const List<MenuEntry> unitManagerMenu = [
  MenuEntry(
      'maintenance_requests', MenuTarget.maintenance, Icons.build_outlined),
  MenuEntry('housekeeping', MenuTarget.cleaningRequests,
      Icons.cleaning_services_outlined),
  MenuEntry('messages', MenuTarget.messages, Icons.chat_bubble_outline_rounded),
];
