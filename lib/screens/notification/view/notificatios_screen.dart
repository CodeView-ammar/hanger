import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => NotificationsScreenState();
}

class NotificationsScreenState extends State<NotificationsScreen> {
  final List<String> notifications = [
    'New product launched!',
    'Sale: Up to 50% off!',
    'Your order has been shipped.',
    'Reminder: You have a meeting at 3 PM.',
    'New message from support.',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('شعار'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // العودة إلى الشاشة السابقة
          },
        ),
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return NotificationTile(notification: notifications[index]);
        },
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final String notification;

  const NotificationTile({Key? key, required this.notification}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.notifications, color: Colors.blue),
      title: Text(notification),
      subtitle: const Text('Just now', style: TextStyle(color: Colors.grey)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        // يمكنك إضافة وظيفة عند الضغط على الإشعار
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tapped on: $notification')),
        );
      },
    );
  }
}