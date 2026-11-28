import 'hotel_model.dart';
import 'unit_model.dart';

/// ملخّص فندق يحتوي على وحدات ملاك — يُبنى من دمج وحدات المالك الحقيقية
/// (`units/browse.php?owner_only=1`) مع بيانات الفندق (`hotels/list.php`).
///
/// هذا هو نموذج قسم «فنادق بوحدات ملاك» في الصفحة الرئيسية (المتطلب 21–22):
/// البطاقة تعرض اسم الفندق، المدينة، عدد الوحدات المتاحة، والتقييم — كلها من
/// بيانات الـ API الفعلية، ولا يوجد أي رقم مكتوب في الواجهة.
class OwnerHotelSummary {
  final String hotelId;
  final String name;
  final String cityAr;
  final String cityEn;
  final int unitCount;
  final double rating;
  final int reviewsCount;
  final String imageUrl;
  final double minPrice;
  final HotelModel? hotel;

  const OwnerHotelSummary({
    required this.hotelId,
    required this.name,
    required this.cityAr,
    required this.cityEn,
    required this.unitCount,
    required this.rating,
    required this.reviewsCount,
    required this.imageUrl,
    required this.minPrice,
    this.hotel,
  });

  /// يبني ملخّصات الفنادق من وحدات المالك، ويُثريها ببيانات الفندق عند توفرها.
  ///
  /// الترتيب يحافظ على ترتيب الوحدات القادم من الـ API (الأحدث أولًا)، لأن
  /// `Map` في Dart يحافظ على ترتيب الإدخال.
  static List<OwnerHotelSummary> build(
    List<UnitModel> units,
    List<HotelModel> hotels,
  ) {
    final hotelById = <String, HotelModel>{
      for (final hotel in hotels) hotel.id: hotel,
    };
    final unitsByHotel = <String, List<UnitModel>>{};
    for (final unit in units) {
      unitsByHotel.putIfAbsent(unit.hotelId.toString(), () => []).add(unit);
    }

    return unitsByHotel.entries.map((entry) {
      final group = entry.value;
      final first = group.first;
      final hotel = hotelById[entry.key];
      return OwnerHotelSummary(
        hotelId: entry.key,
        name: (hotel?.name.isNotEmpty ?? false) ? hotel!.name : first.hotelName,
        cityAr:
            (hotel?.cityAr.isNotEmpty ?? false) ? hotel!.cityAr : first.cityAr,
        cityEn:
            (hotel?.cityEn.isNotEmpty ?? false) ? hotel!.cityEn : first.cityEn,
        unitCount: group.length,
        rating: hotel?.rating ?? 0,
        reviewsCount: hotel?.reviewsCount ?? 0,
        imageUrl: (hotel?.imageUrl.isNotEmpty ?? false)
            ? hotel!.imageUrl
            : first.coverImage,
        minPrice:
            group.map((u) => u.pricePerNight).reduce((a, b) => a < b ? a : b),
        hotel: hotel,
      );
    }).toList();
  }

  String city(bool isArabic) {
    final preferred = isArabic ? cityAr : cityEn;
    if (preferred.isNotEmpty) return preferred;
    return isArabic ? cityEn : cityAr;
  }
}
