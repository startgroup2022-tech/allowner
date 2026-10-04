import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';
import '../utils/app_strings.dart';
import '../utils/session_provider.dart';
import '../utils/locale_provider.dart';

/// أفتار قابل للتغيير — متاح لكل أنواع الحسابات (ضيف / مالك / وكيل / إدارة فندق)
class EditableAvatar extends ConsumerStatefulWidget {
  final String? avatarUrl;
  final double radius;

  const EditableAvatar({super.key, required this.avatarUrl, this.radius = 34});

  @override
  ConsumerState<EditableAvatar> createState() => _EditableAvatarState();
}

class _EditableAvatarState extends ConsumerState<EditableAvatar> {
  bool _uploading = false;

  Future<void> _pick(bool isArabic) async {
    final isCurrentlySet = widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(AppStrings.t(isArabic, 'choose_from_gallery')),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(AppStrings.t(isArabic, 'take_photo')),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            if (isCurrentlySet)
              ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                title: Text(AppStrings.t(isArabic, 'remove_photo'), style: TextStyle(color: AppColors.danger)),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
          ],
        ),
      ),
    );
    if (choice == null) return;

    if (choice == 'remove') {
      setState(() => _uploading = true);
      try {
        await ref.read(sessionProvider.notifier).updateAvatar(remove: true);
      } catch (_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.t(isArabic, 'avatar_update_failed'))));
      } finally {
        if (mounted) setState(() => _uploading = false);
      }
      return;
    }

    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() => _uploading = true);
    try {
      await ref.read(sessionProvider.notifier).updateAvatar(filePath: file.path);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.t(isArabic, 'avatar_update_failed'))));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    return GestureDetector(
      onTap: _uploading ? null : () => _pick(isArabic),
      child: Stack(
        children: [
          CircleAvatar(
            radius: widget.radius,
            backgroundColor: AppColors.surfaceMuted,
            backgroundImage: (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty) ? NetworkImage(widget.avatarUrl!) : null,
            child: (widget.avatarUrl == null || widget.avatarUrl!.isEmpty)
                ? Icon(Icons.person_rounded, size: widget.radius, color: AppColors.textMuted)
                : null,
          ),
          if (_uploading)
            Positioned.fill(
              child: CircleAvatar(
                radius: widget.radius,
                backgroundColor: Colors.black38,
                child: const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              ),
            ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
              child: const Icon(Icons.edit, size: 14, color: AppColors.textOnGold),
            ),
          ),
        ],
      ),
    );
  }
}
