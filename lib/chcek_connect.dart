import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class CheckConnection extends StatefulWidget {
  final Widget child;

  const CheckConnection({Key? key, required this.child}) : super(key: key);

  @override
  _CheckConnectionState createState() => _CheckConnectionState();
}

class _CheckConnectionState extends State<CheckConnection> {
  StreamSubscription? internetConnection;
  bool isOffline = false;
  //set variable for Connectivity subscription listener

  @override
  void initState() {
    internetConnection =
        Connectivity().onConnectivityChanged.listen((connectivityResult) {
      if (connectivityResult.contains(ConnectivityResult.none)) {
        //there is no any connection
        setState(() {
          isOffline = true;
        });
      } else if (connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.wifi)) {
        //connection is from Wifi or Mobile
        setState(() {
          isOffline = false;
        });
      }
    });
    super.initState();
  }
  @override
  void dispose() {
    internetConnection?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (isOffline) _buildErrorMessage("لا يوجد اتصال بالإنترنت"),
          widget.child, // عرض محتوى التطبيق
        ],
      ),
    );
  }

  // دالة لعرض رسالة الخطأ
  Widget _buildErrorMessage(String text) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(10.0),
        color: Colors.red,
        child: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 6),
            Text(text, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
