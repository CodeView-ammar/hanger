import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({Key? key}) : super(key: key);

  @override
  State<AddressesScreen> createState() => AddressesScreenState();
}

class AddressesScreenState extends State<AddressesScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  static const LatLng sourceLocation = LatLng(24.7136, 46.6753); // الرياض
  static const LatLng destination = LatLng(24.7150, 46.6765); // نقطة قريبة من الرياض

  double distanceSourceFinish = 0.0;
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  LocationData? currentLocation;
  LatLng userLocationMarker = sourceLocation; // موقع الدبوس الجديد
  String coordinatesText = ""; // نص الإحداثيات

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
    getPolyline();
  }

  Future<void> getCurrentLocation() async {
    Location location = Location();

    // طلب الأذونات
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    // الاشتراك في تغييرات الموقع
    location.onLocationChanged.listen((newLoc) {
      setState(() {
        currentLocation = newLoc;
      });
    });
  }

  Future<void> getPolyline() async {
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      "AIzaSyDlQrdG8xZxzh1XhQQ0V3Y5rstuOoj0jdg",
      PointLatLng(sourceLocation.latitude, sourceLocation.longitude),
      PointLatLng(destination.latitude, destination.longitude),
      travelMode: TravelMode.driving,
    );

    if (result.points.isNotEmpty) {
      polylineCoordinates.clear(); // تفريغ النقاط القديمة
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
      addPolyLine(polylineCoordinates);
    } else {
      print('Error: ${result.errorMessage}');
    }
  }

  void addPolyLine(List<LatLng> polylineCoordinates) {
    PolylineId id = PolylineId("route");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.black,
      points: polylineCoordinates,
      width: 80,
    );
    polylines[id] = polyline;
    setState(() {});
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      userLocationMarker = position; // تحديث موقع الدبوس
      coordinatesText = "إحداثيات: ${position.latitude}, ${position.longitude}"; // تحديث النص
    });
  }
  // دالة لتحريك الكاميرا وتحديث الإحداثيات
  void _onCameraMove(CameraPosition position) {
    setState(() {
      userLocationMarker = LatLng(position.target.latitude, position.target.longitude); // تحديث موقع الدبوس
      coordinatesText = "إحداثيات: ${userLocationMarker.latitude}, ${userLocationMarker.longitude}"; // تحديث النص
    });
  }

  // دالة لتحديد الموقع الحالي
  Future<void> _goToCurrentLocation() async {
    if (currentLocation != null) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
        ),
      );
      setState(() {
        userLocationMarker = LatLng(currentLocation!.latitude!, currentLocation!.longitude!);
         coordinatesText = "إحداثيات: ${userLocationMarker.latitude},\n ${userLocationMarker.longitude}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "تحديد الموقع",
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
      ),
      body: currentLocation == null
          ? Center(
              child: Text(
                "انتظر...",
                style: const TextStyle(
                  fontSize: 26.0,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      GoogleMap(
                        mapType: MapType.normal,
                        initialCameraPosition: CameraPosition(
                          target: LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
                          zoom: 16,
                        ),
                        polylines: Set<Polyline>.of(polylines.values),
                        markers: {
                          Marker(
                            markerId: const MarkerId("currentLocation"),
                            position: LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
                          ),
                          Marker(
                            markerId: MarkerId("source"),
                            position: sourceLocation,
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                          ),
                          Marker(
                            markerId: MarkerId("destination"),
                            position: destination,
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
                          ),
                          // دبوس المستخدم
                          Marker(
                            markerId: const MarkerId("userLocation"),
                            position: userLocationMarker,
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed), // تغيير لون الدبوس
                          ),
                        },
                        onMapCreated: (mapController) {
                          _controller.complete(mapController);
                        },
                        onTap: _onMapTapped, // إضافة حدث عند الضغط على الخريطة
                        onCameraMove: _onCameraMove, // إضافة حدث عند تحريك الكاميرا
                      ),
                      // تعليق على الدبوس
                      Positioned(
                  top: MediaQuery.of(context).size.height * 0.29,
                  left: MediaQuery.of(context).size.width / 2 - 26, // Center the icon horizontally
                  child: Container(
                    color: Colors.transparent,
                    child: const Icon(
                      Icons.location_pin,
                      size: 50,
                      color: Color.fromARGB(255, 45, 3, 145),
                    ),
                  ),
                ),
                    ],
                  ),
                ),
                 Container(
                  padding: const EdgeInsets.all(16.0),
                  color: Colors.white,
                  child: Text("am,m")
                ),
              
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: Colors.white,
                  child: Text(
                    coordinatesText.isEmpty ? "إحداثيات: لم يتم تحديد الموقع بعد" : coordinatesText,
                    style: const TextStyle(fontSize: 18.0),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToCurrentLocation,
        tooltip: 'حدد الموقع الحالي',
        child: const Icon(Icons.my_location),
      ),
    );
  }
}