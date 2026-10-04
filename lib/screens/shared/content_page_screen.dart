import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../services/content_service.dart';

/// صفحة محتوى عامة (من عنّا / سياسة الخصوصية / الشروط) — النص يُدار من لوحة تحكم
/// السي بانل (site_content) وليس ثابت بالتطبيق.
class ContentPageScreen extends ConsumerStatefulWidget {
  final String contentKey;
  final String titleKey;

  const ContentPageScreen({super.key, required this.contentKey, required this.titleKey});

  @override
  ConsumerState<ContentPageScreen> createState() => _ContentPageScreenState();
}

class _ContentPageScreenState extends ConsumerState<ContentPageScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ContentService().getContent(widget.contentKey);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(AppStrings.t(isArabic, widget.titleKey)),
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(AppStrings.t(isArabic, 'error_loading')));
            }
            final data = snapshot.data!;
            final body = isArabic ? (data['body_ar'] ?? '') : (data['body_en'] ?? '');
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.pagePadding),
              child: Text(body.toString(), style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.8)),
            );
          },
        ),
      ),
    );
  }
}
