import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'https://repairserviceapi-a79i.onrender.com';
}