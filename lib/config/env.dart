class Env {
  static const bool isEmulator = true;

  static String get baseUrl {
    if (isEmulator) {
      return "http://10.0.2.2:3000";
    } else {
      return "http://192.168.1.5:3000";
    }
  }
}
