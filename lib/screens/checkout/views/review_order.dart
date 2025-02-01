import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/components/api_extintion/url_api.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/screens/checkout/views/delegate_note.dart';
import 'package:shop/screens/checkout/views/payment_method.dart';
import 'package:shop/screens/checkout/views/time.dart';

class ReviewOrderScreen extends StatefulWidget {
  final int laundryId;
  final double total;
  final bool isPaid;
  final double distance;
  final String duration;

  const ReviewOrderScreen({
    Key? key,
    required this.laundryId,
    required this.total,
    required this.isPaid,
    required this.distance,
    required this.duration,
  }) : super(key: key);

  @override
  _ReviewOrderScreenState createState() => _ReviewOrderScreenState();
}

class _ReviewOrderScreenState extends State<ReviewOrderScreen> {
  String? address;
  double? x_map;
  double? y_map;
  String delegateNote = '';
  late GoogleMapController mapController;
  late BitmapDescriptor customMarker;
  LatLng userLocationMarker = LatLng(0.0, 0.0);
  String selectedPayment = 'عادي'; // default value
  String? defaultPaymentMethod; // Store default payment method
  String? price_per_kg;

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadCustomMarker(); // Load custom marker image
    fetchAddress();
    fetchDefaultPaymentMethod();
    fetchPricePerKg().then((price) {
      if (price != null) {
        setState(() {
          price_per_kg = price; // تأكد من أن price_per_kg هو من نوع double
        });
      } else {
        print('لم يتم جلب السعر.');
      }
    });
  }

  Future<String?> fetchPricePerKg() async {
    final response = await http.get(Uri.parse(APIConfig.deliverysettingEndpoint));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print(data[0]);
      return data[0]['price_per_kg'];
    } else {
      print('فشل في جلب السعر: ${response.statusCode}');
      return null; // يمكنك إرجاع null عند الفشل
    }
  }

  double get totalAmount {
    double deliveryPrice = (price_per_kg != null && widget.distance != null)
        ? (double.tryParse(price_per_kg!)! * widget.distance)
        : 0.0;
    return (widget.total + deliveryPrice);
  }

  Future<void> fetchDefaultPaymentMethod() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userid');

    final response = await http.post(
      Uri.parse(APIConfig.PaymentUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'user': userId}),
    );

    print('Response Status Code: ${response.statusCode}'); // طباعة الحالة

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      setState(() {
        // تأكد من تعيين defaultPaymentMethod بشكل صحيح
        defaultPaymentMethod = responseData['payment_method'] ?? 'غير محدد';
        // تحويل طريقة الدفع إلى القيمة التي سيقبلها الـ API
        if (defaultPaymentMethod == "الدفع عند الاستلام") {
          defaultPaymentMethod = "COD";
        } else if (defaultPaymentMethod == "الدفع باستخدام البطاقة") {
          defaultPaymentMethod = "CARD";
        } else if (defaultPaymentMethod == "الدفع باستخدام STC") {
          defaultPaymentMethod = "STC";
        }
        if (widget.isPaid) {
          defaultPaymentMethod = "تم الدفع باستخدام البطاقة"; // تم الدفع باستخدام البطاقة
        } else {
          defaultPaymentMethod = "الدفع عند الاستلام"; // الدفع عند الاستلام
        }
      });
    } else {
      print('Error: ${response.body}'); // طباعة الأخطاء
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب تحديد طريقة الدفع')),
      );
    }
  }

  Future<void> submitOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userid');

    if (userId == null) {
      print("لا يوجد معرف للمستخدم.");
      return;
    }

    // Update payment method
    if (defaultPaymentMethod == "الدفع عند الاستلام") defaultPaymentMethod = "COD";
    if (defaultPaymentMethod == "الدفع باستخدام البطاقة") defaultPaymentMethod = "CARD";
    if (defaultPaymentMethod == "الدفع باستخدام STC") defaultPaymentMethod = "STC";

    try {
      print(defaultPaymentMethod);
      final response = await http.post(
        Uri.parse('${APIConfig.orderSubmitUrl}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'laundryId': widget.laundryId,
          'userId': userId,
          'delegateNote': delegateNote,
          'paymentMethod': defaultPaymentMethod,
          "isPaid": widget.isPaid,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('تم إرسال الطلب بنجاح!'),
              content: const Text('تم إرسال طلبك بنجاح إلى المغسلة.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('موافق'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      entryPointScreenRoute,
                      ModalRoute.withName(logInScreenRoute),
                    );
                  },
                ),
              ],
            );
          },
        );
      } else {
        print('فشل في إرسال الطلب: ${response.body}');
      }
    } catch (e) {
      print("حدث خطأ أثناء إرسال الطلب: $e");
    }
  }

  Future<void> _loadCustomMarker() async {
    customMarker = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(38, 38)),
      'assets/icons/pin.png',
    );
    setState(() {});
  }

  Future<void> fetchAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userid');
    final response = await http.get(Uri.parse('${APIConfig.getaddressEndpoint}$userId/'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        address = utf8.decode(data['address_line'].codeUnits);
        x_map = double.tryParse(data['x_map'].toString());
        y_map = double.tryParse(data['y_map'].toString());
        if (x_map != null && y_map != null && mapController != null) {
          try {
            mapController.moveCamera(CameraUpdate.newLatLng(LatLng(x_map!, y_map!)));
          } catch (e) {
            print(e);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل في تحميل العنوان.')),
          );
          Navigator.pushNamed(context, addressesScreenRoute);
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل في تحميل العنوان.')),
      );
      Navigator.pushNamed(context, addressesScreenRoute);
    }
  }

  String formatAddress(String address) {
    if (address.length > 40) {
      return address.substring(0, 25) + '...';
    }
    return address;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مراجعة الطلب'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'تفاصيل التوصيل',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 240, 237, 237),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: TimeIndicator(
                    time: widget.duration.contains("mins")
                        ? (int.tryParse(widget.duration.split("mins")[0]) ?? 0 + 10).toString()
                        : "",
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 240, 237, 237),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 200,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(x_map ?? 21.612702719986466, y_map ?? 39.14032716304064),
                          zoom: 15.0,
                        ),
                        markers: {
                          if (x_map != null && y_map != null && customMarker != null)
                            Marker(
                              markerId: const MarkerId('a'),
                              position: LatLng(x_map!, y_map!),
                              icon: customMarker,
                            ),
                        },
                        zoomControlsEnabled: false,
                        scrollGesturesEnabled: false,
                        zoomGesturesEnabled: false,
                        onMapCreated: (GoogleMapController controller) {
                          mapController = controller;
                          if (x_map != null && y_map != null) {
                            mapController.moveCamera(CameraUpdate.newLatLng(LatLng(x_map!, y_map!)));
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 240, 237, 237),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.pin_drop),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (address != null)
                          Text(formatAddress(address!)),
                        if (address == null)
                          const Text('جاري تحميل العنوان...'),
                      ],
                    ),
                    const SizedBox(width: 0),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, addressesScreenRoute);
                      },
                      child: const Text(
                        'تغيير',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Color.fromRGBO(10, 10, 10, 1),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.black,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.note_add, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'ملاحظة للمندوب',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_left, size: 24),
                          onPressed: () async {
                            final newNote = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => DelegateNoteScreen()),
                            );
                            if (newNote != null) {
                              setState(() {
                                delegateNote = newNote;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      delegateNote.isEmpty ? 'مثال: لا تقوم بدق على الجرس' : delegateNote,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'تفاصيل الدفع',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color.fromRGBO(10, 10, 10, 1)),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'اختر طريقة الدفع أونلاين لاستخدام الرصيد المتاح',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.payment, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'طرق الدفع',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddCardDetailsScreen(name_windows: "main"),
                                settings: RouteSettings(
                                  arguments: [double.tryParse(totalAmount.toStringAsFixed(2)), widget.laundryId]  // تمرير المبلغ الإجمالي
                                ),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(bottom: 10, top: 10, left: 10, right: 10),
                            child: Text(
                              'اختر',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                backgroundColor: Color.fromRGBO(251, 255, 1, 1),
                                color: Color.fromRGBO(10, 10, 10, 1),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      defaultPaymentMethod ?? 'جاري تحميل طريقة الدفع...',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(0),   // الزاوية العليا اليسرى
                    bottomRight: Radius.circular(0),  // الزاوية العليا اليمنى
                    topLeft: Radius.circular(8), // الزاوية السفلى اليسرى
                    topRight: Radius.circular(8), // الزاوية السفلى اليسرى
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'اجمالي الطلب',
                      style: TextStyle(fontSize: 10),
                    ),
                    Text(
                      '${widget.total} ريال',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'سعر التوصيل',
                      style: TextStyle(fontSize: 10),
                    ),
                    Text(
                      '${(price_per_kg != null && widget.distance != null) ? (double.tryParse(price_per_kg!)! * widget.distance).toStringAsFixed(2) : '0.00'} ريال',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(0),   // الزاوية العليا اليسرى
                    topRight: Radius.circular(0),  // الزاوية العليا اليمنى
                    bottomLeft: Radius.circular(8), // الزاوية السفلى اليسرى
                    bottomRight: Radius.circular(8), // الزاوية السفلى اليسرى
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'الإجمالي',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${totalAmount.toStringAsFixed(2)} ريال',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // إظهار حالة الدفع (مدفوع أو غير مدفوع)
              Text(
                widget.isPaid ? 'تم الدفع' : 'لم يتم الدفع',
                style: TextStyle(
                  fontSize: 14, 
                  color: widget.isPaid ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: submitOrder,
                  child: const Text('إرسال الطلب'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}