import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StravaService {
  static const String clientId = '152225'; // Клиент-ID из Strava
  static const String clientSecret = '57fedccaf04dd689aeadbd4c4a8e2e7f8aadf3'; // Секретный ключ
  static const String redirectUri = 'nonstop-backend-app1-dbf27.europe-west4.host.app'; // Callback URL
  static const String authUrl = 'https://www.strava.com/oauth/authorize';
  static const String tokenUrl = 'https://www.strava.com/oauth/token';

  /// Авторизация через Strava
  Future<String?> authenticate() async {
    final url = Uri.parse(
      '$authUrl?client_id=$clientId&redirect_uri=$redirectUri&response_type=code&scope=activity:read_all',
    );

    try {
      // Запускаем процесс авторизации через браузер
      final result = await FlutterWebAuth2.authenticate(
        url: url.toString(),
        callbackUrlScheme: 'nonstop-backend-app1-dbf27',
      );

      // Извлекаем код авторизации из результата
      final code = Uri.parse(result).queryParameters['code'];
      if (code == null) {
        throw Exception('Не удалось получить код авторизации');
      }

      // Обмениваем код на токен доступа
      final tokenResponse = await _exchangeCodeForToken(code);
      final accessToken = tokenResponse['access_token'];

      return accessToken;
    } catch (e) {
      print('Ошибка авторизации Strava: $e');
      return null;
    }
  }

  /// Обмен кода авторизации на токен доступа
  Future<Map<String, dynamic>> _exchangeCodeForToken(String code) async {
    final response = await http.post(
      Uri.parse(tokenUrl),
      body: {
        'client_id': clientId,
        'client_secret': clientSecret,
        'code': code,
        'grant_type': 'authorization_code',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Не удалось обменять код на токен: ${response.body}');
    }
  }
}