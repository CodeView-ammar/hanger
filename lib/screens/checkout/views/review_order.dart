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

  const ReviewOrderScreen({Key? key, required this.laundryId}) : super(key: key);

  @override
  _ReviewOrderScreenState createState() => _ReviewOrderScreenState();
}

class _ReviewOrderScreenState extends State<ReviewOrderScreen> {
  String? address;
  double? x_map;
  double? y_map;
  String delegateNote = ''; // متغير لتخزين الملاحظة
  late GoogleMapController mapController;
  late BitmapDescriptor customMarker; // المتغير المستخدم لتخزين صورة الدبوس المخصص
  LatLng userLocationMarker = LatLng(0.0, 0.0);
  // متغير لتخزين خيار الدروب داون
  String selectedPayment = 'عادي'; // القيمة الافتراضية
  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    _loadCustomMarker(); // تحميل الصورة الخاصة بالدبوس في البداية
    fetchAddress();
    fetchDefaultPaymentMethod();
  }
String? defaultPaymentMethod; // متغير لتخزين طريقة الدفع الافتراضية

Future<void> fetchDefaultPaymentMethod() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userid');
  
  // Send the request to the API
  final response = await http.post(
    Uri.parse(APIConfig.PaymentUrl), // Replace with your API URL
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'user': userId,
    }),
  );
  
  // Check if the request was successful
  if (response.statusCode == 200) {
    // Decode the response body
    final Map<String, dynamic> responseData = json.decode(response.body);
    
    setState(() {
      // Set the default payment method
      if(responseData['name']=="COD")defaultPaymentMethod = "الدفع عند الاستلام";
      if(responseData['name']=="CARD")defaultPaymentMethod = "الدفع باستخدام البطاقة";
      if(responseData['name']=="STC")defaultPaymentMethod = "الدفع باستخدام STC";
    
    });
  } else {
    // يمكنك إضافة معالجة الخطأ هنا في حالة فشل الطلب
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('يجب تحديد طريقة الدفع')),
    );
  }
}
Future<void> submitOrder() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userid');

  // التأكد من أن المغسلة واسم المستخدم موجودين
  if (userId == null) {
    // إذا لم يكن هناك معرف للمستخدم
    print("لا يوجد معرف للمستخدم.");
    return;
  }

  // تحديث طريقة الدفع
  if (defaultPaymentMethod == "الدفع عند الاستلام") defaultPaymentMethod = "COD";
  if (defaultPaymentMethod == "الدفع باستخدام البطاقة") defaultPaymentMethod = "CARD";
  if (defaultPaymentMethod == "الدفع باستخدام STC") defaultPaymentMethod = "STC";

  try {
    final response = await http.post(
      Uri.parse('${APIConfig.orderSubmitUrl}'), // استبدال بـ API الخاص بك
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'laundryId': widget.laundryId,
        'userId': userId,
        'delegateNote': delegateNote, // إضافة الملاحظة
        'paymentMethod': defaultPaymentMethod, // إضافة اختيار العميل
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      // إذا تم قبول الطلب بنجاح
      print('تم إرسال الطلب بنجاح!');

      // عرض مودال تأكيد النجاح
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
                  Navigator.of(context).pop(); // إغلاق المودال
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    entryPointScreenRoute, // الشاشة التي تلي التحقق
                    ModalRoute.withName(logInScreenRoute),
                  ); // التوجيه إلى الشاشة الرئيسية
                },
              ),
            ],
          );
        },
      );
    } else {
      // إذا حدث خطأ
      print('فشل في إرسال الطلب: ${response.body}');
    }
  } catch (e) {
    print("حدث خطأ أثناء إرسال الطلب: $e");
  }
}



// تحميل صورة الدبوس المخصص من الأصول
Future<void> _loadCustomMarker() async {
    customMarker = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(38, 38)),
      'assets/icons/pin.png', // قم بتعديل المسار حسب مكان وجود الصورة في مشروعك
    );
    setState(() {}); // تحديث واجهة المستخدم بعد تحميل الصورة
  }

  // دالة لتحميل العنوان من API
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
        print(widget.laundryId);

        // تحريك الكاميرا إلى موقع الدبوس بعد تحميل القيم فقط إذا كان mapController قد تم تهيئته
        if (x_map != null && y_map != null && mapController != null) {
          try{
          mapController.moveCamera(CameraUpdate.newLatLng(LatLng(x_map!, y_map!)));
          }catch(e){
            print(e);
          }
        }else{
          // يمكنك إضافة معالجة الخطأ هنا في حالة فشل الطلب
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل في تحميل العنوان.')),
          );
          Navigator.pushNamed(context, addressesScreenRoute);
          
        }
      });
    } else {
    // يمكنك إضافة معالجة الخطأ هنا في حالة فشل الطلب
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('فشل في تحميل العنوان.')),
    );
     Navigator.pushNamed(context, addressesScreenRoute);
    }
  }

  // دالة لتنسيق العنوان
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
                child: const Center(
                  child: TimeIndicator(time: '30 - 40'),
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
                      height: 200, // تحديد ارتفاع الخريطة
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(x_map ?? 21.612702719986466, y_map ?? 39.14032716304064), // استخدام القيم المستخرجة
                          zoom: 15.0,
                        ),
                        markers: {
                          if (x_map != null && y_map != null && customMarker != null) // التأكد من تحميل الصورة
                            Marker(
                              markerId: const MarkerId('a'),
                              position: LatLng(x_map!, y_map!), // استخدام القيم المستخرجة
                              icon: customMarker, // تعيين الصورة المخصصة للدبوس
                            ),
                        },
                        zoomControlsEnabled: false,
                        scrollGesturesEnabled: false,
                        zoomGesturesEnabled: false,
                        onMapCreated: (GoogleMapController controller) {
                          mapController = controller;

                          // تحريك الكاميرا عند إنشاء الخريطة إذا كانت القيم متاحة
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
                    color: Colors.black, // لون الإطار
                    width: 1, // سمك الإطار
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // محاذاة العناصر إلى اليسار
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.note_add,
                              size: 24,
                            ),
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
                            // الانتقال إلى شاشة إضافة الملاحظة
                            final newNote = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => DelegateNoteScreen()),
                            );

                            // إذا تم إضافة ملاحظة جديدة، نقوم بتحديث المتغير
                            if (newNote != null) {
                              setState(() {
                                delegateNote = newNote;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8), // مسافة بين Row والنص
                    Text(
                      delegateNote.isEmpty 
                        ? 'مثال: لا تقوم بدق على الجرس' // النص الافتراضي عند كون المتغير فارغ
                        : delegateNote, // الملاحظة المدخلة
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey, // لون الخط
                      ),
                    ),
                  ],
                ),
              ),
        
              const SizedBox(height: 24),
              const Text(
                'تفاصيل الدفع',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(10, 10, 10, 1),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50], // لون خلفية مشابه للون في الصورة
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
                                    builder: (context) => AddCardDetailsScreen(),
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
                          defaultPaymentMethod ?? 'جاري تحميل طريقة الدفع...', // عرض القيمة المناسبة
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
              const SizedBox(height: 24),
              const SizedBox(height: 16),
                ElevatedButton(
                onPressed: submitOrder, // عند الضغط، يتم إرسال الطلب
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'تنفيذ الطلب',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}