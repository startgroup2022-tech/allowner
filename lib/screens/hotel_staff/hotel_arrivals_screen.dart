import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_client.dart';
import '../../services/hotel_staff_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/arrivals.dart';
import '../../utils/locale_provider.dart';
import '../../utils/safe_parse.dart';
import '../../utils/unit_search.dart';

/// وصولات اليوم داخل لوحة إدارة الفندق، مع بيانات الضيف وبحث برقم الوحدة
/// (المتطلبان 80 و81، والمستند 06 §F).
///
/// المصدر `/hotel/bookings.php?scope=active` نفسه، وهو مقيّد على السيرفر بفندق
/// الموظّف، فلا تظهر وصولات فندق غير مصرّح به. تأكيد الدخول يستخدم `check_in`
/// القائم دون أي تغيير في آلية التسجيل.
class HotelArrivalsScreen extends ConsumerStatefulWidget {
  const HotelArrivalsScreen({super.key});

  @override
  ConsumerState<HotelArrivalsScreen> createState() =>
      _HotelArrivalsScreenState();
}

class _HotelArrivalsScreenState extends ConsumerState<HotelArrivalsScreen> {
  final _service = HotelStaffService();
  late Future<List<Map<String, dynamic>>> _future;
  final _searchController = TextEditingController();
  String _query = '';
  int? _busyId;

  @override
  void initState() {
    super.initState();
    _future = _service.getBookings(scope: 'active');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() => setState(() {
        _future = _service.getBookings(scope: 'active');
      });

  Future<void> _checkIn(int bookingId) async {
    setState(() => _busyId = bookingId);
    try {
      await _service.checkIn(bookingId);
      _reload();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
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
        title: Text(AppStrings.t(isArabic, 'arrivals_today_title')),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppDimens.pagePadding,
                  AppDimens.md, AppDimens.pagePadding, 0),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: AppStrings.t(isArabic, 'search_unit_number_hint'),
                  suffixIcon: _query.trim().isEmpty
                      ? null
                      : IconButton(
                          tooltip: AppStrings.t(isArabic, 'clear_search'),
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
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
                        children: [
                          Center(
                            child:
                                Text(AppStrings.t(isArabic, 'error_loading')),
                          ),
                          const SizedBox(height: AppDimens.sm),
                          Center(
                            child: OutlinedButton(
                              onPressed: _reload,
                              child: Text(AppStrings.t(isArabic, 'retry')),
                            ),
                          ),
                        ],
                      );
                    }

                    final rows = filterArrivalsByUnit(
                      bookings: snapshot.data ?? const [],
                      query: _query,
                    );
                    if (rows.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(AppDimens.xl),
                            child: Center(
                              child:
                                  Text(AppStrings.t(isArabic, 'no_arrivals')),
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(AppDimens.pagePadding),
                      itemCount: rows.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppDimens.md),
                      itemBuilder: (context, index) {
                        final b = rows[index];
                        final id = asInt(b['id']);
                        final busy = _busyId == id;
                        final unitNumber = departureUnitNumber(b);
                        final unitName =
                            isArabic ? b['unit_name_ar'] : b['unit_name_en'];
                        final guests = asInt(b['guests'], 0);
                        return Container(
                          padding: const EdgeInsets.all(AppDimens.md),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusLg),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text('${b['guest_name'] ?? ''}',
                                        style: textTheme.titleSmall),
                                  ),
                                  if (unitNumber.isNotEmpty)
                                    Text(
                                      '${AppStrings.t(isArabic, 'room_or_unit_number')}: $unitNumber',
                                      style: textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w700),
                                    ),
                                ],
                              ),
                              if ((b['hotel_name'] ?? '').toString().isNotEmpty)
                                Text('${b['hotel_name']}',
                                    style: textTheme.bodySmall
                                        ?.copyWith(color: AppColors.textMuted)),
                              if (unitName != null &&
                                  unitName.toString().isNotEmpty)
                                Text('$unitName',
                                    style: textTheme.bodySmall
                                        ?.copyWith(color: AppColors.textMuted)),
                              Text(
                                '${AppStrings.t(isArabic, 'check_in')}: ${b['check_in'] ?? '-'}  ·  '
                                '${AppStrings.t(isArabic, 'check_out')}: ${b['check_out'] ?? '-'}',
                                style: textTheme.bodySmall,
                              ),
                              if (guests > 0)
                                Text(
                                  '${AppStrings.t(isArabic, 'guests')}: $guests',
                                  style: textTheme.bodySmall
                                      ?.copyWith(color: AppColors.textMuted),
                                ),
                              if ((b['guest_phone'] ?? '')
                                  .toString()
                                  .trim()
                                  .isNotEmpty)
                                Text(
                                  '${AppStrings.t(isArabic, 'phone')}: ${b['guest_phone']}',
                                  style: textTheme.bodySmall
                                      ?.copyWith(color: AppColors.textMuted),
                                ),
                              const SizedBox(height: AppDimens.sm),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success),
                                  onPressed: busy ? null : () => _checkIn(id),
                                  child: Text(AppStrings.t(
                                      isArabic, 'confirm_check_in')),
                                ),
                              ),
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
