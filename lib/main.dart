import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // ✅ Подключаем Firebase
import 'login_page.dart';  // Можно оставить, но не использовать
import 'register_page.dart';
import 'main_page.dart';
import 'profile_page.dart';
import 'edit_profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ✅ Обязательно перед инициализацией Firebase
  await Firebase.initializeApp(); // ✅ Инициализация Firebase

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/main',  // ✅ Теперь сразу открывается главная страница
      routes: {
        // '/login': (context) => LoginPage(),  // 🔴 Закомментировано, чтобы не открывалось
        '/register': (context) => RegisterPage(),
        '/main': (context) => MainPage(),
        '/profile': (context) => ProfilePage(),
        '/edit-profile': (context) => EditProfilePage(),
      },
    );
  }
}
