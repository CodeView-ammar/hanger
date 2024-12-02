class APIConfig {
  static const String _baseUrl = 'https://hanger.metasoft-ar.com/api';
  
  static String get launderiesEndpoint => '$_baseUrl/laundries/';
  static String get bannerEndpoint => '$_baseUrl/slide-show/';
  static String get userEndpoint => '$_baseUrl/users/register/';
  static String get markEndpoint_get => '$_baseUrl/user_laundry_marks_a/';
  static String get markEndpoint_delete => '$_baseUrl/user_laundry_marks_delete/';
  static String get servicesEndpoint => '$_baseUrl/services/';
  static String get otpphoneEndpoint => '$_baseUrl/user_phone/';
  static String get useraddEndpoint => '$_baseUrl/users/';
  static String get markerEndpoint => '$_baseUrl/user_laundry_marks/';


  static String get otpapiverifyEndpoint => "https://api.authentica.sa/api/sdk/v1/verifyOTP";
  static String get otpapisendOTPEndpoint => "https://api.authentica.sa/api/sdk/v1/sendOTP";
  
}