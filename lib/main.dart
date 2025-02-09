import 'package:flutter/material.dart';
import 'login_page.dart';  // Можно оставить, но не использовать
import 'register_page.dart';
import 'main_page.dart';

void main() {
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
      },
    );
  }
}
