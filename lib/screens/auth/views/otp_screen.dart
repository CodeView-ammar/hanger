import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shop/components/api_extintion/otp_api.dart';
import 'package:shop/components/api_extintion/url_api.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class VerifyOTPScreen extends StatefulWidget {
  final String phone; // استلام رقم الهاتف من شاشة تسجيل الدخول

  const VerifyOTPScreen({Key? key, required this.phone}) : super(key: key);

  @override
  State<VerifyOTPScreen> createState() => _VerifyOTPScreenState();
}

class _VerifyOTPScreenState extends State<VerifyOTPScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _otpController1 = TextEditingController();
  final TextEditingController _otpController2 = TextEditingController();
  final TextEditingController _otpController3 = TextEditingController();
  final TextEditingController _otpController4 = TextEditingController();

  // جمع القيم من الحقول الأربعة
  String get otp {
    return _otpController1.text + _otpController2.text + _otpController3.text + _otpController4.text;
  }

  // دالة لإعادة إرسال OTP
  Future<void> _resendOTP() async {
    var authService = AuthService();
    bool success = await authService.sendOTP(widget.phone);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم إعادة إرسال OTP")),
      );
    } else {
      _showErrorDialog("خطأ في إعادة إرسال الرمز");
    }
  }

Future<String?> saveDataToApi(Map<String, dynamic> data) async {
  try {
    // تحقق مما إذا كان رقم الجوال موجودًا مسبقًا
    final phone = data['phone']; // افترض أن رقم الجوال موجود في الـ data
    final checkResponse = await http.get(
      Uri.parse('${APIConfig.otpphoneEndpoint}$phone'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (checkResponse.statusCode == 200) {
      final checkData = json.decode(checkResponse.body);
      if (checkData.isNotEmpty) {
        // إذا كان رقم الجوال موجودًا، إرجاع الـ id
        return checkData[0]['id'].toString();
      }
    }

    // إرسال البيانات عبر HTTP POST إذا لم يكن رقم الجوال موجودًا
    final response = await http.post(
      Uri.parse(APIConfig.useraddEndpoint),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );

    // التحقق من حالة الاستجابة
    if (response.statusCode == 201) {
      final responseData = json.decode(response.body);
      print("Data submitted successfully.");
      return responseData['id'].toString();
    } else {
      try {
        final responseData = json.decode(response.body);
        print("API error: ${responseData['detail'] ?? 'Unknown error'}");
      } catch (e) {
        print("Error parsing response: $e");
        print("Response body: ${response.body}");
      }
      return "";
    }
  } catch (e) {
    print("Error: $e");
    return "";
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
Future<bool> location() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
   try {
      Position position = await _getCurrentLocation();
      await prefs.setDouble('latitude', position.latitude);
      await prefs.setDouble('longitude', position.longitude);
      print( position.latitude);
      print( position.longitude);
    } catch (e) {
      print('Error getting location: $e');
    return false;
    }
  return true;
}
  Future<bool> logIn(String phone, String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userPhone', phone);
    await prefs.setString('userid', id);
                          location();
    // جلب الموقع وحفظه
   
    return true; // افترض أن تسجيل الدخول ناجح
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.asset(
              "assets/images/log.png",
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "تحقق من رقم الهاتف",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  const Text(
                    "أدخل الرمز المرسل إلى رقم هاتفك",
                  ),
                  const SizedBox(height: defaultPadding),
                  // النموذج مع أربع خانات لإدخال الـ OTP
                  Form(
                    key: _formKey,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildOTPField(controller: _otpController1),
                        _buildOTPField(controller: _otpController2),
                        _buildOTPField(controller: _otpController3),
                        _buildOTPField(controller: _otpController4),
                      ],
                    ),
                  ),
                  const SizedBox(height: defaultPadding),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        String otpCode = otp; // جمع الـ OTP من الحقول الأربعة
                        var authService = AuthService();
                        // التحقق من الرمز
                        bool success = await authService.verifyOTP(widget.phone, otpCode);
                        if (success) {
                          Map<String, dynamic> userData = {
                            "username": widget.phone,
                            "phone": widget.phone,
                            "role": "customer",
                            "password": widget.phone
                          };
                          String? id = await saveDataToApi(userData);

                          // تحقق مما إذا كان الـ id تم استرجاعه بنجاح
                          if (id != null) {
                            // استدعاء دالة تسجيل الدخول مع رقم الهاتف والـ id
                            await logIn(widget.phone, id); // أضف await هنا
                          } else {
                            print("فشل في حفظ البيانات أو استرجاع الـ id.");
                          }
                          location();
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            entryPointScreenRoute, // الشاشة التي تلي التحقق
                            ModalRoute.withName(logInScreenRoute),
                          );
                        } else {
                          // عرض رسالة خطأ للمستخدم
                          _showErrorDialog("خطأ في التحقق من الرمز");
                        }
                      }
                    },
                    child: const Text("تحقق"),
                  ),
                  const SizedBox(height: defaultPadding),
                  TextButton(
                    onPressed: _resendOTP,
                    child: const Text("إعادة إرسال الرمز"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // دالة بناء حقل OTP مخصص
  Widget _buildOTPField({required TextEditingController controller}) {
    return SizedBox(
      width: 50,
      child: TextFormField(
        controller: controller,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          counterText: "", // إخفاء العداد
        ),
        maxLength: 1, // الحد الأقصى لعدد الأحرف هو 1
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        onChanged: (value) {
          if (value.length == 1) {
            // الانتقال إلى الحقل التالي تلقائيًا
            FocusScope.of(context).nextFocus();
          } else if (value.isEmpty) {
            // العودة إلى الحقل السابق إذا تم مسح القيمة
            FocusScope.of(context).previousFocus();
          }
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'الرجاء إدخال الرمز';
          }
          return null;
        },
      ),
    );
  }

  // دالة لعرض رسالة الخطأ
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('خطأ'),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('موافق'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}