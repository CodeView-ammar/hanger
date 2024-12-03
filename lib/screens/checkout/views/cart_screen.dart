import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/components/api_extintion/url_api.dart';
import 'package:http/http.dart' as http;

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  double totalPrice = 0.0;
  List<Map<String, dynamic>> cartItems = [];

  Future<void> fetchCartData(int laundryId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userid');

    if (userId != null) {
      final response = await http.get(
        Uri.parse('${APIConfig.cartfilterEndpoint}?user=$userId&laundry=$laundryId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        setState(() {
          if (data['carts'] != null && data['carts'].isNotEmpty) {
            cartItems = List<Map<String, dynamic>>.from(data['carts']);
            totalPrice = data['carts']
                .fold(0.0, (sum, item) => sum + double.parse(item['price']) * item['quantity']);
          } else {
            cartItems = [];
            totalPrice = 0.0;
          }
        });
      } else {
        throw Exception('فشل في جلب البيانات من الـ API');
      }
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('خطأ'),
            content: const Text('لم يتم العثور على معرف المستخدم. يرجى تسجيل الدخول أولاً.'),
            actions: <Widget>[
              TextButton(
                child: const Text('موافق'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      );
    }
  }

  void updateQuantity(int index, int delta) {
    setState(() {
      cartItems[index]['quantity'] = (cartItems[index]['quantity'] + delta).clamp(1, 99);
      totalPrice = cartItems.fold(0.0, (sum, item) => sum + double.parse(item['price']) * item['quantity']);
    });
  }

  void removeItem(int index) {
    setState(() {
      cartItems.removeAt(index);
      totalPrice = cartItems.fold(0.0, (sum, item) => sum + double.parse(item['price']) * item['quantity']);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    final int laundryId = args != null ? args as int : 0;

    if (laundryId > 0) {
      fetchCartData(laundryId);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              child: cartItems.isEmpty
                  ? const Center(child: Text('لا توجد عناصر في السلة'))
                  : ListView.builder(
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text(utf8.decode(item['service_name'].codeUnits)),
                            subtitle: Text("سعر: \س.ر ${item['price']} × ${item['quantity']}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () => updateQuantity(index, -1),
                                ),
                                Text('${item['quantity']}'),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () => updateQuantity(index, 1),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  color: Colors.red,
                                  onPressed: () => removeItem(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16.0),
            Text(
              "الإجمالي: \س.ر ${totalPrice.toStringAsFixed(2)}",
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