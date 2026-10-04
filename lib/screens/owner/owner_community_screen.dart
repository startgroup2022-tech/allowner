import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../services/owner_service.dart';
import '../../services/api_client.dart';

class OwnerCommunityScreen extends ConsumerStatefulWidget {
  const OwnerCommunityScreen({super.key});

  @override
  ConsumerState<OwnerCommunityScreen> createState() => _OwnerCommunityScreenState();
}

class _OwnerCommunityScreenState extends ConsumerState<OwnerCommunityScreen> {
  final _service = OwnerService();
  late Future<List<Map<String, dynamic>>> _future;
  final _postCtrl = TextEditingController();
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _future = _service.getCommunityPosts();
  }

  void _reload() => setState(() => _future = _service.getCommunityPosts());

  Future<void> _submitPost(bool isArabic) async {
    final text = _postCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _posting = true);
    try {
      await _service.createCommunityPost(text);
      _postCtrl.clear();
      _reload();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _toggleLike(Map<String, dynamic> post) async {
    try {
      await _service.toggleCommunityLike(post['id'] as int);
      _reload();
    } on ApiException catch (_) {}
  }

  Future<void> _openComments(bool isArabic, Map<String, dynamic> post) async {
    final commentCtrl = TextEditingController();
    List<Map<String, dynamic>> comments = [];
    try {
      comments = await _service.getPostComments(post['id'] as int);
    } catch (_) {}
    if (!mounted) return;

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
            builder: (ctx, setSheetState) => SizedBox(
              height: 420,
              child: Column(
                children: [
                  Text(AppStrings.t(isArabic, 'comments'), style: Theme.of(ctx).textTheme.titleMedium),
                  const SizedBox(height: AppDimens.sm),
                  Expanded(
                    child: comments.isEmpty
                        ? Center(child: Text(AppStrings.t(isArabic, 'no_data')))
                        : ListView.builder(
                            itemCount: comments.length,
                            itemBuilder: (context, i) {
                              final c = comments[i];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: RichText(
                                  text: TextSpan(
                                    style: DefaultTextStyle.of(context).style,
                                    children: [
                                      TextSpan(text: '${c['full_name']}: ', style: const TextStyle(fontWeight: FontWeight.w700)),
                                      TextSpan(text: c['content'].toString()),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentCtrl,
                          decoration: InputDecoration(hintText: AppStrings.t(isArabic, 'write_comment')),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send_rounded, color: AppColors.goldDark),
                        onPressed: () async {
                          final text = commentCtrl.text.trim();
                          if (text.isEmpty) return;
                          try {
                            await _service.addComment(post['id'] as int, text);
                            commentCtrl.clear();
                            final refreshed = await _service.getPostComments(post['id'] as int);
                            setSheetState(() => comments = refreshed);
                            _reload();
                          } catch (_) {}
                        },
                      ),
                    ],
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
        title: Text(AppStrings.t(isArabic, 'owners_community')),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _reload(),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _future,
            builder: (context, snapshot) {
              final posts = snapshot.data ?? [];
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppDimens.pagePadding),
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimens.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _postCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(hintText: AppStrings.t(isArabic, 'write_post')),
                        ),
                        const SizedBox(height: AppDimens.sm),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ElevatedButton(
                            onPressed: _posting ? null : () => _submitPost(isArabic),
                            child: Text(AppStrings.t(isArabic, 'post')),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimens.lg),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppDimens.xl),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (posts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppDimens.xl),
                      child: Center(child: Text(AppStrings.t(isArabic, 'no_posts'))),
                    )
                  else
                    ...posts.map((p) => Container(
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
                                  CircleAvatar(
                                    backgroundColor: AppColors.gold.withOpacity(0.2),
                                    child: Text((p['full_name'] ?? '?').toString().substring(0, 1),
                                        style: const TextStyle(color: AppColors.goldDark, fontWeight: FontWeight.w700)),
                                  ),
                                  const SizedBox(width: AppDimens.sm),
                                  Expanded(
                                    child: Text(p['full_name'].toString(), style: textTheme.titleSmall),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppDimens.sm),
                              Text(p['content'].toString(), style: textTheme.bodyMedium),
                              if (p['image_url'] != null) ...[
                                const SizedBox(height: AppDimens.sm),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                                  child: Image.network(p['image_url'].toString(), fit: BoxFit.cover),
                                ),
                              ],
                              const SizedBox(height: AppDimens.sm),
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _toggleLike(p),
                                    icon: Icon(
                                      p['liked_by_me'] == true ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                                      size: 18,
                                      color: p['liked_by_me'] == true ? AppColors.goldDark : AppColors.textMuted,
                                    ),
                                    label: Text('${p['like_count']}'),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _openComments(isArabic, p),
                                    icon: const Icon(Icons.mode_comment_outlined, size: 18, color: AppColors.textMuted),
                                    label: Text('${p['comment_count']}'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
