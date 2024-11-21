import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shop/components/api_extintion/url_api.dart';
import 'package:shop/components/product/laundries_cart.dart';

import '../../../../constants.dart';
import '../../../../route/route_constants.dart';

class ProductModel {
  final int id;
  final String name;
  final String? address;
  final String? image;

  ProductModel({
    required this.id,
    required this.name,
    this.address,
    this.image,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: utf8.decode(json['name'].codeUnits),
      address: utf8.decode(json['address'].codeUnits),
      image: json['image'],
    );
  }
}

class BestSellers extends StatefulWidget {
  const BestSellers({super.key});

  @override
  State<BestSellers> createState() => _BestSellersState();
}

class _BestSellersState extends State<BestSellers> {
  late Future<List<ProductModel>> _fetchedProducts;

  @override
  void initState() {
    super.initState();
    _fetchedProducts = fetchProducts();
  }

  Future<List<ProductModel>> fetchProducts() async {
    final response = await http.get(Uri.parse(APIConfig.launderiesEndpoint));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => ProductModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch products');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: defaultPadding / 2),
        Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Text(
            "الأكثر طلباً",
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        FutureBuilder<List<ProductModel>>(
          future: _fetchedProducts,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final demoBestSellersProducts = snapshot.data!;
              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(), // لتعطيل التمرير
                shrinkWrap: true, // لتقليل الحجم
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // عدد الأعمدة
                  childAspectRatio: 0.75, // نسبة الطول إلى العرض
                  crossAxisSpacing: defaultPadding, // المسافة بين الأعمدة
                  mainAxisSpacing: defaultPadding, // المسافة بين الصفوف
                ),
                itemCount: demoBestSellersProducts.length,
                itemBuilder: (context, index) => Padding(
                  padding: EdgeInsets.only(
                    left: defaultPadding,
                    right: index == demoBestSellersProducts.length - 1
                        ? defaultPadding
                        : 0,
                  ),
                  child: LaundriesCart(
                    image: demoBestSellersProducts[index].image ?? '',
                    brandName: demoBestSellersProducts[index].address ?? '',
                    title: demoBestSellersProducts[index].name,
                    meter: 100, // Placeholder for price
                    priceAfetDiscount: null, // Placeholder for discounted price
                    dicountpercent: null, // Placeholder for discount percentage
                    press: () {
                      Navigator.pushNamed(
                        context,
                        productDetailsScreenRoute,
                        arguments: {
                          "isAvailable": index.isEven,
                          "id": demoBestSellersProducts[index].id,
                        },
                      );
                    },
                  ),
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
      ],
    );
  }
}