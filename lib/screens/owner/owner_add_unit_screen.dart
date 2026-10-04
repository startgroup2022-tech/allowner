import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../services/owner_service.dart';
import '../../services/api_client.dart';

class OwnerAddUnitScreen extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> hotels;

  const OwnerAddUnitScreen({super.key, required this.hotels});

  @override
  ConsumerState<OwnerAddUnitScreen> createState() => _OwnerAddUnitScreenState();
}

class _OwnerAddUnitScreenState extends ConsumerState<OwnerAddUnitScreen> {
  final _service = OwnerService();
  final _formKey = GlobalKey<FormState>();

  final _nameArCtrl = TextEditingController();
  final _nameEnCtrl = TextEditingController();
  final _unitNumberCtrl = TextEditingController();
  final _descArCtrl = TextEditingController();
  final _descEnCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController(text: '2');
  final _bedCountCtrl = TextEditingController(text: '1');
  final _unitTypeArCtrl = TextEditingController();
  final _unitTypeEnCtrl = TextEditingController();
  final _priceNightCtrl = TextEditingController();
  final _priceWeekCtrl = TextEditingController();
  final _priceMonthCtrl = TextEditingController();

  int? _selectedHotelId;
  File? _coverImage;
  final List<File> _galleryImages = [];
  bool _saving = false;
  String? _errorText;
  final List<Map<String, dynamic>> _addons = [];
  final List<Map<String, DateTime?>> _availabilityPeriods = [];

  static const _addonCategories = ['extra_bed', 'meal_plan', 'other'];
  static const _priceUnits = ['per_night', 'per_stay', 'per_person_night'];

  @override
  void initState() {
    super.initState();
    if (widget.hotels.isNotEmpty) {
      _selectedHotelId = widget.hotels.first['id'] as int;
    }
  }

  @override
  void dispose() {
    _nameArCtrl.dispose();
    _nameEnCtrl.dispose();
    _unitNumberCtrl.dispose();
    _descArCtrl.dispose();
    _descEnCtrl.dispose();
    _capacityCtrl.dispose();
    _bedCountCtrl.dispose();
    _unitTypeArCtrl.dispose();
    _unitTypeEnCtrl.dispose();
    _priceNightCtrl.dispose();
    _priceWeekCtrl.dispose();
    _priceMonthCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _coverImage = File(picked.path));
  }

  Future<void> _pickGalleryImages() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 85);
    if (picked.isNotEmpty) {
      setState(() => _galleryImages.addAll(picked.map((x) => File(x.path))));
    }
  }

  Future<void> _submit(bool isArabic) async {
    if (_selectedHotelId == null) {
      setState(() => _errorText = AppStrings.t(isArabic, 'no_hotel_linked'));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _errorText = null;
    });

    try {
      await _service.createUnit(
        hotelId: _selectedHotelId!,
        nameAr: _nameArCtrl.text.trim(),
        nameEn: _nameEnCtrl.text.trim(),
        unitTypeAr: _unitTypeArCtrl.text.trim(),
        unitTypeEn: _unitTypeEnCtrl.text.trim(),
        bedCount: int.tryParse(_bedCountCtrl.text.trim()) ?? 1,
        descriptionAr: _descArCtrl.text.trim(),
        descriptionEn: _descEnCtrl.text.trim(),
        unitNumber: _unitNumberCtrl.text.trim(),
        capacity: int.tryParse(_capacityCtrl.text.trim()) ?? 1,
        pricePerNight: double.tryParse(_priceNightCtrl.text.trim()) ?? 0,
        pricePerWeek: _priceWeekCtrl.text.trim().isEmpty ? null : double.tryParse(_priceWeekCtrl.text.trim()),
        pricePerMonth: _priceMonthCtrl.text.trim().isEmpty ? null : double.tryParse(_priceMonthCtrl.text.trim()),
        coverImagePath: _coverImage?.path,
        galleryPaths: _galleryImages.map((f) => f.path).toList(),
        addons: _addons,
        availabilityPeriods: _availabilityPeriods.map((p) => {
              'from': _fmtDate(p['from'] as DateTime),
              'to': _fmtDate(p['to'] as DateTime),
            }).toList(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _errorText = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _categoryLabel(bool isArabic, String cat) {
    switch (cat) {
      case 'extra_bed':
        return isArabic ? '🛏️ سرير إضافي' : '🛏️ Extra Bed';
      case 'meal_plan':
        return isArabic ? '🍽️ خطة وجبات' : '🍽️ Meal Plan';
      default:
        return isArabic ? '✨ إضافة أخرى' : '✨ Other';
    }
  }

  String _priceUnitLabel(bool isArabic, String pu) {
    switch (pu) {
      case 'per_stay':
        return isArabic ? '/ للإقامة كاملة' : '/ whole stay';
      case 'per_person_night':
        return isArabic ? '/ للشخص لليلة' : '/ person / night';
      default:
        return isArabic ? '/ لليلة' : '/ night';
    }
  }

  Future<void> _addAvailabilityPeriod() async {
    final now = DateTime.now();
    final from = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 3),
    );
    if (from == null || !mounted) return;
    final to = await showDatePicker(
      context: context,
      initialDate: from.add(const Duration(days: 1)),
      firstDate: from.add(const Duration(days: 1)),
      lastDate: DateTime(now.year + 3),
    );
    if (to == null) return;
    setState(() => _availabilityPeriods.add({'from': from, 'to': to}));
  }

  Future<void> _openAddAddonSheet(bool isArabic) async {
    String category = 'extra_bed';
    String priceUnit = 'per_night';
    final nameArCtrl = TextEditingController();
    final nameEnCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    const mealOptions = [
      {'value': '', 'ar': '— اختر الوجبة —', 'en': '— Select meal —'},
      {'value': 'فطور|Breakfast', 'ar': '🌅 فطور', 'en': '🌅 Breakfast'},
      {'value': 'غداء|Lunch', 'ar': '☀️ غداء', 'en': '☀️ Lunch'},
      {'value': 'عشاء|Dinner', 'ar': '🌙 عشاء', 'en': '🌙 Dinner'},
      {'value': 'بدون وجبات|No meals', 'ar': '🚫 بدون وجبات', 'en': '🚫 No meals'},
    ];
    String selectedMealOption = '';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
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
                  Text(AppStrings.t(isArabic, 'add_unit_addon'), style: Theme.of(ctx).textTheme.titleMedium),
                  const SizedBox(height: AppDimens.md),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: _dec(AppStrings.t(isArabic, 'addon_type')),
                    items: _addonCategories
                        .map((c) => DropdownMenuItem(value: c, child: Text(_categoryLabel(isArabic, c))))
                        .toList(),
                    onChanged: (v) => setSheetState(() => category = v ?? category),
                  ),
                  const SizedBox(height: AppDimens.md),
                  if (category == 'meal_plan') ...[
                    DropdownButtonFormField<String>(
                      initialValue: selectedMealOption,
                      decoration: _dec(isArabic ? 'نوع الوجبة' : 'Meal type'),
                      items: mealOptions
                          .map((m) => DropdownMenuItem(value: m['value'], child: Text(isArabic ? m['ar']! : m['en']!)))
                          .toList(),
                      onChanged: (v) {
                        setSheetState(() {
                          selectedMealOption = v ?? '';
                          if (selectedMealOption.isNotEmpty) {
                            final parts = selectedMealOption.split('|');
                            nameArCtrl.text = parts[0];
                            nameEnCtrl.text = parts[1];
                          }
                        });
                      },
                    ),
                    const SizedBox(height: AppDimens.md),
                  ],
                  TextField(controller: nameArCtrl, decoration: _dec(AppStrings.t(isArabic, 'unit_name_ar'))),
                  const SizedBox(height: AppDimens.md),
                  TextField(controller: nameEnCtrl, decoration: _dec(AppStrings.t(isArabic, 'unit_name_en'))),
                  const SizedBox(height: AppDimens.md),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _dec(AppStrings.t(isArabic, 'price')),
                  ),
                  const SizedBox(height: AppDimens.md),
                  DropdownButtonFormField<String>(
                    initialValue: priceUnit,
                    decoration: _dec(AppStrings.t(isArabic, 'billed')),
                    items: _priceUnits
                        .map((p) => DropdownMenuItem(value: p, child: Text(_priceUnitLabel(isArabic, p))))
                        .toList(),
                    onChanged: (v) => setSheetState(() => priceUnit = v ?? priceUnit),
                  ),
                  const SizedBox(height: AppDimens.lg),
                  SizedBox(
                    width: double.infinity,
                    height: AppDimens.buttonHeight,
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameArCtrl.text.trim().isEmpty || nameEnCtrl.text.trim().isEmpty || priceCtrl.text.trim().isEmpty) {
                          return;
                        }
                        setState(() {
                          _addons.add({
                            'category': category,
                            'name_ar': nameArCtrl.text.trim(),
                            'name_en': nameEnCtrl.text.trim(),
                            'price': double.tryParse(priceCtrl.text.trim()) ?? 0,
                            'price_unit': priceUnit,
                          });
                        });
                        Navigator.of(ctx).pop();
                      },
                      child: Text(AppStrings.t(isArabic, 'add_unit_addon')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _dec(String label) => InputDecoration(labelText: label);

  String _fmtDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(AppStrings.t(isArabic, 'add_unit')),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppDimens.pagePadding),
            children: [
              if (widget.hotels.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppDimens.md),
                  margin: const EdgeInsets.only(bottom: AppDimens.md),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                  ),
                  child: Text(
                    AppStrings.t(isArabic, 'no_hotel_linked'),
                    style: const TextStyle(color: AppColors.warning),
                  ),
                )
              else
                DropdownButtonFormField<int>(
                  initialValue: _selectedHotelId,
                  decoration: _dec(AppStrings.t(isArabic, 'hotel')),
                  items: widget.hotels
                      .map((h) => DropdownMenuItem<int>(value: h['id'] as int, child: Text(h['name']?.toString() ?? '')))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedHotelId = v),
                ),
              const SizedBox(height: AppDimens.md),

              GestureDetector(
                onTap: _pickCoverImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                    image: _coverImage != null ? DecorationImage(image: FileImage(_coverImage!), fit: BoxFit.cover) : null,
                  ),
                  child: _coverImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_a_photo_outlined, color: AppColors.textMuted, size: 28),
                            const SizedBox(height: 6),
                            Text(AppStrings.t(isArabic, 'cover_image'), style: const TextStyle(color: AppColors.textMuted)),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: AppDimens.md),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppStrings.t(isArabic, 'gallery_images'), style: Theme.of(context).textTheme.titleSmall),
                  TextButton.icon(
                    onPressed: _pickGalleryImages,
                    icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                    label: Text(AppStrings.t(isArabic, 'add_photos')),
                  ),
                ],
              ),
              if (_galleryImages.isNotEmpty)
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _galleryImages.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                          child: Image.file(_galleryImages[i], width: 80, height: 80, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () => setState(() => _galleryImages.removeAt(i)),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: AppDimens.md),

              TextFormField(
                controller: _nameArCtrl,
                decoration: _dec(AppStrings.t(isArabic, 'unit_name_ar')),
                validator: (v) => (v == null || v.trim().isEmpty) ? AppStrings.t(isArabic, 'required_field') : null,
              ),
              const SizedBox(height: AppDimens.md),
              TextFormField(
                controller: _nameEnCtrl,
                decoration: _dec(AppStrings.t(isArabic, 'unit_name_en')),
                validator: (v) => (v == null || v.trim().isEmpty) ? AppStrings.t(isArabic, 'required_field') : null,
              ),
              const SizedBox(height: AppDimens.md),
              TextFormField(controller: _unitNumberCtrl, decoration: _dec(AppStrings.t(isArabic, 'unit_number'))),
              const SizedBox(height: AppDimens.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _unitTypeArCtrl,
                      decoration: _dec(AppStrings.t(isArabic, 'unit_type_ar')),
                    ),
                  ),
                  const SizedBox(width: AppDimens.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _unitTypeEnCtrl,
                      decoration: _dec(AppStrings.t(isArabic, 'unit_type_en')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.md),
              TextFormField(
                controller: _descArCtrl,
                maxLines: 3,
                decoration: _dec(AppStrings.t(isArabic, 'description_ar')),
              ),
              const SizedBox(height: AppDimens.md),
              TextFormField(
                controller: _descEnCtrl,
                maxLines: 3,
                decoration: _dec(AppStrings.t(isArabic, 'description_en')),
              ),
              const SizedBox(height: AppDimens.md),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _capacityCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _dec(AppStrings.t(isArabic, 'capacity')),
                      validator: (v) => (v == null || v.trim().isEmpty) ? AppStrings.t(isArabic, 'required_field') : null,
                    ),
                  ),
                  const SizedBox(width: AppDimens.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _bedCountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _dec(AppStrings.t(isArabic, 'bed_count')),
                      validator: (v) => (v == null || v.trim().isEmpty) ? AppStrings.t(isArabic, 'required_field') : null,
                    ),
                  ),
                  const SizedBox(width: AppDimens.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _priceNightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _dec(AppStrings.t(isArabic, 'price_per_night')),
                      validator: (v) => (v == null || double.tryParse(v.trim()) == null || double.parse(v.trim()) <= 0)
                          ? AppStrings.t(isArabic, 'required_field')
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceWeekCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _dec(AppStrings.t(isArabic, 'price_per_week_optional')),
                    ),
                  ),
                  const SizedBox(width: AppDimens.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _priceMonthCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _dec(AppStrings.t(isArabic, 'price_per_month_optional')),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimens.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppStrings.t(isArabic, 'unit_addons_title'), style: Theme.of(context).textTheme.titleSmall),
                  TextButton.icon(
                    onPressed: () => _openAddAddonSheet(isArabic),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(AppStrings.t(isArabic, 'add_unit_addon')),
                  ),
                ],
              ),
              if (_addons.isEmpty)
                Text(AppStrings.t(isArabic, 'no_addons_yet'), style: const TextStyle(color: AppColors.textMuted, fontSize: 12))
              else
                ..._addons.asMap().entries.map((entry) {
                  final i = entry.key;
                  final addon = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppDimens.sm),
                    padding: const EdgeInsets.all(AppDimens.sm),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_categoryLabel(isArabic, addon['category'])} — ${isArabic ? addon['name_ar'] : addon['name_en']} — ${addon['price']} ${_priceUnitLabel(isArabic, addon['price_unit'])}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: AppColors.danger),
                          onPressed: () => setState(() => _addons.removeAt(i)),
                        ),
                      ],
                    ),
                  );
                }),

              if (_errorText != null) ...[
                const SizedBox(height: AppDimens.md),
                Text(_errorText!, style: const TextStyle(color: AppColors.danger)),
              ],

              const SizedBox(height: AppDimens.lg),
              const SizedBox(height: AppDimens.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppStrings.t(isArabic, 'availability_periods'), style: Theme.of(context).textTheme.titleSmall),
                  TextButton.icon(
                    onPressed: _addAvailabilityPeriod,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(AppStrings.t(isArabic, 'add_period')),
                  ),
                ],
              ),
              if (_availabilityPeriods.isEmpty)
                Text(AppStrings.t(isArabic, 'no_periods_yet'), style: const TextStyle(color: AppColors.textMuted, fontSize: 12))
              else
                ..._availabilityPeriods.asMap().entries.map((entry) {
                  final i = entry.key;
                  final period = entry.value;
                  final from = period['from'] as DateTime;
                  final to = period['to'] as DateTime;
                  String fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppDimens.sm),
                    padding: const EdgeInsets.all(AppDimens.sm),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text('${fmt(from)}  →  ${fmt(to)}', style: const TextStyle(fontSize: 13))),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: AppColors.danger),
                          onPressed: () => setState(() => _availabilityPeriods.removeAt(i)),
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: AppDimens.lg),
              SizedBox(
                width: double.infinity,
                height: AppDimens.buttonHeight,
                child: ElevatedButton(
                  onPressed: _saving ? null : () => _submit(isArabic),
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(AppStrings.t(isArabic, 'save')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
