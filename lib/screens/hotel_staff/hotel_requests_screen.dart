import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/maintenance_settlement.dart';
import '../../utils/request_settlement.dart';
import '../../utils/locale_provider.dart';
import '../../utils/session_provider.dart';
import '../../services/hotel_staff_service.dart';
import '../../services/api_client.dart';
import '../../utils/safe_parse.dart';

class HotelRequestsScreen extends ConsumerStatefulWidget {
  const HotelRequestsScreen({super.key});

  @override
  ConsumerState<HotelRequestsScreen> createState() =>
      _HotelRequestsScreenState();
}

class _HotelRequestsScreenState extends ConsumerState<HotelRequestsScreen>
    with SingleTickerProviderStateMixin {
  final _service = HotelStaffService();
  late TabController _tab;
  final _types = const ['cleaning', 'maintenance', 'meal', 'extra_bed'];
  late Future<List<Map<String, dynamic>>> _future;
  int? _busyId;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _types.length, vsync: this);
    _tab.addListener(() {
      if (_tab.indexIsChanging) return;
      setState(() {
        _future = _service.getRequests(type: _types[_tab.index]);
      });
    });
    _future = _service.getRequests(type: _types[0]);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _reload() => setState(() {
        _future = _service.getRequests(type: _types[_tab.index]);
      });

  Future<void> _act(bool isArabic, Map<String, dynamic> r, String action,
      String? role) async {
    final needsNote = action == 'reject';
    final noteCtrl = TextEditingController();
    final priceCtrl = TextEditingController(
        text: r['price'] != null ? r['price'].toString() : '');
    // المتطلب 92: صورة اختيارية تُرفق بطلب الصيانة من إدارة الفندق.
    final canAttachImage = (r['type'] ?? '') == 'maintenance';
    File? imageFile;

    // المتطلبات 390–394: عند تأكيد طلب صيانة يختار المستخدم طريقة التسوية.
    final isMaintenanceConfirm = canAttachImage && action == 'confirm';
    MaintenanceSettlement settlement = MaintenanceSettlement.unitBalance;

    // المتطلبات 10–12 من المستند 06: تأكيد طلب النظافة أو الوجبات أو السرير
    // الإضافي يتطلب اختيار طريقة سداد (خصم من الرصيد أو رابط دفع عبر واتساب)
    // بعد ظهور السعر المعتمد. القواعد مشتركة في `request_settlement.dart`.
    final settlementKind = action == 'confirm'
        ? settlementKindForRequestType(r['type']?.toString())
        : null;
    final isServiceConfirm = settlementKind != null;
    final canSettle =
        canConfirmRequestSettlement(ref.read(sessionProvider).user?.role);
    final approvedPrice = approvedRequestPrice(r);
    final mealLabels = settlementKind == SettlementRequestKind.meal
        ? requestMealLabels(r)
        : const <String>[];
    final bedCount = settlementKind == SettlementRequestKind.extraBed
        ? extraBedCount(r)
        : null;
    final bedNights = settlementKind == SettlementRequestKind.extraBed
        ? extraBedNights(r)
        : null;
    final bedTotal = settlementKind == SettlementRequestKind.extraBed
        ? extraBedTotal(r, approvedPrice)
        : null;
    final recordedBefore = isRequestSettlementRecorded(r);
    RequestSettlement? settlementChoice;
    String? dialogError;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(AppStrings.t(
              isArabic,
              action == 'confirm'
                  ? 'confirm_request'
                  : action == 'done'
                      ? 'mark_done'
                      : 'reject_request')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (action != 'reject')
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: AppStrings.t(isArabic, 'price_optional')),
                  ),
                const SizedBox(height: AppDimens.sm),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                      labelText: AppStrings.t(isArabic,
                          needsNote ? 'reject_reason' : 'note_optional')),
                ),
                if (isServiceConfirm) ...[
                  const SizedBox(height: AppDimens.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppStrings.t(isArabic, settlementKind.priceLabelKey),
                          style: Theme.of(ctx).textTheme.titleSmall,
                        ),
                      ),
                      Text(
                        approvedPrice == null
                            ? '—'
                            : '${approvedPrice.toStringAsFixed(0)} ${AppStrings.t(isArabic, 'sar')}',
                        style: Theme.of(ctx)
                            .textTheme
                            .titleSmall
                            ?.copyWith(color: AppColors.goldDark),
                      ),
                    ],
                  ),
                  // المتطلب 11: أنواع الوجبات كما وردت في الطلب.
                  if (settlementKind == SettlementRequestKind.meal &&
                      mealLabels.isNotEmpty) ...[
                    const SizedBox(height: AppDimens.sm),
                    _DetailLine(
                      label: AppStrings.t(isArabic, 'meal_types_label'),
                      value: mealLabels.map((label) {
                        final key = mealLabelKey(label);
                        return key == null
                            ? label
                            : AppStrings.t(isArabic, key);
                      }).join(' • '),
                    ),
                  ],
                  // المتطلب 12: عدد الأسرّة والليالي والإجمالي.
                  if (settlementKind == SettlementRequestKind.extraBed) ...[
                    const SizedBox(height: AppDimens.sm),
                    _DetailLine(
                      label: AppStrings.t(isArabic, 'extra_bed_count'),
                      value: bedCount?.toString() ?? '—',
                    ),
                    _DetailLine(
                      label: AppStrings.t(isArabic, 'extra_bed_nights'),
                      value: bedNights?.toString() ?? '—',
                    ),
                    _DetailLine(
                      label: AppStrings.t(isArabic, 'extra_bed_total'),
                      value: bedTotal == null
                          ? '—'
                          : '${bedTotal.toStringAsFixed(0)} ${AppStrings.t(isArabic, 'sar')}',
                    ),
                  ],
                  const SizedBox(height: AppDimens.sm),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      AppStrings.t(isArabic, 'service_settlement'),
                      style: Theme.of(ctx).textTheme.titleSmall,
                    ),
                  ),
                  RadioGroup<RequestSettlement>(
                    groupValue: settlementChoice,
                    onChanged: (v) => setDialogState(() {
                      // الطلب المسوّى لا يقبل تغيير الوسيلة ولا إعادة الإرسال.
                      if (!recordedBefore) settlementChoice = v;
                    }),
                    child: Column(
                      children: [
                        for (final option in RequestSettlement.values)
                          RadioListTile<RequestSettlement>(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            value: option,
                            title: Text(AppStrings.t(
                                isArabic, requestSettlementLabelKey(option))),
                          ),
                      ],
                    ),
                  ),
                ],
                if (isMaintenanceConfirm) ...[
                  const SizedBox(height: AppDimens.sm),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      AppStrings.t(isArabic, 'maintenance_settlement'),
                      style: Theme.of(ctx).textTheme.titleSmall,
                    ),
                  ),
                  RadioGroup<MaintenanceSettlement>(
                    groupValue: settlement,
                    onChanged: (v) => setDialogState(() {
                      if (v != null) settlement = v;
                    }),
                    child: Column(
                      children: [
                        RadioListTile<MaintenanceSettlement>(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          value: MaintenanceSettlement.unitBalance,
                          title: Text(
                              AppStrings.t(isArabic, 'settle_unit_balance')),
                        ),
                        RadioListTile<MaintenanceSettlement>(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          value: MaintenanceSettlement.whatsappLink,
                          title: Text(
                              AppStrings.t(isArabic, 'settle_whatsapp_link')),
                        ),
                      ],
                    ),
                  ),
                ],
                if (canAttachImage) ...[
                  const SizedBox(height: AppDimens.sm),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await ImagePicker().pickImage(
                          source: ImageSource.gallery, imageQuality: 85);
                      if (picked != null) {
                        setDialogState(() => imageFile = File(picked.path));
                      }
                    },
                    icon: const Icon(Icons.add_photo_alternate_outlined,
                        size: 18),
                    label: Text(imageFile == null
                        ? AppStrings.t(isArabic, 'attach_image')
                        : AppStrings.t(isArabic, 'image_attached')),
                  ),
                  if (imageFile != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppDimens.sm),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                        child: Image.file(imageFile!,
                            height: 100, fit: BoxFit.cover),
                      ),
                    ),
                ],
                if (dialogError != null) ...[
                  const SizedBox(height: AppDimens.sm),
                  Text(
                    AppStrings.t(isArabic, dialogError!),
                    style:
                        const TextStyle(color: AppColors.danger, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppStrings.t(isArabic, 'cancel'))),
            TextButton(
              onPressed: () {
                if (needsNote && noteCtrl.text.trim().isEmpty) return;
                if (isServiceConfirm) {
                  final typedPrice =
                      double.tryParse(priceCtrl.text.trim()) ?? approvedPrice;
                  final error = validateRequestSettlement(
                    request: r,
                    choice: settlementChoice,
                    price: typedPrice,
                    canConfirm: canSettle,
                    kind: settlementKind,
                  );
                  if (error != null) {
                    setDialogState(() => dialogError = error);
                    return;
                  }
                }
                Navigator.pop(ctx, true);
              },
              child: Text(AppStrings.t(isArabic, 'confirm')),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    final parsedPrice = priceCtrl.text.trim().isNotEmpty
        ? double.tryParse(priceCtrl.text.trim())
        : null;

    // فحص نهائي قبل الإرسال: يمنع الخصم المزدوج وطلب الدفع المكرر، ويوقف أي
    // محاولة تجاوز للصلاحيات من واجهة الفندق.
    if (isServiceConfirm) {
      final error = validateRequestSettlement(
        request: r,
        choice: settlementChoice,
        price: parsedPrice ?? approvedPrice,
        canConfirm: canSettle,
        kind: settlementKind,
      );
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.t(isArabic, error))));
        return;
      }
    }

    setState(() => _busyId = asInt(r['id']));
    try {
      final response = await _service.actOnRequest(
        type: asString(r['type']),
        id: asInt(r['id']),
        action: action,
        note: noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : null,
        price: parsedPrice,
        imagePath: imageFile?.path,
        settlement: isMaintenanceConfirm
            ? settlementPayload(settlement)
            : isServiceConfirm
                ? requestSettlementPayload(settlementChoice!)
                : null,
      );
      if (!mounted) return;
      // عند اختيار رابط واتساب نفتح المحادثة فعلًا برسالة تحمل رقم الطلب
      // والوحدة والمبلغ. لا رقم مزيف ولا رسالة فارغة (المتطلبات 391–394).
      if (isMaintenanceConfirm &&
          settlement == MaintenanceSettlement.whatsappLink) {
        final unitName =
            (isArabic ? r['unit_name_ar'] : r['unit_name_en'])?.toString();
        final uri = buildWhatsAppPaymentUri(
          phone: (r['requester_phone'] ?? r['owner_phone'] ?? r['guest_phone'])
              ?.toString(),
          isArabic: isArabic,
          requestId: asInt(r['id']),
          unitName: unitName,
          amount: parsedPrice,
        );
        if (uri == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppStrings.t(isArabic, 'whatsapp_no_number'))),
          );
        } else {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!mounted) return;
        }
      }
      // المتطلبات 10–12 من المستند 06: رابط الدفع يُقرأ من استجابة السيرفر فقط،
      // وتُفتح رسالة واتساب بالمبلغ وبيانات الطلب الحقيقية.
      if (isServiceConfirm &&
          settlementChoice == RequestSettlement.whatsappLink) {
        final paymentLink = extractServerPaymentLink(response);
        if (paymentLink == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(AppStrings.t(isArabic, 'payment_link_not_available'))),
          );
        }
        final unitName =
            (isArabic ? r['unit_name_ar'] : r['unit_name_en'])?.toString();
        final details = <String>[
          if (settlementKind == SettlementRequestKind.meal &&
              mealLabels.isNotEmpty)
            '${AppStrings.t(isArabic, 'meal_types_label')}: ${mealLabels.map((label) {
              final key = mealLabelKey(label);
              return key == null ? label : AppStrings.t(isArabic, key);
            }).join(', ')}',
          if (settlementKind == SettlementRequestKind.extraBed) ...[
            if (bedCount != null)
              '${AppStrings.t(isArabic, 'extra_bed_count')}: $bedCount',
            if (bedNights != null)
              '${AppStrings.t(isArabic, 'extra_bed_nights')}: $bedNights',
            if (bedTotal != null)
              '${AppStrings.t(isArabic, 'extra_bed_total')}: ${bedTotal.toStringAsFixed(0)} SAR',
          ],
        ];
        final uri = buildSettlementWhatsAppUri(
          phone: (r['requester_phone'] ?? r['owner_phone'] ?? r['guest_phone'])
              ?.toString(),
          isArabic: isArabic,
          kind: settlementKind,
          requestId: asInt(r['id']),
          unitName: unitName,
          amount: parsedPrice ?? approvedPrice,
          paymentLink: paymentLink,
          details: details,
        );
        if (uri == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppStrings.t(isArabic, 'whatsapp_no_number'))),
          );
        } else {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
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

  Color _statusColor(String status) {
    switch (status) {
      case 'done':
        return AppColors.success;
      case 'confirmed':
        return AppColors.secondary;
      case 'rejected':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  String _typeLabel(bool isArabic, String type) =>
      AppStrings.t(isArabic, 'req_type_$type');

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    // دور المستخدم يُقرأ أثناء البناء: يحدد صلاحية تأكيد الطلبات وتسويتها.
    final role = ref.watch(sessionProvider).user?.role;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(AppStrings.t(isArabic, 'hotel_requests')),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabs: _types.map((t) => Tab(text: _typeLabel(isArabic, t))).toList(),
        ),
      ),
      body: SafeArea(
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
                    Center(child: Text(AppStrings.t(isArabic, 'error_loading')))
                  ],
                );
              }
              final rows = snapshot.data ?? [];
              if (rows.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Padding(
                        padding: const EdgeInsets.all(AppDimens.xl),
                        child: Center(
                            child: Text(
                                AppStrings.t(isArabic, 'no_open_requests'))))
                  ],
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(AppDimens.pagePadding),
                itemCount: rows.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppDimens.md),
                itemBuilder: (context, index) {
                  final r = rows[index];
                  final status = r['status']?.toString() ?? 'pending';
                  final unitName =
                      isArabic ? r['unit_name_ar'] : r['unit_name_en'];
                  final busy = _busyId == r['id'];
                  // المتطلبات 10–12 من المستند 06: السعر المعتمد ظاهر لموظف
                  // الفندق، والتأكيد معطّل إن سبق تسجيل سداد الطلب (منع التكرار).
                  final requestKind =
                      settlementKindForRequestType(r['type']?.toString());
                  final approvedPrice = approvedRequestPrice(r);
                  final settled =
                      requestKind != null && isRequestSettlementRecorded(r);
                  final cardMealLabels =
                      requestKind == SettlementRequestKind.meal
                          ? requestMealLabels(r)
                          : const <String>[];
                  final cardBeds = requestKind == SettlementRequestKind.extraBed
                      ? extraBedCount(r)
                      : null;
                  final cardNights =
                      requestKind == SettlementRequestKind.extraBed
                          ? extraBedNights(r)
                          : null;
                  final cardTotal =
                      requestKind == SettlementRequestKind.extraBed
                          ? extraBedTotal(r, approvedPrice)
                          : null;
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
                            Expanded(
                              child: Text(
                                  '${r['hotel_name'] ?? ''}${unitName != null ? ' — $unitName' : ''}',
                                  style: textTheme.titleSmall),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusColor(status).withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(AppDimens.radiusSm),
                              ),
                              child: Text(
                                  AppStrings.t(isArabic, 'status_$status'),
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _statusColor(status))),
                            ),
                          ],
                        ),
                        if ((r['requester_name'] ?? '').toString().isNotEmpty)
                          Text(r['requester_name'].toString(),
                              style: textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textMuted)),
                        if ((r['description'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(r['description'].toString(),
                              style: textTheme.bodyMedium),
                        ],
                        if (r['price'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                              '${AppStrings.t(isArabic, 'price')}: ${r['price']} ${AppStrings.t(isArabic, 'sar')}',
                              style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.goldDark,
                                  fontWeight: FontWeight.w600)),
                        ],
                        if (requestKind != null && approvedPrice != null) ...[
                          const SizedBox(height: 4),
                          Text(
                              '${AppStrings.t(isArabic, requestKind.priceLabelKey)}: ${approvedPrice.toStringAsFixed(0)} ${AppStrings.t(isArabic, 'sar')}',
                              style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.goldDark,
                                  fontWeight: FontWeight.w600)),
                        ],
                        if (cardMealLabels.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                              '${AppStrings.t(isArabic, 'meal_types_label')}: ${cardMealLabels.map((label) {
                                final key = mealLabelKey(label);
                                return key == null
                                    ? label
                                    : AppStrings.t(isArabic, key);
                              }).join(' • ')}',
                              style: textTheme.bodySmall),
                        ],
                        if (requestKind == SettlementRequestKind.extraBed) ...[
                          const SizedBox(height: 4),
                          Text(
                              '${AppStrings.t(isArabic, 'extra_bed_count')}: ${cardBeds ?? '—'} · '
                              '${AppStrings.t(isArabic, 'extra_bed_nights')}: ${cardNights ?? '—'} · '
                              '${AppStrings.t(isArabic, 'extra_bed_total')}: ${cardTotal == null ? '—' : '${cardTotal.toStringAsFixed(0)} ${AppStrings.t(isArabic, 'sar')}'}',
                              style: textTheme.bodySmall),
                        ],
                        if (settled) ...[
                          const SizedBox(height: 4),
                          Text(
                              AppStrings.t(
                                  isArabic, 'settlement_already_recorded'),
                              style: textTheme.bodySmall
                                  ?.copyWith(color: AppColors.success)),
                        ],
                        if (status == 'pending' || status == 'confirmed') ...[
                          const SizedBox(height: AppDimens.sm),
                          Row(
                            children: [
                              if (status == 'pending')
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.secondary),
                                    onPressed: busy || settled
                                        ? null
                                        : () =>
                                            _act(isArabic, r, 'confirm', role),
                                    child: Text(AppStrings.t(
                                        isArabic, 'confirm_request')),
                                  ),
                                ),
                              if (status == 'pending')
                                const SizedBox(width: AppDimens.sm),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success),
                                  onPressed: busy
                                      ? null
                                      : () => _act(isArabic, r, 'done', role),
                                  child:
                                      Text(AppStrings.t(isArabic, 'mark_done')),
                                ),
                              ),
                              if (status == 'pending') ...[
                                const SizedBox(width: AppDimens.sm),
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.danger,
                                        side: const BorderSide(
                                            color: AppColors.danger)),
                                    onPressed: busy
                                        ? null
                                        : () =>
                                            _act(isArabic, r, 'reject', role),
                                    child: Text(AppStrings.t(
                                        isArabic, 'reject_request')),
                                  ),
                                ),
                              ],
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

/// سطر تفصيلي داخل نافذة تأكيد الطلب (نوع الوجبة، عدد الأسرّة، الليالي).
class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textMuted)),
          ),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
