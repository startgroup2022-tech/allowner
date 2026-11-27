import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'utils/locale_provider.dart';
import 'services/notification_service.dart';
import 'utils/push_bootstrap.dart';
import 'utils/push_tap_router.dart';
import 'utils/session_provider.dart';
import 'screens/splash_screen.dart';

/// مفتاح التنقّل العام: يسمح لضغطة الإشعار بفتح شاشتها من خارج شجرة الواجهات.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // بلا مشروع Firebase في المستودع ترجع null، فيعمل التطبيق بمزوّد غير مهيّأ
  // ويقول الحقيقة في واجهة الحالة بدل ادّعاء إشعارات لا تصل.
  final pushProvider = await initializeFirebasePush();
  runApp(ProviderScope(
    overrides: [
      pushProviderProvider
          .overrideWithValue(pushProvider ?? const UnavailablePushProvider()),
    ],
    child: const AllOwnersApp(),
  ));
}

/// دور المستخدم الحالي إن كانت الشجرة جاهزة؛ لا يُسقط التطبيق قبل أول إطار.
String? _currentRole() {
  final context = navigatorKey.currentContext;
  if (context == null) return null;
  try {
    return ProviderScope.containerOf(context, listen: false)
        .read(sessionProvider)
        .user
        ?.role;
  } catch (_) {
    return null;
  }
}

class AllOwnersApp extends ConsumerStatefulWidget {
  const AllOwnersApp({super.key});

  @override
  ConsumerState<AllOwnersApp> createState() => _AllOwnersAppState();
}

class _AllOwnersAppState extends ConsumerState<AllOwnersApp> {
  @override
  void initState() {
    super.initState();
    _wirePush();
  }

  /// يربط بثّ الإشعارات بالتنقّل مرة واحدة على الكائن المشترك مع الجلسة.
  /// بلا مزوّد Firebase مهيّأ تبقى البثوث فارغة، فلا أثر ولا ادّعاء.
  Future<void> _wirePush() async {
    final lifecycle = ref.read(pushLifecycleProvider);
    lifecycle.start(onTap: (event, data) {
      final role = _currentRole();
      final screen = screenForNotificationTap(data, role: role) ??
          notificationsScreenForRole(role);
      final navigator = navigatorKey.currentState;
      if (screen == null || navigator == null) return;
      navigator.push(MaterialPageRoute(builder: (_) => screen));
    });
    // رمز تعذّر إلغاؤه في جلسة سابقة: نُعيد المحاولة عند الإقلاع.
    await lifecycle.flushPendingUnregister();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final isArabic = locale.languageCode == 'ar';

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'All Owners',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(isArabic: isArabic),
      builder: (context, child) {
        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        );
      },
      home: const SplashScreen(),
    );
  }
}
