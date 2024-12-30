import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/screens/checkout/views/review_order.dart';

class AddedToCartMessageScreen extends StatelessWidget {
  final int laundryId;  // تحديد النوع كـ final لضمان أنه لا يتغير بعد تمريره

  // التأكد من أن laundryId ليس null بإعطائه قيمة افتراضية
  const AddedToCartMessageScreen({super.key, required this.laundryId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Column(
            children: [
              const Spacer(),
              Image.asset(
                Theme.of(context).brightness == Brightness.light
                    ? "assets/Illustration/success.png"
                    : "assets/Illustration/success_dark.png",
                height: MediaQuery.of(context).size.height * 0.3,
              ),
              const Spacer(flex: 2),
              Text(
                "اضافة للسلة",
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall!
                    .copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: defaultPadding / 2),
              const Text(
                "انقر على زر الخروج لإكمال عملية الشراء.",
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
              OutlinedButton(
                onPressed: () {
                  // إغلاق شاشة AddedToCartMessageScreen و BottomSheet
                  Navigator.pop(context); // إغلاق الشاشة الحالية (AddedToCartMessageScreen)
                  Navigator.pop(context); // إغلاق الـ BottomSheet المفتوح
                },
                child: const Text("مواصلة"),
              ),
              const SizedBox(height: defaultPadding),
              ElevatedButton(
                onPressed: () {
                  // التأكد من أن laundryId ليس null
                  final validLaundryId = laundryId ?? 0;  // تعيين قيمة افتراضية إذا كانت null
                  // الانتقال إلى شاشة ReviewOrderScreen مع تمرير laundryId
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReviewOrderScreen(laundryId: validLaundryId,total: 0.00,isPaid: false),
                    ),
                  );
                },
                child: const Text("الدفع"),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
