import 'package:flutter/material.dart';
import 'package:shop/constants.dart';

import 'components/best_sellers.dart';
import 'components/flash_sale.dart';
import 'components/most_popular.dart';
import 'components/offer_carousel_and_categories.dart';
import 'components/popular_products.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: OffersCarouselAndCategories()),
            SliverToBoxAdapter(child: BestSellers()),
            SliverToBoxAdapter(child: PopularProducts()),
            // SliverPadding(
            //   padding: EdgeInsets.symmetric(vertical: defaultPadding * 1.5),
            //   sliver: SliverToBoxAdapter(child: FlashSale()),
            // ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // While loading use 👇
                  // const BannerMSkelton(),‚
               
                  SizedBox(height: defaultPadding / 4),
                  // We have 4 banner styles, all in the pro version
                ],
              ),
            ),
            SliverToBoxAdapter(child: MostPopular()),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(height: defaultPadding * 1.5),

                  SizedBox(height: defaultPadding / 4),
                  // While loading use 👇
                  // const BannerSSkelton(),
                  
                  SizedBox(height: defaultPadding / 4),
                ],
              ),
            ),
            
          ],
        ),
      ),
    );
  }
}
