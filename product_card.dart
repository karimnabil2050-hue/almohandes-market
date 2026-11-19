import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/units.dart';

import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/favorites_provider.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final String emoji;
  final VoidCallback? onAdd;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.emoji,
    this.onAdd,
    this.onTap,
  });

  int get _discountPercent =>
      ((1 - product.finalPrice / product.price) * 100).round();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // الصورة
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: product.mainImage.isEmpty
                        ? Text(emoji, style: const TextStyle(fontSize: 48))
                        : Image.network(product.mainImage, fit: BoxFit.contain),
                  ),
                  if (product.hasDiscount)
                    PositionedDirectional(
                      top: 6,
                      start: 6,
                      child: _Badge(
                        text: 'خصم $_discountPercent%',
                        color: AppColors.accent,
                      ),
                    ),
                  PositionedDirectional(
                    bottom: 4,
                    end: 4,
                    child: FavoriteButton(productId: product.id, size: 18),
                  ),
                  if (!product.inStock)
                    const PositionedDirectional(
                      top: 6,
                      end: 6,
                      child: _Badge(text: 'نفذت الكمية', color: Colors.grey),
                    )
                  else if (product.weighted)
                    const PositionedDirectional(
                      top: 6,
                      end: 6,
                      child: _Badge(
                        text: '⚖️ بالوزن',
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // الاسم
            Text(
              product.nameAr,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            Text(
              unitPriceLabel(product.unit),
              style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
            ),
            const SizedBox(height: 4),
            // السعر وزرار الإضافة
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${product.finalPrice.toStringAsFixed(0)} ج.م',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      if (product.hasDiscount)
                        Text(
                          '${product.price.toStringAsFixed(0)} ج.م',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textGrey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: product.inStock ? onAdd : null,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: product.inStock
                          ? AppColors.primary
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// زرار القلب ❤️ للمفضلة
class FavoriteButton extends StatelessWidget {
  final String productId;
  final double size;
  const FavoriteButton({super.key, required this.productId, this.size = 22});

  @override
  Widget build(BuildContext context) {
    final fav = context.watch<FavoritesProvider>();
    final on = fav.isFavorite(productId);
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => fav.toggle(productId),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            on ? Icons.favorite : Icons.favorite_border,
            color: on ? Colors.red : Colors.grey,
            size: size,
          ),
        ),
      ),
    );
  }
}
