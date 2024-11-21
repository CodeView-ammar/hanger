import 'package:flutter/material.dart';
import 'package:shop/components/api_extintion/otp_api.dart';
import 'package:shop/constants.dart';
import 'package:shop/screens/auth/views/otp_screen.dart';

import 'components/login_form.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? phoneNumber; // لتخزين رقم الهاتف المدخل

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

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
                    "مرحبا بعودتك",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  const Text(
                    "تسجيل الدخول بإستخدام رقم الهاتف",
                  ),
                  const SizedBox(height: defaultPadding),
                  LogInForm(
                    formKey: _formKey,
                    onPhoneSaved: (phone) {
                      phoneNumber = phone; // حفظ الرقم المدخل
                    },
                  ),
                  SizedBox(
                    height: size.height > 700
                        ? size.height * 0.1
                        : defaultPadding,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // التحقق أولًا من صحة النموذج
                      if (_formKey.currentState?.validate() ?? false) {
                        _formKey.currentState?.save(); // حفظ البيانات المدخلة

                        // التأكد من أن الرقم تم حفظه
                        if (phoneNumber != null && phoneNumber!.isNotEmpty) {
                          
                          var sendOTP = AuthService();
                          bool success = await sendOTP.sendOTP(phoneNumber!); // استخدام الرقم المدخل

                          if (success) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VerifyOTPScreen(phone: phoneNumber!),
                              ),
                            );
                          } else {
                            _showErrorDialog("Error sending OTP");
                          }
                        } else {
                          _showErrorDialog("يرجى إدخال رقم الجوال");
                        }
                      }
                    },
                    child: const Text("تسجيل الدخول"),
                  ),
                ],
              ),
            ),
          ],
        ),
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
