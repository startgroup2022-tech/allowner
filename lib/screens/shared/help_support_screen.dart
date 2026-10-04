import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../services/content_service.dart';

class HelpSupportScreen extends ConsumerStatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  ConsumerState<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends ConsumerState<HelpSupportScreen> {
  final _service = ContentService();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getSettings();
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _digitsOnly(String s) => s.replaceAll(RegExp(r'[^0-9+]'), '');

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(AppStrings.t(isArabic, 'help_support')),
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data ?? {};
            final phone = (data['contact_phone'] ?? '').toString();
            final whatsapp = (data['whatsapp'] ?? phone).toString();
            final email = (data['contact_email'] ?? '').toString();

            return ListView(
              padding: const EdgeInsets.all(AppDimens.pagePadding),
              children: [
                Text(AppStrings.t(isArabic, 'help_support_intro'),
                    style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: AppDimens.lg),
                if (whatsapp.isNotEmpty)
                  _ContactTile(
                    icon: Icons.chat_bubble_outline_rounded,
                    color: AppColors.success,
                    title: AppStrings.t(isArabic, 'contact_whatsapp'),
                    subtitle: whatsapp,
                    onTap: () => _launch('https://wa.me/${_digitsOnly(whatsapp).replaceAll('+', '')}'),
                  ),
                if (phone.isNotEmpty)
                  _ContactTile(
                    icon: Icons.call_outlined,
                    color: AppColors.secondary,
                    title: AppStrings.t(isArabic, 'contact_call'),
                    subtitle: phone,
                    onTap: () => _launch('tel:${_digitsOnly(phone)}'),
                  ),
                if (email.isNotEmpty)
                  _ContactTile(
                    icon: Icons.email_outlined,
                    color: AppColors.goldDark,
                    title: AppStrings.t(isArabic, 'contact_email'),
                    subtitle: email,
                    onTap: () => _launch('mailto:$email'),
                  ),
                if (phone.isEmpty && email.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppDimens.xl),
                    child: Center(child: Text(AppStrings.t(isArabic, 'error_loading'))),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactTile({required this.icon, required this.color, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
        title: Text(title, style: Theme.of(context).textTheme.titleSmall),
        subtitle: Text(subtitle, textDirection: TextDirection.ltr),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
