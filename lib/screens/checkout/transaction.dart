import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/components/api_extintion/url_api.dart';

Future<void> addTransaction(
    String transactionType,
    double amount,
    String description,
    BuildContext context) async {
  final url = Uri.parse(APIConfig.addTransactionEndpoint);
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userid');

  // إعداد القيم
  double debit = transactionType == 'debit' ? amount : 0;
  double credit = transactionType == 'credit' ? amount : 0;

  try {
    var http;
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(
        {
        'user': userId,
        'transaction_type': 'withdraw',
        'amount': amount,
        'debit': debit,
        'credit': credit,
        'description': description,
        }
      ),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      print('تم إضافة المعاملة بنجاح');
      Navigator.pop(context);
    } else {
      print('حدث خطأ: ${response.body}');
    }
  } catch (e) {
    print('فشل الاتصال بالخادم: $e');
  }
}