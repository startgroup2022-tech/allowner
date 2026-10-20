import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../services/hotel_staff_service.dart';
import '../../services/api_client.dart';
import '../../utils/safe_parse.dart';

/// المتطلب 81: ترشيح حجوزات الفندق برقم الوحدة أو اسمها (عربي/إنجليزي).
/// دالة نقية كي تكون قابلة للاختبار المستقل.
List<Map<String, dynamic>> filterBookingsByUnit(
    List<Map<String, dynamic>> bookings, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return bookings;
  return bookings.where((b) {
    final unitNo = (b['unit_number'] ?? '').toString().toLowerCase();
    final unitAr = (b['unit_name_ar'] ?? '').toString().toLowerCase();
    final unitEn = (b['unit_name_en'] ?? '').toString().toLowerCase();
    return unitNo.contains(q) || unitAr.contains(q) || unitEn.contains(q);
  }).toList();
}

class HotelBookingsScreen extends ConsumerStatefulWidget {
  const HotelBookingsScreen({super.key});

  @override
  ConsumerState<HotelBookingsScreen> createState() => _HotelBookingsScreenState();
}

class _HotelBookingsScreenState extends ConsumerState<HotelBookingsScreen> with SingleTickerProviderStateMixin {
  final _service = HotelStaffService();
  late TabController _tab;
  late Future<List<Map<String, dynamic>>> _future;
  String _scope = 'active';
  int? _busyId;

  /// المتطلب 81: بحث موظف الفندق برقم الوحدة لتسريع تأكيد check-in / check-out.
  final _unitQueryController = TextEditingController();
  String _unitQuery = '';

  @override
  void initState() {
    super.initState();
    _unitQueryController.addListener(() {
      final v = _unitQueryController.text.trim();
      if (v != _unitQuery) setState(() => _unitQuery = v);
    });
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      if (_tab.indexIsChanging) return;
      setState(() {
        _scope = _tab.index == 0 ? 'active' : 'history';
        _future = _service.getBookings(scope: _scope);
      });
    });
    _future = _service.getBookings(scope: _scope);
  }

  @override
  void dispose() {
    _tab.dispose();
    _unitQueryController.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _future = _service.getBookings(scope: _scope));

  Future<void> _checkIn(bool isArabic, int id) async {
    setState(() => _busyId = id);
    try {
      await _service.checkIn(id);
      _reload();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _checkOut(bool isArabic, int id) async {
    setState(() => _busyId = id);
    try {
      await _service.checkOut(id);
      _reload();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busyId = null);
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
        bottom: TabBar(
          controller: _tab,
          tabs: [
            Tab(text: AppStrings.t(isArabic, 'active_now')),
            Tab(text: AppStrings.t(isArabic, 'history')),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppDimens.pagePadding, AppDimens.md, AppDimens.pagePadding, 0),
              child: TextField(
                controller: _unitQueryController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: AppStrings.t(isArabic, 'search_unit_number'),
                  suffixIcon: _unitQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => _unitQueryController.clear(),
                        ),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _reload(),
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _future,
                  builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppDimens.xl),
                  children: [Center(child: Text(AppStrings.t(isArabic, 'error_loading')))],
                );
              }
              final rows = filterBookingsByUnit(snapshot.data ?? const [], _unitQuery);
              if (rows.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppDimens.xl),
                      child: Center(
                        child: Text(
                          AppStrings.t(isArabic, _unitQuery.isEmpty ? 'no_bookings' : 'no_matching_bookings'),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(AppDimens.pagePadding),
                itemCount: rows.length,
                separatorBuilder: (context, index) => const SizedBox(height: AppDimens.md),
                itemBuilder: (context, index) {
                  final b = rows[index];
                  final unitName = isArabic ? b['unit_name_ar'] : b['unit_name_en'];
                  final busy = _busyId == b['id'];
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
                        Text('${b['guest_name'] ?? ''}', style: textTheme.titleSmall),
                        Text(
                            '${b['hotel_name'] ?? ''}${unitName != null ? ' — $unitName' : ''}${(b['unit_number'] ?? '').toString().isNotEmpty ? ' · ${AppStrings.t(isArabic, 'unit_no')} ${b['unit_number']}' : ''}',
                            style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                        Text('${b['check_in']} → ${b['check_out']} · ${AppStrings.t(isArabic, 'status_${b['status']}')}',
                            style: textTheme.bodySmall),
                        if (b['can_check_in'] == true || b['can_check_out'] == true) ...[
                          const SizedBox(height: AppDimens.sm),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: b['can_check_in'] == true ? AppColors.success : AppColors.secondary,
                              ),
                              onPressed: busy
                                  ? null
                                  : () => b['can_check_in'] == true
                                      ? _checkIn(isArabic, asInt(b['id']))
                                      : _checkOut(isArabic, asInt(b['id'])),
                              child: Text(AppStrings.t(isArabic, b['can_check_in'] == true ? 'confirm_check_in' : 'confirm_check_out')),
                            ),
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
          ],
        ),
      ),
    );
  }
}
