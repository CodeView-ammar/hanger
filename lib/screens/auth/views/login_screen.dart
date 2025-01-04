import 'package:flutter/material.dart';
import 'package:shop/components/api_extintion/otp_api.dart';
import 'package:shop/constants.dart';
import 'package:shop/screens/auth/views/otp_screen.dart';
import 'package:shop/screens/auth/views/privacy_policy.dart'; // استيراد شاشة سياسة الخصوصية
import 'components/login_form.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? phoneNumber; // لتخزين رقم الهاتف المدخل
  bool isPrivacyPolicyAccepted = false; // لتخزين حالة الموافقة على سياسة الخصوصية

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
                  // إضافة CheckBox للموافقة على سياسة الخصوصية
                  Row(
                    children: [
                      Checkbox(
                        value: isPrivacyPolicyAccepted,
                        onChanged: (bool? value) {
                          setState(() {
                            isPrivacyPolicyAccepted = value!; // تحديث حالة الموافقة
                          });
                        },
                      ),
                      const Text(
                        "أوافق على ",
                        style: TextStyle(fontSize: 16),
                      ),
                      GestureDetector(
                        onTap: () {
                          // عند النقر على النص، سيتم فتح شاشة سياسة الخصوصية
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PrivacyPolicyScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "سياسة الخصوصية",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // زر تسجيل الدخول مع التحقق من حالة الموافقة
                  ElevatedButton(
                    onPressed: isPrivacyPolicyAccepted
                        ? () async {
                            // التحقق أولًا من صحة النموذج والموافقة على سياسة الخصوصية
                            if (_formKey.currentState?.validate() ?? false) {
                              _formKey.currentState?.save(); // حفظ البيانات المدخلة

                              // التأكد من أن الرقم تم حفظه
                              if (phoneNumber != null && phoneNumber!.isNotEmpty) {
                                var sendOTP = AuthService();
                                bool success = await sendOTP.sendOTP(phoneNumber!); // استخدام الرقم المدخل

                                if (success) {
                                  Navigator.push(
                                    // ignore: use_build_context_synchronously
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VerifyOTPScreen(phone: phoneNumber!),
                                    ),
                                  );
                                } else {
                                  _showErrorDialog("خطاء في ارسال الرسالة الرجاء المحاولة لاحقا");
                                }
                              } else {
                                _showErrorDialog("يرجى إدخال رقم الجوال");
                              }
                            }
                          }
                        : null, // تعطيل الزر إذا لم يتم الموافقة
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
