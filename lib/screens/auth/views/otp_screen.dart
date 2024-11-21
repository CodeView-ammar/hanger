import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shop/components/api_extintion/otp_api.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
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
    bool success = await authService.sendOTP(widget.phone); // تأكد من أن sendOTP تعمل بشكل صحيح
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
    // إرسال البيانات عبر HTTP POST
    final response = await http.post(
      Uri.parse('https://hanger.metasoft-ar.com/api/users/'),
      headers: {
        'Content-Type': 'application/json', // تأكد من تعيين الهيدر بشكل صحيح
      },
      body: json.encode(data), // تحويل البيانات إلى JSON
    );

    // التحقق من حالة الاستجابة
    if (response.statusCode == 201) { // تأكد من استخدام 201 لنجاح الإنشاء
      // إذا كانت الاستجابة ناجحة، قم بتحليل البيانات
      final responseData = json.decode(response.body);
      print("Data submitted successfully.");
      // إرجاع الـ id الخاص بالمستخدم
      print(responseData['id'].toString());
      // إرجاع الـ id الخاص بالمستخدم
      return responseData['id'].toString(); // تأكد من أن الـ API يعيد الـ id بهذا الاسم
    } else {
      // إذا كانت الاستجابة غير ناجحة، قم بمعالجة الأخطاء
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
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
        Future<bool> logIn(String phone,String id) async {
          // هنا يمكنك إضافة منطق تسجيل الدخول الخاص بك
          // إذا كان تسجيل الدخول ناجحًا، احفظ الجلسة:
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('userPhone', phone); // حفظ رقم الهاتف
          await prefs.setString('userid', id); // حفظ رقم الهاتف
          return true; // افترض أن تسجيل الدخول ناجح
        }
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
                          

                            if (success) {
                           Map<String, dynamic> userData ={
                            "username": widget.phone,
                            "phone": widget.phone,
                            "role": "customer",
                            "password": widget.phone
                          };
                           String? id = await saveDataToApi(userData);

                            // تحقق مما إذا كان الـ id تم استرجاعه بنجاح
                            if (id != null) {
                              // استدعاء دالة تسجيل الدخول مع رقم الهاتف والـ id
                              logIn(widget.phone, id);
                            } else {
                              // معالجة الحالة عندما يفشل الحفظ
                              print("فشل في حفظ البيانات أو استرجاع الـ id.");
                            }
                              // معالجة النجاح
                              print("User created successfully");
                            } else {
                              // معالجة الفشل
                              print("Failed to create user");
                            }

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
        onTap: () {
          // عند النقر على الحقل، إذا كان هناك قيمة سابقة، نعيد توزيعها
          if (controller.text.isEmpty) {
            String fullOTP = _retrieveFullOTP();
            if (fullOTP.isNotEmpty) {
              _distributeOTP(fullOTP);
            }
          }
        },
        onEditingComplete: () {
          // استدعاء الدالة لتوزيع الرقم عند الانتهاء من التحرير
          String text = controller.text;
          if (text.length > 1) {
            _distributeOTP(text);
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

  // دالة لتوزيع الرقم على الحقول الأربعة
  void _distributeOTP(String otp) {
    if (otp.length > 4) {
      otp = otp.substring(0, 4); // أخذ أول 4 أرقام فقط
    }
    List<String> otpList = otp.split('');
    _otpController1.text = otpList.length > 0 ? otpList[0] : '';
    _otpController2.text = otpList.length > 1 ? otpList[1] : '';
    _otpController3.text = otpList.length > 2 ? otpList[2] : '';
    _otpController4.text = otpList.length > 3 ? otpList[3] : '';
    
    // الانتقال إلى الحقل الأخير بعد التوزيع
    FocusScope.of(context).unfocus(); // أغلق لوحة المفاتيح
  }

  // دالة لاسترجاع الرقم الكامل في حال اللصق
  String _retrieveFullOTP() {
    return _otpController1.text + _otpController2.text + _otpController3.text + _otpController4.text;
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