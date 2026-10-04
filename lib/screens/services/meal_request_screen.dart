import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../services/hotel_service.dart';
import '../../services/api_client.dart';

/// طلب وجبات حقيقي — يُرسل فعليًا لإدارة الفندق (اختيار مفتوح لأكثر من وجبة معًا)
class MealRequestScreen extends ConsumerStatefulWidget {
  const MealRequestScreen({super.key});

  @override
  ConsumerState<MealRequestScreen> createState() => _MealRequestScreenState();
}

class _MealRequestScreenState extends ConsumerState<MealRequestScreen> {
  final _service = HotelService();
  final _notesController = TextEditingController();
  final _roomController = TextEditingController();

  late Future<List<Map<String, dynamic>>> _bookingsFuture;
  int? _selectedBookingId;
  final Set<String> _selectedMeals = {};
  bool _validationError = false;
  bool _submitting = false;

  static const _meals = [
    (key: 'breakfast', icon: Icons.coffee_outlined),
    (key: 'lunch', icon: Icons.wb_sunny_outlined),
    (key: 'dinner', icon: Icons.nightlight_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _bookingsFuture = _service.myBookings().then((list) {
      final eligible = list.where((b) => ['confirmed', 'checked_in'].contains(b['status']?.toString())).toList();
      if (eligible.isNotEmpty) _selectedBookingId = eligible.first['id'] as int;
      return eligible;
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _submit(bool isArabic) async {
    final invalid = _selectedMeals.isEmpty || _selectedBookingId == null || _roomController.text.trim().isEmpty;
    setState(() => _validationError = invalid);
    if (invalid) return;

    setState(() => _submitting = true);
    try {
      await _service.submitMealRequest(
        bookingId: _selectedBookingId!,
        roomNumber: _roomController.text.trim(),
        mealTypes: _selectedMeals.toList(),
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusLg)),
          title: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 32),
              ),
              const SizedBox(height: AppDimens.md),
              Text(AppStrings.t(isArabic, 'request_submitted_title'), style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            ],
          ),
          content: Text(AppStrings.t(isArabic, 'request_submitted_desc'), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: Text(AppStrings.t(isArabic, 'ok')),
              ),
            ),
          ],
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
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
        title: Text(AppStrings.t(isArabic, 'order_meal')),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _bookingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(AppStrings.t(isArabic, 'error_loading')));
            }
            final bookings = snapshot.data ?? [];
            if (bookings.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(AppDimens.xl),
                child: Center(child: Text(AppStrings.t(isArabic, 'no_confirmed_bookings'), textAlign: TextAlign.center)),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.12), borderRadius: BorderRadius.circular(AppDimens.radiusLg)),
                    child: const Icon(Icons.restaurant_outlined, color: AppColors.goldDark, size: 30),
                  ),
                  const SizedBox(height: AppDimens.md),
                  Text(AppStrings.t(isArabic, 'order_meal'), style: textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(AppStrings.t(isArabic, 'order_meal_desc'), style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: AppDimens.xl),

                  Text(AppStrings.t(isArabic, 'select_booking'), style: textTheme.titleSmall),
                  const SizedBox(height: AppDimens.sm),
                  DropdownButtonFormField<int>(
                    value: _selectedBookingId,
                    items: bookings
                        .map((b) => DropdownMenuItem<int>(
                              value: b['id'] as int,
                              child: Text('${b['hotel_name'] ?? ''} — #${b['booking_ref'] ?? b['id']}', overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedBookingId = v),
                  ),
                  const SizedBox(height: AppDimens.lg),

                  Text(AppStrings.t(isArabic, 'room_number'), style: textTheme.titleSmall),
                  const SizedBox(height: AppDimens.sm),
                  TextField(
                    controller: _roomController,
                    decoration: InputDecoration(
                      hintText: AppStrings.t(isArabic, 'room_number'),
                      errorText: (_validationError && _roomController.text.trim().isEmpty) ? AppStrings.t(isArabic, 'room_number_required') : null,
                    ),
                  ),
                  const SizedBox(height: AppDimens.lg),

                  Text(AppStrings.t(isArabic, 'meal_type'), style: textTheme.titleSmall),
                  Text(AppStrings.t(isArabic, 'meal_multi_select_hint'), style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                  const SizedBox(height: AppDimens.sm),
                  Row(
                    children: [
                      for (int i = 0; i < _meals.length; i++) ...[
                        if (i != 0) const SizedBox(width: AppDimens.sm),
                        Expanded(
                          child: _MealOption(
                            icon: _meals[i].icon,
                            label: AppStrings.t(isArabic, _meals[i].key),
                            isSelected: _selectedMeals.contains(_meals[i].key),
                            onTap: () => setState(() {
                              if (_selectedMeals.contains(_meals[i].key)) {
                                _selectedMeals.remove(_meals[i].key);
                              } else {
                                _selectedMeals.add(_meals[i].key);
                              }
                              _validationError = false;
                            }),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (_validationError && _selectedMeals.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(AppStrings.t(isArabic, 'meal_type_required'), style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                    ),
                  const SizedBox(height: AppDimens.lg),

                  Text(AppStrings.t(isArabic, 'notes'), style: textTheme.titleSmall),
                  const SizedBox(height: AppDimens.sm),
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: InputDecoration(hintText: AppStrings.t(isArabic, 'notes_hint'), alignLabelWithHint: true),
                  ),
                  const SizedBox(height: AppDimens.xl),

                  SizedBox(
                    width: double.infinity,
                    height: AppDimens.buttonHeight,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : () => _submit(isArabic),
                      child: _submitting
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                          : Text(AppStrings.t(isArabic, 'submit_request')),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MealOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MealOption({required this.icon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold.withOpacity(0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: isSelected ? AppColors.goldDark : AppColors.cardBorder, width: isSelected ? 1.5 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: isSelected ? AppColors.goldDark : AppColors.textSecondary),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isSelected ? AppColors.goldDark : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
