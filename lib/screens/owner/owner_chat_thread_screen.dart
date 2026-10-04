import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../utils/session_provider.dart';
import '../../services/owner_service.dart';
import '../../services/api_client.dart';

class OwnerChatThreadScreen extends ConsumerStatefulWidget {
  final int conversationId;
  final String otherName;

  const OwnerChatThreadScreen({super.key, required this.conversationId, required this.otherName});

  @override
  ConsumerState<OwnerChatThreadScreen> createState() => _OwnerChatThreadScreenState();
}

class _OwnerChatThreadScreenState extends ConsumerState<OwnerChatThreadScreen> {
  final _service = OwnerService();
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late Future<List<Map<String, dynamic>>> _future;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _future = _service.getThread(widget.conversationId);
  }

  void _reload() {
    setState(() => _future = _service.getThread(widget.conversationId));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
    });
  }

  Future<void> _send(bool isArabic) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await _service.sendMessage(conversationId: widget.conversationId, body: text);
      _msgCtrl.clear();
      _reload();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final myId = ref.watch(sessionProvider).user?.id;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(widget.otherName),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final messages = snapshot.data ?? [];
                  if (messages.isEmpty) {
                    return Center(child: Text(AppStrings.t(isArabic, 'no_data')));
                  }
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
                  });
                  return ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(AppDimens.pagePadding),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final m = messages[index];
                      final isMine = m['sender_id'].toString() == myId.toString();
                      return Align(
                        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: AppDimens.sm),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                          decoration: BoxDecoration(
                            color: isMine ? AppColors.gold.withOpacity(0.18) : AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                          ),
                          child: Text(m['body'].toString(), style: textTheme.bodyMedium),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppDimens.sm),
              decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.cardBorder))),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      decoration: InputDecoration(hintText: AppStrings.t(isArabic, 'type_message')),
                      onSubmitted: (_) => _send(isArabic),
                    ),
                  ),
                  IconButton(
                    icon: _sending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send_rounded, color: AppColors.goldDark),
                    onPressed: _sending ? null : () => _send(isArabic),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
