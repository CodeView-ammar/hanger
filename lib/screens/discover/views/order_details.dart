import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/components/api_extintion/url_api.dart';
import 'package:shop/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailsScreen extends StatefulWidget {
  final Map<String, String> order;
  
  const OrderDetailsScreen({super.key, required this.order});

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  List<Map<String, String>> items = [];
  String salesAgentName = '';
  String salesAgentPhone = '';

  bool get canCancelOrder {
    return widget.order['status'] == 'pending';
  }

  final Map<String, String> orderStatusTranslations = {
    'pending': 'في انتظار المعالجة',
    'courier_accepted': 'المندوب في الطريق',
    'picked_up_from': 'تم أخذها من العميل',
    'delivered_to_laundry': 'تسليمها إلى المغسلة',
    'canceled': 'ملغي',
    'completed': 'مكتمل',
    'ready_for_delivery': 'جاهز للتسليم',
    'courier_on_the_way': 'المندوب في الطريق',
    'picked_up_from_customer': 'تم أخذها من العميل',
    'in_progress': 'جاري التنفيذ',
  };
  Future<void> fetchSalesAgentDetails() async {
    final orderStatus = widget.order['status'];
    if (orderStatus == 'courier_accepted' || orderStatus == 'courier_on_the_way') {
      final orderId = widget.order['id'];
      final response = await http.get(Uri.parse('https://hanger.metasoft-ar.com/api/sales-agent-order/$orderId/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data.containsKey('name') && data.containsKey('phone')) {
          setState(() {
            salesAgentName =utf8.decode( data['name'].codeUnits);
            salesAgentPhone = data['phone'];
          });
        }
      } else {
        print("Error fetching sales agent details: ${response.statusCode}");
      }
    }
  }
  Future<void> fetchItems() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userid');
    final orderId = widget.order['id'];
    final response = await http.get(Uri.parse('${APIConfig.orderitemget_order_itemsUrl}?order_id=$orderId&user_id=$userId'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      setState(() {
        items = List<Map<String, String>>.from(data.map((item) {
          return {
            'name': utf8.decode(item['service_name'].codeUnits),
            'quantity': item['quantity'].toString(),
            'price': item['price'].toString(),
          };
        }));
      });
    } else {
      throw Exception('فشل تحميل البيانات');
    }
  }

  Future<void> EditStatusOrdar() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userid');
    final orderId = widget.order['id'];

    // البيانات التي سيتم إرسالها في الطلب
    Map<String, dynamic> requestData = {
      'status': 'canceled',  // الحالة التي تريد تحديثها
      // يمكنك إضافة بيانات أخرى هنا مثل 'userId' إذا لزم الأمر
    };

    // إرسال الطلب باستخدام PUT مع البيانات
    final response = await http.put(
      Uri.parse('${APIConfig.orderStatusEdit}/$orderId/update-status/'),
      body: json.encode(requestData),
      headers: {'Content-Type': 'application/json'},  // تأكد من تضمين نوع المحتوى المناسب
    );

    print('${APIConfig.orderStatusEdit}/$orderId/update-status/');

    if (response.statusCode == 200) {
      // فك تشفير البيانات المستلمة من الاستجابة
      var data = json.decode(response.body);

      // إذا كانت الاستجابة عبارة عن كائن (Map)
      if (data is Map<String, dynamic>) {
        print(data); // طباعة الكائن المستلم
        setState(() {
          widget.order['status'] = 'canceled';  // تحديث حالة الطلب في واجهة المستخدم
        });
      } else {
        print('Expected a Map, but received: $data');
      }
    } else {
      // التعامل مع الأخطاء إذا كانت الاستجابة غير ناجحة
      print("Failed to update status: ${response.statusCode}");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchItems();
    fetchSalesAgentDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الطلب'),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderDetailsCard(),
            const Divider(),
            _buildOrderStatus(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الشرط للتحقق من ما إذا كان الاسم غير فارغ
                if (salesAgentName.isNotEmpty) ...[
                  const Divider(),
                  _buildSalesAgentInfo(),
                  const SizedBox(height: 20),
                ],
              ],
            ),
              const Divider(),
            _buildItemsList(),
            const Divider(),
            if (canCancelOrder) _buildCancelButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesAgentInfo() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'اسم المندوب: $salesAgentName',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Text(
            //   'رقم الهاتف: $salesAgentPhone',
            //   style: const TextStyle(fontSize: 16, color: Colors.blue),
            // ),
            const SizedBox(height: 10),
           Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // زر الاتصال مع الأيقونة
    ElevatedButton(
      onPressed: () {
        launch('tel:$salesAgentPhone');
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
        backgroundColor: Colors.green, // لون الخلفية (يمكن تغييره)
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.phone, color: Colors.white), // أيقونة الهاتف
          SizedBox(width: 10), // المسافة بين الأيقونة والنص
          Text('اتصال', style: TextStyle(fontSize: 16, color: Colors.white)),
        ],
      ),
    ),
    const SizedBox(height: 10), // المسافة بين الأزرار
    // زر مراسلة عبر واتساب مع الأيقونة
    ElevatedButton(
      onPressed: () {
        launch('https://wa.me/$salesAgentPhone');
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
        backgroundColor: Colors.green, // لون الخلفية (يمكن تغييره)
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.message, color: Colors.white), // أيقونة الرسائل
          SizedBox(width: 10), // المسافة بين الأيقونة والنص
          Text('مراسلة عبر واتساب', style: TextStyle(fontSize: 16, color: Colors.white)),
        ],
      ),
    ),
  ],
)


          ],
        ),
      ),
    );
  }
  Widget _buildOrderDetailsCard() {
    return Card(
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
    );
  }

  Widget _buildOrderStatus() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'حالة الطلب: ${orderStatusTranslations[widget.order['status']] ?? 'غير محددة'}',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الأصناف:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const Center(child: CircularProgressIndicator())
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
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
          ),
      ],
    );
  }

  Widget _buildCancelButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _showCancelDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
        ),
        child: const Text('إلغاء الطلب', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  void _showCancelDialog() {
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
                EditStatusOrdar();
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
  }
}
