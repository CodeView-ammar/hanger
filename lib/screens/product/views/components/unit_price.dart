import 'package:flutter/material.dart';

import '../../../../constants.dart';

class UnitPrice extends StatelessWidget {
  const UnitPrice({
    super.key,
    required this.price,
    this.priceAfterDiscount,
  });

  final double price;
  final double? priceAfterDiscount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "سعر الخدمة",
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: defaultPadding / 1),
        Text.rich(
          TextSpan(
            text: priceAfterDiscount == null
                ? "\ر.س ${price.toStringAsFixed(2)}  "
                : "\ر.س ${priceAfterDiscount!.toStringAsFixed(2)}  ",
            style: Theme.of(context).textTheme.titleLarge,
            children: [
              if (priceAfterDiscount != null)
                TextSpan(
                  text: "\ر.س ${price.toStringAsFixed(2)}",
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium!.color,
                      decoration: TextDecoration.lineThrough),
                ),
            ],
          ),
        )
      ],
    );
  }
}
