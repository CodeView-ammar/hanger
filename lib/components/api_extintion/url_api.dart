class APIConfig {
  static const String _baseUrl = 'https://hanger.metasoft-ar.com/api';
  
  static String get launderiesEndpoint => '$_baseUrl/laundries/';
  static String get bannerEndpoint => '$_baseUrl/slide-show/';
  static String get userEndpoint => '$_baseUrl/users/register/';
  static String get markEndpoint => '$_baseUrl/user_laundry_marks/';
  static String get servicesEndpoint => '$_baseUrl/services/';
}