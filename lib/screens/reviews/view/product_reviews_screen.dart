import 'package:flutter/material.dart';

class ProductReviewsScreen extends StatefulWidget {
  const ProductReviewsScreen({super.key});

  @override
  _ProductReviewsScreenState createState() => _ProductReviewsScreenState();
}

class _ProductReviewsScreenState extends State<ProductReviewsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final List<String> _comments = []; // قائمة لتخزين التعليقات

  void _addComment() {
    if (_commentController.text.isNotEmpty) {
      setState(() {
        _comments.add(_commentController.text); // إضافة التعليق إلى القائمة
        _commentController.clear(); // مسح حقل الإدخال بعد الإضافة
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("التعليقات"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _comments.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(_comments[index]),
                    ),
                  );
                },
              ),
            ),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: "أضف تعليقك هنا...",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _addComment,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
