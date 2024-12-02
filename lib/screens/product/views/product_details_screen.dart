import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/components/api_extintion/url_api.dart';
import 'package:shop/components/cart_button.dart';
import 'package:shop/components/custom_modal_bottom_sheet.dart';
import 'package:shop/components/product/services_card.dart';
import 'package:shop/constants.dart';
import 'package:shop/screens/product/views/components/product_images.dart';
import 'package:shop/screens/product/views/components/service_info.dart';
import 'package:shop/screens/product/views/product_buy_now_screen.dart';

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
      name: utf8.decode(json['name'].codeUnits),
      description: json['description'],
      price: double.parse(json['price']),
      urgentPrice: double.parse(json['urgent_price']),
      image: json['image'],
    );
  }
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
    _services = fetchServices(widget.id);
  }

  Future<List<ServiceModel>> fetchServices(id) async {
    final response = await http.get(Uri.parse('${APIConfig.servicesEndpoint}?laundry_id=${id}'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => ServiceModel.fromJson(item)).toList();
    } else {
      throw Exception('المغسلة لا تمتلك خدمات');
    }
  }

  void showCustomBottomSheet(BuildContext context, ServiceModel service, int quantity) {
    customModalBottomSheet(
      context,
      height: MediaQuery.of(context).size.height * 0.92,
      child: ProductBuyNowScreen(
        serviceName: service.name,
        servicePrice: service.price * quantity, // حساب السعر بناءً على الكمية
        serviceImage: service.image,
        quantity: quantity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: widget.isAvailable
          ? CartButton(
              price: 0,
              press: () {
                showCustomBottomSheet(context, ServiceModel(
                  id: widget.id,
                  name: widget.name,
                  description: "No description",
                  price: 0,
                  urgentPrice: 0,
                  image: widget.image,
                ), 1); // هنا يمكن استبدال 1 بالكمية التي يختارها المستخدم
              },
            )
          : SizedBox(),
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
                  ProductImages(images: [widget.image]),
                  ServiceInfo(
                    brand: widget.address,
                    title: widget.name,
                    isAvailable: widget.isAvailable,
                    description: "لا يوجد وصف",
                    rating: 4.3,
                    numOfReviews: 126,
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(defaultPadding),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        "خدماتنا",
                        style: Theme.of(context).textTheme.titleSmall!,
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final service = services[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: ListTile(
                            leading: Image.network(
                              service.image,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                            title: Text(service.name),
                            subtitle: Text('السعر: \س.ر ${service.price.toStringAsFixed(2)}'),
                            trailing: IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () {
                                showCustomBottomSheet(context, service, 1); // يمكنك هنا تعديل الكمية
                              },
                            ),
                          ),
                        );
                      },
                      childCount: services.length,
                    ),
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
