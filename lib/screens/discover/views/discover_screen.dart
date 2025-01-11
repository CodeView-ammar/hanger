import 'dart:convert';  // لاستعمال jsonDecode
import 'dart:async';     // لاستعمال Timer
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/components/api_extintion/url_api.dart';
import 'package:shop/constants.dart';
import 'package:intl/intl.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/screens/discover/views/order_details.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  List<Map<String, String>> orders = [];
  bool isLoading = true;
  bool isLoggedIn = false; // التحقق من تسجيل الدخول
  Timer? _timer;  // متغير الـ Timer

  @override
  void initState() {
    super.initState();
    checkLoginStatus(); // التحقق من حالة تسجيل الدخول عند بدء الشاشة
    _startPeriodicUpdate();  // بدأ التحديث الدوري للبيانات
  }

  @override
  void dispose() {
    _timer?.cancel();  // إلغاء التحديث الدوري عند الخروج من الشاشة
    super.dispose();
  }

  // دالة لبدء التحديث الدوري كل 30 ثانية
  void _startPeriodicUpdate() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      fetchOrders();  // تحديث البيانات من الـ API كل 30 ثانية
    });
  }

  // دالة لتنسيق التاريخ
  String formatDate(String orderDate) {
    try {
      DateTime dateTime = DateTime.parse(orderDate);  // تحويل النص إلى كائن DateTime
      return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);  // تنسيق التاريخ
    } catch (e) {
      return 'Invalid Date';  // التعامل مع التاريخ غير الصحيح
    }
  }

  // دالة لجلب الطلبات من API
  Future<void> fetchOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userid = prefs.getString('userid');

    if (userid == null) {
      // إذا لم يكن المستخدم مسجل دخول، نعرض رسالة و زر تسجيل الدخول
      setState(() {
        isLoggedIn = false;
        isLoading = false;
      });
      return;
    }

    final url = '${APIConfig.orderuserUrl}?user=$userid';  // رابط الـ API
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);  // تحويل البيانات إلى قائمة
        setState(() {
          isLoading = false;
          isLoggedIn = true;
          orders = data.map<Map<String, String>>((order) {
            return {
              'id':order['id'].toString(),
              'name': utf8.decode(order['laundry_name'].codeUnits) ?? 'اسم غير متاح',
              'image': order['laundry_image'] ?? '${APIConfig.static_baseUrl}/images/store.jpg',
              'price': order['total_amount']?.toString() ?? '0',
              'date': formatDate(order['order_date']) ?? 'تاريخ غير متاح',
              'status': order['status'] ?? 'حالة غير متوفرة',
            };
          }).toList();
        });
      } else {
        print('فشل في جلب البيانات: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('حدث خطأ: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // دالة للتحقق من حالة تسجيل الدخول
  Future<void> checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userid = prefs.getString('userid');
    
    if (userid != null) {
      setState(() {
        isLoggedIn = true; // المستخدم مسجل دخول
        fetchOrders(); // جلب الطلبات إذا كان مسجلًا دخول
      });
    } else {
      setState(() {
        isLoggedIn = false; // المستخدم غير مسجل دخول
        isLoading = false; // إيقاف التحميل
      });
    }
  }

  // دالة لترجمة الحالة
  String translateStatus(String status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'courier_accepted':
        return 'تم قبول الطلب من قبل المندوب';
      case 'courier_on_the_way':
        return 'المندوب في الطريق';
      case 'picked_up_from_customer':
        return 'تم استلام الطلب من العميل';
      case 'delivered_to_laundry':
        return 'تم تسليم الطلب للمغسلة';
      case 'in_progress':
        return 'قيد المعالجة';
      case 'ready_for_delivery':
        return 'جاهز للتسليم';
      case 'completed':
        return 'تم إتمام الطلب';
      case 'canceled':
        return 'تم إلغاء الطلب';
      default:
        return 'حالة غير معروفة';
    }
  }

  // دالة لتحديد الأيقونة بناءً على الحالة
  IconData getStatusIcon(String status) {
    switch (status) {
      case 'pending':
      case 'courier_accepted':
        return Icons.hourglass_empty;  // الساعة الرملية
      case 'courier_on_the_way':
        return Icons.local_shipping;  // شاحنة
      case 'picked_up_from_customer':
        return Icons.thumb_up;  // إعجاب
      case 'delivered_to_laundry':
        return Icons.store;  // مغسلة
      case 'in_progress':
        return Icons.build;  // أدوات العمل
      case 'ready_for_delivery':
        return Icons.check_circle;  // دائرة صح
      case 'completed':
        return Icons.check;  // صح
      case 'canceled':
        return Icons.cancel;  // إلغاء
      default:
        return Icons.help_outline;  // سؤال
    }
  }

  // دالة لتحديد اللون بناءً على الحالة
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
      case 'courier_accepted':
        return Colors.orange;
      case 'courier_on_the_way':
        return Colors.blue;
      case 'picked_up_from_customer':
        return Colors.green;
      case 'delivered_to_laundry':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'ready_for_delivery':
        return Colors.green;
      case 'completed':
        return Colors.green;
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(defaultPadding),
              child: Text(
                "قائمة الطلبات",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: isLoggedIn
                ? RefreshIndicator(
                    onRefresh: fetchOrders,  // سيتم استدعاء هذه الدالة عند السحب إلى الأسفل
                    child: isLoading
                        ? Center(child: CircularProgressIndicator()) // عرض دائرة التحميل إذا كانت القائمة فارغة
                        : orders.isEmpty
                            ? Center(child: Text("لا توجد طلبات حالياً"))
                            : ListView.builder(
                                itemCount: orders.length,
                                itemBuilder: (context, index) {
                                  final order = orders[index]; // الحصول على الطلب الحالي
                                  final status = order['status']!;
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OrderDetailsScreen(order: order),  // تمرير البيانات إلى الشاشة الجديدة
                                      ),
                                    );
                                    },
                                    child: Card(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: defaultPadding / 2,
                                          horizontal: defaultPadding),
                                      elevation: 4.0,
                                      child: ListTile(
                                        leading: ClipRRect(
                                          borderRadius: BorderRadius.circular(8.0),
                                          child: Image.network(
                                            order['image']!,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        title: Text(order['name']!),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('${order['date']}'),
                                            Text('طلب استلام | ${translateStatus(status)}'),
                                            const SizedBox(height: 4),
                                            Text(
                                              'السعر: ${order['price']}',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              getStatusIcon(status),
                                              color: _getStatusColor(status),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.arrow_forward_ios,
                                              size: 16.0,
                                              color: Colors.grey,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("يجب أن تكون مسجل دخول لعرض الطلبات"),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, logInScreenRoute);
                          },
                          child: Text("تسجيل الدخول"),
                        ),
                      ],
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
