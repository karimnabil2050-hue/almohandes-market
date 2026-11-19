import 'package:flutter/foundation.dart';
import '../core/units.dart';
import '../models/product.dart';

class CartItem {
  final Product product;
  int quantity; // عدد قطع، أو عدد أتمان الكيلو للحاجات اللي بالوزن

  CartItem({required this.product, this.quantity = 1});

  /// الكمية الحقيقية (قطع أو كيلوهات)
  double get amount => amountOf(product.unit, quantity);
  double get total => product.finalPrice * amount;

  /// "3" أو "ربع كيلو"
  String get qtyText => formatQty(product.unit, quantity);

  /// "× 3" أو "ربع كيلو"
  String get itemText => formatItemQty(product.unit, quantity);
}

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();
  bool get isEmpty => _items.isEmpty;

  /// الرقم اللي على أيقونة السلة (المنتج اللي بالوزن بيتحسب واحد)
  int get count => _items.values
      .fold(0, (sum, i) => sum + (i.product.weighted ? 1 : i.quantity));

  double get subtotal => _items.values.fold(0.0, (sum, i) => sum + i.total);
  int quantityOf(String productId) => _items[productId]?.quantity ?? 0;

  /// بيزوّد قطعة واحدة أو تُمن كيلو. بترجع false لو الكمية خلصت
  bool add(Product product) => setQuantity(product, quantityOf(product.id) + 1);

  /// بيحط كمية معينة. بترجع false لو أكتر من المتاح
  bool setQuantity(Product product, int qty) {
    if (qty <= 0) {
      remove(product.id);
      return true;
    }
    if (qty > product.maxQty) return false;
    final item = _items[product.id];
    if (item == null) {
      _items[product.id] = CartItem(product: product, quantity: qty);
    } else {
      item.quantity = qty;
    }
    notifyListeners();
    return true;
  }

  void decrease(String productId) {
    final item = _items[productId];
    if (item == null) return;
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void remove(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
