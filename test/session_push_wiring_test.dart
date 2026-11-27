import 'package:allowners/utils/session_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// القسم 10: جلسة المستخدم يجب ألا تنكسر بسبب الإشعارات.
///
/// المزوّد غير مهيّأ في هذه البيئة (لا Firebase في المستودع)، فهذه الحالات
/// تثبت السلوك الواقعي: لا شبكة، لا رمز محفوظ، ولا استثناء يصل للواجهة.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('تسجيل الخروج يمسح حالة الجلسة دون رمز دفع محفوظ', () async {
    final notifier = SessionNotifier();
    addTearDown(notifier.dispose);

    await notifier.logout();

    expect(notifier.state.user, isNull);
  });

  test('حالة الإشعارات تبقى صريحة: لا ادّعاء تسجيل بلا مزوّد', () async {
    final notifier = SessionNotifier();
    addTearDown(notifier.dispose);

    await notifier.logout();

    // لا رمز ولا سبب نجاح: إما لا شيء أو سبب حقيقي، وليس نجاحًا وهميًا.
    expect(notifier.pushResult?.registered, isNot(true));
  });
}
