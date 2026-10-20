import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../services/owner_service.dart';
import '../../services/api_client.dart';
import '../../utils/safe_parse.dart';

/// المتطلب 73: أسطر ملخّص إضافات الحجز (وجبات / سرير إضافي / ملاحظات) من الحقول
/// الحقيقية التي يُرجعها الـ API. دالة نقية قابلة للاختبار؛ لا تُختلق بيانات.
List<String> buildBookingAddonLines(bool isArabic, Map<String, dynamic> b) {
  final lines = <String>[];

  final meals = asMapList(b['addons'] ?? b['meal_addons'])
      .map((a) => (isArabic ? a['name_ar'] : a['name_en']) ?? a['name'])
      .where((n) => n != null && n.toString().trim().isNotEmpty)
      .map((n) => n.toString())
      .toList();
  final legacyMeals = asMapList(b['meal_types'])
      .map((m) => m['name'] ?? m['type'])
      .where((n) => n != null && n.toString().trim().isNotEmpty)
      .map((n) => AppStrings.t(isArabic, 'meal_option_$n'))
      .toList();
  final allMeals = [...meals, ...legacyMeals];
  if (allMeals.isNotEmpty) {
    lines.add('🍽️ ${AppStrings.t(isArabic, 'meal_type')}: ${allMeals.join(isArabic ? '، ' : ', ')}');
  }

  final extraBedQty = asInt(b['extra_bed_count'] ?? b['extra_beds'], 0);
  final extraBedPrice = asDouble(b['extra_bed_price']);
  if (extraBedQty > 0 || extraBedPrice > 0) {
    final qtyPart = extraBedQty > 0 ? ' × $extraBedQty' : '';
    final pricePart = extraBedPrice > 0
        ? ' (${extraBedPrice.toStringAsFixed(0)} ${AppStrings.t(isArabic, 'sar')})'
        : '';
    lines.add('🛏️ ${AppStrings.t(isArabic, 'add_extra_bed')}$qtyPart$pricePart');
  }

  final notes = (b['notes'] ?? '').toString().trim();
  if (notes.isNotEmpty) lines.add('📝 $notes');

  return lines;
}

class OwnerBookingsScreen extends ConsumerStatefulWidget {
  const OwnerBookingsScreen({super.key});

  @override
  ConsumerState<OwnerBookingsScreen> createState() => _OwnerBookingsScreenState();
}

class _OwnerBookingsScreenState extends ConsumerState<OwnerBookingsScreen> {
  final _service = OwnerService();
  late Future<Map<String, dynamic>> _future;
  int? _busyId;

  @override
  void initState() {
    super.initState();
    _future = _service.getBookings();
  }

  void _reload() => setState(() => _future = _service.getBookings());

  Future<void> _cancelBooking(bool isArabic, int bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.t(isArabic, 'confirm_cancel_booking')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.t(isArabic, 'cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStrings.t(isArabic, 'confirm'), style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busyId = bookingId);
    try {
      await _service.cancelBooking(bookingId);
      _reload();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _confirmBooking(bool isArabic, int bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.t(isArabic, 'confirm_booking_dialog_title')),
        content: Text(AppStrings.t(isArabic, 'confirm_booking_dialog_body')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.t(isArabic, 'cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStrings.t(isArabic, 'confirm'), style: const TextStyle(color: AppColors.success)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busyId = bookingId);
    try {
      await _service.confirmBooking(bookingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.t(isArabic, 'booking_confirmed_notified'))));
      }
      _reload();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _editBooking(bool isArabic, Map<String, dynamic> b) async {
    final nameCtrl = TextEditingController(text: (b['guest_name'] ?? '').toString());
    final phoneCtrl = TextEditingController(text: (b['guest_phone'] ?? '').toString());
    DateTime? checkIn = DateTime.tryParse(b['check_in'].toString());
    DateTime? checkOut = DateTime.tryParse(b['check_out'].toString());

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppDimens.pagePadding,
          right: AppDimens.pagePadding,
          top: AppDimens.pagePadding,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppDimens.pagePadding,
        ),
        child: StatefulBuilder(
          builder: (ctx, setSheetState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.t(isArabic, 'edit_booking'), style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: AppDimens.md),
                TextField(controller: nameCtrl, decoration: InputDecoration(labelText: AppStrings.t(isArabic, 'guest_name'))),
                const SizedBox(height: AppDimens.md),
                TextField(controller: phoneCtrl, decoration: InputDecoration(labelText: AppStrings.t(isArabic, 'guest_phone'))),
                const SizedBox(height: AppDimens.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: checkIn ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 730)),
                          );
                          if (picked != null) setSheetState(() => checkIn = picked);
                        },
                        child: Text(checkIn != null
                            ? '${AppStrings.t(isArabic, 'check_in')}: ${checkIn!.toIso8601String().split('T').first}'
                            : AppStrings.t(isArabic, 'check_in')),
                      ),
                    ),
                    const SizedBox(width: AppDimens.sm),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: checkOut ?? DateTime.now().add(const Duration(days: 1)),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 730)),
                          );
                          if (picked != null) setSheetState(() => checkOut = picked);
                        },
                        child: Text(checkOut != null
                            ? '${AppStrings.t(isArabic, 'check_out')}: ${checkOut!.toIso8601String().split('T').first}'
                            : AppStrings.t(isArabic, 'check_out')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.lg),
                SizedBox(
                  width: double.infinity,
                  height: AppDimens.buttonHeight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(AppStrings.t(isArabic, 'save_changes')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (saved != true) return;
    setState(() => _busyId = asInt(b['id']));
    try {
      await _service.editBooking(
        bookingId: asInt(b['id']),
        checkIn: checkIn,
        checkOut: checkOut,
        guestName: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : null,
        guestPhone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.t(isArabic, 'booking_updated'))));
      }
      _reload();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  List<Widget> _addonSummaryLines(
          bool isArabic, TextTheme textTheme, Map<String, dynamic> b) =>
      buildBookingAddonLines(isArabic, b)
          .map((line) => Text(line, style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted)))
          .toList();

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
      case 'checked_in':
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(AppStrings.t(isArabic, 'owner_bookings')),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _reload(),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppDimens.xl),
                  children: [
                    Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 32),
                    const SizedBox(height: AppDimens.sm),
                    Text(AppStrings.t(isArabic, 'error_loading'), textAlign: TextAlign.center),
                    const SizedBox(height: AppDimens.sm),
                    Center(child: OutlinedButton(onPressed: _reload, child: Text(AppStrings.t(isArabic, 'retry')))),
                  ],
                );
              }

              final bookings = asMapList(snapshot.data?['bookings']);
              if (bookings.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppDimens.xl),
                      child: Center(child: Text(AppStrings.t(isArabic, 'no_bookings'))),
                    ),
                  ],
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(AppDimens.pagePadding),
                itemCount: bookings.length,
                separatorBuilder: (context, index) => const SizedBox(height: AppDimens.md),
                itemBuilder: (context, index) {
                  final b = bookings[index];
                  final status = (b['status'] ?? 'pending').toString();
                  final guestName = (b['guest_name'] ?? AppStrings.t(isArabic, 'guest')).toString();
                  final unitName = isArabic ? (b['unit_name'] ?? '') : (b['unit_name_en'] ?? b['unit_name'] ?? '');
                  final total = (b['total'] is num) ? (b['total'] as num).toStringAsFixed(0) : '0';

                  return Container(
                    padding: const EdgeInsets.all(AppDimens.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(guestName, style: textTheme.titleSmall)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusColor(status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                              ),
                              child: Text(
                                AppStrings.t(isArabic, 'status_$status'),
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(status)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('${b['hotel_name'] ?? ''} — $unitName', style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                        if ((b['guest_phone'] ?? '').toString().isNotEmpty)
                          Text('📞 ${b['guest_phone']}', style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                        if ((b['guest_id_number'] ?? '').toString().isNotEmpty)
                          Text('🪪 ${b['guest_id_number']}', style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                        // المتطلب 73: إظهار إضافات الوجبات والسرير الإضافي في حجوزات
                        // المالك. تُعرض فقط الحقول التي يُرجعها الـ API فعليًا؛ إن لم
                        // يُرجعها بعد فلا تُختلق بيانات (اعتماد السيرفر موثّق في
                        // docs/EXECUTION_01_BACKEND_DEPENDENCIES.md).
                        ..._addonSummaryLines(isArabic, textTheme, b),
                        const Divider(height: AppDimens.lg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${AppStrings.t(isArabic, 'check_in')}: ${b['check_in']}', style: textTheme.bodySmall),
                            Text('${AppStrings.t(isArabic, 'check_out')}: ${b['check_out']}', style: textTheme.bodySmall),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(AppStrings.t(isArabic, 'total_amount'), style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                            Text('$total ${AppStrings.t(isArabic, 'sar')}', style: textTheme.titleSmall?.copyWith(color: AppColors.goldDark)),
                          ],
                        ),
                        if (b['can_confirm'] == true || b['can_edit'] == true || b['can_cancel'] == true) ...[
                          const SizedBox(height: AppDimens.sm),
                          Row(
                            children: [
                              if (b['can_confirm'] == true)
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                                    onPressed: _busyId == b['id'] ? null : () => _confirmBooking(isArabic, asInt(b['id'])),
                                    child: Text(AppStrings.t(isArabic, 'confirm_booking')),
                                  ),
                                ),
                              if (b['can_confirm'] == true && (b['can_edit'] == true || b['can_cancel'] == true))
                                const SizedBox(width: AppDimens.sm),
                              if (b['can_edit'] == true)
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _busyId == b['id'] ? null : () => _editBooking(isArabic, b),
                                    child: Text(AppStrings.t(isArabic, 'edit_booking')),
                                  ),
                                ),
                              if (b['can_edit'] == true && b['can_cancel'] == true) const SizedBox(width: AppDimens.sm),
                              if (b['can_cancel'] == true)
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                                    onPressed: _busyId == b['id'] ? null : () => _cancelBooking(isArabic, asInt(b['id'])),
                                    child: Text(AppStrings.t(isArabic, 'cancel_booking')),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
