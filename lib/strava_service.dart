import 'dart:convert';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;

class StravaService {
  // ← Strava API ключи (замени при необходимости)
  static const String clientId = '152225';
  static const String clientSecret = 'b744e80833e46131b27087c7845425138bf32003';
  static const String redirectUri = 'https://app1-dbf27.firebaseapp.com';
  static const String callbackScheme = 'https';

  /// Авторизация и получение access_token от Strava
  Future<String?> authenticate() async {
    try {
      // Шаг 1: перенаправление на страницу авторизации
      final authUrl =
          'https://www.strava.com/oauth/authorize?client_id=$clientId&redirect_uri=$redirectUri&response_type=code&scope=activity:read_all';

      final result = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: callbackScheme,
      );

      // Шаг 2: получение authorization code
      final code = Uri.parse(result).queryParameters['code'];
      if (code == null) return null;

      // Шаг 3: обмен code на access_token
      final response = await http.post(
        Uri.parse('https://www.strava.com/oauth/token'),
        body: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'code': code,
          'grant_type': 'authorization_code',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['access_token'];
        print('✅ Strava access token: $accessToken');
        return accessToken;
      } else {
        print('❌ Ошибка получения токена: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❗ Ошибка авторизации Strava: $e');
      return null;
    }
  }
}
