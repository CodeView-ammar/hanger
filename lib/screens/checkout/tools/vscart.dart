import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/screens/checkout/tools/add_card_screen.dart';

class AddCardDetailsScreen extends StatelessWidget {
  const AddCardDetailsScreen({Key? key}) : super(key: key);

  // دالة لإضافة طريقة الدفع عبر API
  Future<void> addPaymentMethod(String name, String description) async {
    final url = Uri.parse('https://hanger.metasoft-ar.com/api/add-payment-method/');
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userid');  

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'description': description,
          'is_active': true,
          'user': userId,
        }),
      );

      if (response.statusCode == 201) {
        print('تم إضافة طريقة الدفع بنجاح');
      } else {
        print('حدث خطأ: ${response.body}');
      }
    } catch (e) {
      print('فشل الاتصال بالخادم: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'طرق الدفع',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  PaymentOption(
                    title: 'الدفع الإلكتروني لاحقا او نقدأ',
                    subtitle: 'ادفع نقدا او ادفع إلكترونيا من خلال التطبيق بمجرد ان يستلم المندوب الطلب',
                    logo: 'assets/icons/money_hand.jpg',
                    onTap: () {
                      // استدعاء دالة إضافة طريقة الدفع عند النقر على الدفع الإلكتروني
                      addPaymentMethod('COD', 'الدفع عند الاستلام');
                    },
                  ),
                  const Divider(),
                  PaymentOption(
                    title: 'stc pay',
                    subtitle: 'ادفع لجهة معينة باستخدام رقم الجوال',
                    logo: 'assets/icons/stc_pay.png',
                    onTap: () {
                      // استدعاء دالة إضافة طريقة الدفع عند النقر على STC Pay
                      addPaymentMethod('STC', 'دفع لجهة معينة باستخدام رقم الجوال');
                    },
                  ),
                  const Divider(),
                  PaymentOption(
                    title: 'إضافة بطاقة جديدة',
                    subtitle: 'لا يوجد لديك بطاقات مضافة',
                    logo: 'assets/icons/credit_card.png',
                    onTap: () {
                    
                      // addPaymentMethod('CARD', 'إضافة بطاقة جديدة');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddCardScreen()),
                    );
                    },
                  ),
                  const Divider(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final String logo;
  final VoidCallback onTap;

  const PaymentOption({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.logo,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // عندما يتم النقر على العنصر، يتم استدعاء onTap
      child: Row(
        children: [
          Image.asset(
            logo,
            width: 40,
            height: 40,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
