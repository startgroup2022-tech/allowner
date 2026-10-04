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
  final double? extraBedPrice;

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
    this.extraBedPrice,
  });

  /// يبني الموديل من استجابة الـ API الحقيقية (/api/hotels/list.php و detail.php)
  factory HotelModel.fromJson(Map<String, dynamic> json, {List<String>? gallery, bool isFavorite = false}) {
    return HotelModel(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
      cityAr: json['city_ar']?.toString() ?? '',
      cityEn: json['city_en']?.toString() ?? '',
      typeAr: json['type_ar']?.toString() ?? '',
      typeEn: json['type_en']?.toString() ?? '',
      rating: double.tryParse(json['rating']?.toString() ?? '0') ?? 0,
      reviewsCount: int.tryParse(json['reviews_count']?.toString() ?? '0') ?? 0,
      pricePerNight: double.tryParse(json['price_per_night']?.toString() ?? '0') ?? 0,
      stars: int.tryParse(json['stars']?.toString() ?? '0') ?? 0,
      imageUrl: json['cover_image']?.toString() ?? '',
      galleryUrls: gallery ?? (json['cover_image'] != null ? [json['cover_image'].toString()] : const []),
      freeCancellation: json['free_cancellation'] == true || json['free_cancellation'] == 1,
      breakfastIncluded: json['breakfast_included'] == true || json['breakfast_included'] == 1,
      isFavorite: isFavorite,
      extraBedPrice: json['extra_bed_price'] == null ? null : double.tryParse(json['extra_bed_price'].toString()),
    );
  }

  HotelModel copyWith({bool? isFavorite}) {
    return HotelModel(
      id: id, name: name, cityAr: cityAr, cityEn: cityEn, typeAr: typeAr, typeEn: typeEn,
      rating: rating, reviewsCount: reviewsCount, pricePerNight: pricePerNight, stars: stars,
      imageUrl: imageUrl, galleryUrls: galleryUrls, freeCancellation: freeCancellation,
      breakfastIncluded: breakfastIncluded, isFavorite: isFavorite ?? this.isFavorite,
      extraBedPrice: extraBedPrice,
    );
  }

  String city(bool isArabic) => isArabic ? cityAr : cityEn;
  String type(bool isArabic) => isArabic ? typeAr : typeEn;

  /// @deprecated بيانات وهمية للاختبار فقط بدون اتصال إنترنت — الشاشات الفعلية تستخدم HotelService
  static List<HotelModel> demoList() => [
        HotelModel(
          id: '1',
          name: 'Ritz Carlton Riyadh',
          cityAr: 'الرياض',
          cityEn: 'Riyadh',
          typeAr: 'فندق',
          typeEn: 'Hotel',
          rating: 4.9,
          reviewsCount: 1284,
          pricePerNight: 1450,
          stars: 5,
          breakfastIncluded: true,
          imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',
          galleryUrls: [
            'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',
            'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800&q=80',
            'https://images.unsplash.com/photo-1564501049412-61c2a3083791?w=800&q=80',
          ],
        ),
        HotelModel(
          id: '2',
          name: 'Al Faisaliah Suites',
          cityAr: 'الرياض',
          cityEn: 'Riyadh',
          typeAr: 'شقق فندقية',
          typeEn: 'Apartments',
          rating: 4.6,
          reviewsCount: 542,
          pricePerNight: 620,
          stars: 4,
          imageUrl: 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=800&q=80',
          galleryUrls: [
            'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=800&q=80',
            'https://images.unsplash.com/photo-1560185007-5f0bb1866cab?w=800&q=80',
          ],
        ),
        HotelModel(
          id: '3',
          name: 'Jeddah Hilton Corniche',
          cityAr: 'جدة',
          cityEn: 'Jeddah',
          typeAr: 'فندق',
          typeEn: 'Hotel',
          rating: 4.7,
          reviewsCount: 980,
          pricePerNight: 890,
          stars: 5,
          breakfastIncluded: true,
          imageUrl: 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800&q=80',
          galleryUrls: [
            'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800&q=80',
            'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=800&q=80',
          ],
        ),
        HotelModel(
          id: '4',
          name: 'Boudl Al Khobar',
          cityAr: 'الخبر',
          cityEn: 'Al Khobar',
          typeAr: 'شقق فندقية',
          typeEn: 'Apartments',
          rating: 4.3,
          reviewsCount: 312,
          pricePerNight: 380,
          stars: 3,
          imageUrl: 'https://images.unsplash.com/photo-1560185127-6ed189bf02f4?w=800&q=80',
          galleryUrls: [
            'https://images.unsplash.com/photo-1560185127-6ed189bf02f4?w=800&q=80',
          ],
        ),
        HotelModel(
          id: '5',
          name: 'Shaza Makkah',
          cityAr: 'مكة المكرمة',
          cityEn: 'Makkah',
          typeAr: 'فندق',
          typeEn: 'Hotel',
          rating: 4.8,
          reviewsCount: 2150,
          pricePerNight: 1100,
          stars: 5,
          breakfastIncluded: true,
          imageUrl: 'https://images.unsplash.com/photo-1564501049412-61c2a3083791?w=800&q=80',
          galleryUrls: [
            'https://images.unsplash.com/photo-1564501049412-61c2a3083791?w=800&q=80',
            'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',
          ],
        ),
        HotelModel(
          id: '6',
          name: 'Narcissus Resort Abha',
          cityAr: 'أبها',
          cityEn: 'Abha',
          typeAr: 'منتجع',
          typeEn: 'Resort',
          rating: 4.5,
          reviewsCount: 198,
          pricePerNight: 720,
          stars: 4,
          imageUrl: 'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=800&q=80',
          galleryUrls: [
            'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=800&q=80',
            'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=800&q=80',
          ],
        ),
      ];
}
