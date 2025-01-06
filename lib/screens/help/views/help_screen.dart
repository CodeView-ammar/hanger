import 'package:flutter/material.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  _HelpScreenState createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  bool isTechHelpSelected = false;
  bool isGeneralHelpSelected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("احصل على المساعدة"),
      ),
      body: SingleChildScrollView( // إضافة خاصية التمرير
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // نص الترحيب
            const Text(
              'كيف يمكننا مساعدتك؟',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // خيارات المساعدة
            const Text(
              'اختر نوع المساعدة التي تحتاجها:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),

            // Checkbox للمساعدة التقنية
            CheckboxListTile(
              title: const Text("المساعدة التقنية"),
              value: isTechHelpSelected,
              onChanged: (bool? value) {
                setState(() {
                  isTechHelpSelected = value!;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: Colors.blue,
              contentPadding: EdgeInsets.zero,
            ),

            // Checkbox للدعم العام
            CheckboxListTile(
              title: const Text("الدعم العام"),
              value: isGeneralHelpSelected,
              onChanged: (bool? value) {
                setState(() {
                  isGeneralHelpSelected = value!;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: Colors.blue,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 20),

            // نموذج لإدخال استفسار أو مشكلة
            const Text(
              'أو يمكنك كتابة استفسارك هنا:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                labelText: 'أدخل استفسارك أو مشكلتك',
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
              maxLines: 4,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 20),

            // زر إرسال المساعدة
            ElevatedButton(
              onPressed: () {
                // إرسال الطلب
                _sendHelpRequest(context);
              },
              child: const Text("إرسال طلب المساعدة"),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ), 
              ),
            ),
          ],
        ),
      ),
    );
  }

  // دالة لإرسال طلب المساعدة
  void _sendHelpRequest(BuildContext context) {
    // يمكنك إضافة أي منطق آخر هنا لإرسال البيانات أو معالجة الطلب
    String selectedHelp = "";
    if (isTechHelpSelected) selectedHelp += "المساعدة التقنية ";
    if (isGeneralHelpSelected) selectedHelp += "الدعم العام";

    if (selectedHelp.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إرسال طلب المساعدة لـ: $selectedHelp')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تحديد نوع المساعدة')),
      );
    }
  }
}
