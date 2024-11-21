import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:shop/components/api_extintion/url_api.dart';
import 'package:shop/components/cart_button.dart';
import 'package:shop/components/custom_modal_bottom_sheet.dart';
import 'package:shop/components/product/services_card.dart';
import 'package:shop/constants.dart';
import 'package:shop/screens/home/views/components/categories.dart';
import 'package:shop/screens/home/views/components/services_and_categories.dart';
import 'package:shop/screens/product/views/components/service_info.dart';
import 'components/notify_me_card.dart';
import 'components/product_images.dart';
import 'product_buy_now_screen.dart';

// نموذج البيانات للخدمة
class ServiceModel {
  final int id;
  final String name;
  final String? description;
  final double price;
  final double urgentPrice;
  final String image;

  ServiceModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.urgentPrice,
    required this.image,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: double.parse(json['price']),
      urgentPrice: double.parse(json['urgent_price']),
      image: json['image'],
    );
  }
}

// نموذج البيانات للفئة
class CategoryModel {
  final String name;
  final String? svgSrc;
  final String? route;

  CategoryModel({required this.name, this.svgSrc, this.route});
}

class ProductDetailsScreen extends StatefulWidget {
  final bool isAvailable;
  final int id;
  final String name;
  final String image;
  final String address;

  const ProductDetailsScreen({
    super.key,
    required this.id,
    required this.isAvailable,
    required this.name,
    required this.image,
    required this.address,
  });

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late Future<List<ServiceModel>> _services;

  @override
  void initState() {
    super.initState();
    _services = fetchServices(widget.id); // تهيئة المتغير هنا
  }

  // دالة لجلب بيانات الخدمات عبر API
  Future<List<ServiceModel>> fetchServices(id) async {
    final response = await http.get(Uri.parse('${APIConfig.servicesEndpoint}?laundry_id=${id}'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => ServiceModel.fromJson(item)).toList();
    } else {
      throw Exception('المغسلة لا تمتلك خدمات');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: widget.isAvailable
          ? CartButton(
              price: 140,
              press: () {
                customModalBottomSheet(
                  context,
                  height: MediaQuery.of(context).size.height * 0.92,
                  child: const ProductBuyNowScreen(),
                );
              },
            )
          : NotifyMeCard(
              isNotify: false,
              onChanged: (value) {},
            ),
      body: SafeArea(
        child: FutureBuilder<List<ServiceModel>>(
          future: _services,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('خطأ: ${snapshot.error}'));
            } else if (snapshot.hasData) {
              final services = snapshot.data!;

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    floating: true,
                    actions: [
                      IconButton(
                        onPressed: () {},
                        icon: SvgPicture.asset(
                          "assets/icons/Bookmark.svg",
                          color: Theme.of(context).textTheme.bodyLarge!.color,
                        ),
                      ),
                    ],
                  ),
                  // عرض صور المنتج
                  ProductImages(images: [widget.image]),

                  // عرض تفاصيل الخدمة
                  ServiceInfo(
                    brand: widget.address,
                    title: widget.name,
                    isAvailable: widget.isAvailable,
                    description: "لا يوجد وصف", // يمكنك تعديل الوصف حسب الحاجة
                    rating: 4.3,
                    numOfReviews: 126,
                  ),
                  SliverToBoxAdapter(child: ServicesAndCategories()),

                  // خدماتنا
                  SliverPadding(
                    padding: const EdgeInsets.all(defaultPadding),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        "خدماتنا",
                        style: Theme.of(context).textTheme.titleSmall!,
                      ),
                    ),
                  ),
                  SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: defaultPadding,
                      mainAxisSpacing: defaultPadding,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final service = services[index];
                        return ServicesCard(
                          image: service.image,
                          title: utf8.decode(service.name.codeUnits), // استخدام utf8.decode
                          brandName: widget.name,
                          price: service.price,
                          press: () {},
                        );
                      },
                      childCount: services.length,
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: defaultPadding),
                  ),
                ],
              );
            } else {
              return const Center(child: Text('لا توجد بيانات للخدمات'));
            }
          },
        ),
      ),
    );
  }
}