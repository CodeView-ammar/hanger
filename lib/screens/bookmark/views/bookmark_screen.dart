import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/components/api_extintion/url_api.dart';
import 'package:shop/components/product/laundries_cart.dart';
import 'package:http/http.dart' as http;
import 'package:shop/route/route_constants.dart';
import 'dart:convert';

import '../../../constants.dart';

// تعريف نموذج الخدمة (LaundryModel) مع إضافة id
class LaundryModel {
  final int id; // إضافة id هنا
  final String name;
  final String address;
  final String phone;
  final String? image;
  final String email;

  LaundryModel({
    required this.id, // تم إضافة id في المُنشئ
    required this.name,
    required this.address,
    required this.phone,
    this.image,
    required this.email,
  });

  // دالة لتحويل JSON إلى LaundryModel
  factory LaundryModel.fromJson(Map<String, dynamic> json) {
    return LaundryModel(
      id: json['id'], // تأكد من أن الـ id موجود في الـ JSON
      name: utf8.decode(json['name'].codeUnits) ,
      address: utf8.decode(json['address'].codeUnits) ,
      phone: json['phone'] ?? 'غير متوفر',
      image: json['image'],
      email: json['email'] ?? 'غير متوفر',
    );
  }
}

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  _BookmarkScreenState createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  late Future<List<LaundryModel>> _futureLaundries;

  @override
  void initState() {
    super.initState();
    _futureLaundries = fetchProducts(); // جلب البيانات عند بدء التطبيق
  }

  // دالة لجلب المنتجات أو الخدمات من API
  Future<List<LaundryModel>> fetchProducts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userid');

    if (userId == null) {
      throw Exception("User ID is not found.");
    }

    final response = await http.get(Uri.parse('${APIConfig.markEndpoint}$userId/'));

    if (response.statusCode == 200) {
      // Decode the JSON response
      List<dynamic> jsonResponse = json.decode(response.body);

      // Initialize an empty list to store LaundryModel objects
      List<LaundryModel> laundries = [];

      for (var item in jsonResponse) {
        try {
          // Assuming 'laundry' is a key in the response to fetch more details
          final laundryResponse = await http.get(Uri.parse('${APIConfig.launderiesEndpoint}${item['laundry'].toString()}'));

          if (laundryResponse.statusCode == 200) {
            // Decode the laundry response
            var jsonLaundryResponse = json.decode(laundryResponse.body);

            // If the response is a list, process each item
            if (jsonLaundryResponse is List) {
              for (var laundryItem in jsonLaundryResponse) {
                if (laundryItem is Map<String, dynamic>) {
                  // Map the laundry item data to LaundryModel
                  LaundryModel laundry = LaundryModel.fromJson(laundryItem);
                  laundries.add(laundry);
                }
              }
            } else if (jsonLaundryResponse is Map<String, dynamic>) {
              LaundryModel laundry = LaundryModel.fromJson(jsonLaundryResponse);
              laundries.add(laundry);
            }
          } else {
            print('Error fetching laundry data: ${laundryResponse.statusCode}');
          }
        } catch (e) {
          print('Error during data processing: $e');
        }
      }

      return laundries;
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }

  // دالة لحذف خدمة من المحفوظات
  void removeLaundry(int id, int userId) async {
    try {
      // إرسال الطلب لحذف العنصر من الـ API
      print(id);
      final response = await http.delete(Uri.parse('${APIConfig.markEndpoint}$userId/$id'));

      // التحقق من حالة الاستجابة
      if (response.statusCode == 200) {
        // إذا تم الحذف بنجاح، أعد تحميل المنتجات
        setState(() {
          _futureLaundries = fetchProducts(); // إعادة تحميل البيانات من جديد
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حذف المحفوظات بنجاح')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل في حذف المحفوظات')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _futureLaundries = fetchProducts(); // إعادة تعيين future لجلب البيانات مرة أخرى
          });
          await _futureLaundries; // انتظر حتى تكتمل عملية الجلب
        },
        child: FutureBuilder<List<LaundryModel>>(
          future: _futureLaundries, // استخدم الـ future الذي تم تعيينه
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator()); // مؤشر تحميل
            } else if (snapshot.hasError) {
              return Center(child: Text('حدث خطأ: ${snapshot.error}')); // عرض رسالة الخطأ
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('لا توجد خدمات.')); // إذا لم توجد بيانات
            }

            final products = snapshot.data!; // البيانات المحملة

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: defaultPadding, vertical: defaultPadding),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200.0,
                      mainAxisSpacing: defaultPadding,
                      crossAxisSpacing: defaultPadding,
                      childAspectRatio: 0.66,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        return Stack(
                          children: [
                            LaundriesCart(
                              image: products[index].image ?? '',
                              brandName: products[index].address  ,
                              title: products[index].name,
                              meter: 100, // Placeholder for price
                              priceAfetDiscount: null, // Placeholder for discounted price
                              dicountpercent: null, // Placeholder for discount percentage
                              press: () {
                                Navigator.pushNamed(
                                  context,
                                  productDetailsScreenRoute,
                                  arguments: {
                                    "isAvailable": index.isEven, // Change the key to "isAvailable"
                                    "id": products[index].id, // تم إضافة id هنا
                                  },
                                );
                              },
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: CircleAvatar(
                                backgroundColor: Colors.red,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                  onPressed: () async {
                                    // استخدام await داخل onPressed من خلال جعلها async
                                    SharedPreferences prefs = await SharedPreferences.getInstance();
                                    final userId = prefs.getString('userid');
                                    
                                    if (userId != null) {
                                      // عند الضغط على زر الحذف، قم بحذفه من المحفوظات
                                      removeLaundry(products[index].id, int.parse(userId)); // تحويل userId إلى int
                                    } else {
                                      // إذا لم يتم العثور على userId، يمكن إظهار رسالة للمستخدم
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('لم يتم العثور على بيانات المستخدم')));
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      childCount: products.length,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
