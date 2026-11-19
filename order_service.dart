import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/units.dart';
import '../models/coupon.dart';
import '../providers/cart_provider.dart';

class OrderService {
  final _db = FirebaseFirestore.instance;

  /// بيحفظ الطلب ويخصم المخزون، ويرجّع رقم الطلب، مثلًا "#1001"
  Future<String> placeOrder({
    required String customerName,
    required String phone,
    required String address,
    double? lat,
    double? lng,
    String notes = '',
    required String paymentMethod,
    required List<CartItem> items,
    required double subtotal,
    required double deliveryFee,
    String? couponCode,
    String paymentRef = '',
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('لازم تسجل دخول الأول');
    }

    final counterRef = _db.collection('settings').doc('counters');
    final orderRef = _db.collection('orders').doc();
    final userRef = _db.collection('users').doc(uid);
    final productRefs =
        items.map((i) => _db.collection('products').doc(i.product.id)).toList();
    final code = couponCode == null ? '' : Coupon.normalize(couponCode);
    final couponRef = code.isEmpty ? null : _db.collection('coupons').doc(code);

    return _db.runTransaction<String>((tx) async {
      // ===== القراءة الأول (شرط في Firestore) =====
      final counterSnap = await tx.get(counterRef);
      final productSnaps = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final ref in productRefs) {
        productSnaps.add(await tx.get(ref));
      }
      final couponSnap = couponRef == null ? null : await tx.get(couponRef);

      // ===== نتأكد إن الكميات لسه متاحة =====
      for (var k = 0; k < items.length; k++) {
        final stock =
            ((productSnaps[k].data()?['stock'] ?? 0) as num).toDouble();
        if (stock + 1e-9 < items[k].amount) {
          throw Exception(
            'الكمية المتاحة من ${items[k].product.nameAr} بقت ${formatStock(items[k].product.unit, stock)} بس',
          );
        }
      }

      // ===== الكوبون (بنتأكد منه تاني وقت الطلب) =====
      var discount = 0.0;
      if (couponSnap != null) {
        if (!couponSnap.exists) throw Exception('كود الخصم مش صحيح');
        final coupon = Coupon.fromFirestore(couponSnap);
        final problem = coupon.problemFor(subtotal);
        if (problem != null) throw Exception(problem);
        discount = coupon.discountFor(subtotal);
      }

      // ===== الكتابة =====
      final last =
          ((counterSnap.data()?['lastOrderNumber'] ?? 1000) as num).toInt();
      final number = last + 1;
      tx.set(counterRef, {'lastOrderNumber': number}, SetOptions(merge: true));

      for (var k = 0; k < items.length; k++) {
        tx.update(productRefs[k], {
          'stock': FieldValue.increment(-items[k].amount),
        });
      }

      if (couponRef != null) {
        tx.update(couponRef, {'usedCount': FieldValue.increment(1)});
      }

      tx.set(orderRef, {
        'orderNumber': number,
        'userId': uid,
        'customerName': customerName,
        'phone': phone,
        'address': {'details': address, 'lat': lat, 'lng': lng},
        'notes': notes,
        'items': items
            .map((i) => {
                  'productId': i.product.id,
                  'name': i.product.nameAr,
                  'price': i.product.finalPrice,
                  'quantity': i.quantity,
                  'unit': i.product.unit,
                  'imageUrl': i.product.mainImage,
                })
            .toList(),
        'subtotal': subtotal,
        'discount': discount,
        'couponCode': code,
        'deliveryFee': deliveryFee,
        'total': subtotal - discount + deliveryFee,
        'paymentMethod': paymentMethod,
        'paymentStatus': 'pending',
        'paymentRef': paymentRef,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // نفتكر آخر عنوان وموقع عشان نملاهم للعميل المرة الجاية
      tx.set(
        userRef,
        {'lastAddress': address, 'lastLat': lat, 'lastLng': lng},
        SetOptions(merge: true),
      );

      return '#$number';
    });
  }

  /// العميل يلغي طلبه (مسموح بس طول ما الطلب لسه «جديد»).
  /// الكميات بترجع للمخزون لوحدها من عند المحل.
  Future<void> cancelMyOrder(String orderId) {
    return _db.collection('orders').doc(orderId).update({
      'status': 'cancelled',
      'cancelledBy': 'customer',
      'stockRestored': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
