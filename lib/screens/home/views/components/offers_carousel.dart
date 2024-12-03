import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shop/components/Banner/M/banner_m_style_1.dart';
import 'package:shop/components/dot_indicators.dart';
import 'package:shop/components/api_extintion/url_api.dart';

import '../../../../constants.dart';

class OffersCarousel extends StatefulWidget {
  const OffersCarousel({
    super.key,
  });

  @override
  State<OffersCarousel> createState() => _OffersCarouselState();
}

class _OffersCarouselState extends State<OffersCarousel> {
  int _selectedIndex = 0;
  late PageController _pageController;
  late Timer _timer;
  List<Map<String, dynamic>> _bannerData = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    fetchBannerData();
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_selectedIndex < _bannerData.length - 1) {
        _selectedIndex++;
      } else {
        _selectedIndex = 0;
      }

      _pageController.animateToPage(
        _selectedIndex,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel();
    super.dispose();
  }

  Future<void> fetchBannerData() async {
    try {
      // Call the API to fetch the banner data
      final response = await http.get(Uri.parse(APIConfig.bannerEndpoint));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          _bannerData = data
              .map((item) => {
                    'image': item['image'],
                    'caption': utf8.decode(item['caption'].codeUnits),
                    'order': item['order'],
                  })
              .toList();
          _bannerData.sort((a, b) => a['order'].compareTo(b['order']));
        });
      } else {
        // Handle error cases
        print('Error fetching banner data: ${response.statusCode}');
      }
    } catch (e) {
      // Handle exceptions
      print('Error fetching banner data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.87,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _bannerData.length,
            onPageChanged: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final banner = _bannerData[index];
              return BannerMStyle1(
                text: banner['caption'],
                image: banner['image'] ?? "https://i.imgur.com/aA8ST9l.jpeg",
                press: () {
                  // Add your banner click logic here
                },
              );
            },
          ),
          FittedBox(
            child: Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: SizedBox(
                height: 16,
                child: Row(
                  children: List.generate(
                    _bannerData.length,
                    (index) {
                      return Padding(
                        padding:
                            const EdgeInsets.only(left: defaultPadding / 4),
                        child: DotIndicator(
                          isActive: index == _selectedIndex,
                          activeColor: Colors.white70,
                          inActiveColor: Colors.white54,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}