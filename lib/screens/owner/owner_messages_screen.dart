import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../services/owner_service.dart';
import '../../services/api_client.dart';
import 'owner_chat_thread_screen.dart';

class OwnerMessagesScreen extends ConsumerStatefulWidget {
  const OwnerMessagesScreen({super.key});

  @override
  ConsumerState<OwnerMessagesScreen> createState() => _OwnerMessagesScreenState();
}

class _OwnerMessagesScreenState extends ConsumerState<OwnerMessagesScreen> {
  final _service = OwnerService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getConversations();
  }

  void _reload() => setState(() => _future = _service.getConversations());

  Future<void> _openNewMessageSheet(bool isArabic) async {
    List<Map<String, dynamic>> owners = [];
    try {
      owners = await _service.getOwnerDirectory();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (!mounted) return;

    final msgCtrl = TextEditingController();
    int? selectedId;

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
                  Text(AppStrings.t(isArabic, 'new_message'), style: Theme.of(ctx).textTheme.titleMedium),
                  const SizedBox(height: AppDimens.md),
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(labelText: AppStrings.t(isArabic, 'select_recipient')),
                    items: owners
                        .map((o) => DropdownMenuItem<int>(value: o['id'] as int, child: Text(o['full_name'].toString())))
                        .toList(),
                    onChanged: (v) => setSheetState(() => selectedId = v),
                  ),
                  const SizedBox(height: AppDimens.md),
                  TextField(controller: msgCtrl, maxLines: 3, decoration: InputDecoration(hintText: AppStrings.t(isArabic, 'type_message'))),
                  const SizedBox(height: AppDimens.lg),
                  SizedBox(
                    width: double.infinity,
                    height: AppDimens.buttonHeight,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (selectedId == null || msgCtrl.text.trim().isEmpty) return;
                        try {
                          await _service.sendMessage(recipientId: selectedId, body: msgCtrl.text.trim());
                          if (ctx.mounted) Navigator.of(ctx).pop();
                          _reload();
                        } on ApiException catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                        }
                      },
                      child: Text(AppStrings.t(isArabic, 'send')),
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

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(AppStrings.t(isArabic, 'messages')),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        onPressed: () => _openNewMessageSheet(isArabic),
        child: const Icon(Icons.edit_outlined, color: AppColors.textOnGold),
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

              final conversations = snapshot.data ?? [];
              if (conversations.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppDimens.xl),
                      child: Center(child: Text(AppStrings.t(isArabic, 'no_conversations'))),
                    ),
                  ],
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: AppDimens.sm),
                itemCount: conversations.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.cardBorder),
                itemBuilder: (context, index) {
                  final c = conversations[index];
                  final unread = (c['unread_count'] as num?)?.toInt() ?? 0;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.gold.withOpacity(0.2),
                      child: Text((c['other_name'] ?? '?').toString().substring(0, 1),
                          style: const TextStyle(color: AppColors.goldDark, fontWeight: FontWeight.w700)),
                    ),
                    title: Text(c['other_name'].toString(), style: textTheme.titleSmall),
                    subtitle: Text(
                      (c['last_body'] ?? '').toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                    ),
                    trailing: unread > 0
                        ? CircleAvatar(radius: 10, backgroundColor: AppColors.gold, child: Text('$unread', style: const TextStyle(fontSize: 10, color: AppColors.textOnGold)))
                        : null,
                    onTap: () async {
                      await Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => OwnerChatThreadScreen(conversationId: c['id'] as int, otherName: c['other_name'].toString()),
                      ));
                      _reload();
                    },
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
