import 'package:flutter/material.dart';
import 'package:shop/components/cart_button.dart';
import 'package:shop/components/custom_modal_bottom_sheet.dart';
import 'package:shop/screens/product/views/added_to_cart_message_screen.dart';
import '../../../constants.dart';
import 'components/product_quantity.dart';
import 'components/unit_price.dart';

class ProductBuyNowScreen extends StatefulWidget {
  final String serviceName;
  final double servicePrice;
  final String serviceImage;
  final int quantity;

  const ProductBuyNowScreen({
    super.key,
    required this.serviceName,
    required this.servicePrice,
    required this.serviceImage,
    required this.quantity,
  });

  @override
  _ProductBuyNowScreenState createState() => _ProductBuyNowScreenState();
}

class _ProductBuyNowScreenState extends State<ProductBuyNowScreen> {
  int _quantity = 1;

  void addToCart() {
    // إضافة الخدمة إلى السلة
    // يمكنك تعديل هذا الجزء ليقوم بإضافة الخدمة إلى سلة التسوق
    // مثلاً يمكنك استخدام SharedPreferences أو أي طريقة تخزين أخرى

    // مثال على كيفية إضافة الخدمة إلى السلة
    final cartItem = {
      'serviceName': widget.serviceName,
      'servicePrice': widget.servicePrice,
      'quantity': _quantity,
      'serviceImage': widget.serviceImage,
    };

    // هنا يمكنك تخزين cartItem في قائمة السلة الخاصة بك
    // هذا مجرد مثال، فعليك تعديل هذا الجزء حسب منطق التطبيق الخاص بك

    // عرض رسالة تأكيد
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.serviceName} تمت إضافته إلى السلة!'),
        duration: const Duration(seconds: 2),
      ),
    );

    // إظهار شاشة الرسالة
    customModalBottomSheet(
      context,
      isDismissible: false,
      child: const AddedToCartMessageScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalPrice = widget.servicePrice * _quantity;

    return Scaffold(
      bottomNavigationBar: CartButton(
        price: totalPrice,
        title: "إضافة للسلة",
        subTitle: "الإجمالي",
        press: addToCart, // استدعاء دالة addToCart عند الضغط
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: defaultPadding / 2, vertical: defaultPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const BackButton(),
                Text(
                  widget.serviceName,  // عرض اسم الخدمة المرسل
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(defaultPadding),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: UnitPrice(
                            price: widget.servicePrice,  // تمرير السعر الأصلي
                          ),
                        ),
                        ProductQuantity(
                          numOfItem: _quantity,
                          onIncrement: () {
                            setState(() {
                              _quantity++;
                            });
                          },
                          onDecrement: () {
                            setState(() {
                              if (_quantity > 1) {
                                _quantity--;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: Divider()),
                const SliverToBoxAdapter(child: SizedBox(height: defaultPadding)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}