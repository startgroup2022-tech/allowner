import '../utils/safe_parse.dart';

/// فندق / عقار — يبني من استجابات `/api/hotels/list.php` و `/api/hotels/detail.php`.
///
/// كل الحقول الرقمية تُقرأ عبر `asInt`/`asDouble` لأن السيرفر يعيد أعمدة
/// DECIMAL/INT أحيانًا كأرقام وأحيانًا كنصوص.
class HotelModel {
  final String id;
  final String name;
  final String cityAr;
  final String cityEn;
  final String typeAr;
  final String typeEn;
  final double rating;
  final int reviewsCount;
  final double pricePerNight;
  final int stars;
  final String imageUrl;
  final List<String> galleryUrls;
  final bool freeCancellation;
  final bool breakfastIncluded;
  final bool isFavorite;
  final bool isFeatured;
  final double? extraBedPrice;
  final String descriptionAr;
  final String descriptionEn;
  final String? address;

  HotelModel({
    required this.id,
    required this.name,
    required this.cityAr,
    required this.cityEn,
    required this.typeAr,
    required this.typeEn,
    required this.rating,
    required this.reviewsCount,
    required this.pricePerNight,
    required this.stars,
    required this.imageUrl,
    this.galleryUrls = const [],
    this.freeCancellation = true,
    this.breakfastIncluded = false,
    this.isFavorite = false,
    this.isFeatured = false,
    this.extraBedPrice,
    this.descriptionAr = '',
    this.descriptionEn = '',
    this.address,
  });

  /// يبني الموديل من استجابة الـ API الحقيقية (/api/hotels/list.php و detail.php)
  factory HotelModel.fromJson(
    Map<String, dynamic> json, {
    List<String>? gallery,
    bool isFavorite = false,
  }) {
    final cover = asString(json['cover_image']);
    final resolvedGallery = gallery ?? asStringList(json['gallery']);
    return HotelModel(
      id: asString(json['id']),
      name: asString(json['name']),
      cityAr: asString(json['city_ar']),
      cityEn: asString(json['city_en']),
      typeAr: asString(json['type_ar']),
      typeEn: asString(json['type_en']),
      rating: asDouble(json['rating']),
      reviewsCount: asInt(json['reviews_count']),
      pricePerNight: asDouble(json['price_per_night']),
      stars: asInt(json['stars']),
      imageUrl: cover,
      galleryUrls: resolvedGallery.isNotEmpty
          ? resolvedGallery
          : (cover.isEmpty ? const [] : [cover]),
      freeCancellation: asBool(json['free_cancellation'], true),
      breakfastIncluded: asBool(json['breakfast_included']),
      isFavorite: isFavorite,
      isFeatured: asBool(json['is_featured']),
      extraBedPrice: asDoubleOrNull(json['extra_bed_price']),
      descriptionAr: asString(json['description_ar']),
      descriptionEn: asString(json['description_en']),
      address: asStringOrNull(json['address']),
    );
  }

  HotelModel copyWith({bool? isFavorite}) {
    return HotelModel(
      id: id,
      name: name,
      cityAr: cityAr,
      cityEn: cityEn,
      typeAr: typeAr,
      typeEn: typeEn,
      rating: rating,
      reviewsCount: reviewsCount,
      pricePerNight: pricePerNight,
      stars: stars,
      imageUrl: imageUrl,
      galleryUrls: galleryUrls,
      freeCancellation: freeCancellation,
      breakfastIncluded: breakfastIncluded,
      isFavorite: isFavorite ?? this.isFavorite,
      isFeatured: isFeatured,
      extraBedPrice: extraBedPrice,
      descriptionAr: descriptionAr,
      descriptionEn: descriptionEn,
      address: address,
    );
  }

  String city(bool isArabic) {
    final preferred = isArabic ? cityAr : cityEn;
    if (preferred.isNotEmpty) return preferred;
    return isArabic ? cityEn : cityAr;
  }

  String type(bool isArabic) {
    final preferred = isArabic ? typeAr : typeEn;
    if (preferred.isNotEmpty) return preferred;
    return isArabic ? typeEn : typeAr;
  }

  /// وصف الفندق الحقيقي من الـ API. يُرجع نصًا فارغًا إذا لم تُدخل الإدارة وصفًا
  /// — الشاشة تعرض حالة "لا يوجد وصف" بدلًا من نص مُصاغ آليًا.
  String description(bool isArabic) {
    final preferred = isArabic ? descriptionAr : descriptionEn;
    if (preferred.isNotEmpty) return preferred;
    return (isArabic ? descriptionEn : descriptionAr);
  }

  String get heroTag => 'hotel_$id';
}
