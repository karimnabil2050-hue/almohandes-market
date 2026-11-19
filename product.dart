import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/units.dart';

class Product {
  final String id;
  final String nameAr;
  final String nameEn;
  final String description;
  final String brand;
  final String categoryId;
  final String subcategoryId;
  final double price; // للمنتجات اللي بالوزن: سعر الكيلو
  final double? discountPrice;
  final String unit; // piece | kg | pack
  final double stock; // للمنتجات اللي بالوزن: بالكيلو (ممكن 2.5)
  final List<String> images;
  final bool isActive;
  final bool isFeatured;

  Product({
    required this.id,
    required this.nameAr,
    this.nameEn = '',
    this.description = '',
    this.brand = '',
    required this.categoryId,
    this.subcategoryId = '',
    required this.price,
    this.discountPrice,
    this.unit = 'piece',
    this.stock = 0,
    this.images = const [],
    this.isActive = true,
    this.isFeatured = false,
  });

  // السعر اللي العميل هيدفعه فعلًا (للقطعة أو للكيلو)
  double get finalPrice => discountPrice ?? price;
  bool get hasDiscount => discountPrice != null && discountPrice! < price;
  String get mainImage => images.isNotEmpty ? images.first : '';

  bool get weighted => unitIsWeighted(unit);

  /// أقصى كمية ممكن تتطلب: عدد قطع، أو عدد أتمان كيلو
  int get maxQty =>
      weighted ? (stock / kgStep + 1e-9).floor() : stock.floor();

  bool get inStock => maxQty > 0;

  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Product(
      id: doc.id,
      nameAr: data['nameAr'] ?? '',
      nameEn: data['nameEn'] ?? '',
      description: data['description'] ?? '',
      brand: data['brand'] ?? '',
      categoryId: data['categoryId'] ?? '',
      subcategoryId: data['subcategoryId'] ?? '',
      price: ((data['price'] ?? 0) as num).toDouble(),
      discountPrice: data['discountPrice'] == null
          ? null
          : (data['discountPrice'] as num).toDouble(),
      unit: data['unit'] ?? 'piece',
      stock: ((data['stock'] ?? 0) as num).toDouble(),
      images: List<String>.from(data['images'] ?? []),
      isActive: data['isActive'] ?? true,
      isFeatured: data['isFeatured'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'nameAr': nameAr,
        'nameEn': nameEn,
        'description': description,
        'brand': brand,
        'categoryId': categoryId,
        'subcategoryId': subcategoryId,
        'price': price,
        'discountPrice': discountPrice,
        'unit': unit,
        'stock': stock,
        'images': images,
        'isActive': isActive,
        'isFeatured': isFeatured,
        'searchKeywords': nameAr.split(' ') + nameEn.toLowerCase().split(' '),
      };
}
