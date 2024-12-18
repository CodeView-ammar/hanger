import 'dart:convert'; // لتحويل JSON إلى Map
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // استيراد مكتبة HTTP
import 'package:shop/constants.dart';

class OrderDetailsScreen extends StatefulWidget {
  final Map<String, String> order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  // دالة للتحقق إذا كان يمكن إلغاء الطلب
  bool get canCancelOrder {
    return widget.order['status'] == 'pending';
  }

  // خريطة لترجمة حالات الطلب
  final Map<String, String> orderStatusTranslations = {
    'pending': 'في انتظار المعالجة',
    'courier_accepted': 'المندوب في الطريق',
    'picked_up_from': 'تم أخذها من العميل',
    'delivered_to_laundry': 'تسليمها إلى المغسلة',
  };

  // قائمة من الأصناف
  List<Map<String, String>> items = [];

  // الدالة التي تستخدم لتحميل البيانات من API
  Future<void> fetchItems() async {
    final response = await http.get(Uri.parse('https://example.com/api/items'));

    if (response.statusCode == 200) {
      // إذا كانت الاستجابة ناجحة (200)، نقوم بتحويل البيانات من JSON إلى قائمة
      List<dynamic> data = json.decode(response.body);
      setState(() {
        items = List<Map<String, String>>.from(data.map((item) {
          return {
            'name': item['name'],
            'quantity': item['quantity'].toString(),
            'price': item['price'].toString(),
          };
        }));
      });
    } else {
      throw Exception('فشل تحميل البيانات');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchItems(); // استدعاء الدالة عند تحميل الشاشة
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الطلب'),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255), // استخدام اللون الأساسي في التطبيق
      ),
      body: SingleChildScrollView( // إضافة SingleChildScrollView لجعل الشاشة قابلة للتحريك
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عرض تفاصيل المغسلة
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'اسم المغسلة: ${widget.order['name']} \nرقم الطلب #${widget.order['id']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Image.network(widget.order['image']!),
                    const SizedBox(height: 10),
                    Text(
                      'الإجمالي: ${widget.order['price']}',
                      style: const TextStyle(fontSize: 16, color: Colors.red),
                    ),
                    Text(
                      'تاريخ الطلب: ${widget.order['date']}',
                      style: const TextStyle(fontSize: 16, color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(), // فاصل بين الأقسام
            // حالة الطلب
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'حالة الطلب: ${orderStatusTranslations[widget.order['status']] ?? 'غير محددة'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ),
            const Divider(),
            // عرض قائمة الأصناف
            const Text(
              'الأصناف:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // استخدام FutureBuilder لتحميل البيانات
            FutureBuilder(
              future: fetchItems(), // جلب البيانات
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // في حال انتظار البيانات
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  // في حال حدوث خطأ
                  return Center(child: Text('حدث خطأ: ${snapshot.error}'));
                } else if (!snapshot.hasData || items.isEmpty) {
                  // إذا كانت القائمة فارغة
                  return const Center(child: Text('لا توجد أصناف لعرضها'));
                } else {
                  // عرض الأصناف بعد تحميلها
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          title: Text(item['name']!),
                          subtitle: Text('الكمية: ${item['quantity']}, السعر: ${item['price']}'),
                        ),
                      );
                    },
                  );
                }
              },
            ),
            const Divider(),
            // عرض زر إلغاء الطلب إذا كانت الحالة "قيد المعالجة"
            if (canCancelOrder)
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // هنا يمكنك تنفيذ عملية إلغاء الطلب
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('تأكيد الإلغاء'),
                          content: const Text('هل أنت متأكد أنك تريد إلغاء هذا الطلب؟'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('إلغاء'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم إلغاء الطلب بنجاح'),
                                  ),
                                );
                              },
                              child: const Text('تأكيد'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // لون الزر الأحمر للإلغاء
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  child: const Text('إلغاء الطلب', style: TextStyle(fontSize: 16)),
                ),
              ),
            const SizedBox(height: 20), // إضافة مسافة أسفل الزر
          ],
        ),
      ),
    );
  }
}
