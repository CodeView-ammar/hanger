import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/components/api_extintion/url_api.dart';
import 'package:shop/screens/checkout/tools/add_card_screen.dart';

class AddCardDetailsScreen extends StatefulWidget {
  const AddCardDetailsScreen({Key? key}) : super(key: key);

  @override
  _AddCardDetailsScreenState createState() => _AddCardDetailsScreenState();
}

class _AddCardDetailsScreenState extends State<AddCardDetailsScreen> {
  double? totalAmount;
  int laundryId =0; 

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // استلام المبلغ الإجمالي من الـ arguments
    final args = ModalRoute.of(context)?.settings.arguments as List<dynamic>?;
    if (args != null && args.length >= 2) {
      totalAmount = args[0] as double; // استلام المبلغ
      laundryId= args[1] as int; // استلام ID المغسلة
    }
  }

  Future<void> addPaymentMethod(String name, String description, BuildContext context) async {
    final url = Uri.parse(APIConfig.addPaymentUrl);
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
          'default': true,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('تم إضافة طريقة الدفع بنجاح');
        Navigator.pop(context);
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
      appBar: AppBar(
        title: const Text("اختر طريقة الدفع"),
      ),
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
            if (totalAmount != null) 
              Text(
                ' المبلغ الإجمالي: ${totalAmount!} ريال',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  PaymentOption(
                    title: 'الدفع الإلكتروني لاحقا او نقدأ',
                    subtitle: 'ادفع نقدا او ادفع إلكترونيا من خلال التطبيق بمجرد ان يستلم المندوب الطلب',
                    logo: 'assets/icons/money_hand.jpg',
                    total: totalAmount ?? 0.0, // ضمان عدم تمرير null
                    onTap: () {
                      addPaymentMethod('COD', 'الدفع عند الاستلام', context);
                    },
                  ),
                  const Divider(),
                  PaymentOption(
                    title: 'stc pay',
                    subtitle: 'ادفع لجهة معينة باستخدام رقم الجوال',
                    logo: 'assets/icons/stc_pay.png',
                    onTap: null, // الزر غير قابل للنقر
                    isReadOnly: true, // خاصية لجعل الزر للقراءة فقط
                    total: totalAmount ?? 0.0, // ضمان عدم تمرير null
                  ),
                  const Divider(),
                  PaymentOption(
                    title: 'إضافة بطاقة جديدة',
                    subtitle: 'لا يوجد لديك بطاقات مضافة',
                    logo: 'assets/icons/credit_card.png',
                    total: totalAmount ?? 0.0, // ضمان عدم تمرير null
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddCardScreen(total: totalAmount ?? 0.0, laundryId:laundryId), // ضمان عدم تمرير null
                        ),
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
  final VoidCallback? onTap; // جعل onTap من نوع Nullable
  final bool isReadOnly; // خاصية لجعل العنصر للقراءة فقط
  final double total;
  
  const PaymentOption({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.logo,
    this.onTap,
    this.isReadOnly = false, // القيمة الافتراضية هي false
    required this.total,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isReadOnly ? null : onTap, // إذا كان العنصر للقراءة فقط، فلا يتم استدعاء onTap
      child: Container(
        color: isReadOnly ? Colors.grey[200] : Colors.transparent, // تغيير لون الخلفية إذا كان للقراءة فقط
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isReadOnly ? Colors.grey : Colors.black, // تغيير اللون إذا كان للقراءة فقط
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (isReadOnly) // إضافة عنصر مرئي إذا كان للقراءة فقط
              const Icon(Icons.lock, color: Colors.grey), // أيقونة قفل
          ],
        ),
      ),
    );
  }
}