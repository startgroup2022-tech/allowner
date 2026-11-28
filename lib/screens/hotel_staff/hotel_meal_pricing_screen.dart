import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api_client.dart';
import '../../services/hotel_staff_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../utils/pricing_forms.dart';
import '../../utils/safe_parse.dart';
import '../../widgets/pricing_widgets.dart';

/// تسعير الوجبات (المتطلب 16 من المستند 06).
///
/// النموذج يحمل عنوانًا وتاريخًا وثلاث وجبات بأسعارها. السجلات المحفوظة تُقرأ
/// وتُعدَّل ولا تُحذف ولا تُستبدل من التطبيق.
class HotelMealPricingScreen extends ConsumerStatefulWidget {
  const HotelMealPricingScreen({super.key});

  @override
  ConsumerState<HotelMealPricingScreen> createState() =>
      _HotelMealPricingScreenState();
}

class _HotelMealPricingScreenState
    extends ConsumerState<HotelMealPricingScreen> {
  final _service = HotelStaffService();
  final _titleCtrl = TextEditingController();

  bool _loading = true;
  String? _loadError;
  List<Map<String, dynamic>> _records = const [];

  DateTime? _date;
  int? _editingId;
  List<TextEditingController> _nameCtrls = const [];
  List<TextEditingController> _priceCtrls = const [];
  String? _formError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _resetForm();
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    for (final c in _nameCtrls) {
      c.dispose();
    }
    for (final c in _priceCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _resetForm({Map<String, dynamic>? saved}) {
    for (final c in _nameCtrls) {
      c.dispose();
    }
    for (final c in _priceCtrls) {
      c.dispose();
    }
    final rows = buildMealPricingRows(saved: saved);
    _nameCtrls = [
      for (final row in rows) TextEditingController(text: row.name)
    ];
    _priceCtrls = [
      for (final row in rows)
        TextEditingController(text: row.price?.toString() ?? ''),
    ];
    _editingId = asIntOrNull(saved?['id']);
    _titleCtrl.text = (saved?['title'] ?? saved?['title_ar'] ?? '').toString();
    _date = parsePricingDate(saved?['pricing_date'] ?? saved?['date']);
    _formError = null;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final data = await _service.getMealPricing();
      if (!mounted) return;
      setState(() {
        _records = asMapList(data['records']);
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _loading = false;
      });
    }
  }

  List<MealPricingRow> get _rows => [
        for (var i = 0; i < _nameCtrls.length; i++)
          MealPricingRow(
            name: _nameCtrls[i].text,
            price: double.tryParse(_priceCtrls[i].text.trim()),
          ),
      ];

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _date = picked);
  }

  Future<void> _save(bool isArabic) async {
    final error = validateMealPricing(
      title: _titleCtrl.text,
      date: _date,
      rows: _rows,
    );
    if (error != null) {
      setState(() => _formError = error);
      return;
    }
    setState(() {
      _saving = true;
      _formError = null;
    });
    try {
      await _service.saveMealPricing(mealPricingPayload(
        id: _editingId,
        title: _titleCtrl.text,
        date: _date!,
        rows: _rows,
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t(isArabic, 'pricing_saved'))),
      );
      await _load();
      if (!mounted) return;
      setState(() => _resetForm());
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
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
        title: Text(AppStrings.t(isArabic, 'meal_pricing_title')),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppDimens.pagePadding),
            children: [
              if (_loading) const Center(child: CircularProgressIndicator()),
              if (_loadError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppDimens.md),
                  child: Text(_loadError!,
                      style: const TextStyle(color: AppColors.danger)),
                ),
              PricingTitleField(controller: _titleCtrl, isArabic: isArabic),
              const SizedBox(height: AppDimens.md),
              PricingDateField(
                date: _date,
                isArabic: isArabic,
                onPick: _pickDate,
              ),
              const SizedBox(height: AppDimens.md),
              Text(AppStrings.t(isArabic, 'meal_prices_three_rows'),
                  style: textTheme.titleSmall),
              const SizedBox(height: AppDimens.sm),
              for (var i = 0; i < _nameCtrls.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppDimens.sm),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _nameCtrls[i],
                          decoration: InputDecoration(
                            labelText:
                                '${AppStrings.t(isArabic, 'meal_name_column')} ${i + 1}',
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimens.sm),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _priceCtrls[i],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText:
                                AppStrings.t(isArabic, 'unit_price_column'),
                            suffixText: AppStrings.t(isArabic, 'sar'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_formError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppDimens.sm),
                  child: Text(AppStrings.t(isArabic, _formError!),
                      style: const TextStyle(
                          color: AppColors.danger, fontSize: 12)),
                ),
              SizedBox(
                width: double.infinity,
                height: AppDimens.buttonHeight,
                child: ElevatedButton(
                  onPressed: _saving ? null : () => _save(isArabic),
                  child: Text(AppStrings.t(isArabic, 'save_changes')),
                ),
              ),
              const SizedBox(height: AppDimens.xl),
              Text(AppStrings.t(isArabic, 'saved_pricing_records'),
                  style: textTheme.titleSmall),
              const SizedBox(height: AppDimens.sm),
              if (_records.isEmpty)
                Text(AppStrings.t(isArabic, 'no_saved_pricing'),
                    style: textTheme.bodySmall
                        ?.copyWith(color: AppColors.textMuted))
              else
                for (final record in _records)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppDimens.sm),
                    child: PricingRecordCard(
                      title: (record['title'] ?? record['title_ar'] ?? '')
                          .toString(),
                      date: formatPricingDate(
                        parsePricingDate(
                                record['pricing_date'] ?? record['date']) ??
                            DateTime.now(),
                      ),
                      lines: [
                        for (final meal in asMapList(record['meals']))
                          (
                            (meal['name'] ?? meal['name_ar'] ?? '').toString(),
                            '${meal['price'] ?? '—'} ${AppStrings.t(isArabic, 'sar')}',
                          ),
                      ],
                      onTap: () => setState(() => _resetForm(saved: record)),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
