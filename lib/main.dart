import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'main_page.dart';
import 'profile_page.dart';
import 'edit_profile_page.dart';
import 'team_selection_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthChecker(), // 🔥 Проверяем, куда отправлять пользователя
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/team-selection': (context) => TeamSelectionPage(),
        '/main': (context) => MainPage(),
        '/profile': (context) => ProfilePage(),
        '/edit-profile': (context) => EditProfilePage(),
      },
    );
  }
}

/// ✅ Проверяем, вошёл ли пользователь и есть ли у него команда
class AuthChecker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // 🔥 Следим за входом/выходом пользователя
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        User? user = snapshot.data;

        if (user == null) {
          // 🔥 Если пользователь НЕ вошёл → отправляем в LoginPage
          return LoginPage();
        }

        // 🔥 Если пользователь вошёл, проверяем его команду
        return FutureBuilder(
          future: _checkUserTeam(user.uid),
          builder: (context, AsyncSnapshot<bool> teamSnapshot) {
            if (teamSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (teamSnapshot.hasError) {
              return Scaffold(body: Center(child: Text("Ошибка: ${teamSnapshot.error}")));
            }
            return teamSnapshot.data == true ? MainPage() : TeamSelectionPage();
          },
        );
      },
    );
  }

  /// 🔥 Проверяем Firestore, состоит ли пользователь в команде
  Future<bool> _checkUserTeam(String userId) async {
    QuerySnapshot teams = await FirebaseFirestore.instance
        .collection('teams')
        .where('members', arrayContains: userId)
        .get();

    return teams.docs.isNotEmpty; // ✅ Если есть команда → true, иначе false
  }
}
