import 'dart:convert';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;

/// Сервис для работы с API Strava: авторизация OAuth2 и загрузка данных
class StravaService {
  // ⚠️ Убедитесь, что эти параметры соответствуют вашему приложению Strava:
  static const String clientId = '152225';  // ID вашего приложения Strava
  static const String clientSecret = 'b744e80833e46131b27087c7845425138bf32003';  // Secret вашего приложения
  static const String redirectUri = 'https://app1-dbf27.firebaseapp.com';  // Redirect URI, указанный в настройках Strava
  static const String callbackScheme = 'https';  // Scheme для перехвата (соответствует схеме redirectUri)

  /// 1. OAuth авторизация пользователя через Strava.
  /// Возвращает словарь с `accessToken`, `refreshToken` и `expiresAt` или null, если не удалось.
  Future<Map<String, dynamic>?> authenticate() async {
    try {
      // Шаг 1: Открываем страницу авторизации Strava в браузере.
      final authUrl =
          'https://www.strava.com/oauth/authorize'
          '?client_id=$clientId'
          '&redirect_uri=$redirectUri'
          '&response_type=code'
          '&approval_prompt=auto'
          '&scope=activity:read_all';
      // Параметр scope=activity:read_all запрашивает доступ ко всем видам активностей пользователя.

      // Открываем системный браузер для авторизации. Пользователь вводит данные Strava.
      final result = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: callbackScheme,
      );

      // Шаг 2: Strava перенаправила на redirectUri. Извлекаем код авторизации из URL.
      final code = Uri.parse(result).queryParameters['code'];
      if (code == null) {
        print('❌ Не получен код авторизации Strava');
        return null;
      }

      // Шаг 3: Обмениваем authorization code на access token (и refresh token).
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
        final accessToken = data['access_token'];
        final refreshToken = data['refresh_token'];
        final expiresAt = data['expires_at']; // Время истечения (Epoch секунд)

        print('✅ Strava access token: $accessToken');
        // Вернём полученные токены и время истечения для сохранения в базе
        return {
          'accessToken': accessToken,
          'refreshToken': refreshToken,
          'expiresAt': expiresAt,
        };
      } else {
        print('❌ Ошибка получения токена Strava: ${tokenResponse.body}');
        return null;
      }
    } catch (e) {
      print('❗ Исключение при авторизации Strava: $e');
      return null;
    }
  }

  /// 2. Обновление (рефреш) токена доступа, если он истёк.
  /// Принимает сохранённый refreshToken, возвращает новую пару токенов или null при неудаче.
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
        // Обычно Strava вернёт новый access_token, refresh_token и expires_at
        return {
          'accessToken': data['access_token'],
          'refreshToken': data['refresh_token'],
          'expiresAt': data['expires_at'],
        };
      } else {
        print('❌ Ошибка обновления токена Strava: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❗ Исключение при обновлении токена: $e');
      return null;
    }
  }

  /// 3. Загрузка последних активностей пользователя и подсчёт очков.
  /// Использует переданный accessToken для доступа к API Strava.
  /// Возвращает количество баллов, начисленных за бег и ходьбу.
  Future<int> fetchActivityPoints(String accessToken) async {
    try {
      // Запрос последних 200 активностей пользователя (максимум, что позволяет Strava за раз).
      final response = await http.get(
        Uri.parse('https://www.strava.com/api/v3/athlete/activities?per_page=200'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );
      if (response.statusCode == 200) {
        final List activities = jsonDecode(response.body);
        double totalRunDistance = 0.0;   // суммарная дистанция бега в метрах
        double totalWalkDistance = 0.0;  // суммарная дистанция ходьбы (или пеших прогулок) в метрах

        for (var activity in activities) {
          if (activity is Map<String, dynamic>) {
            String type = activity['type'] ?? '';
            double distance = (activity['distance'] ?? 0).toDouble(); // дистанция в метрах
            if (type == 'Run') {
              totalRunDistance += distance;
            } else if (type == 'Walk' || type == 'Hike') {
              // Walk – прогулка, Hike – поход/пешая тренировка
              totalWalkDistance += distance;
            }
            // Можно обработать и другие типы, например, 'Ride' (велосипед), если нужно.
          }
        }

        // Переводим метры в километры и начисляем очки:
        double runKm = totalRunDistance / 1000.0;
        double walkKm = totalWalkDistance / 1000.0;
        // Правило начисления очков (можно настроить по своему усмотрению):
        int points = 0;
        points += (runKm * 20).round();   // 20 баллов за каждый км бега
        points += (walkKm * 8).round();   // 8 баллов за каждый км ходьбы
        print('ℹ️ Статистика Strava: бег ${runKm.toStringAsFixed(2)} км, ходьба ${walkKm.toStringAsFixed(2)} км, всего баллов = $points');

        return points;
      } else if (response.statusCode == 401) {
        // Неавторизовано: возможно, accessToken истёк.
        print('ℹ️ Токен Strava недействителен (401). Требуется refresh.');
        return -1; // сигнализируем, что нужен рефреш (обработка будет в вызывающем коде)
      } else {
        print('❌ Ошибка получения активностей Strava: ${response.statusCode} ${response.body}');
        return 0;
      }
    } catch (e) {
      print('❗ Исключение при загрузке данных Strava: $e');
      return 0;
    }
  }
}
