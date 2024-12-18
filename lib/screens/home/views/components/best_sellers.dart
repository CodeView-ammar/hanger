import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/components/api_extintion/url_api.dart';
import 'dart:math';
import '../../../../constants.dart';
import '../../../../route/route_constants.dart';

class ProductModel {
  final int id;
  final String name;
  final String? address;
  final String? image;
  final double? x_latitude; 
  final double? y_longitude;

  ProductModel({
    required this.id,
    required this.name,
    this.address,
    this.image,
    this.x_latitude,
    this.y_longitude,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: utf8.decode(json['name'].codeUnits),
      address: utf8.decode(json['address'].codeUnits),
      image: json['image']?.isNotEmpty == true ? json['image'] : null, // Check if image is empty or null
      x_latitude: json['x_map'] != "" ? double.parse(json['x_map'].toString()) : 0,
      y_longitude: json['y_map'] != "" ? double.parse(json['y_map'].toString()) : 0,
    );
  }
}

class LocationService {
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371;
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
               cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
               sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  Future<Map<String, double?>> getCurrentLocation() async {
    final location = Location();
    var userLocation = await location.getLocation();
    return {
      'latitude': userLocation.latitude,
      'longitude': userLocation.longitude,
    };
  }
}

class BestSellers extends StatefulWidget {
  const BestSellers({super.key});

  @override
  State<BestSellers> createState() => _BestSellersState();
}

class _BestSellersState extends State<BestSellers> {
  late Future<List<ProductModel>> _fetchedProducts;
  List<ProductModel> _allProducts = [];
  List<ProductModel> _displayedProducts = [];
  bool _isLoading = false;
  int _currentPage = 1;
  final LocationService _locationService = LocationService();
  double? _userLatitude;
  double? _userLongitude;

  @override
  void initState() {
    super.initState();
    _fetchedProducts = fetchProducts(page: _currentPage);
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    var userLocation = await _locationService.getCurrentLocation();
  
    // تحقق مما إذا كان العنصر لا يزال موجودًا قبل استدعاء setState
    if (mounted) {
      setState(() {
        _userLatitude = userLocation['latitude'];
        _userLongitude = userLocation['longitude'];
      });
    }
  }

  double _getDistanceToLaundry(ProductModel product) {
    if (_userLatitude != null && _userLongitude != null) {
      return _locationService.calculateDistance(
        _userLatitude!,
        _userLongitude!,
        product.x_latitude!,
        product.y_longitude!,
      );
    } else {
      return double.infinity;
    }
  }

  Future<List<ProductModel>> fetchProducts({int page = 1}) async {
    final response = await http.get(Uri.parse("${APIConfig.launderiesEndpoint}?page=$page"));
    if (response.statusCode == 200) {
      print(response.body);

      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => ProductModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch products');
    }
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final refreshedProducts = await fetchProducts(page: 1);
      setState(() {
        _currentPage = 1;
        _allProducts = refreshedProducts;
        _displayedProducts = _allProducts.take(10).toList();
        _displayedProducts.sort((a, b) {
          double distanceA = _getDistanceToLaundry(a);
          double distanceB = _getDistanceToLaundry(b);
          return distanceA.compareTo(distanceB);
        });
      });
    } catch (e) {
      print("Error refreshing products: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveDistanceToStorage(double distance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('distance', distance);
  }

  Future<double?> _getSavedDistance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('distance');
  }

  Future<void> _loadMore() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final moreProducts = await fetchProducts(page: _currentPage + 1);
      setState(() {
        _currentPage++;
        _allProducts.addAll(moreProducts);

        for (var product in moreProducts) {
          if (!_displayedProducts.any((existingProduct) => existingProduct.id == product.id)) {
            _displayedProducts.add(product);
          }
        }

        _displayedProducts.sort((a, b) {
          double distanceA = _getDistanceToLaundry(a);
          double distanceB = _getDistanceToLaundry(b);
          return distanceA.compareTo(distanceB);
        });
      });
    } catch (e) {
      print("Error loading more products: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshProducts,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: defaultPadding / 2),
          Padding(
            padding: const EdgeInsets.all(defaultPadding),
            child: Text(
              "الاقرب لكم",
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
       
          FutureBuilder<List<ProductModel>>(
            future: _fetchedProducts,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final demoBestSellersProducts = snapshot.data!;
                if (_currentPage == 1) {
                  _allProducts = demoBestSellersProducts;
                  _displayedProducts = _allProducts.take(10).toList();

                  _getSavedDistance().then((savedDistance) {
                    if (savedDistance == null) {
                      final distance = _getDistanceToLaundry(demoBestSellersProducts[0]);
                      _saveDistanceToStorage(distance);
                    }
                  });

                  _displayedProducts.sort((a, b) {
                    double distanceA = _getDistanceToLaundry(a);
                    double distanceB = _getDistanceToLaundry(b);
                    return distanceA.compareTo(distanceB);
                  });
                }
                return Column(
                  children: [
                    _buildProductList(_displayedProducts),
                    if (!_isLoading)
                      TextButton(
                        onPressed: _loadMore,
                        child: const Text("عرض المزيد"),
                      ),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: CircularProgressIndicator(),
                      ),
                  ],
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
       
      ),
    );
  }
Widget _buildProductList(List<ProductModel> products) {
  return ListView.builder(
    physics: const NeverScrollableScrollPhysics(),
    shrinkWrap: true,
    itemCount: products.length,
    itemBuilder: (context, index) {
      // Use the image from the product if available, else use the default image
      String imageUrl = products[index].image ?? 'assets/images/store.jpg';

      return Padding(
        padding: const EdgeInsets.only(
          left: defaultPadding,
          right: defaultPadding,
          bottom: defaultPadding,
        ),
        child: GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              productDetailsScreenRoute,
              arguments: {
                "isAvailable": index.isEven,
                "id": products[index].id,
                "name": products[index].name,
                "image": products[index].image,
                "address": products[index].address,
              },
            );
          },
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 17, 52, 92),
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRect(
                    child: Image.network(
                      imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        } else {
                          return const CircularProgressIndicator();
                        }
                      },
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to local image if network image fails
                        return Image.asset(
                          'assets/images/store.jpg', // Your local default image
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          products[index].name,
                          style: const TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            SvgPicture.asset(
                              "assets/icons/Location.svg",
                              height: 20,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${_getDistanceToLaundry(products[index]).toStringAsFixed(2)} كم',
                              style: const TextStyle(fontSize: 14, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
}
