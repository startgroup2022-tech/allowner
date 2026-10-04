import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import 'hotel_dashboard_screen.dart';
import 'hotel_bookings_screen.dart';
import 'hotel_requests_screen.dart';
import 'hotel_prices_screen.dart';
import 'hotel_profile_screen.dart';

/// الشاشة الرئيسية لحساب "إدارة الفندق": لوحة سريعة، حجوزات (دخول/خروج)،
/// طلبات النظافة/الصيانة/الوجبات/السرير، وأسعار الخدمات.
class HotelStaffNavigationScreen extends ConsumerStatefulWidget {
  const HotelStaffNavigationScreen({super.key});

  @override
  ConsumerState<HotelStaffNavigationScreen> createState() => _HotelStaffNavigationScreenState();
}

class _HotelStaffNavigationScreenState extends ConsumerState<HotelStaffNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';

    final screens = <Widget>[
      const HotelDashboardScreen(),
      const HotelBookingsScreen(),
      const HotelRequestsScreen(),
      const HotelPricesScreen(),
      const HotelProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            activeIcon: const Icon(Icons.dashboard_rounded),
            label: AppStrings.t(isArabic, 'nav_home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_month_outlined),
            activeIcon: const Icon(Icons.calendar_month_rounded),
            label: AppStrings.t(isArabic, 'owner_bookings'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.pending_actions_outlined),
            activeIcon: const Icon(Icons.pending_actions_rounded),
            label: AppStrings.t(isArabic, 'hotel_requests'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.sell_outlined),
            activeIcon: const Icon(Icons.sell_rounded),
            label: AppStrings.t(isArabic, 'service_prices'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline_rounded),
            activeIcon: const Icon(Icons.person_rounded),
            label: AppStrings.t(isArabic, 'nav_profile'),
          ),
        ],
      ),
    );
  }
}
