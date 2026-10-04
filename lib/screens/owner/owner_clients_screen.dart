import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../utils/safe_parse.dart';
import '../../services/owner_service.dart';
import '../../services/api_client.dart';
import '../search/search_screen.dart';

/// عملاء الوكيل / مندوب التسويق — بيانات حقيقية من قاعدة البيانات:
/// إضافة عميل، عرض عملائه مع عدد حجوزاتهم وإجمالي المبالغ، وتفاصيل كل حجز وعمولته.
class OwnerClientsScreen extends ConsumerStatefulWidget {
  const OwnerClientsScreen({super.key});

  @override
  ConsumerState<OwnerClientsScreen> createState() => _OwnerClientsScreenState();
}

class _OwnerClientsScreenState extends ConsumerState<OwnerClientsScreen> {
  final _service = OwnerService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getAgentClients();
  }

  void _reload() => setState(() => _future = _service.getAgentClients());

  Future<void> _openEditor(bool isArabic, {Map<String, dynamic>? existing}) async {
    final nameCtrl = TextEditingController(text: existing?['full_name']?.toString() ?? '');
    final phoneCtrl = TextEditingController(text: existing?['phone']?.toString() ?? '');
    final emailCtrl = TextEditingController(text: existing?['email']?.toString() ?? '');
    final idCtrl = TextEditingController(text: existing?['id_number']?.toString() ?? '');
    final notesCtrl = TextEditingController(text: existing?['notes']?.toString() ?? '');
    String? error;
    bool saving = false;

    await showModalBottomSheet(
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
          builder: (ctx, setSheet) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.t(isArabic, existing == null ? 'add_client' : 'edit_client'), style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: AppDimens.md),
                TextField(controller: nameCtrl, decoration: InputDecoration(labelText: AppStrings.t(isArabic, 'customer_name'))),
                const SizedBox(height: AppDimens.md),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: AppStrings.t(isArabic, 'customer_phone')),
                ),
                const SizedBox(height: AppDimens.md),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: AppStrings.t(isArabic, 'client_email_optional')),
                ),
                const SizedBox(height: AppDimens.md),
                TextField(controller: idCtrl, decoration: InputDecoration(labelText: AppStrings.t(isArabic, 'guest_id_number'))),
                const SizedBox(height: AppDimens.md),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: AppStrings.t(isArabic, 'notes')),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppDimens.sm),
                    child: Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                  ),
                const SizedBox(height: AppDimens.lg),
                SizedBox(
                  width: double.infinity,
                  height: AppDimens.buttonHeight,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().length < 7) {
                              setSheet(() => error = AppStrings.t(isArabic, 'customer_name_phone_required'));
                              return;
                            }
                            setSheet(() {
                              saving = true;
                              error = null;
                            });
                            try {
                              await _service.saveAgentClient(
                                id: existing?['id'] as int?,
                                fullName: nameCtrl.text.trim(),
                                phone: phoneCtrl.text.trim(),
                                email: emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
                                idNumber: idCtrl.text.trim().isNotEmpty ? idCtrl.text.trim() : null,
                                notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                              );
                              if (ctx.mounted) Navigator.of(ctx).pop();
                              _reload();
                            } on ApiException catch (e) {
                              setSheet(() {
                                saving = false;
                                error = e.message;
                              });
                            }
                          },
                    child: Text(AppStrings.t(isArabic, 'save_changes')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(bool isArabic, int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.t(isArabic, 'confirm_delete_client')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.t(isArabic, 'cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStrings.t(isArabic, 'confirm'), style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.deleteAgentClient(id);
      _reload();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
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
        title: Text(AppStrings.t(isArabic, 'my_clients')),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        onPressed: () => _openEditor(isArabic),
        child: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.textOnGold),
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
                    Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 32),
                    const SizedBox(height: AppDimens.sm),
                    Text(AppStrings.t(isArabic, 'error_loading'), textAlign: TextAlign.center),
                    const SizedBox(height: AppDimens.sm),
                    Center(child: OutlinedButton(onPressed: _reload, child: Text(AppStrings.t(isArabic, 'retry')))),
                  ],
                );
              }
              final clients = snapshot.data ?? [];
              if (clients.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppDimens.xl),
                      child: Center(child: Text(AppStrings.t(isArabic, 'no_clients_yet'), textAlign: TextAlign.center)),
                    ),
                  ],
                );
              }
              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(AppDimens.pagePadding, AppDimens.pagePadding, AppDimens.pagePadding, 90),
                itemCount: clients.length,
                separatorBuilder: (context, index) => const SizedBox(height: AppDimens.md),
                itemBuilder: (context, index) {
                  final c = clients[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => _ClientDetailScreen(clientId: c['id'] as int)))
                        .then((_) => _reload()),
                    child: Container(
                      padding: const EdgeInsets.all(AppDimens.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.gold.withOpacity(0.15),
                            child: const Icon(Icons.person_rounded, color: AppColors.goldDark),
                          ),
                          const SizedBox(width: AppDimens.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c['full_name']?.toString() ?? '', style: textTheme.titleSmall),
                                Text(c['phone']?.toString() ?? '',
                                    textDirection: TextDirection.ltr,
                                    style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                                const SizedBox(height: 4),
                                Text(
                                  '${asInt(c['bookings_count'])} ${AppStrings.t(isArabic, 'bookings_word')} · ${asDouble(c['total_spent']).toStringAsFixed(0)} ${AppStrings.t(isArabic, 'sar')}',
                                  style: textTheme.bodySmall?.copyWith(color: AppColors.goldDark, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'edit') _openEditor(isArabic, existing: c);
                              if (v == 'delete') _delete(isArabic, c['id'] as int);
                              if (v == 'book') {
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen(initialQuery: '')));
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(value: 'book', child: Text(AppStrings.t(isArabic, 'book_for_client'))),
                              PopupMenuItem(value: 'edit', child: Text(AppStrings.t(isArabic, 'edit_client'))),
                              PopupMenuItem(value: 'delete', child: Text(AppStrings.t(isArabic, 'delete'))),
                            ],
                          ),
                        ],
                      ),
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

/// تفاصيل عميل: بياناته + كل حجوزاته (الحالة، المبلغ، العمولة)
class _ClientDetailScreen extends ConsumerStatefulWidget {
  final int clientId;
  const _ClientDetailScreen({required this.clientId});

  @override
  ConsumerState<_ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<_ClientDetailScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = OwnerService().getAgentClientDetail(widget.clientId);
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'confirmed':
      case 'completed':
      case 'checked_in':
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
      appBar: AppBar(backgroundColor: AppColors.surface, elevation: 0, title: Text(AppStrings.t(isArabic, 'client_details'))),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text(AppStrings.t(isArabic, 'error_loading')));
            final client = snapshot.data!['client'] as Map<String, dynamic>;
            final bookings = (snapshot.data!['bookings'] as List).cast<Map<String, dynamic>>();

            return ListView(
              padding: const EdgeInsets.all(AppDimens.pagePadding),
              children: [
                Text(client['full_name']?.toString() ?? '', style: textTheme.headlineSmall),
                Text(client['phone']?.toString() ?? '', textDirection: TextDirection.ltr, style: textTheme.bodyMedium),
                if ((client['email'] ?? '').toString().isNotEmpty) Text(client['email'].toString(), style: textTheme.bodySmall),
                if ((client['notes'] ?? '').toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(client['notes'].toString(), style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                  ),
                const SizedBox(height: AppDimens.lg),
                Text(AppStrings.t(isArabic, 'client_bookings'), style: textTheme.titleMedium),
                const SizedBox(height: AppDimens.sm),
                if (bookings.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppDimens.lg),
                    child: Center(child: Text(AppStrings.t(isArabic, 'no_bookings'))),
                  ),
                ...bookings.map((b) {
                  final status = (b['status'] ?? 'pending').toString();
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppDimens.md),
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
                            Expanded(child: Text('#${b['booking_ref']} · ${b['hotel_name'] ?? ''}', style: textTheme.titleSmall)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusColor(status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                              ),
                              child: Text(AppStrings.t(isArabic, 'status_$status'),
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(status))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('${b['check_in']} → ${b['check_out']} (${asInt(b['nights'])} ${AppStrings.t(isArabic, 'nights')})', style: textTheme.bodySmall),
                        const SizedBox(height: 4),
                        Text('${AppStrings.t(isArabic, 'total')}: ${asDouble(b['total']).toStringAsFixed(0)} ${AppStrings.t(isArabic, 'sar')}',
                            style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                        if (b['commission_amount'] != null)
                          Text(
                            '${AppStrings.t(isArabic, 'my_commission')}: ${asDouble(b['commission_amount']).toStringAsFixed(0)} ${AppStrings.t(isArabic, 'sar')} (${AppStrings.t(isArabic, b['commission_status'] == 'paid' ? 'commission_paid' : 'commission_unpaid')})',
                            style: textTheme.bodySmall?.copyWith(color: AppColors.goldDark, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}
