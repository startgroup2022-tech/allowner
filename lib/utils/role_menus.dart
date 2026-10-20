import 'package:flutter/material.dart';

/// وجهة عنصر القائمة. الربط بالشاشة يبقى في `owner_home_screen.dart`، وهنا
/// بيانات نقية فقط حتى يمكن اختبار ترتيب القوائم ووجود العناصر بدون تشغيل واجهة.
enum MenuTarget {
  ownerClients,
  newBooking,
  ownerBookings,
  commission,
  messages,
  mealRequests,
  cleaningRequests,
  extraBedRequests,
  maintenance,
  revenueReports,
  servicePrices,
  bankAccount,
  contracts,
  voting,
  community,
  marketplace,
}

/// عنصر قائمة واحد: المفتاح النصي (للعرض من `AppStrings`) والوجهة والأيقونة.
class MenuEntry {
  final String labelKey;
  final MenuTarget target;
  final IconData icon;

  const MenuEntry(this.labelKey, this.target, this.icon);
}

/// قائمة الوكيل (المتطلبات 100–107):
///   • 100: «تقارير عمولات» بدل «التقارير المالية» — الرصيد المالي الحقيقي للوكيل.
///   • 101–103: لا عقود/مستندات، لا مجتمع ملاك، لا تصويت.
///   • 104: خدمات الصيانة تبقى.
///   • 105–107: طلبات الوجبات والنظافة والسرير الإضافي مضافة.
const List<MenuEntry> agentMenu = [
  MenuEntry('my_clients', MenuTarget.ownerClients, Icons.people_alt_outlined),
  MenuEntry('book_new_stay', MenuTarget.newBooking, Icons.add_business_outlined),
  MenuEntry('owner_bookings', MenuTarget.ownerBookings,
      Icons.calendar_month_outlined),
  MenuEntry('commission_reports', MenuTarget.commission, Icons.payments_outlined),
  MenuEntry('maintenance_requests', MenuTarget.maintenance,
      Icons.build_outlined),
  MenuEntry('meal_requests', MenuTarget.mealRequests, Icons.restaurant_outlined),
  MenuEntry('housekeeping', MenuTarget.cleaningRequests,
      Icons.cleaning_services_outlined),
  MenuEntry('add_extra_bed', MenuTarget.extraBedRequests, Icons.bed_outlined),
  MenuEntry('messages', MenuTarget.messages, Icons.chat_bubble_outline_rounded),
];

/// قائمة المالك: كل الأقسام بما فيها العقود والتصويت والمجتمع وسوق الوحدات
/// والتقارير المالية وبيانات الحساب البنكي.
const List<MenuEntry> ownerMenu = [
  MenuEntry('owner_bookings', MenuTarget.ownerBookings,
      Icons.calendar_month_outlined),
  MenuEntry('financial_reports', MenuTarget.revenueReports,
      Icons.bar_chart_outlined),
  MenuEntry('service_prices', MenuTarget.servicePrices, Icons.sell_outlined),
  MenuEntry('nav_bank', MenuTarget.bankAccount, Icons.account_balance_outlined),
  MenuEntry('maintenance_requests', MenuTarget.maintenance,
      Icons.build_outlined),
  MenuEntry('housekeeping', MenuTarget.cleaningRequests,
      Icons.cleaning_services_outlined),
  MenuEntry('meal_requests', MenuTarget.mealRequests, Icons.restaurant_outlined),
  MenuEntry('add_extra_bed', MenuTarget.extraBedRequests, Icons.bed_outlined),
  MenuEntry('contracts_docs', MenuTarget.contracts, Icons.folder_outlined),
  MenuEntry('voting_decisions', MenuTarget.voting, Icons.how_to_vote_outlined),
  MenuEntry('owners_community', MenuTarget.community, Icons.groups_outlined),
  MenuEntry('units_marketplace', MenuTarget.marketplace,
      Icons.storefront_outlined),
  MenuEntry('messages', MenuTarget.messages, Icons.chat_bubble_outline_rounded),
];

List<MenuEntry> menuForRole(String? role) =>
    role == 'booking_agent' ? agentMenu : ownerMenu;
