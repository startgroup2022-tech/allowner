import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/maintenance_settlement.dart';
import '../../utils/locale_provider.dart';
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
      setState(() => _future = _service.getRequests(type: _types[_tab.index]));
    });
    _future = _service.getRequests(type: _types[0]);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _reload() =>
      setState(() => _future = _service.getRequests(type: _types[_tab.index]));

  Future<void> _act(
      bool isArabic, Map<String, dynamic> r, String action) async {
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.t(
            isArabic,
            action == 'confirm'
                ? 'confirm_request'
                : action == 'done'
                    ? 'mark_done'
                    : 'reject_request')),
        content: Column(
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
                  labelText: AppStrings.t(
                      isArabic, needsNote ? 'reject_reason' : 'note_optional')),
            ),
            if (isMaintenanceConfirm) ...[
              const SizedBox(height: AppDimens.sm),
              StatefulBuilder(
                builder: (ictx, setSettleState) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.t(isArabic, 'maintenance_settlement'),
                      style: Theme.of(ictx).textTheme.titleSmall,
                    ),
                    RadioListTile<MaintenanceSettlement>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: MaintenanceSettlement.unitBalance,
                      groupValue: settlement,
                      onChanged: (v) => setSettleState(() => settlement = v!),
                      title:
                          Text(AppStrings.t(isArabic, 'settle_unit_balance')),
                    ),
                    RadioListTile<MaintenanceSettlement>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: MaintenanceSettlement.whatsappLink,
                      groupValue: settlement,
                      onChanged: (v) => setSettleState(() => settlement = v!),
                      title:
                          Text(AppStrings.t(isArabic, 'settle_whatsapp_link')),
                    ),
                  ],
                ),
              ),
            ],
            if (canAttachImage) ...[
              const SizedBox(height: AppDimens.sm),
              StatefulBuilder(
                builder: (ictx, setDlgState) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await ImagePicker().pickImage(
                            source: ImageSource.gallery, imageQuality: 85);
                        if (picked != null)
                          setDlgState(() => imageFile = File(picked.path));
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
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusMd),
                          child: Image.file(imageFile!,
                              height: 100, fit: BoxFit.cover),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppStrings.t(isArabic, 'cancel'))),
          TextButton(
            onPressed: () {
              if (needsNote && noteCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: Text(AppStrings.t(isArabic, 'confirm')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final parsedPrice = priceCtrl.text.trim().isNotEmpty
        ? double.tryParse(priceCtrl.text.trim())
        : null;

    setState(() => _busyId = asInt(r['id']));
    try {
      await _service.actOnRequest(
        type: asString(r['type']),
        id: asInt(r['id']),
        action: action,
        note: noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : null,
        price: parsedPrice,
        imagePath: imageFile?.path,
        settlement: isMaintenanceConfirm ? settlementPayload(settlement) : null,
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
        }
      }
      _reload();
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
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
                        if (status == 'pending' || status == 'confirmed') ...[
                          const SizedBox(height: AppDimens.sm),
                          Row(
                            children: [
                              if (status == 'pending')
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.secondary),
                                    onPressed: busy
                                        ? null
                                        : () => _act(isArabic, r, 'confirm'),
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
                                      : () => _act(isArabic, r, 'done'),
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
                                        : () => _act(isArabic, r, 'reject'),
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
