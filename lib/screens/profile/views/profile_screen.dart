import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shop/components/list_tile/divider_list_tile.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'components/profile_card.dart';
import 'components/profile_menu_item_list_tile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<String> getUserPhoneNumber() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userPhone') ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<String>(
        future: getUserPhoneNumber(),  // استدعاء الدالة غير المتزامنة
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // عرض مؤشر التحميل أثناء الانتظار
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // في حال حدوث خطأ أثناء جلب البيانات
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            // في حال جلب البيانات بنجاح
            String userPhoneNumber = snapshot.data!;
            return ListView(
              children: [
                ProfileCard(
                  name: userPhoneNumber,
                  email: "ammarwadood0@gmail.com",
                  imageSrc: "https://i.imgur.com/aA8ST9l.jpeg",
                  press: () {
                    Navigator.pushNamed(context, userInfoScreenRoute);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: defaultPadding, vertical: defaultPadding * 1.5),

                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                  child: Text(
                    "حساب",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(height: defaultPadding / 2),
                ProfileMenuListTile(
                  text: "طلبات",
                  svgSrc: "assets/icons/Order.svg",
                  press: () {
                    Navigator.pushNamed(context, ordersScreenRoute);
                  },
                ),
                // ProfileMenuListTile(
                //   text: "المرتجعات",
                //   svgSrc: "assets/icons/Return.svg",
                //   press: () {},
                // ),
                // ProfileMenuListTile(
                //   text: "قائمة الرغبات",
                //   svgSrc: "assets/icons/Wishlist.svg",
                //   press: () {},
                // ),
                ProfileMenuListTile(
                  text: "العناوين",
                  svgSrc: "assets/icons/Address.svg",
                  press: () {
                    Navigator.pushNamed(context, addressesScreenRoute);
                  },
                ),
                // ProfileMenuListTile(
                //   text: "قسط",
                //   svgSrc: "assets/icons/card.svg",
                //   press: () {
                //     Navigator.pushNamed(context, emptyPaymentScreenRoute);
                //   },
                // ),
                ProfileMenuListTile(
                  text: "محفظة",
                  svgSrc: "assets/icons/Wallet.svg",
                  press: () {
                    Navigator.pushNamed(context, walletScreenRoute);
                  },
                ),
                const SizedBox(height: defaultPadding),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: defaultPadding, vertical: defaultPadding / 2),
                  child: Text(
                    "التخصيص",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                DividerListTileWithTrilingText(
                  svgSrc: "assets/icons/Notification.svg",
                  title: "إشعار",
                  trilingText: "Off",
                  press: () {
                    Navigator.pushNamed(context, enableNotificationScreenRoute);
                  },
                ),
                // ProfileMenuListTile(
                //   text: "التفضيلات",
                //   svgSrc: "assets/icons/Preferences.svg",
                //   press: () {
                //     Navigator.pushNamed(context, preferencesScreenRoute);
                //   },
                // ),
                const SizedBox(height: defaultPadding),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: defaultPadding, vertical: defaultPadding / 2),
                  child: Text(
                    "إعدادات",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                // ProfileMenuListTile(
                //   text: "لغة",
                //   svgSrc: "assets/icons/Language.svg",
                //   press: () {
                //     Navigator.pushNamed(context, selectLanguageScreenRoute);
                //   },
                // ),
                ProfileMenuListTile(
                  text: "موقع",
                  svgSrc: "assets/icons/Location.svg",
                  press: () {},
                ),
                const SizedBox(height: defaultPadding),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: defaultPadding, vertical: defaultPadding / 2),
                  child: Text(
                    "المساعدة والدعم",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                ProfileMenuListTile(
                  text: "احصل على المساعدة",
                  svgSrc: "assets/icons/Help.svg",
                  press: () {
                    Navigator.pushNamed(context, getHelpScreenRoute);
                  },
                ),
                ProfileMenuListTile(
                  text: "التعليمات",
                  svgSrc: "assets/icons/FAQ.svg",
                  press: () {
                    Navigator.pushNamed(context, instructionsScreenRoute);

                  },
                  isShowDivider: false,
                ),
                const SizedBox(height: defaultPadding),

                // تسجيل الخروج
                ListTile(
                  onTap: () async {
                    // تنفيذ عملية تسجيل الخروج هنا
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    await prefs.clear(); // مسح جميع البيانات المخزنة

                    // الانتقال إلى شاشة تسجيل الدخول
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      logInScreenRoute, // إعادة التوجيه إلى شاشة تسجيل الدخول
                      (route) => false, // إزالة جميع الشاشات السابقة
                    );
                  },
                  minLeadingWidth: 24,
                  leading: SvgPicture.asset(
                    "assets/icons/Logout.svg",
                    height: 24,
                    width: 24,
                    colorFilter: const ColorFilter.mode(
                      errorColor,
                      BlendMode.srcIn,
                    ),
                  ),
                  title: const Text(
                    "تسجيل الخروج",
                    style: TextStyle(color: errorColor, fontSize: 14, height: 1),
                  ),
                ),
              ],
            );
          } else {
            return Center(child: Text('No data found.'));
          }
        },
      ),
    );
  }
}
