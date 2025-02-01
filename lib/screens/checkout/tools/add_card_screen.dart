import 'package:flutter/material.dart';
import 'package:moyasar/moyasar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shop/components/api_extintion/url_api.dart';
import 'package:shop/screens/checkout/transaction.dart';
import 'package:shop/screens/checkout/views/review_order.dart';
import 'package:shop/screens/discover/views/courier_order_details.dart';

class AddCardScreen extends StatefulWidget {
  final double total; // المبلغ الذي تم تمريره
  final int laundryId; // ID المغسلة
  final String? name_windows;

  AddCardScreen({
    super.key, 
    required this.total, 
    required this.laundryId,
    required this.name_windows,
  });

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
          // addTransaction(
          //   "debit",
          //   widget.total,
          //    "تم دفع المبلغ",
          //     context
          //     );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("تم الدفع بنجاح")),
          );
          // تأجيل الرجوع حتى بعد تحديث الشجرة
          WidgetsBinding.instance!.addPostFrameCallback((_) {
            // الانتقال إلى الشاشة المناسبة بناءً على `name_windows`
            if (widget.name_windows == "main") {
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
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => CourierOrderDetailsScreen(
                    orderId: widget.laundryId,
                    isPaid: true,
                  ),
                ),
              );
            }
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
          // يمكن معالجة هذه الحالات إذا لزم الأمر
          break;
      }
    }
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
