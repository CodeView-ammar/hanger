// For demo only
import 'package:shop/constants.dart';

class ProductModel {
  final String image, brandName, title;
  final double price;
  final double? priceAfetDiscount;
  final int? dicountpercent;

  ProductModel({
    required this.image,
    required this.brandName,
    required this.title,
    required this.price,
    this.priceAfetDiscount,
    this.dicountpercent,
  });
}

List<ProductModel> demoFlashSaleProducts = [
  ProductModel(
    image: productDemoImg5,
    title: "مغسلة العطاء",
    brandName: "الرياض",
    price: 650.62,
    priceAfetDiscount: 390.36,
    dicountpercent: 40,
  ),
];


List<ProductModel> demoBestSellersProducts = [
  ProductModel(
    image: "https://i.imgur.com/aA8ST9l.jpeg",
    title: "مغسلة الحياة",
    brandName: "الرياض",
    price: 650.62,
    priceAfetDiscount: 390.36,
    dicountpercent: 40,
  ),
];



List<ProductModel> kidsProducts = [
  ProductModel(
    image: "https://i.imgur.com/aA8ST9l.jpeg",
    title: "مغسلة الحياة",
    brandName: "الرياض",
    price: 650.62,
    priceAfetDiscount: 590.36,
    dicountpercent: 24,
  ),
];
