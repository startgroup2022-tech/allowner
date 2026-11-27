import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'utils/locale_provider.dart';
import 'utils/push_lifecycle.dart';
import 'utils/push_tap_router.dart';
import 'utils/session_provider.dart';
import 'screens/splash_screen.dart';

/// مفتاح التنقّل العام: يسمح لضغطة الإشعار بفتح شاشتها من خارج شجرة الواجهات.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _wirePushTaps();
  runApp(const ProviderScope(child: AllOwnersApp()));
}

/// يربط بثّ الإشعارات بالتنقّل. بلا مزوّد Firebase مهيّأ تبقى البثوث فارغة،
/// فلا يحدث أي أثر — ولا يُدّعى وصول إشعار لم يصل.
void _wirePushTaps() {
  final lifecycle = PushLifecycle();
  lifecycle.start(onTap: (event, data) {
    final role = _currentRole();
    final screen = screenForNotificationTap(data, role: role) ??
        notificationsScreenForRole(role);
    final navigator = navigatorKey.currentState;
    if (screen == null || navigator == null) return;
    navigator.push(MaterialPageRoute(builder: (_) => screen));
  });
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

class AllOwnersApp extends ConsumerWidget {
  const AllOwnersApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
