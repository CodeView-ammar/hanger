import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:moyasar/moyasar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/screens/checkout/tools/model/paymodel.dart';
import 'package:shop/screens/checkout/tools/model/source/creditcardmodel.dart';
import 'package:shop/screens/checkout/tools/moyasar_payment.dart';
import 'package:geideapay/geideapay.dart';
import 'package:geideapay/models/address.dart';
import 'package:geideapay/widgets/checkout/checkout_options.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({Key? key}) : super(key: key);

  @override
  _AddCardScreenState createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _plugin = GeideapayPlugin();
  bool _isInitialized = false; // لتتبع حالة التهيئة

  @override
  void initState() {
    super.initState();
    _initializePlugin(); // تهيئة SDK عند بدء التشغيل
  }

  Future<void> _initializePlugin() async {
    try {
      var serverEnvironment = ServerEnvironment;
      await _plugin.initialize(
        publicKey: "0293c7c6-c005-41d8-821b-132af79602e5",
        apiPassword: "9ce86693-0b09-476b-853f-87a8d966b50d",
        serverEnvironment:ServerEnvironmentModel("KSA-PROD","https://api.ksamerchant.geidea.net","https://www.ksamerchant.geidea.net/hpp/checkout/?") , // تعيين البيئة حسب الحاجة
      );
      setState(() {
        _isInitialized = true; // تم التهيئة بنجاح
      });
    } catch (e) {
      _showMessage("Geideapay SDK has not been initialized.");// التعامل مع الأخطاء إذا لزم الأمر
    }
  }

  // دالة لبدء عملية الدفع
  Future<void> _startPaymentProcess() async {
    if (!_isInitialized) {
      _showMessage("Geideapay SDK has not been initialized.");
      return; // لا تبدأ عملية الدفع إذا لم يتم التهيئة
    }

    try {
      Address billingAddress = Address(
        city: "Riyadh",
        countryCode: "SAU",
        street: "Street 1",
        postCode: "1000",
      );
      Address shippingAddress = Address(
        city: "Riyadh",
        countryCode: "SAU",
        street: "Street 1",
        postCode: "1000",
      );

      CheckoutOptions checkoutOptions = CheckoutOptions(
        123.45,
        "SAR",
        callbackUrl: "https://website.hook/", // Optional
        returnUrl: "https://returnurl.com", 
        lang: "AR", // Optional
        billingAddress: billingAddress, // Optional
        shippingAddress: shippingAddress, // Optional
        customerEmail: "email@noreply.test", // Optional
        merchantReferenceID: "1234", // Optional
        paymentIntentId: null, // Optional
        paymentOperation: "Pay", // Optional
        showAddress: true, // Optional
        showEmail: true, // Optional
      );

      OrderApiResponse response = await _plugin.checkout(
        context: context,
        checkoutOptions: checkoutOptions,
      );

      _showMessage("Geideapay SDK has not been initialized.");
      // Payment successful, order returned in response
      print(response.detailedResponseMessage);
      print(response.toString());
      // _updateStatus(response.detailedResponseMessage, truncate(response.toString()));
    } catch (e) {
      _showMessage("Geideapay SDK has not been initialized.");// _showMessage(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Card"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _isInitialized ? _startPaymentProcess : null,
          child: const Text("Start Payment"),
        ),
      ),
    );
  }
void _showMessage(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
}

