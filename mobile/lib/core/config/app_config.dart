class AppConfig {
  const AppConfig._();

  // Android emulator -> 10.0.2.2
  // Real phone on same Wi-Fi -> replace with your PC's LAN IP
  static const String apiBaseUrl = 'http://10.0.2.2:8000/api/v1';
}