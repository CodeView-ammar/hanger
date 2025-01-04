import 'package:flutter/material.dart';
import 'package:moyasar/moyasar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shop/components/api_extintion/url_api.dart';
import 'package:shop/screens/checkout/views/review_order.dart';

class AddCardScreen extends StatefulWidget {
  final double total; // المبلغ الذي تم تمريره
  final int laundryId; // ID المغسلة

  AddCardScreen({super.key, required this.total, required this.laundryId});

  @override
  _AddCardScreenState createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  @override
  void initState() {
    super.initState();
  }

  void onPaymentResult(BuildContext context, PaymentResponse result) {
    if (result is PaymentResponse) {
      switch (result.status) {
        case PaymentStatus.paid:
          print("تم الدفع بنجاح");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("تم الدفع بنجاح")),
          );

          // حفظ بيانات البطاقة بعد التحقق من الدفع
          // saveCardData(result, context);
  // تأجيل الرجوع حتى بعد تحديث الشجرة
        WidgetsBinding.instance!.addPostFrameCallback((_) {
          // Navigator.pop(context, true);  // تم الدفع بنجاح
          // الانتقال إلى ReviewOrderScreen مع تمرير المتغيرات
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ReviewOrderScreen(
                laundryId: widget.laundryId,
                total: widget.total,
                isPaid: true,
                distance: 0,
                duration: '',
              ),
            ),
          );
        });
          break;
        case PaymentStatus.failed:
          print("فشل في الدفع");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("فشل في الدفع")),
          );
          break;
        // يمكنك إضافة معالجة للحالات الأخرى إذا لزم الأمر
        case PaymentStatus.initiated:
        case PaymentStatus.authorized:
        case PaymentStatus.captured:
          // TODO: Handle these cases if needed.
          break;
      }
    }
  }

  Future<void> saveCardData(PaymentResponse result, BuildContext context) async {
    // final url = Uri.parse('https://hanger.metasoft-ar.com/api/payment-methods-details/');

    // الحصول على البيانات من PaymentResponse أو مدخلات المستخدم
    // String cardNumber = "1123091231"; // استبدل هذا برقم البطاقة الفعلي
    // String cardHolderName = "عمار"; // استبدل هذا باسم صاحب البطاقة
    // String cardExpiryDate = "12/25"; // استبدل هذا بتاريخ انتهاء البطاقة
    // String cvv = "124"; // استبدل هذا بـ CVV الخاص بالبطاقة

    // final response = await http.post(
    //   url,
    //   headers: {
    //     'Content-Type': 'application/json',
    //   },
    //   body: jsonEncode({
    //     'card_name': cardHolderName,
    //     'card_number': cardNumber,
    //     'card_expiry_date': cardExpiryDate,
    //     'cvv': cvv,
    //     'payment_method': "CARD",
    //   }),
    // );

    // print(response.statusCode);
    // if (response.statusCode == 200 || response.statusCode == 201) {
    //   print("تم حفظ بيانات البطاقة بنجاح");
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text("تم حفظ بيانات البطاقة بنجاح")),
    //   );
    // } else {
    //   print("فشل في حفظ بيانات البطاقة: ${response.body}");
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text("فشل في حفظ بيانات البطاقة")),
    //   );
    // }
  }

  @override
  Widget build(BuildContext context) {
    final paymentConfig = PaymentConfig(
      publishableApiKey: APIConfig.apiPayment,
      amount: (widget.total * 100).toInt(),
      description: 'خصم 1 ريال للتحقق من البطاقة',
      metadata: {'size': '250g'},
      applePay: ApplePayConfig(
        merchantId: 'YOUR_MERCHANT_ID',
        label: 'معلاق',
        manual: false,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("إضافة وسيلة الدفع"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CreditCard(
              config: paymentConfig,
              onPaymentResult: (result) => onPaymentResult(context, result),
              locale: const Localization.ar(),
            ),
          ],
        ),
      ),
    );
  }
}