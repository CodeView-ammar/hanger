import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/constants.dart';
import 'components/best_sellers.dart';
import 'components/offer_carousel_and_categories.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _locationFetched = false;

  @override
  void initState() {
    _fetchLocation();
    super.initState();
  }

  Future<void> _fetchLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      Position position = await _getCurrentLocation();
      await prefs.setDouble('latitude', position.latitude);
      await prefs.setDouble('longitude', position.longitude);
      setState(() {
        _locationFetched = true; // تحديث الحالة بعد جلب الموقع
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<Position> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permissions are denied');
      }
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: OffersCarouselAndCategories()),
            SliverToBoxAdapter(child: BestSellers()),
           
          ],
        ),
      ),
    );
  }
}