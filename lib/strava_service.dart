import 'dart:convert';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;

/// Сервис для работы с API Strava: авторизация OAuth2 и загрузка данных
class StravaService {
  // Данные вашего приложения Strava (зарегистрированного на https://developers.strava.com/)
  static const String clientId = '152225';
  static const String clientSecret = 'b744e80833e46131b27087c7845425138bf32003';

  // ⚠️ ВАЖНО: используем Custom Scheme, чтобы обойти ошибку 404 и вернуть управление в приложение
  static const String redirectUri = 'https://app1-dbf27.firebaseapp.com/redirect';
  static const String callbackScheme = 'https';


  /// Авторизация пользователя через Strava
  Future<Map<String, dynamic>?> authenticate() async {
    try {
      // 🔍 Логируем redirectUri
      print('🔗 redirectUri: $redirectUri');

      // Формируем URL авторизации Strava
      final authUrl =
          'https://www.strava.com/oauth/authorize'
          '?client_id=$clientId'
          '&redirect_uri=$redirectUri'
          '&response_type=code'
          '&approval_prompt=auto'
          '&scope=activity:read_all';

      // 🔍 Показываем весь URL авторизации
      print('🔗 FULL authUrl: $authUrl');

      // Запускаем авторизацию в браузере
      final result = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: callbackScheme,
      );

      // Извлекаем code из результата редиректа
      final code = Uri.parse(result).queryParameters['code'];
      if (code == null) {
        print('❌ Код авторизации Strava не получен');
        return null;
      }

      // Обмениваем code на access_token
      final tokenResponse = await http.post(
        Uri.parse('https://www.strava.com/oauth/token'),
        body: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'code': code,
          'grant_type': 'authorization_code',
        },
      );

      if (tokenResponse.statusCode == 200) {
        final data = jsonDecode(tokenResponse.body);
        return {
          'accessToken': data['access_token'],
          'refreshToken': data['refresh_token'],
          'expiresAt': data['expires_at'],
        };
      } else {
        print('❌ Ошибка при получении токена: ${tokenResponse.body}');
        return null;
      }
    } catch (e) {
      print('❗ Ошибка авторизации Strava: $e');
      return null;
    }
  }


  /// Обновление accessToken, если он истёк
  Future<Map<String, dynamic>?> refreshAccessToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse('https://www.strava.com/oauth/token'),
        body: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'accessToken': data['access_token'],
          'refreshToken': data['refresh_token'],
          'expiresAt': data['expires_at'],
        };
      } else {
        print('❌ Ошибка при обновлении токена: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❗ Ошибка при обновлении токена: $e');
      return null;
    }
  }

  /// Загрузка активностей пользователя и подсчёт очков
  Future<int> fetchActivityPoints(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('https://www.strava.com/api/v3/athlete/activities?per_page=200'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );
      if (response.statusCode == 200) {
        final List activities = jsonDecode(response.body);
        double runDistance = 0;
        double walkDistance = 0;

        for (var activity in activities) {
          final type = activity['type'];
          final distance = (activity['distance'] ?? 0).toDouble();

          if (type == 'Run') runDistance += distance;
          if (type == 'Walk' || type == 'Hike') walkDistance += distance;
        }

        final int runPoints = (runDistance / 1000 * 20).round();
        final int walkPoints = (walkDistance / 1000 * 8).round();
        final int total = runPoints + walkPoints;

        print("🏃 Бег: ${runPoints} очков, 🚶 Ходьба: ${walkPoints} очков");
        return total;
      } else if (response.statusCode == 401) {
        return -1; // токен истёк
      } else {
        print('❌ Ошибка загрузки активностей: ${response.statusCode}');
        return 0;
      }
    } catch (e) {
      print('❗ Ошибка получения данных с Strava: $e');
      return 0;
    }
  }
}
