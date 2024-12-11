import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
  double calculateDistance(lat1, lon1, lat2, lon2){
    var p = 0.017453292519943295; //conversion factor from radians to decimal degrees, exactly math.pi/180
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 +
        c(lat1 * p) * c(lat2 * p) *
            (1 - c((lon2 - lon1) * p))/2;
    var radiusOfEarth = 6371;
    return radiusOfEarth * 2 * asin(sqrt(a));
  }
Future<String?> fetchTime(String location) async {
  try {
    // بناء عنوان URL باستخدام الموقع
    final url = 'http://worldtimeapi.org/api/timezone/$location';

    // إجراء طلب GET
    final response = await http.get(Uri.parse(url));

    // التحقق من حالة الاستجابة
    if (response.statusCode == 200) {
      // تحليل البيانات من JSON
      final data = jsonDecode(response.body);
      // جلب الوقت الحالي
      String datetime = data['datetime'];
      return datetime; // إرجاع الوقت
    } else {
      print('فشل في جلب البيانات: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('حدث خطأ: $e');
    return null;
  }
}