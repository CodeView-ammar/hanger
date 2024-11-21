import 'package:flutter/material.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // مثال على قائمة بالمنتجات في السلة
    final List<Map<String, dynamic>> cartItems = [
      {
        'name': 'منتج 1',
        'price': 50.0,
        'quantity': 1,
      },
      {
        'name': 'منتج 2',
        'price': 30.0,
        'quantity': 2,
      },
      {
        'name': 'منتج 3',
        'price': 20.0,
        'quantity': 1,
      },
    ];

    // حساب السعر الإجمالي
    double totalPrice = 0;
    for (var item in cartItems) {
      totalPrice += item['price'] * item['quantity'];
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("سلة التسوق"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(item['name']),
                      subtitle: Text("سعر: \$${item['price']} × ${item['quantity']}"),
                      trailing: Text("إجمالي: \$${item['price'] * item['quantity']}"),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              "الإجمالي: \$${totalPrice.toStringAsFixed(2)}",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                // تنفيذ عملية الدفع
              },
              child: const Text("متابعة إلى الدفع"),
            ),
          ],
        ),
      ),
    );
  }
}