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
import '../hotel/hotel_details_screen.dart';
import '../auth/login_screen.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  final HotelService _hotelService = HotelService();
  List<HotelModel> _favorites = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (!ref.read(sessionProvider).isLoggedIn) {
      setState(() {
        _isLoading = false;
        _favorites = [];
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final favorites = await _hotelService.myFavorites();
      if (!mounted) return;
      setState(() {
        _favorites = favorites;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFavorite(HotelModel hotel) async {
    try {
      await _hotelService.toggleFavorite(hotel.id);
      setState(() => _favorites.removeWhere((h) => h.id == hotel.id));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final isLoggedIn = ref.watch(sessionProvider).isLoggedIn;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(AppStrings.t(isArabic, 'favorites'))),
      body: SafeArea(
        child: !isLoggedIn
            ? _EmptyState(
                icon: Icons.lock_outline_rounded,
                message: isArabic ? 'سجّل الدخول لعرض المفضلة' : 'Log in to view your favorites',
                actionLabel: AppStrings.t(isArabic, 'login'),
                onAction: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ).then((_) => _loadFavorites()),
              )
            : _isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.gold))
                : _error != null
                    ? _EmptyState(
                        icon: Icons.error_outline_rounded,
                        message: _error!,
                        actionLabel: isArabic ? 'إعادة المحاولة' : 'Retry',
                        onAction: _loadFavorites,
                      )
                    : _favorites.isEmpty
                        ? _EmptyState(
                            icon: Icons.favorite_border_rounded,
                            message: AppStrings.t(isArabic, 'no_favorites_yet'),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadFavorites,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(AppDimens.pagePadding),
                              itemCount: _favorites.length,
                              itemBuilder: (context, index) {
                                final hotel = _favorites[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: AppDimens.md),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.of(context)
                                          .push(MaterialPageRoute(builder: (_) => HotelDetailsScreen(hotel: hotel)))
                                          .then((_) => _loadFavorites());
                                    },
                                    borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                                    child: Container(
                                      padding: const EdgeInsets.all(AppDimens.sm),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                                        border: Border.all(color: AppColors.cardBorder),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 80,
                                            height: 80,
                                            clipBehavior: Clip.antiAlias,
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceMuted,
                                              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                                            ),
                                            child: CachedNetworkImage(
                                              imageUrl: hotel.imageUrl,
                                              fit: BoxFit.cover,
                                              errorWidget: (context, url, error) =>
                                                  Icon(Icons.image_outlined, color: AppColors.textMuted),
                                            ),
                                          ),
                                          const SizedBox(width: AppDimens.sm),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(hotel.name, style: Theme.of(context).textTheme.titleSmall),
                                                Text(hotel.city(isArabic),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(color: AppColors.textMuted)),
                                                const SizedBox(height: 4),
                                                Text(
                                                    '${hotel.pricePerNight.toInt()} ${AppStrings.t(isArabic, "sar")} ${AppStrings.t(isArabic, "per_night")}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleSmall
                                                        ?.copyWith(color: AppColors.goldDark)),
                                              ],
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () => _removeFavorite(hotel),
                                            borderRadius: BorderRadius.circular(20),
                                            child: const Padding(
                                              padding: EdgeInsets.all(6),
                                              child: Icon(Icons.favorite_rounded, color: AppColors.danger),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({required this.icon, required this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: AppColors.textMuted),
          const SizedBox(height: AppDimens.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.pagePadding),
            child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppDimens.md),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
