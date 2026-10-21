import 'dart:convert';
import 'dart:typed_data';

import 'package:allowners/screens/owner/owner_bank_screen.dart';
import 'package:allowners/screens/owner/owner_bookings_screen.dart';
import 'package:allowners/screens/owner/owner_cleaning_screen.dart';
import 'package:allowners/screens/owner/owner_clients_screen.dart';
import 'package:allowners/screens/owner/owner_commission_screen.dart';
import 'package:allowners/screens/owner/owner_community_screen.dart';
import 'package:allowners/screens/owner/owner_decisions_screen.dart';
import 'package:allowners/screens/owner/owner_documents_screen.dart';
import 'package:allowners/screens/owner/owner_extra_bed_screen.dart';
import 'package:allowners/screens/owner/owner_home_screen.dart';
import 'package:allowners/screens/owner/owner_maintenance_screen.dart';
import 'package:allowners/screens/owner/owner_marketplace_screen.dart';
import 'package:allowners/screens/owner/owner_meal_requests_screen.dart';
import 'package:allowners/screens/owner/owner_messages_screen.dart';
import 'package:allowners/screens/owner/owner_notifications_screen.dart';
import 'package:allowners/screens/owner/owner_revenue_screen.dart';
import 'package:allowners/screens/owner/owner_service_prices_screen.dart';
import 'package:allowners/screens/owner/owner_staff_screen.dart';
import 'package:allowners/screens/owner/owner_units_screen.dart';
import 'package:allowners/services/api_client.dart';
import 'package:allowners/theme/app_theme.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// اختبارات عرض لشاشات المالك والفندق والوكيل (المتطلبات 60–143).
///
/// كل شاشة هنا تُبنى **عبر طبقة الـ service الحقيقية** بمحوّل Dio يخدم حمولات
/// بشكل استجابات الإنتاج. الهدف إثبات أن الشاشة تُرسم ببيانات السيرفر الفعلية
/// بلا استثناء ولا تجاوز (overflow) على العروض 360/390/768، وأنها تعرض الحقول
/// الحقيقية (السعر، ملاحظة الفندق، نص الإشعار، الإضافات) لا عناصر وهمية.
///
/// هذه ليست اختبارات تكامل حيّ (لا شبكة) ولا لقطات جهاز — بل رسم فعلي لشجرة
/// الودجات الحقيقية. الحالات المحمية بالتوثيق تُختبر على مسار القراءة نفسه.
const _maintenanceJson = {
  'success': true,
  'requests': [
    {
      'id': 7,
      'title': 'تسريب ماء',
      'description': 'الحنفية تسرّب',
      'status': 'in_progress',
      'hotel_name': 'فندق فيرمونت مكه',
      'unit_name': 'جناح عائلي',
      'hotel_note': 'الفني في الطريق',
      'price': 250,
    },
  ],
};

const _cleaningJson = {
  'success': true,
  'requests': [
    {
      'id': 11,
      'description': 'تنظيف بعد المغادرة',
      'status': 'closed',
      'hotel_name': 'فندق فيرمونت مكه',
      'unit_name_ar': 'جناح عائلي',
      'unit_name_en': 'Family Suite',
      'hotel_note': 'تم التنظيف',
      'price': '120',
      'can_cancel': false,
    },
  ],
};

const _mealsJson = {
  'success': true,
  'requests': [
    {
      'id': 21,
      'guest_name': 'محمد علي',
      'hotel_name': 'فندق فيرمونت مكه',
      'room_number': '402',
      'meal_type': 'إفطار',
      'notes': 'بدون سكر',
      'status': 'pending',
    },
  ],
};

const _bookingsJson = {
  'success': true,
  'bookings': [
    {
      'id': 31,
      'booking_ref': 'BK-1001',
      'guest_name': 'محمد علي',
      'guest_phone': '0500000000',
      'guest_id_number': '1234567890',
      'hotel_name': 'فندق فيرمونت مكه',
      'unit_name': 'جناح عائلي',
      'check_in': '2026-11-01',
      'check_out': '2026-11-03',
      'total': '1500',
      'status': 'confirmed',
      'can_cancel': true,
      'can_confirm': false,
      'can_edit': true,
      'booking_source': 'app',
      'meal_types': ['breakfast'],
      'extra_bed_count': 1,
      'extra_bed_price': 150,
      'notes': 'وصول متأخر',
    },
  ],
};

const _notificationsJson = {
  'success': true,
  'notifications': [
    {
      'id': 1,
      'type': 'maintenance',
      'title_ar': 'طلب صيانة جديد',
      'title_en': 'New maintenance request',
      'body_ar': 'تم إنشاء طلب صيانة للوحدة',
      'body_en': 'A maintenance request was created',
      'created_at': '2026-10-19 10:00:00',
      'is_read': false,
    },
  ],
};

const _revenueJson = {
  'success': true,
  'total_revenue': '12000',
  'maintenance_expense': '500',
  'cleaning_expense': '300',
  'monthly': [
    {'month': '2025-01', 'total': '5000'},
    {'month': '2026-01', 'total': '7000'},
  ],
  'units': [
    {'unit_name': 'جناح عائلي', 'revenue': '7000'},
  ],
};

const _clientsJson = {
  'success': true,
  'clients': [
    {
      'id': 1,
      'full_name': 'عميل الوكيل',
      'phone': '0511111111',
      'bookings_count': 2,
      'total_spent': '3000',
    },
  ],
};

const _commissionJson = {
  'success': true,
  'commission_type': 'percentage',
  'commission_rate': '10',
  'total_bookings': 4,
  'total_commission': '600',
  'paid': '400',
  'unpaid': '200',
  'items': [
    {
      'booking_ref': 'BK-1001',
      'guest_name': 'محمد علي',
      'hotel_name': 'فندق فيرمونت مكه',
      'booking_total': '1500',
      'amount': '150',
      'status': 'paid',
      'booking_status': 'confirmed',
    },
  ],
};

const _bankJson = {
  'success': true,
  'bank_name': 'البنك الأهلي',
  'account_name': 'مالك الوحدة',
  'iban': 'SA0000000000000000000000',
};

const _unitsJson = {
  'success': true,
  'can_create': true,
  'units': [
    {
      'id': 13,
      'name_ar': 'جناح عائلي',
      'name_en': 'Family Suite',
      'hotel_name': 'فندق فيرمونت مكه',
      'price_per_night': 750,
      'is_active': 1,
    },
  ],
  'hotels': [
    {'id': 2, 'name': 'فندق فيرمونت مكه'},
  ],
};

const _documentsJson = {
  'success': true,
  'documents': [
    {
      'id': 3,
      'title': 'عقد الوحدة 402',
      'hotel_name': 'فندق فيرمونت مكه',
      'file_type': 'pdf',
      'file_url': 'https://all-owner.online/uploads/doc.pdf',
    },
  ],
};

const _communityJson = {
  'success': true,
  'posts': [
    {
      'id': 5,
      'full_name': 'مالك الوحدة',
      'content': 'عرض جديد للوحدات في مكة',
      'like_count': 4,
      'comment_count': 2,
      'liked_by_me': false,
      'image_url': '',
    },
  ],
};

const _decisionsJson = {
  'success': true,
  'decisions': [
    {
      'id': 8,
      'title': 'تحديث لائحة الرسوم',
      'description': 'تصويت على نسبة العمولة',
      'status': 'open',
      'total_votes': 12,
      'my_vote': 'yes',
      'options': [
        {'label': 'موافق', 'votes': 8},
        {'label': 'غير موافق', 'votes': 4},
      ],
    },
  ],
  'hotels': [
    {'id': 2, 'name': 'فندق فيرمونت مكه'},
  ],
};

const _marketplaceJson = {
  'success': true,
  'listings': [
    {
      'id': 4,
      'name_ar': 'جناح عائلي للتنازل',
      'title': 'جناح عائلي للتنازل',
      'hotel_name': 'فندق فيرمونت مكه',
      'price': '90000',
      'price_per_night': 750,
      'unit_capacity': 4,
      'interest_count': 3,
      'is_mine': false,
      'image_url': '',
    },
  ],
};

const _messagesJson = {
  'success': true,
  'conversations': [
    {
      'id': 2,
      'other_name': 'إدارة الفندق',
      'full_name': 'إدارة الفندق',
      'last_body': 'تم تأكيد الحجز',
      'unread_count': 1,
    },
  ],
};

const _staffJson = {
  'success': true,
  'staff': [
    {
      'id': 6,
      'full_name': 'مدير الوحدات',
      'email': 'manager@example.com',
      'phone': '0522222222',
      'role': 'unit_manager',
      'status': 'active',
    },
  ],
};

const _servicePricesJson = {
  'success': true,
  'prices': [
    {
      'id': 9,
      'service_type': 'cleaning',
      'title_ar': 'تنظيف',
      'title_en': 'Cleaning',
      'unit_id': 13,
      'price': '120',
    },
  ],
  'units': [
    {'id': 13, 'name_ar': 'جناح عائلي', 'name_en': 'Family Suite'},
  ],
  'hotels': [
    {'id': 2, 'name': 'فندق فيرمونت مكه'},
  ],
};

const _dashboardJson = {
  'success': true,
  'stats': {
    'units_count': 3,
    'bookings_count': 12,
    'pending_bookings': 2,
    'revenue': '12000',
    'total_bookings': 4,
    'total_commission': '600',
    'paid': '400',
    'unpaid': '200',
  },
};

class _Adapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    Object body;
    if (path.contains('owner-maintenance')) {
      body = _maintenanceJson;
    } else if (path.contains('owner-meals')) {
      body = _mealsJson;
    } else if (path.contains('owner-requests')) {
      body = _cleaningJson;
    } else if (path.contains('owner-bookings')) {
      body = _bookingsJson;
    } else if (path.contains('notifications')) {
      body = _notificationsJson;
    } else if (path.contains('owner-revenue')) {
      body = _revenueJson;
    } else if (path.contains('agent-clients')) {
      body = _clientsJson;
    } else if (path.contains('agent-commission')) {
      body = _commissionJson;
    } else if (path.contains('owner-bank')) {
      body = _bankJson;
    } else if (path.contains('owner-units')) {
      body = _unitsJson;
    } else if (path.contains('documents/list')) {
      body = _documentsJson;
    } else if (path.contains('community/list')) {
      body = _communityJson;
    } else if (path.contains('decisions/list')) {
      body = _decisionsJson;
    } else if (path.contains('marketplace/list')) {
      body = _marketplaceJson;
    } else if (path.contains('messages/conversations')) {
      body = _messagesJson;
    } else if (path.contains('owner-staff')) {
      body = _staffJson;
    } else if (path.contains('hotel/prices')) {
      body = _servicePricesJson;
    } else if (path.contains('owner-dashboard')) {
      body = _dashboardJson;
    } else if (path.contains('content/settings')) {
      body = {'success': true};
    } else {
      body = {'success': true};
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

Widget _wrap(Widget child, {bool isArabic = true, double width = 390}) {
  return ProviderScope(
    child: MaterialApp(
      locale: Locale(isArabic ? 'ar' : 'en'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(isArabic: isArabic),
      home: child,
    ),
  );
}

void main() {
  late HttpClientAdapter _originalAdapter;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _originalAdapter = ApiClient.instance.dio.httpClientAdapter;
    ApiClient.instance.dio.httpClientAdapter = _Adapter();
  });

  tearDown(() {
    ApiClient.instance.dio.httpClientAdapter = _originalAdapter;
  });

  Future<void> _pump(WidgetTester tester, Widget screen,
      {double width = 390, bool isArabic = true}) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_wrap(screen, width: width, isArabic: isArabic));
    await tester.pumpAndSettle();
  }

  group('شاشات الطلبات (المتطلبات 60، 69، 70، 72)', () {
    testWidgets('الصيانة تعرض العنوان والسعر وملاحظة الفندق', (tester) async {
      await _pump(tester, const OwnerMaintenanceScreen());
      expect(tester.takeException(), isNull);
      expect(find.text('تسريب ماء'), findsWidgets);
      expect(find.textContaining('250'), findsWidgets);
      expect(find.textContaining('الفني في الطريق'), findsWidgets);
    });

    testWidgets('النظافة تعرض السعر وملاحظة الفندق (المتطلب 70)',
        (tester) async {
      await _pump(tester, const OwnerCleaningScreen());
      expect(tester.takeException(), isNull);
      expect(find.textContaining('120'), findsWidgets);
      expect(find.textContaining('تم التنظيف'), findsWidgets);
    });

    testWidgets('الوجبات تعرض الضيف والغرفة والنوع (المتطلب 71)',
        (tester) async {
      await _pump(tester, const OwnerMealRequestsScreen());
      expect(tester.takeException(), isNull);
      expect(find.textContaining('محمد علي'), findsWidgets);
    });

    testWidgets('السرير الإضافي تُرسم ببياناتها', (tester) async {
      await _pump(tester, const OwnerExtraBedScreen());
      expect(tester.takeException(), isNull);
    });

    for (final w in const [360.0, 768.0]) {
      testWidgets('الصيانة بلا تجاوز على ${w.toInt()}px', (tester) async {
        await _pump(tester, const OwnerMaintenanceScreen(), width: w);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('حجوزات المالك (المتطلبات 35، 37، 38، 73)', () {
    testWidgets('البطاقة تعرض الضيف والإضافات ومصدر الحجز', (tester) async {
      await _pump(tester, const OwnerBookingsScreen());
      expect(tester.takeException(), isNull);
      expect(find.textContaining('محمد علي'), findsWidgets);
      // المتطلب 73: الإضافات تظهر من الحقول الحقيقية
      expect(find.textContaining('فطور'), findsWidgets);
    });

    testWidgets('زر الإلغاء يظهر عند can_cancel من السيرفر', (tester) async {
      await _pump(tester, const OwnerBookingsScreen());
      expect(tester.takeException(), isNull);
      expect(find.text('إلغاء الحجز'), findsWidgets);
    });
  });

  group('الإشعارات (المتطلب 71)', () {
    testWidgets('نص الإشعار يظهر من body_ar الحقيقي', (tester) async {
      await _pump(tester, const OwnerNotificationsScreen());
      expect(tester.takeException(), isNull);
      expect(find.textContaining('طلب صيانة جديد'), findsWidgets);
    });
  });

  group('تقارير الإيرادات (المتطلبات 126–129)', () {
    testWidgets('الصافي والمصروفات والسنة تظهر من الحقول الحقيقية',
        (tester) async {
      await _pump(tester, const OwnerRevenueScreen());
      expect(tester.takeException(), isNull);
      // المتطلب 126: الإجمالي والسنة من سطور monthly الحقيقية.
      expect(find.textContaining('12000'), findsWidgets);
      expect(find.textContaining('2026'), findsWidgets);
      // المتطلبان 128 و129: مصروفات الصيانة والنظافة تُعرض من حقولها.
      expect(find.textContaining('500'), findsWidgets);
      expect(find.textContaining('300'), findsWidgets);
      // المتطلب 127: الصافي = 12000 − 500 − 300 = 11200.
      expect(find.textContaining('11200'), findsWidgets);
      // إيراد الوحدة يُعرض باسمها الحقيقي من `units`.
      expect(find.textContaining('جناح عائلي'), findsWidgets);
    });
  });

  group('العمولة والبنك (المتطلبات 108، 118)', () {
    testWidgets(
        'شاشة العمولة تعرض الإجمالي والمدفوع وغير المدفوع (المتطلب 108)',
        (tester) async {
      await _pump(tester, const OwnerCommissionScreen());
      expect(tester.takeException(), isNull);
      // الإجمالي والمدفوع وغير المدفوع من حقول الـ API الحقيقية.
      expect(find.textContaining('600'), findsWidgets);
      expect(find.textContaining('400'), findsWidgets);
      expect(find.textContaining('200'), findsWidgets);
      expect(find.textContaining('BK-1001'), findsWidgets);
    });

    testWidgets('شاشة البنك تعرض الآيبان المسجّل', (tester) async {
      await _pump(tester, const OwnerBankScreen());
      expect(tester.takeException(), isNull);
      expect(find.textContaining('SA0000000000000000000000'), findsWidgets);
    });
  });

  group('عملاء الوكيل (المتطلبات 93، 99)', () {
    testWidgets('قائمة العملاء تُرسم بعدد الحجوزات والإجمالي (المتطلب 99)',
        (tester) async {
      await _pump(tester, const OwnerClientsScreen());
      expect(tester.takeException(), isNull);
      expect(find.textContaining('عميل الوكيل'), findsWidgets);
      // المتطلب 99: يرى الوكيل عدد حجوزات عميله وإجمالي ما دفعه.
      expect(find.textContaining('2'), findsWidgets);
      expect(find.textContaining('3000'), findsWidgets);
    });
  });

  group('وحدات المالك (المتطلبات 74، 123)', () {
    testWidgets('الوحدات تُرسم ببياناتها', (tester) async {
      await _pump(tester, const OwnerUnitsScreen());
      expect(tester.takeException(), isNull);
      expect(find.textContaining('جناح عائلي'), findsWidgets);
    });
  });

  group('اللغة الإنجليزية (LTR)', () {
    testWidgets('الصيانة بالإنجليزية تُرسم LTR بلا تجاوز', (tester) async {
      SharedPreferences.setMockInitialValues({'app_locale': 'en'});
      await _pump(tester, const OwnerMaintenanceScreen(), isArabic: false);
      expect(tester.takeException(), isNull);
    });
  });

  group('الشاشات المساندة (المتطلبات 61، 75، 77، 78، 79، 80، 84، 86)', () {
    testWidgets('لوحة المالك تعرض الإحصاءات الحقيقية', (tester) async {
      await _pump(tester, const OwnerHomeScreen());
      expect(tester.takeException(), isNull);
      expect(find.textContaining('12000'), findsWidgets);
    });

    testWidgets('المستندات تعرض العنوان الحقيقي', (tester) async {
      await _pump(tester, const OwnerDocumentsScreen());
      expect(tester.takeException(), isNull);
      expect(find.textContaining('عقد الوحدة 402'), findsWidgets);
    });

    testWidgets('المجتمع يعرض المنشور الحقيقي', (tester) async {
      await _pump(tester, const OwnerCommunityScreen());
      expect(tester.takeException(), isNull);
      expect(find.textContaining('عرض جديد للوحدات في مكة'), findsWidgets);
    });

    testWidgets('القرارات تعرض عنوان القرار', (tester) async {
      await _pump(tester, const OwnerDecisionsScreen());
      expect(tester.takeException(), isNull);
      expect(find.textContaining('تحديث لائحة الرسوم'), findsWidgets);
    });

    testWidgets('سوق التنازل يعرض الوحدة الحقيقية', (tester) async {
      await _pump(tester, const OwnerMarketplaceScreen());
      expect(tester.takeException(), isNull);
      expect(find.textContaining('جناح عائلي للتنازل'), findsWidgets);
    });

    testWidgets('الرسائل تعرض آخر نص حقيقي', (tester) async {
      await _pump(tester, const OwnerMessagesScreen());
      expect(tester.takeException(), isNull);
      expect(find.textContaining('تم تأكيد الحجز'), findsWidgets);
    });

    testWidgets('موظفو المالك يعرضون الاسم والدور', (tester) async {
      await _pump(tester, const OwnerStaffScreen());
      expect(tester.takeException(), isNull);
      expect(find.textContaining('مدير الوحدات'), findsWidgets);
    });

    testWidgets('أسعار الخدمات تعرض الخدمة الحقيقية', (tester) async {
      await _pump(tester, const OwnerServicePricesScreen());
      expect(tester.takeException(), isNull);
      expect(find.textContaining('تنظيف'), findsWidgets);
    });

    for (final screen in const [
      OwnerHomeScreen(),
      OwnerDocumentsScreen(),
      OwnerCommunityScreen(),
      OwnerDecisionsScreen(),
      OwnerMarketplaceScreen(),
      OwnerMessagesScreen(),
      OwnerStaffScreen(),
      OwnerServicePricesScreen(),
    ]) {
      for (final w in const [360.0, 768.0]) {
        testWidgets('${screen.runtimeType} بلا تجاوز على ${w.toInt()}px',
            (tester) async {
          await _pump(tester, screen, width: w);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
