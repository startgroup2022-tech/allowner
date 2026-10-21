import 'package:allowners/utils/role_menus.dart';
import 'package:allowners/utils/role_permissions.dart';
import 'package:flutter_test/flutter_test.dart';

/// اختبارات المتطلب 74: صلاحيات موظف الوحدة (`unit_manager`).
///
/// القاعدة المُختبَرة: الموظف يشاهد الوحدات ويبدّل حالتها ويستقبل بلاغات
/// الصيانة/التنظيف **فقط**؛ ولا حذف ولا وصول للمحفظة أو الإيرادات أو البنك.
void main() {
  group('الصلاحيات الأساسية للموظف', () {
    const staff = RolePermissions('unit_manager');

    test('يشاهد الوحدات ويبدّل حالتها', () {
      expect(staff.canViewUnits, isTrue);
      expect(staff.canToggleUnitStatus, isTrue);
    });

    test('ممنوع من الإضافة والحذف', () {
      expect(staff.canAddUnits, isFalse);
      expect(staff.canDeleteUnits, isFalse);
    });

    test('يستقبل بلاغات الصيانة والتنظيف', () {
      expect(staff.canViewMaintenance, isTrue);
      expect(staff.canViewCleaning, isTrue);
    });

    test('ممنوع من المحفظة والاشتراك والبنك والإيرادات', () {
      expect(staff.canViewWallet, isFalse);
      expect(staff.canViewSubscription, isFalse);
      expect(staff.canViewBankAccount, isFalse);
      expect(staff.canViewRevenueReports, isFalse);
    });

    test('ممنوع من العقود والتصويت والمجتمع والسوق', () {
      expect(staff.canViewContracts, isFalse);
      expect(staff.canViewVoting, isFalse);
      expect(staff.canViewCommunity, isFalse);
      expect(staff.canViewMarketplace, isFalse);
    });
  });

  group('قائمة الموظف لا تحتوي أي وجهة ممنوعة', () {
    const staff = RolePermissions('unit_manager');
    final targets = staff.menu.map((e) => e.target).toList();

    test('تحتوي الصيانة والتنظيف والرسائل فقط', () {
      expect(targets, contains(MenuTarget.maintenance));
      expect(targets, contains(MenuTarget.cleaningRequests));
      expect(targets, contains(MenuTarget.messages));
      expect(targets.length, 3);
    });

    test('لا تحتوي المحفظة ولا الاشتراك ولا البنك ولا الإيرادات', () {
      expect(targets, isNot(contains(MenuTarget.wallet)));
      expect(targets, isNot(contains(MenuTarget.subscription)));
      expect(targets, isNot(contains(MenuTarget.bankAccount)));
      expect(targets, isNot(contains(MenuTarget.revenueReports)));
      expect(targets, isNot(contains(MenuTarget.contracts)));
    });
  });

  group('صلاحيات المالك والوكيل لم تتغيّر', () {
    const owner = RolePermissions('owner');

    test('المالك يملك كل شيء', () {
      expect(owner.canAddUnits, isTrue);
      expect(owner.canDeleteUnits, isTrue);
      expect(owner.canViewWallet, isTrue);
      expect(owner.canViewSubscription, isTrue);
      expect(owner.canViewBankAccount, isTrue);
      expect(owner.canViewRevenueReports, isTrue);
      expect(owner.menu.length, ownerMenu.length);
    });

    const agent = RolePermissions('booking_agent');

    test('الوكيل: لا وحدات، له البنك والعمولات، لا محفظة', () {
      expect(agent.isAgent, isTrue);
      expect(agent.canViewUnits, isFalse);
      expect(agent.canAddUnits, isFalse);
      expect(agent.canViewBankAccount, isTrue);
      expect(agent.canViewRevenueReports, isTrue);
      expect(agent.canViewWallet, isFalse);
      expect(agent.canViewSubscription, isFalse);
      expect(agent.menu.length, agentMenu.length);
    });
  });

  test('الدور المجهول يُعامل كمالك (سلوك التطبيق الحالي محفوظ)', () {
    const unknown = RolePermissions(null);
    expect(unknown.menu.length, ownerMenu.length);
  });
}
