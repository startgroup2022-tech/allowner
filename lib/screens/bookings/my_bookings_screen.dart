import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../utils/session_provider.dart';
import '../../services/hotel_service.dart';
import '../../services/api_client.dart';
import '../auth/login_screen.dart';
import '../../utils/safe_parse.dart';

/// المتطلب 97: صفوف تفاصيل الحجز المعروضة للوكيل/الضيف. دالة نقية تُرجع فقط
/// الصفوف التي تُرجع بياناتها الحقيقية من الـ API (تُخفى الصفوف الفارغة).
List<(String, String)> buildBookingDetailRows(
    bool isArabic, Map<String, dynamic> b) {
  final rows = <(String, String)>[];
  void add(String key, String? value) {
    final v = (value ?? '').toString().trim();
    if (v.isNotEmpty) rows.add((AppStrings.t(isArabic, key), v));
  }

  add('hotel_name', b['hotel_name']?.toString());
  add('city', isArabic ? b['city_ar']?.toString() : b['city_en']?.toString());
  add(
      'unit_name',
      (isArabic ? b['unit_name_ar'] : b['unit_name_en'])?.toString() ??
          b['unit_name']?.toString());
  // المتطلب 52: رقم الغرفة يُعرض قبل عدد الأشخاص، ورقم الوحدة قبل الاسم.
  final unitNumber = (b['unit_number'] ?? '').toString().trim();
  if (unitNumber.isNotEmpty) {
    rows.add((AppStrings.t(isArabic, 'unit_no'), unitNumber));
  }
  add('guest_name', b['guest_name']?.toString());
  add('guest_phone', b['guest_phone']?.toString());
  add('guest_id_number', b['guest_id_number']?.toString());
  add('check_in', b['check_in']?.toString());
  add('check_out', b['check_out']?.toString());
  final nights = asInt(b['nights'] ?? b['nights_count'], 0);
  if (nights > 0)
    rows.add((AppStrings.t(isArabic, 'nights'), nights.toString()));
  final guests = asInt(b['guests'] ?? b['guests_count'], 0);
  if (guests > 0) {
    rows.add((AppStrings.t(isArabic, 'guests'), guests.toString()));
  }
  final total = asDouble(b['total']);
  if (total > 0) {
    rows.add((
      AppStrings.t(isArabic, 'total_amount'),
      '${total.toStringAsFixed(0)} ${AppStrings.t(isArabic, 'sar')}'
    ));
  }
  return rows;
}

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HotelService _hotelService = HotelService();

  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  String? _error;
  int? _busyId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    if (!ref.read(sessionProvider).isLoggedIn) {
      setState(() {
        _isLoading = false;
        _bookings = [];
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final bookings = await _hotelService.myBookings();
      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _upcoming => _bookings
      .where(
          (b) => ['pending', 'confirmed', 'checked_in'].contains(b['status']))
      .toList();
  List<Map<String, dynamic>> get _past =>
      _bookings.where((b) => b['status'] == 'completed').toList();
  List<Map<String, dynamic>> get _cancelled =>
      _bookings.where((b) => b['status'] == 'cancelled').toList();

  String _statusLabel(String status, bool isArabic) {
    const labels = {
      'pending': {'ar': 'قيد الانتظار', 'en': 'Pending'},
      'confirmed': {'ar': 'مؤكد', 'en': 'Confirmed'},
      'checked_in': {'ar': 'تسجيل وصول', 'en': 'Checked-in'},
      'completed': {'ar': 'مكتمل', 'en': 'Completed'},
      'cancelled': {'ar': 'ملغي', 'en': 'Cancelled'},
    };
    return labels[status]?[isArabic ? 'ar' : 'en'] ?? status;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.danger;
      default:
        return AppColors.goldDark;
    }
  }

  /// المتطلب 97: نافذة تفاصيل الحجز الكاملة للوكيل/الضيف — تُعرض الصفوف التي
  /// يرجعها الـ API فعلًا فقط (buildBookingDetailRows تتكفّل بالفلترة).
  void _showBookingDetails(bool isArabic, Map<String, dynamic> b) {
    final rows = buildBookingDetailRows(isArabic, b);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppDimens.pagePadding,
          right: AppDimens.pagePadding,
          top: AppDimens.pagePadding,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppDimens.pagePadding,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.t(isArabic, 'booking_details'),
                  style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: AppDimens.md),
              if (rows.isEmpty)
                Text(AppStrings.t(isArabic, 'no_data'),
                    style: Theme.of(ctx)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textMuted))
              else
                for (final row in rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppDimens.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text(row.$1,
                              style: Theme.of(ctx)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textMuted)),
                        ),
                        Expanded(
                          child: Text(row.$2,
                              style: Theme.of(ctx)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
              const SizedBox(height: AppDimens.md),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final isLoggedIn = ref.watch(sessionProvider).isLoggedIn;

    // استعادة الجلسة غير متزامنة وتنتهي غالبًا بعد `initState`، لذا لا يكفي
    // تحميل الحجوزات مرة واحدة هناك: عند اكتمال تسجيل الدخول نُعيد التحميل.
    ref.listen<bool>(sessionProvider.select((s) => s.isLoggedIn),
        (previous, next) {
      if (next && previous != true) _loadBookings();
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.t(isArabic, 'my_bookings')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: AppStrings.t(isArabic, 'upcoming')),
            Tab(text: AppStrings.t(isArabic, 'past')),
            Tab(text: AppStrings.t(isArabic, 'cancelled')),
          ],
        ),
      ),
      body: SafeArea(
        child: !isLoggedIn
            ? _EmptyState(
                icon: Icons.lock_outline_rounded,
                message: isArabic
                    ? 'سجّل الدخول لعرض حجوزاتك'
                    : 'Log in to view your bookings',
                actionLabel: AppStrings.t(isArabic, 'login'),
                onAction: () => Navigator.of(context)
                    .push(
                        MaterialPageRoute(builder: (_) => const LoginScreen()))
                    .then((_) => _loadBookings()),
              )
            : _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: AppColors.gold))
                : _error != null
                    ? _EmptyState(
                        icon: Icons.error_outline_rounded,
                        message: _error!,
                        actionLabel: isArabic ? 'إعادة المحاولة' : 'Retry',
                        onAction: _loadBookings,
                      )
                    : RefreshIndicator(
                        onRefresh: _loadBookings,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildList(_upcoming, isArabic),
                            _buildList(_past, isArabic),
                            _buildList(_cancelled, isArabic),
                          ],
                        ),
                      ),
      ),
    );
  }

  Future<void> _cancelBooking(bool isArabic, int bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.t(isArabic, 'confirm_cancel_booking')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppStrings.t(isArabic, 'cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStrings.t(isArabic, 'confirm'),
                style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busyId = bookingId);
    try {
      await _hotelService.cancelMyBooking(bookingId);
      await _loadBookings();
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _editBooking(bool isArabic, Map<String, dynamic> b) async {
    final isAgentBooking = (b['agent_id'] != null);
    final nameCtrl =
        TextEditingController(text: (b['guest_name'] ?? '').toString());
    final phoneCtrl =
        TextEditingController(text: (b['guest_phone'] ?? '').toString());
    final notesCtrl =
        TextEditingController(text: (b['notes'] ?? '').toString());
    // المتطلب 42: الوكيل يعدّل بيانات عميله (الاسم/الهاتف/عدد الأشخاص/ملاحظة).
    int guests = asInt(b['guests'], 1);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: AppDimens.pagePadding,
            right: AppDimens.pagePadding,
            top: AppDimens.pagePadding,
            bottom:
                MediaQuery.of(ctx).viewInsets.bottom + AppDimens.pagePadding,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.t(isArabic, 'edit_booking'),
                    style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: AppDimens.md),
                if (isAgentBooking) ...[
                  TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                          labelText: AppStrings.t(isArabic, 'customer_name'))),
                  const SizedBox(height: AppDimens.md),
                  TextField(
                      controller: phoneCtrl,
                      decoration: InputDecoration(
                          labelText: AppStrings.t(isArabic, 'customer_phone'))),
                  const SizedBox(height: AppDimens.md),
                ],
                Row(
                  children: [
                    Expanded(
                        child: Text(AppStrings.t(isArabic, 'guests'),
                            style: Theme.of(ctx).textTheme.bodyMedium)),
                    IconButton(
                      onPressed: guests > 1
                          ? () => setSheetState(() => guests--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$guests', style: Theme.of(ctx).textTheme.titleMedium),
                    IconButton(
                      onPressed: () => setSheetState(() => guests++),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.sm),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                      labelText: AppStrings.t(isArabic, 'notes')),
                ),
                const SizedBox(height: AppDimens.md),
                Text(
                  isArabic
                      ? 'لتعديل التواريخ تواصل مع الفندق مباشرة، أو أرسل ملاحظة هنا.'
                      : 'To change dates, contact the hotel directly, or add a note here.',
                  style: Theme.of(ctx)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textMuted),
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
      await _hotelService.editMyBooking(
        bookingId: asInt(b['id']),
        guestName:
            nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : null,
        guestPhone:
            phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
        guests: guests,
        notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.t(isArabic, 'booking_updated'))));
      }
      await _loadBookings();
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  /// رقم/اسم الوحدة للحجز (المتطلب 52). يُرجع null إن لم يُرجع الـ API أي منهما.
  String? _unitNumberLabel(bool isArabic, Map<String, dynamic> b) {
    final number = (b['unit_number'] ?? '').toString().trim();
    if (number.isNotEmpty)
      return '${AppStrings.t(isArabic, 'unit_no')} $number';
    final name =
        (isArabic ? b['unit_name_ar'] : b['unit_name_en']) ?? b['unit_name'];
    final text = (name ?? '').toString().trim();
    return text.isEmpty ? null : text;
  }

  Widget _buildList(List<Map<String, dynamic>> items, bool isArabic) {
    if (items.isEmpty) {
      return ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 56, color: AppColors.textMuted),
                  const SizedBox(height: AppDimens.md),
                  Text(AppStrings.t(isArabic, 'no_bookings_yet'),
                      style: const TextStyle(color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimens.pagePadding),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final b = items[index];
        final status = b['status']?.toString() ?? 'pending';
        final canCancel = b['can_cancel'] == true;
        final canEdit = b['can_edit'] == true;
        final busy = _busyId == b['id'];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimens.md),
          child: Container(
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
                    Container(
                      width: 56,
                      height: 56,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: b['cover_image']?.toString() ?? '',
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Icon(
                            Icons.image_outlined,
                            color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(width: AppDimens.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b['hotel_name']?.toString() ?? '',
                              style: Theme.of(context).textTheme.titleSmall),
                          Text(
                              isArabic
                                  ? (b['city_ar']?.toString() ?? '')
                                  : (b['city_en']?.toString() ?? ''),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textMuted)),
                          // المتطلب 52: رقم الوحدة ثم عدد الأشخاص أسفله (من حقول
                          // الحجز الحقيقية؛ يُخفى السطر إن لم يرجع الـ API الحقل).
                          if (_unitNumberLabel(isArabic, b) != null)
                            Text(_unitNumberLabel(isArabic, b)!,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: AppColors.textMuted)),
                          if (asInt(b['guests'], 0) > 0)
                            Text(
                                '${AppStrings.t(isArabic, 'guests')}: ${asInt(b['guests'], 0)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: AppColors.textMuted)),
                          Text('${b['check_in']} → ${b['check_out']}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusFull),
                      ),
                      child: Text(_statusLabel(status, isArabic),
                          style: TextStyle(
                              color: _statusColor(status),
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                // المتطلب 97: زر عرض تفاصيل الحجز — متاح دائمًا لأن البيانات
                // موجودة أصلًا في البطاقة ولا يحتاج صلاحية من السيرفر.
                const SizedBox(height: AppDimens.sm),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => _showBookingDetails(isArabic, b),
                    icon: const Icon(Icons.receipt_long_outlined, size: 18),
                    label: Text(AppStrings.t(isArabic, 'view_details')),
                  ),
                ),
                if (canCancel || canEdit) ...[
                  const SizedBox(height: AppDimens.sm),
                  Row(
                    children: [
                      if (canEdit)
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                busy ? null : () => _editBooking(isArabic, b),
                            child: Text(AppStrings.t(isArabic, 'edit_booking')),
                          ),
                        ),
                      if (canEdit && canCancel)
                        const SizedBox(width: AppDimens.sm),
                      if (canCancel)
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.danger,
                                side:
                                    const BorderSide(color: AppColors.danger)),
                            onPressed: busy
                                ? null
                                : () =>
                                    _cancelBooking(isArabic, asInt(b['id'])),
                            child:
                                Text(AppStrings.t(isArabic, 'cancel_booking')),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState(
      {required this.icon,
      required this.message,
      this.actionLabel,
      this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: AppColors.textMuted),
          const SizedBox(height: AppDimens.md),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppDimens.pagePadding),
            child: Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted)),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppDimens.md),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
