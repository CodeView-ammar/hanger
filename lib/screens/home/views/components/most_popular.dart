import 'package:flutter/material.dart';
import 'package:shop/components/product/secondary_product_card.dart';
import 'package:shop/models/book_mark_model.dart';

import '../../../../constants.dart';
import '../../../../route/route_constants.dart';

class MostPopular extends StatelessWidget {
  const MostPopular({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: defaultPadding / 2),
        Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Text(
            "الأكثر شعبية",
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        // While loading use 👇
        // SeconderyProductsSkelton(),
        SizedBox(
          height: 114,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            // Find bookMarkedProduct on models/ProductModel.dart
            itemCount: bookMarkedProduct.length,
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.only(
                left: defaultPadding,
                right: index == bookMarkedProduct.length - 1
                    ? defaultPadding
                    : 0,
              ),
              child: SecondaryProductCard(
                image: bookMarkedProduct[index].image,
                brandName: bookMarkedProduct[index].brandName,
                title: bookMarkedProduct[index].title,
                price: bookMarkedProduct[index].price,
                priceAfetDiscount: bookMarkedProduct[index].priceAfetDiscount,
                dicountpercent: bookMarkedProduct[index].dicountpercent,
                press: () {
                  Navigator.pushNamed(context, productDetailsScreenRoute,
                      arguments: index.isEven);
                },
              ),
            ),
          ),
        )
      ],
    );
  }
}
