import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../utils/session_provider.dart';
import '../../models/hotel_model.dart';
import '../../services/hotel_service.dart';
import '../../services/owner_service.dart';
import '../../utils/safe_parse.dart';
import '../auth/login_screen.dart';
import 'booking_success_screen.dart';

enum PaymentMethod { online, atHotel, ownerTransfer }

class BookingScreen extends ConsumerStatefulWidget {
  final HotelModel hotel;
  final int? unitId;
  final String? unitName;
  final double? unitPricePerNight;
  final String? unitImageUrl;
  const BookingScreen({super.key, required this.hotel, this.unitId, this.unitName, this.unitPricePerNight, this.unitImageUrl});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final HotelService _hotelService = HotelService();

  PaymentMethod _paymentMethod = PaymentMethod.online;
  int _guests = 2;
  DateTime _checkIn = DateTime.now().add(const Duration(days: 1));
  DateTime _checkOut = DateTime.now().add(const Duration(days: 3));
  final Set<String> _selectedLegacyMeals = {}; // للحجز العام: يسمح باختيار أكثر من وجبة
  bool _extraBed = false;
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardNameController = TextEditingController();
  final _guestIdNumberController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  List<Map<String, dynamic>> _agentClients = [];
  int? _selectedClientId;

  bool _isSubmitting = false;

  // إضافات الوحدة الحقيقية (سرير/وجبات/أخرى) يلي حددها المالك — لو في وحدة محددة
  List<Map<String, dynamic>> _unitAddons = [];
  bool _loadingAddons = false;
  final Set<int> _selectedMealAddonIds = {}; // فاضية = بدون وجبات — يسمح باختيار أكثر من وجبة معاً (فطور + غداء مثلاً)
  final Set<int> _selectedOtherAddonIds = {};

  int get _nights => _checkOut.difference(_checkIn).inDays.clamp(1, 365);

  double get _basePricePerNight => widget.unitPricePerNight ?? widget.hotel.pricePerNight;

  List<Map<String, dynamic>> get _mealAddons =>
      _unitAddons.where((a) => a['category'] == 'meal_plan').toList()
        ..sort((a, b) {
          const order = {'فطور': 0, 'Breakfast': 0, 'غداء': 1, 'Lunch': 1, 'عشاء': 2, 'Dinner': 2};
          return (order[a['name_ar']] ?? 9).compareTo(order[b['name_ar']] ?? 9);
        });

  List<Map<String, dynamic>> get _otherAddons =>
      _unitAddons.where((a) => a['category'] != 'meal_plan').toList();

  double _addonLineTotal(Map<String, dynamic> addon) {
    final price = asDouble(addon['price']);
    switch (addon['price_unit']) {
      case 'per_stay':
        return price;
      case 'per_person_night':
        return price * _nights * (_guests < 1 ? 1 : _guests);
      default:
        return price * _nights;
    }
  }

  double get _addonsTotal {
    double sum = 0;
    for (final id in _selectedMealAddonIds) {
      final meal = _unitAddons.firstWhere((a) => a['id'] == id, orElse: () => {});
      if (meal.isNotEmpty) sum += _addonLineTotal(meal);
    }
    for (final id in _selectedOtherAddonIds) {
      final addon = _unitAddons.firstWhere((a) => a['id'] == id, orElse: () => {});
      if (addon.isNotEmpty) sum += _addonLineTotal(addon);
    }
    return sum;
  }

  @override
  void initState() {
    super.initState();
    if (ref.read(sessionProvider).user?.role == 'booking_agent') {
      OwnerService().getAgentClients().then((list) {
        if (mounted) setState(() => _agentClients = list);
      }).catchError((_) {});
    }
    if (widget.unitId != null) _loadAddons();
  }

  Future<void> _loadAddons() async {
    setState(() => _loadingAddons = true);
    try {
      final addons = await _hotelService.getUnitAddons(widget.unitId!);
      if (mounted) setState(() => _unitAddons = addons);
    } catch (_) {
      // فشل تحميل الإضافات مش مشكلة قاتلة — الحجز الأساسي يضل شغال بدونها
    } finally {
      if (mounted) setState(() => _loadingAddons = false);
    }
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardNameController.dispose();
    _guestIdNumberController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isCheckIn}) async {
    final initial = isCheckIn ? _checkIn : _checkOut;
    final firstDate = isCheckIn ? DateTime.now() : _checkIn.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked == null) return;

    setState(() {
      if (isCheckIn) {
        _checkIn = picked;
        if (!_checkOut.isAfter(_checkIn)) {
          _checkOut = _checkIn.add(const Duration(days: 1));
        }
      } else {
        _checkOut = picked;
      }
    });
  }

  bool get _isAgent => ref.read(sessionProvider).user?.role == 'booking_agent';

  Future<void> _confirmBooking() async {
    final isArabic = ref.read(localeProvider).languageCode == 'ar';

    if (!ref.read(sessionProvider).isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isArabic ? 'الرجاء تسجيل الدخول أولاً لإتمام الحجز' : 'Please log in first to complete booking')),
      );
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    if (_paymentMethod == PaymentMethod.online) {
      final digits = _cardNumberController.text.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 12) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isArabic ? 'رقم البطاقة غير صحيح' : 'Invalid card number')),
        );
        return;
      }
    }

    if (_guestIdNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t(isArabic, 'guest_id_number_required'))),
      );
      return;
    }

    if (_isAgent && (_customerNameController.text.trim().isEmpty || _customerPhoneController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t(isArabic, 'customer_name_phone_required'))),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final addonIds = <int>[
        ..._selectedMealAddonIds,
        ..._selectedOtherAddonIds,
      ];
      final booking = await _hotelService.createBooking(
        hotelId: widget.hotel.id,
        unitId: widget.unitId,
        checkIn: _checkIn,
        checkOut: _checkOut,
        guests: _guests,
        paymentMethod: _paymentMethod == PaymentMethod.online
            ? 'online'
            : _paymentMethod == PaymentMethod.ownerTransfer
                ? 'owner_transfer'
                : 'at_hotel',
        cardNumber: _paymentMethod == PaymentMethod.online
            ? _cardNumberController.text.replaceAll(RegExp(r'\D'), '')
            : null,
        mealTypes: _selectedLegacyMeals.toList(),
        extraBed: _extraBed,
        addonIds: addonIds.isNotEmpty ? addonIds : null,
        guestIdNumber: _guestIdNumberController.text.trim(),
        customerName: _isAgent ? _customerNameController.text.trim() : null,
        customerPhone: _isAgent ? _customerPhoneController.text.trim() : null,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BookingSuccessScreen(
            hotel: widget.hotel,
            bookingRef: booking['booking_ref']?.toString(),
            total: double.tryParse(booking['total']?.toString() ?? ''),
            checkIn: _checkIn,
            checkOut: _checkOut,
            nights: asInt(booking['nights'], _nights),
            guests: _guests,
            unitName: widget.unitName,
            guestName: _isAgent ? _customerNameController.text.trim() : ref.read(sessionProvider).user?.fullName,
            guestPhone: _isAgent ? _customerPhoneController.text.trim() : ref.read(sessionProvider).user?.phone,
            status: booking['status']?.toString(),
            paymentMethod: booking['payment_method']?.toString(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _formatDate(DateTime d, bool isArabic) {
    const monthsAr = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    const monthsEn = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return isArabic ? '${d.day} ${monthsAr[d.month - 1]}' : '${monthsEn[d.month - 1]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final textTheme = Theme.of(context).textTheme;
    final hotel = widget.hotel;

    final roomPrice = _basePricePerNight * _nights;
    final addonsTotal = _addonsTotal;
    final hasAddonsSelected = _selectedMealAddonIds.isNotEmpty || _selectedOtherAddonIds.isNotEmpty;
    // نفس منطق الباكيند: سرير إضافي يُحسب كرسم ثابت مرة واحدة، ويُحتسب فقط إذا ما فيه إضافات وحدة مختارة
    final extraBedCharge = (!hasAddonsSelected && _extraBed && widget.hotel.extraBedPrice != null) ? widget.hotel.extraBedPrice! : 0.0;
    final taxes = (roomPrice + addonsTotal + extraBedCharge) * 0.15;
    final total = roomPrice + addonsTotal + extraBedCharge + taxes;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 240,
                  pinned: true,
                  backgroundColor: AppColors.ink,
                  iconTheme: const IconThemeData(color: Colors.white),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: widget.unitImageUrl ?? hotel.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: AppColors.surfaceMuted),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.surfaceMuted,
                            child: const Icon(Icons.image_outlined, size: 40, color: AppColors.textMuted),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.black.withOpacity(0.05), Colors.black.withOpacity(0.75)],
                              stops: const [0.4, 1.0],
                            ),
                          ),
                        ),
                        Positioned(
                          left: AppDimens.pagePadding,
                          right: AppDimens.pagePadding,
                          bottom: AppDimens.md,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.unitName ?? hotel.name,
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, color: Colors.white70, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.unitName != null ? hotel.name : hotel.city(isArabic),
                                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimens.pagePadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(AppStrings.t(isArabic, 'your_stay'), style: textTheme.titleMedium),
                    const SizedBox(height: AppDimens.sm),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate(isCheckIn: true),
                            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                            child: _InfoBox(
                              icon: Icons.calendar_today_outlined,
                              label: AppStrings.t(isArabic, 'check_in'),
                              value: _formatDate(_checkIn, isArabic),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimens.sm),
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate(isCheckIn: false),
                            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                            child: _InfoBox(
                              icon: Icons.calendar_today_outlined,
                              label: AppStrings.t(isArabic, 'check_out'),
                              value: _formatDate(_checkOut, isArabic),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimens.md),
                    Row(
                      children: [
                        Expanded(
                          child: _StepperBox(
                            label: AppStrings.t(isArabic, 'guests'),
                            value: _guests,
                            onMinus: () => setState(() => _guests = _guests > 1 ? _guests - 1 : 1),
                            onPlus: () => setState(() => _guests++),
                          ),
                        ),
                        const SizedBox(width: AppDimens.sm),
                        Expanded(
                          child: _InfoBox(
                            icon: Icons.nightlight_outlined,
                            label: AppStrings.t(isArabic, 'nights'),
                            value: '$_nights',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimens.md),
                    TextField(
                      controller: _guestIdNumberController,
                      decoration: InputDecoration(labelText: AppStrings.t(isArabic, 'guest_id_number')),
                    ),
                    if (_isAgent) ...[
                      if (_agentClients.isNotEmpty) ...[
                        const SizedBox(height: AppDimens.md),
                        DropdownButtonFormField<int?>(
                          value: _selectedClientId,
                          decoration: InputDecoration(labelText: AppStrings.t(isArabic, 'saved_client')),
                          items: [
                            DropdownMenuItem<int?>(value: null, child: Text(AppStrings.t(isArabic, 'new_client'))),
                            ..._agentClients.map((c) => DropdownMenuItem<int?>(
                                  value: c['id'] as int,
                                  child: Text('${c['full_name']} — ${c['phone']}', overflow: TextOverflow.ellipsis),
                                )),
                          ],
                          onChanged: (v) => setState(() {
                            _selectedClientId = v;
                            final c = _agentClients.where((x) => x['id'] == v).toList();
                            if (c.isNotEmpty) {
                              _customerNameController.text = c.first['full_name']?.toString() ?? '';
                              _customerPhoneController.text = c.first['phone']?.toString() ?? '';
                              if ((c.first['id_number'] ?? '').toString().isNotEmpty) {
                                _guestIdNumberController.text = c.first['id_number'].toString();
                              }
                            }
                          }),
                        ),
                      ],
                      const SizedBox(height: AppDimens.md),
                      TextField(
                        controller: _customerNameController,
                        decoration: InputDecoration(labelText: AppStrings.t(isArabic, 'customer_name')),
                      ),
                      const SizedBox(height: AppDimens.md),
                      TextField(
                        controller: _customerPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(labelText: AppStrings.t(isArabic, 'customer_phone')),
                      ),
                    ],
                    const SizedBox(height: AppDimens.lg),

                    if (widget.unitId != null) ...[
                      // إضافات الوحدة الحقيقية يلي حددها المالك (وجبات: فطور/غداء/عشاء + سرير إضافي + إضافات أخرى)
                      if (_loadingAddons)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppDimens.md),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else ...[
                        if (_mealAddons.isNotEmpty) ...[
                          Text(AppStrings.t(isArabic, 'meal_type'), style: textTheme.titleMedium),
                          Text(AppStrings.t(isArabic, 'meal_multi_select_hint'),
                              style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                          const SizedBox(height: AppDimens.sm),
                          _MealOptionTile(
                            label: AppStrings.t(isArabic, 'meal_option_none'),
                            priceLabel: AppStrings.t(isArabic, 'free'),
                            selected: _selectedMealAddonIds.isEmpty,
                            onTap: () => setState(() => _selectedMealAddonIds.clear()),
                          ),
                          ..._mealAddons.map((m) {
                            final id = m['id'] as int;
                            final selected = _selectedMealAddonIds.contains(id);
                            return _MealOptionTile(
                              label: isArabic ? (m['name_ar']?.toString() ?? '') : (m['name_en']?.toString() ?? ''),
                              priceLabel: '+${_addonLineTotal(m).toStringAsFixed(0)} ${AppStrings.t(isArabic, "sar")}',
                              selected: selected,
                              onTap: () => setState(() {
                                if (selected) {
                                  _selectedMealAddonIds.remove(id);
                                } else {
                                  _selectedMealAddonIds.add(id);
                                }
                              }),
                            );
                          }),
                          const SizedBox(height: AppDimens.lg),
                        ],
                        if (_otherAddons.isNotEmpty) ...[
                          Text(AppStrings.t(isArabic, 'unit_addons_title'), style: textTheme.titleMedium),
                          const SizedBox(height: AppDimens.sm),
                          ..._otherAddons.map((a) {
                            final id = a['id'] as int;
                            final selected = _selectedOtherAddonIds.contains(id);
                            return Container(
                              margin: const EdgeInsets.only(bottom: AppDimens.sm),
                              padding: const EdgeInsets.all(AppDimens.md),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${a['category'] == 'extra_bed' ? '🛏️ ' : '✨ '}${isArabic ? (a['name_ar']?.toString() ?? '') : (a['name_en']?.toString() ?? '')}',
                                          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          '+${_addonLineTotal(a).toStringAsFixed(0)} ${AppStrings.t(isArabic, "sar")}',
                                          style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: selected,
                                    activeColor: AppColors.gold,
                                    onChanged: (v) => setState(() {
                                      if (v) {
                                        _selectedOtherAddonIds.add(id);
                                      } else {
                                        _selectedOtherAddonIds.remove(id);
                                      }
                                    }),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: AppDimens.md),
                        ],
                        if (_mealAddons.isEmpty && _otherAddons.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppDimens.md),
                            child: Text(
                              AppStrings.t(isArabic, 'no_addons_yet'),
                              style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                            ),
                          ),
                      ],
                    ] else ...[
                      // مافي وحدة محددة (حجز على مستوى الفندق العام) — النظام القديم كتوافق
                      Text(AppStrings.t(isArabic, 'meal_type'), style: textTheme.titleMedium),
                      const SizedBox(height: AppDimens.sm),
                      Wrap(
                        spacing: AppDimens.sm,
                        runSpacing: AppDimens.sm,
                        children: ['breakfast', 'lunch', 'dinner'].map((m) {
                          final selected = _selectedLegacyMeals.contains(m);
                          return FilterChip(
                            label: Text(AppStrings.t(isArabic, 'meal_option_$m')),
                            selected: selected,
                            onSelected: (v) => setState(() {
                              if (v) {
                                _selectedLegacyMeals.add(m);
                              } else {
                                _selectedLegacyMeals.remove(m);
                              }
                            }),
                            selectedColor: AppColors.gold.withOpacity(0.2),
                            labelStyle: TextStyle(color: selected ? AppColors.goldDark : AppColors.textMuted, fontWeight: selected ? FontWeight.w700 : FontWeight.w400),
                          );
                        }).toList(),
                      ),
                      if (_selectedLegacyMeals.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: AppDimens.sm),
                          child: Text(AppStrings.t(isArabic, 'meal_option_none'), style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                        ),

                      if (widget.hotel.extraBedPrice != null) ...[
                        const SizedBox(height: AppDimens.lg),
                        Container(
                          padding: const EdgeInsets.all(AppDimens.md),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(AppStrings.t(isArabic, 'add_extra_bed'), style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                    Text(
                                      widget.hotel.extraBedPrice == 0
                                          ? AppStrings.t(isArabic, 'free')
                                          : '+${widget.hotel.extraBedPrice!.toStringAsFixed(0)} ${AppStrings.t(isArabic, 'sar')} (${AppStrings.t(isArabic, 'one_time_fee')})',
                                      style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _extraBed,
                                activeColor: AppColors.gold,
                                onChanged: (v) => setState(() => _extraBed = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: AppDimens.lg),

                    Text(AppStrings.t(isArabic, 'payment_method'), style: textTheme.titleMedium),
                    const SizedBox(height: AppDimens.sm),
                    _PaymentOption(
                      icon: Icons.credit_card_rounded,
                      label: AppStrings.t(isArabic, 'pay_online'),
                      selected: _paymentMethod == PaymentMethod.online,
                      onTap: () => setState(() => _paymentMethod = PaymentMethod.online),
                    ),
                    const SizedBox(height: AppDimens.sm),
                    _PaymentOption(
                      icon: Icons.storefront_outlined,
                      label: AppStrings.t(isArabic, 'pay_at_hotel'),
                      selected: _paymentMethod == PaymentMethod.atHotel,
                      onTap: () => setState(() => _paymentMethod = PaymentMethod.atHotel),
                    ),
                    if (widget.unitId != null) ...[
                      const SizedBox(height: AppDimens.sm),
                      _PaymentOption(
                        icon: Icons.account_balance_outlined,
                        label: AppStrings.t(isArabic, 'pay_owner_transfer'),
                        selected: _paymentMethod == PaymentMethod.ownerTransfer,
                        onTap: () => setState(() => _paymentMethod = PaymentMethod.ownerTransfer),
                      ),
                    ],

                    if (_paymentMethod == PaymentMethod.online) ...[
                      const SizedBox(height: AppDimens.md),
                      TextField(
                        controller: _cardNumberController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: AppStrings.t(isArabic, 'card_number'),
                          prefixIcon: const Icon(Icons.credit_card_outlined),
                        ),
                      ),
                      const SizedBox(height: AppDimens.sm),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _expiryController,
                              decoration: InputDecoration(hintText: AppStrings.t(isArabic, 'expiry_date')),
                            ),
                          ),
                          const SizedBox(width: AppDimens.sm),
                          Expanded(
                            child: TextField(
                              controller: _cvvController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(hintText: AppStrings.t(isArabic, 'cvv')),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimens.sm),
                      TextField(
                        controller: _cardNameController,
                        decoration: InputDecoration(hintText: AppStrings.t(isArabic, 'cardholder_name')),
                      ),
                    ],
                    const SizedBox(height: AppDimens.lg),

                    Text(AppStrings.t(isArabic, 'price_details'), style: textTheme.titleMedium),
                    const SizedBox(height: AppDimens.sm),
                    _PriceRow(label: AppStrings.t(isArabic, 'room_price'), value: roomPrice, isArabic: isArabic),
                    if (addonsTotal > 0)
                      _PriceRow(label: AppStrings.t(isArabic, 'unit_addons_title'), value: addonsTotal, isArabic: isArabic),
                    if (extraBedCharge > 0)
                      _PriceRow(label: AppStrings.t(isArabic, 'add_extra_bed'), value: extraBedCharge, isArabic: isArabic),
                    _PriceRow(label: AppStrings.t(isArabic, 'taxes_fees'), value: taxes, isArabic: isArabic),
                    const Divider(height: 24),
                    _PriceRow(
                      label: AppStrings.t(isArabic, 'total_price'),
                      value: total,
                      isArabic: isArabic,
                      isTotal: true,
                    ),
                    const SizedBox(height: AppDimens.xl),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppDimens.pagePadding),
            decoration: BoxDecoration(color: AppColors.surface, boxShadow: AppColors.cardShadow),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: AppDimens.buttonHeight,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _confirmBooking,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        )
                      : Text(AppStrings.t(isArabic, 'confirm_booking')),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoBox({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _StepperBox extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _StepperBox({required this.label, required this.value, required this.onMinus, required this.onPlus});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.sm, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          IconButton(
            onPressed: onMinus,
            icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Text('$value', style: Theme.of(context).textTheme.titleSmall),
          IconButton(
            onPressed: onPlus,
            icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentOption({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink.withOpacity(0.04) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: selected ? AppColors.ink : AppColors.cardBorder, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppColors.ink : AppColors.textMuted),
            const SizedBox(width: AppDimens.sm),
            Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: selected ? AppColors.ink : AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isArabic;
  final bool isTotal;

  const _PriceRow({required this.label, required this.value, required this.isArabic, this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    final style = isTotal
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('${value.toInt()} ${AppStrings.t(isArabic, "sar")}',
              style: isTotal ? style?.copyWith(color: AppColors.goldDark) : style),
        ],
      ),
    );
  }
}

class _MealOptionTile extends StatelessWidget {
  final String label;
  final String priceLabel;
  final bool selected;
  final VoidCallback onTap;

  const _MealOptionTile({required this.label, required this.priceLabel, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimens.sm),
        padding: const EdgeInsets.all(AppDimens.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold.withOpacity(0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: selected ? AppColors.gold : AppColors.cardBorder, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: selected ? AppColors.goldDark : AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(width: AppDimens.sm),
            Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
            Text(priceLabel, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.goldDark, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
