import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:moyasar/moyasar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/screens/checkout/tools/model/paymodel.dart';
import 'package:shop/screens/checkout/tools/model/source/creditcardmodel.dart';
import 'package:shop/screens/checkout/tools/moyasar_payment.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({Key? key}) : super(key: key);

  @override
  _AddCardScreenState createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();

  // المتغيرات لتخزين بيانات البطاقة
  String cardNumber = '';
  String cardHolderName = '';
  String expiryMonth = '';
  String expiryYear = '';
  String cvv = '';

  // إعدادات الدفع عبر Moyasar
  final String publishableApiKey = 'sk_test_NGyCJ2hNRoHjusfowDePNucyR5J6bFxhkx8kycHp';
  final String callbackUrl = "https://example.com/thankyou"; 

  // دالة التعامل مع نتيجة الدفع
  void onPaymentResult(PayModel result) {
    print(result.status);
    switch (result.status) {
      case PaymentStatus.paid:
        print("تم الدفع بنجاح");
        _addCardDetails(); // إضافة البطاقة إلى النظام
        break;
      case PaymentStatus.failed:
        print("فشل الدفع: ${result}"); 
        break;
      case PaymentStatus.initiated:
        print("تم إنشاء الدفع ولكن لم يدفع حامل البطاقة بعد: ${result}"); 
        break;
      default:
        print("حالة غير معروفة: ${result.status}");
    }
  }

  // دالة لإضافة بيانات البطاقة عبر الـ API بعد التحقق من الدفع
  Future<void> _addCardDetails() async {
    final url = Uri.parse('https://hanger.metasoft-ar.com/api/add-payment-method/');
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userid');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': 'Credit Card',
          'description': 'بطاقة ائتمانية جديدة',
          'is_active': true,
          'user': userId,
          'card_number': cardNumber,
          'card_holder_name': cardHolderName,
          'expiry_date': '$expiryMonth/$expiryYear',
          'cvv': cvv,
        }),
      );

      if (response.statusCode == 201) {
        print('تم إضافة البطاقة بنجاح');
        Navigator.pop(context);
      } else {
        print('حدث خطأ أثناء إضافة البطاقة: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('فشل الاتصال بالخادم: $e');
    }
  }



 static Future<void> sendAuthenticationResult(String url_) async {
    final String authResult = 'AUTHENTICATED';  // القيمة التي نريد إرسالها
    
    final url = Uri.parse(url_.replaceAll("prepare", "acs_emulator"));
    final requestData = {
      'authentication_result': authResult,
    };


    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestData),
      );
      print(url);
      if (response.statusCode == 200) {
        // إذا كانت الاستجابة ناجحة
        print('تم إرسال البيانات بنجاح');
      } else {
        // إذا حدث خطأ في الاستجابة
        print('حدث خطأ في إرسال البيانات');
      }
    } catch (e) {
      print('خطأ في الاتصال: $e');
    }
  }
  // دالة لبدء عملية الدفع
  Future<void> _startPaymentProcess() async {
    try {
      PayModel result = await MoyasarPayment().creditCard(
        amount: 100, 
        publishableKey: publishableApiKey, 
        cardHolderName: cardHolderName, 
        cardNumber: cardNumber, 
        cvv: int.parse(cvv), 
        expiryManth: int.parse(expiryMonth), 
        expiryYear: int.parse(expiryYear), 
        description: "Verify that the card is linked $cardHolderName",
        callbackUrl: 'https://example.com/orders',
        
        );
        // print(result.type);
        // print(result.message);
        // print(result.error);
        CreditcardModel creditcardModel = CreditcardModel.fromJson(result.source);
        print(creditcardModel.toJson());
      sendAuthenticationResult(creditcardModel.toJson()['transaction_url']);

      // معالجة نتيجة الدفع
      onPaymentResult(result);
    } catch (e) {
      print('فشل عملية الدفع: $e');
    }
  }

  // دالة لإنشاء الحقول النصية الأخرى
  Widget _buildTextField({
    required String label,
    required IconData icon,
    required Function(String) onChanged,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        keyboardType: keyboardType,
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  // دالة لإنشاء حقل رقم البطاقة مع أيقونة فيزا
  Widget _buildCardNumberField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Image.asset(
            'assets/icons/credit_card.png',
            width: 40,
            height: 40,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              decoration: InputDecoration(
                labelText: 'رقم البطاقة',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  cardNumber = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال رقم البطاقة';
                }
                if (!RegExp(r'^\d{16}$').hasMatch(value)) {
                  return 'رقم البطاقة يجب أن يتكون من 16 رقمًا';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  // دالة لإنشاء حقل تاريخ الانتهاء (شهر وسنة)
  Widget _buildExpiryDateFields() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              decoration: InputDecoration(
                labelText: 'الشهر (MM)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  expiryMonth = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال الشهر';
                }
                if (!RegExp(r'^(0[1-9]|1[0-2])$').hasMatch(value)) {
                  return 'الشهر يجب أن يكون بين 01 و 12';
                }
                return null;
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              decoration: InputDecoration(
                labelText: 'السنة (YY)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  expiryYear = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال السنة';
                }
                if (!RegExp(r'^\d{2}$').hasMatch(value)) {
                  return 'السنة يجب أن تكون بتنسيق YY';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة بطاقة جديدة'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'الرجاء إدخال بيانات البطاقة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildCardNumberField(),
              _buildTextField(
                label: 'اسم حامل البطاقة',
                icon: Icons.person,
                onChanged: (value) {
                  setState(() {
                    cardHolderName = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال اسم حامل البطاقة';
                  }
                  return null;
                },
              ),
              _buildExpiryDateFields(),
              _buildTextField(
                label: 'CVV',
                icon: Icons.lock,
                onChanged: (value) {
                  setState(() {
                    cvv = value;
                  });
                },
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال CVV';
                  }
                  if (value.length != 3) {
                    return 'CVV يجب أن يتكون من 3 أرقام';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'سيتم سحب 1 ريال لتأكيد صحة بيانات البطاقة. سيتم إرجاع المبلغ بعد التحقق.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _startPaymentProcess();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'إضافة البطاقة',
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