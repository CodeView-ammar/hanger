import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as location_;
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/components/api_extintion/url_api.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({Key? key}) : super(key: key);

  @override
  State<AddressesScreen> createState() => AddressesScreenState();
}

class AddressesScreenState extends State<AddressesScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  location_.Location location = location_.Location();
  location_.LocationData? currentLocation;
  LatLng userLocationMarker = LatLng(0.0, 0.0);
  String addressText = "";
  late BitmapDescriptor customMarker;
  late GoogleMapController mapController;
  TextEditingController addressController = TextEditingController();
  StreamSubscription<location_.LocationData>? locationSubscription;

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
    fetchLocationFromApi(); // جلب الموقع من API عند بدء التطبيق
  }

  Future<void> _loadCustomMarker() async {
    customMarker = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(38, 38)),
      'assets/icons/pin.png',
    );
  }

  Future<void> fetchLocationFromApi() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userid');  
    final response = await http.get(Uri.parse('${APIConfig.getaddressEndpoint}$userId/'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        userLocationMarker = LatLng(
          double.parse(data['x_map']),
          double.parse(data['y_map']),
        );
        addressText = data['address_line'];
      });
    } else {
      throw Exception('فشل في جلب الموقع');
    }
    await getCurrentLocation(userLocationMarker.latitude, userLocationMarker.longitude); // استدعاء لجلب الموقع الحالي
  }

  Future<void> getCurrentLocation(double latitude, double longitude) async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    location_.PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == location_.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != location_.PermissionStatus.granted) return;
    }

    if (latitude != null||longitude != null) {
      setState(() {
        userLocationMarker = LatLng(latitude, longitude);
      });
    }else{
        final prefs = await SharedPreferences.getInstance();
        double? latitude = prefs.getDouble('latitude');
        double? longitude = prefs.getDouble('longitude');

        if (latitude != null && longitude != null) {
          setState(() {
            userLocationMarker = LatLng(latitude, longitude);
          });
        } else {
          // هنا يمكنك التعامل مع الحالة إذا كانت القيم غير موجودة (null)
          print("No latitude and longitude saved in SharedPreferences.");
        }

    }

    currentLocation = await location.getLocation();
    if (currentLocation != null) {
    }

    // Initialize locationSubscription only after location is fetched
    locationSubscription = location.onLocationChanged.listen((location_.LocationData newLoc) {
      setState(() {
        currentLocation = newLoc;
      });
    });
  }

  Future<void> _updateAddress(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          addressText = "${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}";
          addressController.text = addressText;
        });
      }
    } catch (e) {
      print('Error retrieving address: $e');
    }
  }

  void _onCameraMove(CameraPosition position) {
    // تحديث مكان الدبوس عند تحريك الكاميرا
    setState(() {
      userLocationMarker = LatLng(position.target.latitude, position.target.longitude);
    });
  }

  void _onCameraIdle() {
    // تحديث العنوان عند توقف الكاميرا
    _updateAddress(userLocationMarker.latitude, userLocationMarker.longitude);
  }

  void _goToCurrentLocation() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(
      LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
      16,
    ));
  }

  void _confirmAddress() {
    setState(() {
      addressText = addressController.text;
    });
    print('تم تأكيد العنوان: $addressText');
    saveAddress(addressController.text, userLocationMarker.latitude, userLocationMarker.longitude);
  }

  Future<void> saveAddress(String addressLine, double latitude, double longitude) async {
    final url = APIConfig.addressesEndpoint;
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userid');  
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لا يوجد مستخدم مسجل.'),
        ),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('جاري حفظ العنوان...'),
        ),
      );

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'address_line': addressLine,
          'x_map': latitude,
          'y_map': longitude,
          'user': userId,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ العنوان بنجاح'),
          ),
        );

        await Future.delayed(Duration(seconds: 2));
        Navigator.pop(context);  
      } else {
        print('فشل في حفظ العنوان');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في حفظ العنوان'),
          ),
        );
      }
    } catch (e) {
      print('خطأ في الاتصال بالخادم: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ في الاتصال بالخادم.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    // Check if locationSubscription is initialized before cancelling it
    if (locationSubscription != null) {
      locationSubscription!.cancel();  
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تحديد الموقع")),
      body: userLocationMarker.latitude == 0.0 && userLocationMarker.longitude == 0.0
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: CameraPosition(
                      target: userLocationMarker,
                      zoom: 16,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId("userLocation"),
                        position: userLocationMarker,
                        icon: customMarker,
                        draggable: false,
                      ),
                    },
                    onMapCreated: (controller) {
                      _controller.complete(controller);
                      mapController = controller;
                    },
                    onCameraMove: _onCameraMove,
                    onCameraIdle: _onCameraIdle,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "العنوان:",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      TextField(
                        controller: addressController,
                        decoration: const InputDecoration(
                          hintText: "أدخل العنوان هنا",
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _confirmAddress,
                        child: Text("تأكيد العنوان"),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 16.0, bottom: 210.0),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: FloatingActionButton(
            onPressed: _goToCurrentLocation,
            child: Icon(Icons.my_location),
            backgroundColor: const Color.fromARGB(255, 255, 219, 247),
          ),
        ),
      ),
    );
  }
}
