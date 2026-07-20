class ApiConfig {
  static String baseUrl = 'http://localhost:8000/api';
  static const Duration timeout = Duration(seconds: 30);

  static void setBaseUrl(String url) {
    baseUrl = url;
  }
}
